import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../core/models.dart';
import '../core/database_helper.dart';
import '../providers/doctor_visits_provider.dart';
import 'package:lottie/lottie.dart';

class DoctorVisitsScreen extends StatefulWidget {
  const DoctorVisitsScreen({super.key});

  @override
  State<DoctorVisitsScreen> createState() => _DoctorVisitsScreenState();
}

class _DoctorVisitsScreenState extends State<DoctorVisitsScreen> {
  final Set<int> _expandedVisitIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorVisitsProvider>(context, listen: false).loadAll();
    });
  }

  void _showAddVisitBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
      ),
      builder: (context) {
        return const AddVisitBottomSheet();
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatMonthYear(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(parsed);
    } catch (_) {
      return 'Other';
    }
  }

  void _shareVisitDetails(DoctorVisit visit) {
    final details = '''
MediTrack Doctor Visit Details:
Doctor: ${visit.doctorName}
Hospital: ${visit.hospital}
Date: ${_formatDate(visit.visitDate)}
Diagnosis: ${visit.diagnosis ?? 'None'}
Notes: ${visit.notes ?? 'No notes recorded.'}
${visit.followUpDate != null ? 'Follow-up Date: ${_formatDate(visit.followUpDate!)}' : ''}
''';
    Clipboard.setData(ClipboardData(text: details));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Visit details copied to clipboard to share!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text('Doctor Visits', style: context.titleLarge),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: context.colors.textPrimary),
              onPressed: _showAddVisitBottomSheet,
            ),
            const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
          ],
          bottom: TabBar(
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.primary,
            labelStyle: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: context.bodyMedium,
            tabs: const [
              Tab(text: 'Timeline'),
              Tab(text: 'Follow-ups'),
              Tab(text: 'Diagnoses'),
            ],
          ),
        ),
        body: Consumer<DoctorVisitsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.visits.isEmpty) {
              return _buildEmptyState();
            }

            return TabBarView(
              children: [
                _buildTimelineTab(provider),
                _buildFollowupsTab(provider),
                _buildDiagnosesTab(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 80,
              color: context.colors.textHint,
            ),
            const SizedBox(height: MediTrackSpacing.large),
            Text(
              'No doctor visits recorded',
              style: context.titleLarge.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: MediTrackSpacing.large),
            ElevatedButton(
              onPressed: _showAddVisitBottomSheet,
              child: const Text('Add Your First Visit'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TIMELINE TAB ---
  Widget _buildTimelineTab(DoctorVisitsProvider provider) {
    // Group visits by Month Year
    final sortedVisits = List<DoctorVisit>.from(provider.visits);
    sortedVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate)); // Newest first

    final Map<String, List<DoctorVisit>> grouped = {};
    for (var v in sortedVisits) {
      final key = _formatMonthYear(v.visitDate);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(v);
    }

    final keys = grouped.keys.toList();

    return CustomScrollView(
      slivers: keys.expand((month) {
        final monthVisits = grouped[month]!;
        return [
          SliverPersistentHeader(
            pinned: true,
            delegate: MonthHeaderDelegate(monthStr: month),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding, vertical: 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final visit = monthVisits[index];
                  final isExpanded = _expandedVisitIds.contains(visit.id);
                  final prescription = provider.prescriptions.firstWhere(
                    (p) => p.id == visit.prescriptionId,
                    orElse: () => Prescription(id: -1, imagePath: ''),
                  );

                  return Slidable(
                    key: ValueKey(visit.id ?? index),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) async {
                            final confirm = await showConfirmDeleteDialog(
                              context,
                              title: 'Delete Visit',
                              content: 'Are you sure you want to delete this doctor visit entry?',
                            );
                            if (confirm == true && visit.id != null) {
                              provider.deleteVisit(visit.id!);
                            }
                          },
                          backgroundColor: context.colors.errorSos,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedVisitIds.remove(visit.id);
                            } else if (visit.id != null) {
                              _expandedVisitIds.add(visit.id!);
                            }
                          });
                        },
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 4,
                                color: visit.followUpDate != null
                                    ? context.colors.warning
                                    : context.colors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.local_hospital_outlined, size: 20, color: context.colors.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              visit.doctorName,
                                              style: context.titleMedium,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: context.colors.primaryLight,
                                              borderRadius: BorderRadius.circular(MediTrackRadius.chipsBadges),
                                            ),
                                            child: Text(
                                              _formatDate(visit.visitDate),
                                              style: context.labelSmall.copyWith(
                                                color: context.colors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        visit.hospital,
                                        style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Diagnosis: ',
                                            style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Expanded(
                                            child: Text(
                                              visit.diagnosis ?? 'General Checkup',
                                              style: context.bodyMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: visit.followUpDate != null
                                                  ? context.colors.warningLight
                                                  : context.colors.successLight,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              visit.followUpDate != null ? 'Follow-up' : 'Completed',
                                              style: context.labelSmall.copyWith(
                                                color: visit.followUpDate != null
                                                    ? context.colors.warning
                                                    : context.colors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        height: isExpanded ? null : 0,
                                        child: isExpanded
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Divider(height: 16),
                                                  Text(
                                                    'Consultation Notes:',
                                                    style: context.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    visit.notes ?? 'No notes recorded.',
                                                    style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                                                  ),
                                                  if (visit.followUpDate != null) ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.event, size: 16, color: context.colors.warning),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Follow-up scheduled on ${_formatDate(visit.followUpDate!)}',
                                                          style: context.bodySmall.copyWith(color: context.colors.warning, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  if (prescription.id != -1) ...[
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Prescription:',
                                                      style: context.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    InkWell(
                                                      onTap: () => _viewPrescriptionImage(prescription.imagePath),
                                                      child: Row(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius: BorderRadius.circular(8),
                                                            child: Image.file(
                                                              File(prescription.imagePath),
                                                              width: 50,
                                                              height: 50,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (_, __, ___) => Container(
                                                                width: 50,
                                                                height: 50,
                                                                color: context.colors.dividerColor,
                                                                child: const Icon(Icons.broken_image, size: 20),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text('Tap to view Prescription', style: context.bodySmall.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
                                                                if (prescription.notes != null)
                                                                  Text(prescription.notes!, style: context.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      TextButton.icon(
                                                        icon: const Icon(Icons.share, size: 16),
                                                        label: const Text('Share'),
                                                        onPressed: () => _shareVisitDetails(visit),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              )
                                            : const SizedBox(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: monthVisits.length,
              ),
            ),
          )
        ];
      }).toList(),
    );
  }

  void _viewPrescriptionImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(40),
                    color: Colors.white,
                    child: const Column(
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Image file not found'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FOLLOW-UPS TAB ---
  Widget _buildFollowupsTab(DoctorVisitsProvider provider) {
    final upcoming = provider.upcomingFollowups;
    final overdue = provider.overdueFollowups;

    return ListView(
      padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
      children: [
        // Summary Header Card
        Card(
          color: context.colors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${upcoming.length}',
                      style: context.headlineMedium.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Upcoming', style: context.bodySmall.copyWith(color: context.colors.primary)),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: context.colors.dividerColor,
                ),
                Column(
                  children: [
                    Text(
                      '${overdue.length}',
                      style: context.headlineMedium.copyWith(
                        color: overdue.isNotEmpty ? context.colors.errorSos : context.colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overdue',
                      style: context.bodySmall.copyWith(
                        color: overdue.isNotEmpty ? context.colors.errorSos : context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (overdue.isNotEmpty) ...[
          Text('Overdue Follow-ups', style: context.titleMedium.copyWith(color: context.colors.errorSos, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...overdue.map((v) => _buildFollowupCard(v, isOverdue: true, provider: provider)),
          const SizedBox(height: 16),
        ],

        Text('Upcoming Follow-ups', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: Lottie.network(
                    'https://lottie.host/c5c8e3cc-7257-4148-be2a-fbba2f07d2f4/k5aB5D6G4N.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.event_available_outlined,
                      size: 80,
                      color: context.colors.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No upcoming follow-ups! 🎉',
                  style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...upcoming.map((v) => _buildFollowupCard(v, isOverdue: false, provider: provider)),
      ],
    );
  }

  Widget _buildFollowupCard(DoctorVisit visit, {required bool isOverdue, required DoctorVisitsProvider provider}) {
    // Calculate days difference
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final fDate = DateTime.parse(visit.followUpDate!);
    final diff = fDate.difference(today).inDays;

    final badgeColor = isOverdue
        ? context.colors.errorSos.withOpacity(0.1)
        : (diff == 0 ? context.colors.warning.withOpacity(0.1) : context.colors.primaryLight);
    final badgeTextColor = isOverdue
        ? context.colors.errorSos
        : (diff == 0 ? context.colors.warning : context.colors.primary);

    final badgeText = isOverdue
        ? 'Overdue by ${diff.abs()} day${diff.abs() == 1 ? "" : "s"}'
        : (diff == 0 ? 'Today' : 'In $diff day${diff == 1 ? "" : "s"}');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    visit.doctorName,
                    style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: context.labelSmall.copyWith(color: badgeTextColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              visit.hospital,
              style: context.bodySmall.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: context.colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Follow-up: ${_formatDate(visit.followUpDate!)}',
                  style: context.bodySmall,
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: const Text('Reschedule'),
                  onPressed: () => _rescheduleFollowUp(visit, provider),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Visited'),
                  onPressed: () async {
                    if (visit.id != null) {
                      await provider.markFollowupDone(visit.id!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Follow-up marked as completed!')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rescheduleFollowUp(DoctorVisit visit, DoctorVisitsProvider provider) async {
    final initialDate = visit.followUpDate != null ? DateTime.parse(visit.followUpDate!) : DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(DateTime.now()) ? DateTime.now() : initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null) {
      final updated = DoctorVisit(
        id: visit.id,
        userId: visit.userId,
        doctorName: visit.doctorName,
        hospital: visit.hospital,
        visitDate: visit.visitDate,
        diagnosis: visit.diagnosis,
        notes: visit.notes,
        followUpDate: DateFormat('yyyy-MM-dd').format(newDate),
        prescriptionId: visit.prescriptionId,
      );
      await provider.updateVisit(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rescheduled follow-up to ${DateFormat('dd MMM yyyy').format(newDate)}')),
        );
      }
    }
  }

  // --- DIAGNOSES TAB ---
  Widget _buildDiagnosesTab(DoctorVisitsProvider provider) {
    final visitsByDoc = provider.visitsByDoctor;
    final docNames = visitsByDoc.keys.toList();

    // Prepare chart data: Count occurrences of each diagnosis
    final Map<String, int> diagCounts = {};
    for (var v in provider.visits) {
      if (v.diagnosis != null && v.diagnosis!.trim().isNotEmpty) {
        final d = v.diagnosis!.trim();
        diagCounts[d] = (diagCounts[d] ?? 0) + 1;
      }
    }

    // Sort diagnoses by count descending
    final sortedDiags = diagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
      children: [
        // Diagnoses List by Doctor
        Text('Diagnoses by Doctor', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...docNames.map((doc) {
          final docVisits = visitsByDoc[doc]!;
          final uniqueDiags = docVisits
              .map((v) => v.diagnosis ?? 'General Checkup')
              .toSet()
              .toList();

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 20, color: context.colors.primary),
                      const SizedBox(width: 8),
                      Text(doc, style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: uniqueDiags.map((diag) {
                      return Chip(
                        label: Text(diag),
                        backgroundColor: context.colors.primaryLight.withOpacity(0.5),
                        labelStyle: context.labelSmall.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600),
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Diagnosis Frequency Chart
        if (sortedDiags.isNotEmpty) ...[
          Text('Diagnosis Frequencies', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 220,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(MediTrackRadius.cards),
              border: Border.all(color: context.colors.dividerColor),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (sortedDiags.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.colors.primary.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final name = sortedDiags[groupIndex].key;
                      return BarTooltipItem(
                        '$name\n${rod.toY.toInt()} visit(s)',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < sortedDiags.length) {
                          final label = sortedDiags[idx].key;
                          final abbrev = label.length > 8 ? '${label.substring(0, 7)}…' : label;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(abbrev, style: context.labelSmall),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: sortedDiags.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final count = entry.value.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: context.colors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

// --- Month Header Delegate for Sticky Headers ---
class MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String monthStr;

  MonthHeaderDelegate({required this.monthStr});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.colors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.primaryLight,
          borderRadius: BorderRadius.circular(MediTrackRadius.chipsBadges),
        ),
        child: Text(
          monthStr,
          style: context.titleMedium.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 44.0;

  @override
  double get minExtent => 44.0;

  @override
  bool shouldRebuild(covariant MonthHeaderDelegate oldDelegate) {
    return oldDelegate.monthStr != monthStr;
  }
}

// --- ADD VISIT BOTTOM SHEET ---
class AddVisitBottomSheet extends StatefulWidget {
  final String? initialNotes;
  final String? initialDiagnosis;
  const AddVisitBottomSheet({super.key, this.initialNotes, this.initialDiagnosis});

  @override
  State<AddVisitBottomSheet> createState() => _AddVisitBottomSheetState();
}

class _AddVisitBottomSheetState extends State<AddVisitBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  DateTime? _followUpDate;

  int? _selectedPrescriptionId;

  @override
  void initState() {
    super.initState();
    if (widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
    }
    if (widget.initialDiagnosis != null) {
      _diagnosisController.text = widget.initialDiagnosis!;
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _hospitalController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<DoctorVisitsProvider>(context, listen: false);

    final visit = DoctorVisit(
      doctorName: _doctorController.text.trim(),
      hospital: _hospitalController.text.trim(),
      visitDate: DateFormat('yyyy-MM-dd').format(_visitDate),
      diagnosis: _diagnosisController.text.trim().isNotEmpty ? _diagnosisController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      followUpDate: _followUpDate != null ? DateFormat('yyyy-MM-dd').format(_followUpDate!) : null,
      prescriptionId: _selectedPrescriptionId,
    );

    // Save doctor visit
    await provider.addVisit(visit);

    // Fetch the newly added visit to get its ID if we need to link prescriptions
    final visits = provider.visits;
    DoctorVisit? savedVisit;
    if (visits.isNotEmpty) {
      savedVisit = visits.first; // Since sorted by date desc, or we can find matching details
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor visit saved successfully!')),
      );
      Navigator.pop(context); // Close the bottom sheet first
    }

    // Now offer prescription attachment prompt if not linked
    if (_selectedPrescriptionId == null && savedVisit != null && savedVisit.id != null) {
      _promptPrescriptionUpload(savedVisit);
    }
  }

  void _promptPrescriptionUpload(DoctorVisit savedVisit) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.cards),
            side: BorderSide(color: ctx.colors.dividerColor, width: 0.8),
          ),
          title: Text('Attach Prescription?', style: ctx.titleLarge),
          content: Text('Would you like to take a photo or upload a prescription for this visit now?', style: ctx.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Skip', style: TextStyle(color: ctx.colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _pickNewPrescriptionImage(savedVisit, ImageSource.gallery);
              },
              child: Text('Gallery', style: TextStyle(color: ctx.colors.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _pickNewPrescriptionImage(savedVisit, ImageSource.camera);
              },
              child: Text('Camera', style: TextStyle(color: ctx.colors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickNewPrescriptionImage(DoctorVisit visit, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final String origName = pickedFile.name;
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String fileName = 'prescription_${timestamp}_$origName';
        final File localImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

        final prescription = Prescription(
          imagePath: localImage.path,
          doctorName: visit.doctorName,
          visitDate: visit.visitDate,
          notes: 'Uploaded for visit on ${visit.visitDate}',
        );

        final prescId = await DatabaseHelper.instance.insertPrescription(prescription);
        if (!mounted) return;
        // Update the doctor visit to link the prescription ID
        final provider = Provider.of<DoctorVisitsProvider>(context, listen: false);
        final updatedVisit = DoctorVisit(
          id: visit.id,
          userId: visit.userId,
          doctorName: visit.doctorName,
          hospital: visit.hospital,
          visitDate: visit.visitDate,
          diagnosis: visit.diagnosis,
          notes: visit.notes,
          followUpDate: visit.followUpDate,
          prescriptionId: prescId,
        );
        await provider.updateVisit(updatedVisit);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Prescription linked to doctor visit successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving prescription from doctor visit: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorVisitsProvider>(context);
    final existingVisits = provider.visits;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: context.colors.card,
          appBar: AppBar(
            backgroundColor: context.colors.card,
            title: Text('Add Doctor Visit', style: context.titleLarge),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Autocomplete Doctor Name
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return existingVisits
                                .map((v) => v.doctorName)
                                .toSet()
                                .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String selection) {
                            _doctorController.text = selection;
                          },
                          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                            // Sync standard controller if user picks autocomplete
                            if (_doctorController.text.isNotEmpty && textController.text.isEmpty) {
                              textController.text = _doctorController.text;
                            }
                            textController.addListener(() {
                              _doctorController.text = textController.text;
                            });

                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              style: context.bodyMedium,
                              decoration: const InputDecoration(
                                labelText: 'Doctor Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Doctor Name is required';
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),

                        // Autocomplete Hospital / Clinic
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return existingVisits
                                .map((v) => v.hospital)
                                .toSet()
                                .where((hosp) => hosp.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String selection) {
                            _hospitalController.text = selection;
                          },
                          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                            // Sync standard controller if user picks autocomplete
                            if (_hospitalController.text.isNotEmpty && textController.text.isEmpty) {
                              textController.text = _hospitalController.text;
                            }
                            textController.addListener(() {
                              _hospitalController.text = textController.text;
                            });

                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              style: context.bodyMedium,
                              decoration: const InputDecoration(
                                labelText: 'Hospital / Clinic',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Hospital / Clinic is required';
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),

                        TextFormField(
                          readOnly: true,
                          style: context.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Visit Date',
                            prefixIcon: const Icon(Icons.calendar_today),
                            hintText: DateFormat('yyyy-MM-dd').format(_visitDate),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _visitDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _visitDate = date;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),

                        TextFormField(
                          controller: _diagnosisController,
                          maxLines: 2,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Diagnosis',
                            prefixIcon: Icon(Icons.assignment_outlined),
                          ),
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),

                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Consultation Notes',
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),

                        TextFormField(
                          readOnly: true,
                          style: context.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Follow-up Date (optional)',
                            prefixIcon: const Icon(Icons.event),
                            hintText: _followUpDate != null ? DateFormat('yyyy-MM-dd').format(_followUpDate!) : 'None',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                _followUpDate = date;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),

                        if (provider.prescriptions.isNotEmpty) ...[
                          DropdownButtonFormField<int?>(
                            value: _selectedPrescriptionId,
                            style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Link Existing Prescription (optional)',
                              prefixIcon: Icon(Icons.attach_file),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('None')),
                              ...provider.prescriptions.map((p) {
                                final label = p.doctorName != null ? 'Prescription: ${p.doctorName}' : 'Prescription #${p.id}';
                                return DropdownMenuItem<int?>(value: p.id, child: Text(label));
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedPrescriptionId = val;
                              });
                            },
                          ),
                          const SizedBox(height: MediTrackSpacing.large),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    border: Border(top: BorderSide(color: context.colors.dividerColor, width: 0.8)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Visit'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
