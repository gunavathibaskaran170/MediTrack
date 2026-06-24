import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../providers/medicine_provider.dart';
import '../core/models.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
    });
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

  List<Medicine> _getFilteredMedicines(List<Medicine> list) {
    if (_selectedFilter == 'All') return list;
    if (_selectedFilter == 'Active') return list.where((m) => m.isActive).toList();
    if (_selectedFilter == 'Inactive') return list.where((m) => !m.isActive).toList();

    return list.where((m) {
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
          : Column(
              children: [
                _buildAdherenceSummaryCard(context, medProvider),
                const SizedBox(height: MediTrackSpacing.small),
                _buildFilterChipsRow(),
                const SizedBox(height: MediTrackSpacing.small),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final med = filtered[index];
                            return _buildMedicineCard(med, index, medProvider);
                          },
                        ),
                ),
              ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: context.colors.textHint),
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

  Widget _buildAdherenceSummaryCard(BuildContext context, MedicineProvider provider) {
    final adherenceStr = '${(provider.weeklyAdherence * 100).toInt()}%';
    return Card(
      color: context.colors.primary,
      margin: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MediTrackSpacing.cardInternalPaddingHorizontal,
          vertical: MediTrackSpacing.cardInternalPaddingVertical,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: context.titleLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adherence',
                    style: context.bodySmall.copyWith(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: provider.weeklyAdherence,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  adherenceStr,
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taken: ${provider.takenThisWeek}',
                    style: context.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Missed/Skipped: ${provider.missedThisWeek}',
                    style: context.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: isOverdueVal ? context.colors.errorSos : context.colors.accent,
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.medication, color: iconColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: context.titleMedium,
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
                        children: [
                          Icon(Icons.alarm, size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Next: ${_getNextDoseTime(med)}',
                            style: context.bodySmall,
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

  String _selectedFrequency = 'Once daily';
  String _unit = 'mg';
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
      expand: false,
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: context.colors.card,
          appBar: AppBar(
            backgroundColor: context.colors.card,
            title: Text('Add Medicine', style: context.titleLarge),
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
                          controller: _nameController,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name',
                            prefixIcon: Icon(Icons.medication_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Medicine Name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: MediTrackSpacing.formFieldGap),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _dosageController,
                                style: context.bodyMedium,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Dosage',
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  final d = double.tryParse(val.trim());
                                  if (d == null || d <= 0) return 'Must be positive number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _unit,
                                style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'mg', child: Text('mg')),
                                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                                  DropdownMenuItem(value: 'tablet', child: Text('tablet')),
                                  DropdownMenuItem(value: 'capsule', child: Text('capsule')),
                                  DropdownMenuItem(value: 'drops', child: Text('drops')),
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
                        const SizedBox(height: MediTrackSpacing.formFieldGap),
                        DropdownButtonFormField<String>(
                          value: _selectedFrequency,
                          style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                          ),
                          items: _frequencies.map((freq) {
                            return DropdownMenuItem(value: freq, child: Text(freq));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedFrequency = val;
                                _updateDoseTimesCount();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: MediTrackSpacing.large),
                        Text(
                          'Dose Times',
                          style: context.titleMedium,
                        ),
                        const SizedBox(height: MediTrackSpacing.titleToContentGap),
                        ...List.generate(_getDoseTimeCount(), (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.alarm, size: 20, color: context.colors.primary),
                                const SizedBox(width: 8),
                                Text('Dose ${index + 1} Time:', style: context.bodyMedium),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _doseTimes[index],
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _doseTimes[index] = time;
                                      });
                                    }
                                  },
                                  child: Text(_doseTimes[index].format(context), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 32),
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
                        const SizedBox(height: MediTrackSpacing.large),
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
                        const SizedBox(height: MediTrackSpacing.large),
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
