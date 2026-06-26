import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../providers/vitals_provider.dart';
import '../core/models.dart';

class VitalsHistory extends StatefulWidget {
  const VitalsHistory({super.key});

  @override
  State<VitalsHistory> createState() => _VitalsHistoryState();
}

class _VitalsHistoryState extends State<VitalsHistory> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeframe = 'all';
  String _selectedSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VitalsProvider>(context, listen: false).loadVitals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isItemAbnormal(String name, Vital vital) {
    if (name == 'BP') {
      final sys = vital.bpSystolic ?? 120;
      final dia = vital.bpDiastolic ?? 80;
      if (sys >= 90 && sys <= 119 && dia >= 60 && dia <= 79) return false;
      return true;
    }
    if (name == 'Sugar') {
      final val = vital.bloodSugar ?? 90;
      final isFasting = vital.sugarType == 'fasting';
      if (isFasting) {
        if (val >= 70 && val <= 99) return false;
      } else {
        if (val < 140) return false;
      }
      return true;
    }
    if (name == 'Heart Rate') {
      final val = vital.heartRate ?? 70;
      if (val >= 60 && val <= 100) return false;
      return true;
    }
    if (name == 'SpO2') {
      final val = vital.spo2 ?? 98;
      if (val >= 95) return false;
      return true;
    }
    if (name == 'Temperature') {
      final val = vital.temperature ?? 36.5;
      if (val >= 36.0 && val <= 37.2) return false;
      return true;
    }
    return false;
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  List<Map<String, dynamic>> _getGroupedLogs(List<Vital> vitals) {
    final now = DateTime.now();
    List<Vital> filtered = vitals;

    // Timeframe Filter
    if (_selectedTimeframe == '7') {
      final cutoff = now.subtract(const Duration(days: 7));
      filtered = vitals.where((v) {
        final d = DateTime.tryParse(v.date) ?? now;
        return d.isAfter(cutoff);
      }).toList();
    } else if (_selectedTimeframe == '30') {
      final cutoff = now.subtract(const Duration(days: 30));
      filtered = vitals.where((v) {
        final d = DateTime.tryParse(v.date) ?? now;
        return d.isAfter(cutoff);
      }).toList();
    }

    final tabIndex = _tabController.index;
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // Sort by date descending
    final sortedVitals = List<Vital>.from(filtered);
    sortedVitals.sort((a, b) => b.date.compareTo(a.date));

    for (var v in sortedVitals) {
      final dateStr = _formatDate(v.date);
      final List<Map<String, dynamic>> items = [];

      void addIfValid(Map<String, dynamic> item) {
        final isAbnormal = _isItemAbnormal(item['name'] as String, v);
        if (_selectedSeverity == 'normal' && isAbnormal) return;
        if (_selectedSeverity == 'abnormal' && !isAbnormal) return;
        items.add(item);
      }

      if (tabIndex == 0 || tabIndex == 1) {
        if (v.bpSystolic != null && v.bpDiastolic != null) {
          addIfValid({
            'vital_obj': v,
            'name': 'BP',
            'value': '${v.bpSystolic!.toInt()}/${v.bpDiastolic!.toInt()}',
            'unit': 'mmHg',
            'icon': Icons.favorite,
            'field': 'bp',
          });
        }
      }
      if (tabIndex == 0 || tabIndex == 2) {
        if (v.bloodSugar != null) {
          final typeStr = v.sugarType == 'fasting' ? ' (Fasting)' : (v.sugarType == 'post_meal' ? ' (Post-meal)' : '');
          addIfValid({
            'vital_obj': v,
            'name': 'Sugar',
            'value': '${v.bloodSugar!.toInt()}$typeStr',
            'unit': 'mg/dL',
            'icon': Icons.water_drop,
            'field': 'sugar',
          });
        }
      }
      if (tabIndex == 0 || tabIndex == 3) {
        if (v.heartRate != null) {
          addIfValid({
            'vital_obj': v,
            'name': 'Heart Rate',
            'value': '${v.heartRate!.toInt()}',
            'unit': 'bpm',
            'icon': Icons.speed,
            'field': 'heartRate',
          });
        }
      }
      if (tabIndex == 0 || tabIndex == 4) {
        if (v.spo2 != null) {
          addIfValid({
            'vital_obj': v,
            'name': 'SpO2',
            'value': '${v.spo2!.toInt()}',
            'unit': '%',
            'icon': Icons.air,
            'field': 'spo2',
          });
        }
      }

      if (tabIndex == 0) {
        if (v.temperature != null) {
          addIfValid({
            'vital_obj': v,
            'name': 'Temperature',
            'value': v.temperature!.toStringAsFixed(1),
            'unit': '°C',
            'icon': Icons.thermostat,
            'field': 'temp',
          });
        }
        if (v.weight != null) {
          addIfValid({
            'vital_obj': v,
            'name': 'Weight',
            'value': v.weight!.toStringAsFixed(1),
            'unit': 'kg',
            'icon': Icons.monitor_weight_outlined,
            'field': 'weight',
          });
        }
      }

      if (items.isNotEmpty) {
        if (grouped[dateStr] == null) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.addAll(items);
      }
    }

    final List<Map<String, dynamic>> result = [];
    grouped.forEach((date, list) {
      result.add({
        'date': date,
        'vitals': list,
      });
    });

    return result;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter History',
                    style: context.titleLarge,
                  ),
                  const SizedBox(height: MediTrackSpacing.large),
                  DropdownButtonFormField<String>(
                    value: _selectedTimeframe,
                    style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Timeframe'),
                    items: const [
                      DropdownMenuItem(value: '7', child: Text('Last 7 Days')),
                      DropdownMenuItem(value: '30', child: Text('Last 30 Days')),
                      DropdownMenuItem(value: 'all', child: Text('All Time')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTimeframe = val;
                        });
                        setModalState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: MediTrackSpacing.formFieldGap),
                  DropdownButtonFormField<String>(
                    value: _selectedSeverity,
                    style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Severity Status'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Entries')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal Only')),
                      DropdownMenuItem(value: 'abnormal', child: Text('Abnormal Only')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSeverity = val;
                        });
                        setModalState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: MediTrackSpacing.large),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final vital = item['vital_obj'] as Vital;
    final name = item['name'] as String;
    final field = item['field'] as String;
    final unit = item['unit'] as String;

    String initialVal = '';
    if (field == 'bp') {
      initialVal = '${vital.bpSystolic?.toInt() ?? ""}/${vital.bpDiastolic?.toInt() ?? ""}';
    } else if (field == 'sugar') {
      initialVal = '${vital.bloodSugar?.toInt() ?? ""}';
    } else if (field == 'heartRate') {
      initialVal = '${vital.heartRate?.toInt() ?? ""}';
    } else if (field == 'spo2') {
      initialVal = '${vital.spo2?.toInt() ?? ""}';
    } else if (field == 'temp') {
      initialVal = '${vital.temperature ?? ""}';
    } else if (field == 'weight') {
      initialVal = '${vital.weight ?? ""}';
    }

    final controller = TextEditingController(text: initialVal);
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.cards),
            side: BorderSide(color: context.colors.dividerColor, width: 0.8),
          ),
          title: Text('Edit $name Entry', style: context.titleLarge),
          content: Form(
            key: editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  style: context.bodyMedium,
                  decoration: InputDecoration(
                    labelText: field == 'bp' ? 'Value (Systolic/Diastolic)' : 'Value',
                    suffixText: unit,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Value cannot be empty';
                    if (field == 'bp') {
                      final parts = val.split('/');
                      if (parts.length != 2) return 'Use Systolic/Diastolic format';
                      final sys = double.tryParse(parts[0].trim());
                      final dia = double.tryParse(parts[1].trim());
                      if (sys == null || dia == null) return 'Must be valid numbers';
                      if (sys < 50 || sys > 250 || dia < 30 || dia > 150) return 'Out of bounds';
                    } else {
                      final numVal = double.tryParse(val.trim());
                      if (numVal == null) return 'Must be a valid number';
                      if (field == 'sugar' && (numVal < 20 || numVal > 600)) return 'Range 20-600';
                      if (field == 'temp' && (numVal < 30 || numVal > 45)) return 'Range 30-45';
                      if (field == 'weight' && (numVal < 10 || numVal > 300)) return 'Range 10-300';
                      if (field == 'spo2' && (numVal < 50 || numVal > 100)) return 'Range 50-100';
                      if (field == 'heartRate' && (numVal < 30 || numVal > 220)) return 'Range 30-220';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                if (!editFormKey.currentState!.validate()) return;
                
                final val = controller.text.trim();
                Vital updated;
                if (field == 'bp') {
                  final parts = val.split('/');
                  final sys = double.parse(parts[0].trim());
                  final dia = double.parse(parts[1].trim());
                  updated = Vital(
                    id: vital.id,
                    userId: vital.userId,
                    date: vital.date,
                    bpSystolic: sys,
                    bpDiastolic: dia,
                    bloodSugar: vital.bloodSugar,
                    sugarType: vital.sugarType,
                    temperature: vital.temperature,
                    weight: vital.weight,
                    spo2: vital.spo2,
                    heartRate: vital.heartRate,
                    notes: vital.notes,
                    createdAt: vital.createdAt,
                  );
                } else if (field == 'sugar') {
                  final numVal = double.parse(val);
                  updated = Vital(
                    id: vital.id,
                    userId: vital.userId,
                    date: vital.date,
                    bpSystolic: vital.bpSystolic,
                    bpDiastolic: vital.bpDiastolic,
                    bloodSugar: numVal,
                    sugarType: vital.sugarType,
                    temperature: vital.temperature,
                    weight: vital.weight,
                    spo2: vital.spo2,
                    heartRate: vital.heartRate,
                    notes: vital.notes,
                    createdAt: vital.createdAt,
                  );
                } else if (field == 'heartRate') {
                  final numVal = double.parse(val);
                  updated = Vital(
                    id: vital.id,
                    userId: vital.userId,
                    date: vital.date,
                    bpSystolic: vital.bpSystolic,
                    bpDiastolic: vital.bpDiastolic,
                    bloodSugar: vital.bloodSugar,
                    sugarType: vital.sugarType,
                    temperature: vital.temperature,
                    weight: vital.weight,
                    spo2: vital.spo2,
                    heartRate: numVal,
                    notes: vital.notes,
                    createdAt: vital.createdAt,
                  );
                } else if (field == 'spo2') {
                  final numVal = double.parse(val);
                  updated = Vital(
                    id: vital.id,
                    userId: vital.userId,
                    date: vital.date,
                    bpSystolic: vital.bpSystolic,
                    bpDiastolic: vital.bpDiastolic,
                    bloodSugar: vital.bloodSugar,
                    sugarType: vital.sugarType,
                    temperature: vital.temperature,
                    weight: vital.weight,
                    spo2: numVal,
                    heartRate: vital.heartRate,
                    notes: vital.notes,
                    createdAt: vital.createdAt,
                  );
                } else if (field == 'temp') {
                  final numVal = double.parse(val);
                  updated = Vital(
                    id: vital.id,
                    userId: vital.userId,
                    date: vital.date,
                    bpSystolic: vital.bpSystolic,
                    bpDiastolic: vital.bpDiastolic,
                    bloodSugar: vital.bloodSugar,
                    sugarType: vital.sugarType,
                    temperature: numVal,
                    weight: vital.weight,
                    spo2: vital.spo2,
                    heartRate: vital.heartRate,
                    notes: vital.notes,
                    createdAt: vital.createdAt,
                  );
                } else {
                  final numVal = double.parse(val);
                  updated = Vital(
                    id: vital.id,
                    userId: vital.userId,
                    date: vital.date,
                    bpSystolic: vital.bpSystolic,
                    bpDiastolic: vital.bpDiastolic,
                    bloodSugar: vital.bloodSugar,
                    sugarType: vital.sugarType,
                    temperature: vital.temperature,
                    weight: numVal,
                    spo2: vital.spo2,
                    heartRate: vital.heartRate,
                    notes: vital.notes,
                    createdAt: vital.createdAt,
                  );
                }

                await Provider.of<VitalsProvider>(context, listen: false).updateVitals(updated);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text('Save', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVitalField(Map<String, dynamic> item) async {
    final vital = item['vital_obj'] as Vital;
    final field = item['field'] as String;

    Vital updated = Vital(
      id: vital.id,
      userId: vital.userId,
      date: vital.date,
      bpSystolic: field == 'bp' ? null : vital.bpSystolic,
      bpDiastolic: field == 'bp' ? null : vital.bpDiastolic,
      bloodSugar: field == 'sugar' ? null : vital.bloodSugar,
      sugarType: field == 'sugar' ? null : vital.sugarType,
      temperature: field == 'temp' ? null : vital.temperature,
      weight: field == 'weight' ? null : vital.weight,
      spo2: field == 'spo2' ? null : vital.spo2,
      heartRate: field == 'heartRate' ? null : vital.heartRate,
      notes: vital.notes,
      createdAt: vital.createdAt,
    );

    if (updated.bpSystolic == null &&
        updated.bpDiastolic == null &&
        updated.bloodSugar == null &&
        updated.temperature == null &&
        updated.weight == null &&
        updated.spo2 == null &&
        updated.heartRate == null) {
      await Provider.of<VitalsProvider>(context, listen: false).deleteVitals(vital.id!);
    } else {
      await Provider.of<VitalsProvider>(context, listen: false).updateVitals(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vitalsProvider = Provider.of<VitalsProvider>(context);
    final groupedLogs = _getGroupedLogs(vitalsProvider.vitals);
    final hasData = groupedLogs.isNotEmpty;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text('Vitals History', style: context.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: context.colors.primary),
            tooltip: 'Checkup Analysis',
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: context.colors.textPrimary),
            onPressed: _showFilterBottomSheet,
          ),
          const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: vitalsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: context.colors.primary,
                      unselectedLabelColor: context.colors.textSecondary,
                      indicatorColor: context.colors.primary,
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'BP'),
                        Tab(text: 'Sugar'),
                        Tab(text: 'Heart Rate'),
                        Tab(text: 'SpO2'),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: groupedLogs.length,
                        itemBuilder: (context, index) {
                          final log = groupedLogs[index];
                          return _buildDateGroup(log, index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 80,
              color: context.colors.textHint,
            ),
            const SizedBox(height: MediTrackSpacing.large),
            Text(
              'No vitals recorded yet',
              style: context.titleLarge.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: MediTrackSpacing.large),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/vitals/log'),
              child: const Text('Log Your First Vitals'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(Map<String, dynamic> log, int groupIndex) {
    final List<dynamic> vitalsList = log['vitals'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: context.colors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: MediTrackSpacing.screenHorizontalPadding,
            vertical: 8,
          ),
          child: Text(
            log['date'] as String,
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vitalsList.length,
          itemBuilder: (context, itemIndex) {
            final vital = vitalsList[itemIndex] as Map<String, dynamic>;
            return Slidable(
              key: ValueKey('${log['date']}_${vital['name']}_${vital['field']}'),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      final confirm = await showConfirmDeleteDialog(
                        context,
                        title: 'Delete Vital Log',
                        content: 'Are you sure you want to delete this vital log entry?',
                      );
                      if (confirm == true) {
                        await _deleteVitalField(vital);
                      }
                    },
                    backgroundColor: context.colors.errorSos,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(vital['icon'] as IconData, size: 20, color: context.colors.primary),
                title: Text(
                  vital['name'] as String,
                  style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: vital['value'] as String,
                        style: context.vitalValue.copyWith(fontSize: 18),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: vital['unit'] as String,
                        style: context.vitalUnit,
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: context.colors.textSecondary),
                      onPressed: () => _showEditDialog(vital),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: context.colors.errorSos),
                      onPressed: () async {
                        final confirm = await showConfirmDeleteDialog(
                          context,
                          title: 'Delete Vital Log',
                          content: 'Are you sure you want to delete this vital log entry?',
                        );
                        if (confirm == true) {
                          await _deleteVitalField(vital);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
