import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../providers/medicine_provider.dart';
import '../core/models.dart';
import 'package:lottie/lottie.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddMedicineBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
      ),
      builder: (context) {
        return const AddMedicineBottomSheet();
      },
    );
  }

  void _showMedicineCareDialog(Medicine med) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.bottomSheets),
          ),
          title: Row(
            children: [
              Icon(Icons.health_and_safety, color: context.colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  med.name,
                  style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCareSection(
                  icon: Icons.info_outline,
                  title: 'How to Take (Instructions)',
                  content: med.instructions ?? 'Take as directed by your physician.',
                  color: context.colors.primary,
                ),
                const SizedBox(height: 16),
                _buildCareSection(
                  icon: Icons.warning_amber_outlined,
                  title: 'Precautions',
                  content: med.precautions ?? 'Consult doctor before taking with other medications.',
                  color: context.colors.warning,
                ),
                const SizedBox(height: 16),
                _buildCareSection(
                  icon: Icons.sick_outlined,
                  title: 'Common Side Effects',
                  content: med.sideEffects ?? 'Nausea, dizziness or light headache in some cases.',
                  color: context.colors.errorSos,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCareSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Text(
            content,
            style: context.bodyMedium.copyWith(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  List<Medicine> _getFilteredMedicines(List<Medicine> list) {
    List<Medicine> filteredList = list;

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Tab filter
    if (_selectedFilter == 'All') return filteredList;
    if (_selectedFilter == 'Active') return filteredList.where((m) => m.isActive).toList();
    if (_selectedFilter == 'Inactive') return filteredList.where((m) => !m.isActive).toList();

    return filteredList.where((m) {
      for (var timeStr in m.reminderTimes) {
        try {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          if (_selectedFilter == 'Morning' && hour >= 5 && hour < 12) return true;
          if (_selectedFilter == 'Afternoon' && hour >= 12 && hour < 17) return true;
          if (_selectedFilter == 'Evening' && (hour >= 17 || hour < 5)) return true;
        } catch (_) {}
      }
      return false;
    }).toList();
  }

  String _getNextDoseTime(Medicine med) {
    if (!med.isActive || med.reminderTimes.isEmpty) return 'N/A';
    final now = TimeOfDay.now();

    final sortedTimes = List<String>.from(med.reminderTimes);
    sortedTimes.sort((a, b) => a.compareTo(b));

    for (var timeStr in sortedTimes) {
      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        if (hour > now.hour || (hour == now.hour && min > now.minute)) {
          final tempDate = DateTime(2026, 1, 1, hour, min);
          return DateFormat('hh:mm a').format(tempDate);
        }
      } catch (_) {}
    }

    try {
      final parts = sortedTimes.first.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      final tempDate = DateTime(2026, 1, 1, hour, min);
      return '${DateFormat('hh:mm a').format(tempDate)} (Tomorrow)';
    } catch (_) {
      return 'N/A';
    }
  }

  List<String> _getDueTimes(Medicine med, List<MedicationLog> todayLogs) {
    if (!med.isActive) return [];
    final List<String> due = [];
    final now = DateTime.now();

    for (var timeStr in med.reminderTimes) {
      final log = todayLogs.firstWhere(
        (l) => l.medicineId == med.id && l.scheduledTime == timeStr,
        orElse: () => MedicationLog(date: '', scheduledTime: '', status: ''),
      );

      if (log.status == 'taken' || log.status == 'skipped') continue;

      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, min);

        if (now.isAfter(scheduledDateTime)) {
          due.add(timeStr);
        }
      } catch (_) {}
    }
    return due;
  }

  bool _isOverdue(Medicine med, List<MedicationLog> todayLogs) {
    if (!med.isActive) return false;
    final now = DateTime.now();
    for (var timeStr in med.reminderTimes) {
      final log = todayLogs.firstWhere(
        (l) => l.medicineId == med.id && l.scheduledTime == timeStr,
        orElse: () => MedicationLog(date: '', scheduledTime: '', status: ''),
      );
      if (log.status == 'taken' || log.status == 'skipped') continue;

      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, min);

        if (now.isAfter(scheduledDateTime.add(const Duration(minutes: 30)))) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  void _mockCallDoctor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Doctor / Pharmacy'),
        content: const Text('Would you like to call Apollo Pharmacy Support at +1-800-APOLLO?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling +1-800-APOLLO... (Mock Dial)')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _mockWhatsAppOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order via WhatsApp'),
        content: const Text('Initiate medicine ordering via WhatsApp with your active prescription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to WhatsApp Order Chat... (Mock)')),
              );
            },
            child: const Text('Order Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = Provider.of<MedicineProvider>(context);
    final filtered = _getFilteredMedicines(medProvider.medicines);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('My Medicines', style: context.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.colors.textPrimary),
            onPressed: _showAddMedicineBottomSheet,
          ),
          const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: medProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Superfast Delivery Banner
                  _buildApolloBanner(),

                  // Search Bar Card
                  _buildSearchBarCard(),

                  // Quick Shortcuts Row
                  _buildQuickShortcuts(),
                  const SizedBox(height: 12),

                  // Filter Chips
                  _buildFilterChipsRow(),
                  const SizedBox(height: 12),

                  // Medicines List
                  filtered.isEmpty
                      ? SizedBox(height: 300, child: _buildEmptyState())
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final med = filtered[index];
                            return _buildMedicineCard(med, index, medProvider);
                          },
                        ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicineBottomSheet,
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildApolloBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary,
            context.colors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MediTrackRadius.bottomSheets),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Get Medicines Fast',
                style: context.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'APOLLO STYLE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Superfast Delivery directly in your city',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBannerBadge(Icons.monetization_on_outlined, 'Cash on Delivery'),
              _buildBannerBadge(Icons.local_shipping_outlined, 'Express Delivery'),
              _buildBannerBadge(Icons.assignment_return_outlined, 'Easy Returns'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSearchBarCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding),
      child: Card(
        elevation: 3,
        shadowColor: context.colors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.inputFields),
          side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
          child: TextField(
            controller: _searchController,
            style: context.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search for Medicines...',
              hintStyle: TextStyle(color: context.colors.textHint),
              prefixIcon: Icon(Icons.search, color: context.colors.primary),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickShortcuts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildShortcutItem(
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: _mockWhatsAppOrder,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildShortcutItem(
              icon: Icons.qr_code_scanner,
              label: 'Scan Rx',
              color: context.colors.primary,
              onTap: () => Navigator.pushNamed(context, '/prescriptions'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildShortcutItem(
              icon: Icons.call_outlined,
              label: 'Call Doctor',
              color: Colors.orange,
              onTap: _mockCallDoctor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MediTrackRadius.cards),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.network(
              'https://lottie.host/3e8e2034-722e-468f-9e6e-213c41551608/D7f5Z2dJgC.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.medication_outlined,
                  size: 80,
                  color: context.colors.textHint,
                );
              },
            ),
          ),
          const SizedBox(height: MediTrackSpacing.large),
          Text(
            'No medicines found',
            style: context.titleLarge.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: MediTrackSpacing.large),
          ElevatedButton(
            onPressed: _showAddMedicineBottomSheet,
            child: const Text('Add Your First Medicine'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    final filters = ['All', 'Morning', 'Afternoon', 'Evening', 'Active', 'Inactive'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicineCard(Medicine med, int index, MedicineProvider provider) {
    Color iconBg;
    Color iconColor;
    int cycle = index % 3;
    if (cycle == 0) {
      iconBg = context.colors.primaryLight;
      iconColor = context.colors.primary;
    } else if (cycle == 1) {
      iconBg = context.colors.accentLight;
      iconColor = context.colors.accent;
    } else {
      iconBg = context.colors.warningLight;
      iconColor = context.colors.warning;
    }

    final isOverdueVal = _isOverdue(med, provider.todayLogs);
    final dueTimes = _getDueTimes(med, provider.todayLogs);
    final isDueNow = dueTimes.isNotEmpty;

    return Slidable(
      key: ValueKey(med.id ?? med.name),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showConfirmDeleteDialog(
                context,
                title: 'Delete Medicine',
                content: 'Are you sure you want to delete this medicine?',
              );
              if (confirm == true && med.id != null) {
                await provider.deleteMedicine(med.id!);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediTrackRadius.cards),
          side: BorderSide(color: context.colors.dividerColor.withOpacity(0.7)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: isOverdueVal
                    ? context.colors.errorSos
                    : (med.isActive ? context.colors.primary : context.colors.textHint),
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
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: med.isActive ? iconBg : context.colors.dividerColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.medication,
                              color: med.isActive ? iconColor : context.colors.textHint,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: context.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: med.isActive ? context.colors.textPrimary : context.colors.textHint,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${med.dosage?.toStringAsFixed(0) ?? ""} ${med.unit ?? ""}',
                                      style: context.bodySmall,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ${med.frequency ?? ""}',
                                      style: context.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: med.isActive,
                            activeColor: context.colors.primary,
                            onChanged: (val) async {
                              if (med.id != null) {
                                await provider.toggleActive(med.id!, val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.alarm, size: 14, color: context.colors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Next Dose: ${_getNextDoseTime(med)}',
                                style: context.bodySmall,
                              ),
                            ],
                          ),
                          // Details & Care Button
                          TextButton.icon(
                            onPressed: () => _showMedicineCareDialog(med),
                            icon: Icon(Icons.info_outline, size: 12, color: context.colors.primary),
                            label: Text(
                              'Details & Care',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      if (isDueNow && med.isActive) ...[
                        const SizedBox(height: MediTrackSpacing.medium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await provider.logDose(med.id!, dueTimes.first, 'taken');
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: context.colors.successLight,
                                  foregroundColor: context.colors.success,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text('✓ Taken', style: context.bodySmall.copyWith(color: context.colors.success, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await provider.logDose(med.id!, dueTimes.first, 'snoozed');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Dose snoozed for 15 minutes')),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: context.colors.warningLight,
                                  foregroundColor: context.colors.warning,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text('⏰ Snooze', style: context.bodySmall.copyWith(color: context.colors.warning, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await provider.logDose(med.id!, dueTimes.first, 'skipped');
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: context.colors.errorSos,
                                  side: BorderSide(color: context.colors.errorSos, width: 1.0),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text('✗ Skip', style: context.bodySmall.copyWith(color: context.colors.errorSos, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddMedicineBottomSheet extends StatefulWidget {
  const AddMedicineBottomSheet({super.key});

  @override
  State<AddMedicineBottomSheet> createState() => _AddMedicineBottomSheetState();
}

class _AddMedicineBottomSheetState extends State<AddMedicineBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _precautionsController = TextEditingController();
  final _sideEffectsController = TextEditingController();

  String _selectedFrequency = 'Once daily';
  String _unit = 'tablet(s)';
  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
  ];

  List<TimeOfDay> _doseTimes = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _enableReminders = true;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _precautionsController.dispose();
    _sideEffectsController.dispose();
    super.dispose();
  }

  int _getDoseTimeCount() {
    switch (_selectedFrequency) {
      case 'Once daily':
        return 1;
      case 'Twice daily':
        return 2;
      case 'Three times daily':
        return 3;
      default:
        return 1;
    }
  }

  void _updateDoseTimesCount() {
    final targetCount = _getDoseTimeCount();
    if (_doseTimes.length < targetCount) {
      while (_doseTimes.length < targetCount) {
        if (_doseTimes.length == 1) {
          _doseTimes.add(const TimeOfDay(hour: 14, minute: 0));
        } else if (_doseTimes.length == 2) {
          _doseTimes.add(const TimeOfDay(hour: 20, minute: 0));
        } else {
          _doseTimes.add(const TimeOfDay(hour: 8, minute: 0));
        }
      }
    } else if (_doseTimes.length > targetCount) {
      _doseTimes = _doseTimes.sublist(0, targetCount);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final String name = _nameController.text.trim();
    final double dosage = double.parse(_dosageController.text.trim());
    final String instructions = _instructionsController.text.trim();
    final String precautions = _precautionsController.text.trim();
    final String sideEffects = _sideEffectsController.text.trim();

    final reminderTimes = _doseTimes.map((t) {
      final hourStr = t.hour.toString().padLeft(2, '0');
      final minStr = t.minute.toString().padLeft(2, '0');
      return '$hourStr:$minStr';
    }).toList();

    final med = Medicine(
      name: name,
      dosage: dosage,
      unit: _unit,
      frequency: _selectedFrequency,
      reminderTimes: reminderTimes,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      isActive: true,
      instructions: instructions.isNotEmpty ? instructions : 'Take as directed by your physician.',
      precautions: precautions.isNotEmpty ? precautions : 'Consult doctor before taking with other medications.',
      sideEffects: sideEffects.isNotEmpty ? sideEffects : 'Nausea, dizziness or light headache in some cases.',
    );

    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await provider.addMedicine(med);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.colors.dividerColor, width: 0.8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add New Medicine', style: context.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name',
                            prefixIcon: Icon(Icons.medication_outlined),
                            hintText: 'e.g. Paracetamol',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _dosageController,
                                style: context.bodyMedium,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Dosage',
                                  prefixIcon: Icon(Icons.pin),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  if (double.tryParse(val.trim()) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _unit,
                                style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'tablet(s)', child: Text('tablet(s)')),
                                  DropdownMenuItem(value: 'capsule(s)', child: Text('capsule(s)')),
                                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                                  DropdownMenuItem(value: 'drop(s)', child: Text('drop(s)')),
                                  DropdownMenuItem(value: 'mg', child: Text('mg')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _unit = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedFrequency,
                          style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                            prefixIcon: Icon(Icons.repeat),
                          ),
                          items: _frequencies
                              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedFrequency = val;
                                _updateDoseTimesCount();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Dose Timings',
                          style: context.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _doseTimes.length,
                          itemBuilder: (context, index) {
                            final time = _doseTimes[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Dose #${index + 1}:',
                                    style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final selectedTime = await showTimePicker(
                                          context: context,
                                          initialTime: time,
                                        );
                                        if (selectedTime != null) {
                                          setState(() {
                                            _doseTimes[index] = selectedTime;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.alarm, size: 16),
                                      label: Text(
                                        DateFormat('hh:mm a').format(
                                          DateTime(2026, 1, 1, time.hour, time.minute),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Duration',
                          style: context.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                style: context.bodyMedium,
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  hintText: DateFormat('yyyy-MM-dd').format(_startDate),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _startDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                style: context.bodyMedium,
                                decoration: InputDecoration(
                                  labelText: 'End Date (optional)',
                                  prefixIcon: const Icon(Icons.event),
                                  hintText: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'None',
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _endDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Care & Instructions (Apollo/Pharmeasy Style)',
                          style: context.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _instructionsController,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Instructions (e.g. Take with food)',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _precautionsController,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Precautions (e.g. Avoid alcohol)',
                            prefixIcon: Icon(Icons.warning_amber_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _sideEffectsController,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Side Effects (e.g. Causes drowsiness)',
                            prefixIcon: Icon(Icons.sick_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          value: _enableReminders,
                          onChanged: (val) {
                            setState(() {
                              _enableReminders = val;
                            });
                          },
                          secondary: Icon(Icons.notifications_active, color: context.colors.primary),
                          title: Text('Enable Reminders', style: context.bodyMedium),
                          subtitle: Text('Get notified at each dose time', style: context.bodySmall),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 40),
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
                      child: const Text('Add Medicine'),
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
