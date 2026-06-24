import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../core/models.dart';
import '../core/database_helper.dart';
import '../services/notification_service.dart';

class DoctorVisitsScreen extends StatefulWidget {
  const DoctorVisitsScreen({super.key});

  @override
  State<DoctorVisitsScreen> createState() => _DoctorVisitsScreenState();
}

class _DoctorVisitsScreenState extends State<DoctorVisitsScreen> {
  List<DoctorVisit> _visitsList = [];
  bool _isLoading = true;
  String _sortOrder = 'Most Recent';

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.getDoctorVisits();
      setState(() {
        _visitsList = list;
      });
    } catch (e) {
      debugPrint("Error loading visits: $e");
    } finally {
      setState(() => _isLoading = false);
    }
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
        return AddVisitBottomSheet(onSave: _loadVisits);
      },
    );
  }

  void _showNotesDialog(String doctor, String notes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.cards),
            side: BorderSide(color: context.colors.dividerColor, width: 0.8),
          ),
          title: Text('Notes - $doctor', style: context.titleLarge),
          content: SingleChildScrollView(
            child: Text(
              notes,
              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  List<DoctorVisit> _getSortedVisits() {
    final list = List<DoctorVisit>.from(_visitsList);
    if (_sortOrder == 'Most Recent') {
      list.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    } else {
      list.sort((a, b) => a.visitDate.compareTo(b.visitDate));
    }
    return list;
  }

  bool _isDateUpcoming(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr);
      // Compare without time component
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final checkDate = DateTime(date.year, date.month, date.day);
      return checkDate.isAfter(today) || checkDate.isAtSameMomentAs(today);
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedVisits = _getSortedVisits();
    final hasData = sortedVisits.isNotEmpty;

    return Scaffold(
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Sort Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding, vertical: 8.0),
                      child: Row(
                        children: [
                          Text(
                            'Sorted by:',
                            style: context.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            dropdownColor: context.colors.card,
                            value: _sortOrder,
                            style: context.bodyMedium.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w500),
                            items: const [
                              DropdownMenuItem(value: 'Most Recent', child: Text('Most Recent')),
                              DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortOrder = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // Visits List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding),
                        itemCount: sortedVisits.length,
                        itemBuilder: (context, index) {
                          final visit = sortedVisits[index];
                          return _buildDoctorVisitCard(visit, index);
                        },
                      ),
                    ),
                  ],
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

  Widget _buildDoctorVisitCard(DoctorVisit visit, int index) {
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
                await DatabaseHelper.instance.deleteDoctorVisit(visit.id!);
                _loadVisits();
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MediTrackSpacing.cardInternalPaddingHorizontal,
                    vertical: MediTrackSpacing.cardInternalPaddingVertical,
                  ),
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
                        style: context.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diagnosis: ',
                            style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              visit.diagnosis ?? 'None',
                              style: context.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (visit.followUpDate != null) ...[
                        Row(
                          children: [
                            Icon(Icons.upcoming, size: 14, color: context.colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Follow-up: ${_formatDate(visit.followUpDate!)}',
                              style: context.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            if (_isDateUpcoming(visit.followUpDate))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.colors.warningLight,
                                  borderRadius: BorderRadius.circular(MediTrackRadius.chipsBadges),
                                ),
                                child: Text(
                                  'Upcoming',
                                  style: context.labelSmall.copyWith(
                                    color: context.colors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            label: const Text('View Notes'),
                            onPressed: () => _showNotesDialog(visit.doctorName, visit.notes ?? 'No notes entered.'),
                          ),
                        ],
                      ),
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

class AddVisitBottomSheet extends StatefulWidget {
  final VoidCallback onSave;
  const AddVisitBottomSheet({super.key, required this.onSave});

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

  List<Prescription> _prescriptions = [];
  int? _selectedPrescriptionId;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _hospitalController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    try {
      final list = await DatabaseHelper.instance.getPrescriptions();
      setState(() {
        _prescriptions = list;
      });
    } catch (e) {
      debugPrint("Error loading prescriptions: $e");
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final visit = DoctorVisit(
      doctorName: _doctorController.text.trim(),
      hospital: _hospitalController.text.trim(),
      visitDate: DateFormat('yyyy-MM-dd').format(_visitDate),
      diagnosis: _diagnosisController.text.trim().isNotEmpty ? _diagnosisController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      followUpDate: _followUpDate != null ? DateFormat('yyyy-MM-dd').format(_followUpDate!) : null,
      prescriptionId: _selectedPrescriptionId,
    );

    final visitId = await DatabaseHelper.instance.insertDoctorVisit(visit);

    if (_followUpDate != null) {
      await NotificationService().scheduleAppointmentReminder(
        visitId: visitId,
        doctorName: visit.doctorName,
        hospital: visit.hospital,
        followUpDateStr: visit.followUpDate!,
      );
    }

    widget.onSave();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor visit saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        TextFormField(
                          controller: _doctorController,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Doctor Name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),
                        TextFormField(
                          controller: _hospitalController,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Hospital / Clinic',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Hospital / Clinic is required';
                            return null;
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
                        if (_prescriptions.isNotEmpty) ...[
                          DropdownButtonFormField<int?>(
                            value: _selectedPrescriptionId,
                            style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Link Prescription (optional)',
                              prefixIcon: Icon(Icons.attach_file),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('None')),
                              ..._prescriptions.map((p) {
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
