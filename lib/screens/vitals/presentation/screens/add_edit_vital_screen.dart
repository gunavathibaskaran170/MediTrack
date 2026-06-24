import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/vitals_providers.dart';
import '../widgets/vital_input_validator.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/spo2_entity.dart';
import '../../domain/entities/vital_types.dart';

/// Screen allowing the user to add or edit health vital records.
class AddEditVitalScreen extends ConsumerStatefulWidget {
  static const String routeName = '/add-edit-vital';

  /// Pass either a [VitalType] (for adding) or an existing Vital Entity (for editing).
  final Object argument;

  const AddEditVitalScreen({
    Key? key,
    required this.argument,
  }) : super(key: key);

  @override
  ConsumerState<AddEditVitalScreen> createState() => _AddEditVitalScreenState();
}

class _AddEditVitalScreenState extends ConsumerState<AddEditVitalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late bool _isEditMode;
  late VitalType _vitalType;
  Object? _existingRecord;

  // Form Fields State
  DateTime _selectedDateTime = DateTime.now();
  
  // Blood Pressure
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();

  // Blood Sugar
  final _sugarValueController = TextEditingController();
  BloodSugarReadingType _sugarReadingType = BloodSugarReadingType.random;

  // Temperature
  final _tempValueController = TextEditingController();
  TemperatureUnit _tempUnit = TemperatureUnit.celsius;

  // Weight
  final _weightValueController = TextEditingController();
  WeightUnit _weightUnit = WeightUnit.kg;

  // SpO2
  final _spo2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resolveArguments();
  }

  void _resolveArguments() {
    final arg = widget.argument;
    if (arg is VitalType) {
      _isEditMode = false;
      _vitalType = arg;
    } else {
      _isEditMode = true;
      _existingRecord = arg;
      _selectedDateTime = _getTimestampFromRecord(arg);
      
      if (arg is BloodPressureEntity) {
        _vitalType = VitalType.bloodPressure;
        _systolicController.text = arg.systolic.toString();
        _diastolicController.text = arg.diastolic.toString();
        _pulseController.text = arg.pulse?.toString() ?? '';
      } else if (arg is BloodSugarEntity) {
        _vitalType = VitalType.bloodSugar;
        _sugarValueController.text = arg.value.toStringAsFixed(0);
        _sugarReadingType = arg.readingType;
      } else if (arg is TemperatureEntity) {
        _vitalType = VitalType.temperature;
        _tempValueController.text = arg.value.toStringAsFixed(1);
        _tempUnit = arg.unit;
      } else if (arg is WeightEntity) {
        _vitalType = VitalType.weight;
        _weightValueController.text = arg.value.toStringAsFixed(1);
        _weightUnit = arg.unit;
      } else if (arg is SpO2Entity) {
        _vitalType = VitalType.spo2;
        _spo2Controller.text = arg.percentage.toString();
      }
    }
  }

  DateTime _getTimestampFromRecord(Object record) {
    if (record is BloodPressureEntity) return record.timestamp;
    if (record is BloodSugarEntity) return record.timestamp;
    if (record is TemperatureEntity) return record.timestamp;
    if (record is WeightEntity) return record.timestamp;
    if (record is SpO2Entity) return record.timestamp;
    return DateTime.now();
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _sugarValueController.dispose();
    _tempValueController.dispose();
    _weightValueController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(minutes: 10)),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionState = ref.watch(vitalsActionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit ${_getVitalName(_vitalType)}' : 'Log ${_getVitalName(_vitalType)}'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Timestamp Picker Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickDateTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Measurement Time',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDateTime),
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Change',
                              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Dynamic Input Fields based on Vital Type
                  _buildInputForm(),

                  const SizedBox(height: 40),

                  // 3. Save Button
                  FilledButton.icon(
                    onPressed: actionState.isLoading ? null : _saveRecord,
                    icon: Icon(_isEditMode ? Icons.check : Icons.save_outlined),
                    label: Text(
                      _isEditMode ? 'Update Record' : 'Save Record',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (actionState.isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return switch (_vitalType) {
      VitalType.bloodPressure => _buildBPFields(),
      VitalType.bloodSugar => _buildBloodSugarFields(),
      VitalType.temperature => _buildTemperatureFields(),
      VitalType.weight => _buildWeightFields(),
      VitalType.spo2 => _buildSpO2Fields(),
    };
  }

  // ==========================================
  // Blood Pressure Form Fields
  // ==========================================
  Widget _buildBPFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _systolicController,
          label: 'Systolic Pressure (mmHg)',
          helperText: 'Top reading. Normal is < 120 mmHg',
          keyboardType: TextInputType.number,
          validator: VitalInputValidator.validateSystolic,
          prefixIcon: Icons.arrow_upward,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _diastolicController,
          label: 'Diastolic Pressure (mmHg)',
          helperText: 'Bottom reading. Normal is < 80 mmHg',
          keyboardType: TextInputType.number,
          validator: VitalInputValidator.validateDiastolic,
          prefixIcon: Icons.arrow_downward,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _pulseController,
          label: 'Pulse (bpm - Optional)',
          helperText: 'Normal resting rate is 60-100 bpm',
          keyboardType: TextInputType.number,
          validator: VitalInputValidator.validatePulse,
          prefixIcon: Icons.favorite_outline,
        ),
      ],
    );
  }

  // ==========================================
  // Blood Sugar Form Fields
  // ==========================================
  Widget _buildBloodSugarFields() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildTextField(
          controller: _sugarValueController,
          label: 'Glucose Value (mg/dL)',
          helperText: 'Value measured via glucometer',
          keyboardType: TextInputType.number,
          validator: VitalInputValidator.validateBloodSugar,
          prefixIcon: Icons.bloodtype_outlined,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<BloodSugarReadingType>(
          value: _sugarReadingType,
          decoration: InputDecoration(
            labelText: 'Reading Context',
            prefixIcon: const Icon(Icons.restaurant_menu),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          items: BloodSugarReadingType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _sugarReadingType = val;
              });
            }
          },
        )
      ],
    );
  }

  // ==========================================
  // Temperature Form Fields
  // ==========================================
  Widget _buildTemperatureFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _tempValueController,
          label: 'Body Temperature',
          helperText: 'Normal range is ~37.0°C (98.6°F)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (val) => VitalInputValidator.validateTemperature(val, _tempUnit),
          prefixIcon: Icons.thermostat_outlined,
        ),
        const SizedBox(height: 20),
        // Segmented Unit Selector
        Row(
          children: [
            const Text('Unit of Measurement:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            SegmentedButton<TemperatureUnit>(
              segments: const [
                ButtonSegment(value: TemperatureUnit.celsius, label: Text('Celsius (°C)')),
                ButtonSegment(value: TemperatureUnit.fahrenheit, label: Text('Fahrenheit (°F)')),
              ],
              selected: {_tempUnit},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _tempUnit = newSelection.first;
                });
              },
            ),
          ],
        )
      ],
    );
  }

  // ==========================================
  // Weight Form Fields
  // ==========================================
  Widget _buildWeightFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _weightValueController,
          label: 'Body Weight',
          helperText: 'Measure weight in scale',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: VitalInputValidator.validateWeight,
          prefixIcon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Unit:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            SegmentedButton<WeightUnit>(
              segments: const [
                ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                ButtonSegment(value: WeightUnit.lbs, label: Text('lbs')),
              ],
              selected: {_weightUnit},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _weightUnit = newSelection.first;
                });
              },
            ),
          ],
        )
      ],
    );
  }

  // ==========================================
  // SpO2 Form Fields
  // ==========================================
  Widget _buildSpO2Fields() {
    return _buildTextField(
      controller: _spo2Controller,
      label: 'Oxygen Saturation Percentage (SpO₂)',
      helperText: 'Healthy blood oxygenation is 95% - 100%',
      keyboardType: TextInputType.number,
      validator: VitalInputValidator.validateSpO2,
      prefixIcon: Icons.bubble_chart_outlined,
    );
  }

  // Helper textfield builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String helperText,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    required IconData prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _isEditMode ? (_existingRecord as dynamic).id as String : const Uuid().v4();
    final now = DateTime.now();
    final createdAt = _isEditMode ? (_existingRecord as dynamic).createdAt as DateTime : now;

    bool success = false;
    final notifier = ref.read(vitalsActionNotifierProvider.notifier);

    switch (_vitalType) {
      case VitalType.bloodPressure:
        final record = BloodPressureEntity(
          id: id,
          systolic: int.parse(_systolicController.text),
          diastolic: int.parse(_diastolicController.text),
          pulse: int.tryParse(_pulseController.text),
          timestamp: _selectedDateTime,
          createdAt: createdAt,
          updatedAt: now,
        );
        success = _isEditMode ? await notifier.editBP(record) : await notifier.addBP(record);
        break;

      case VitalType.bloodSugar:
        final record = BloodSugarEntity(
          id: id,
          value: double.parse(_sugarValueController.text),
          readingType: _sugarReadingType,
          timestamp: _selectedDateTime,
          createdAt: createdAt,
          updatedAt: now,
        );
        success = _isEditMode ? await notifier.editBloodSugar(record) : await notifier.addBloodSugar(record);
        break;

      case VitalType.temperature:
        final record = TemperatureEntity(
          id: id,
          value: double.parse(_tempValueController.text),
          unit: _tempUnit,
          timestamp: _selectedDateTime,
          createdAt: createdAt,
          updatedAt: now,
        );
        success = _isEditMode ? await notifier.editTemperature(record) : await notifier.addTemperature(record);
        break;

      case VitalType.weight:
        final record = WeightEntity(
          id: id,
          value: double.parse(_weightValueController.text),
          unit: _weightUnit,
          timestamp: _selectedDateTime,
          createdAt: createdAt,
          updatedAt: now,
        );
        success = _isEditMode ? await notifier.editWeight(record) : await notifier.addWeight(record);
        break;

      case VitalType.spo2:
        final record = SpO2Entity(
          id: id,
          percentage: int.parse(_spo2Controller.text),
          timestamp: _selectedDateTime,
          createdAt: createdAt,
          updatedAt: now,
        );
        success = _isEditMode ? await notifier.editSpO2(record) : await notifier.addSpO2(record);
        break;
    }

    if (!mounted) return;

    final errorMsg = ref.read(vitalsActionNotifierProvider).error?.toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Vitals saved successfully.'
            : 'Saved to local cache. Sync pending. ${errorMsg != null ? "($errorMsg)" : ""}'),
      ),
    );

    if (success || !success) {
      // Navigate back in both cases since offline-first caches immediately
      Navigator.pop(context);
    }
  }

  String _getVitalName(VitalType type) {
    return switch (type) {
      VitalType.bloodPressure => 'Blood Pressure',
      VitalType.bloodSugar => 'Blood Sugar',
      VitalType.temperature => 'Body Temperature',
      VitalType.weight => 'Body Weight',
      VitalType.spo2 => 'Oxygen (SpO₂)',
    };
  }
}
