import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../providers/vitals_provider.dart';
import '../core/models.dart';

class VitalsLoggingScreen extends StatefulWidget {
  const VitalsLoggingScreen({super.key});

  @override
  State<VitalsLoggingScreen> createState() => _VitalsLoggingScreenState();
}

class _VitalsLoggingScreenState extends State<VitalsLoggingScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<bool> _sugarToggleSelected = [true, false];
  DateTime _selectedDate = DateTime.now();

  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _sugarController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _hrController = TextEditingController();

  final _bpNotesController = TextEditingController();
  final _sugarNotesController = TextEditingController();
  final _tempNotesController = TextEditingController();
  final _weightNotesController = TextEditingController();
  final _spo2NotesController = TextEditingController();
  final _hrNotesController = TextEditingController();

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _sugarController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _spo2Controller.dispose();
    _hrController.dispose();
    _bpNotesController.dispose();
    _sugarNotesController.dispose();
    _tempNotesController.dispose();
    _weightNotesController.dispose();
    _spo2NotesController.dispose();
    _hrNotesController.dispose();
    super.dispose();
  }

  void _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;

    final sysStr = _sysController.text.trim();
    final diaStr = _diaController.text.trim();
    final sugarStr = _sugarController.text.trim();
    final tempStr = _tempController.text.trim();
    final weightStr = _weightController.text.trim();
    final spo2Str = _spo2Controller.text.trim();
    final hrStr = _hrController.text.trim();

    if (sysStr.isEmpty &&
        diaStr.isEmpty &&
        sugarStr.isEmpty &&
        tempStr.isEmpty &&
        weightStr.isEmpty &&
        spo2Str.isEmpty &&
        hrStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log at least one vital reading.')),
      );
      return;
    }

    if ((sysStr.isNotEmpty && diaStr.isEmpty) || (sysStr.isEmpty && diaStr.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both Systolic and Diastolic blood pressure are required.')),
      );
      return;
    }

    final double? sys = double.tryParse(sysStr);
    final double? dia = double.tryParse(diaStr);
    final double? sugar = double.tryParse(sugarStr);
    final double? temp = double.tryParse(tempStr);
    final double? weight = double.tryParse(weightStr);
    final double? spo2 = double.tryParse(spo2Str);
    final double? hr = double.tryParse(hrStr);

    final List<String> notesParts = [];
    if (_bpNotesController.text.trim().isNotEmpty) notesParts.add('BP: ${_bpNotesController.text.trim()}');
    if (_sugarNotesController.text.trim().isNotEmpty) notesParts.add('Sugar: ${_sugarNotesController.text.trim()}');
    if (_tempNotesController.text.trim().isNotEmpty) notesParts.add('Temp: ${_tempNotesController.text.trim()}');
    if (_weightNotesController.text.trim().isNotEmpty) notesParts.add('Weight: ${_weightNotesController.text.trim()}');
    if (_spo2NotesController.text.trim().isNotEmpty) notesParts.add('SpO2: ${_spo2NotesController.text.trim()}');
    if (_hrNotesController.text.trim().isNotEmpty) notesParts.add('HR: ${_hrNotesController.text.trim()}');
    final notes = notesParts.isNotEmpty ? notesParts.join(' | ') : null;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final vital = Vital(
      date: formattedDate,
      bpSystolic: sys,
      bpDiastolic: dia,
      bloodSugar: sugar,
      sugarType: sugar != null ? (_sugarToggleSelected[0] ? 'fasting' : 'post_meal') : null,
      temperature: temp,
      weight: weight,
      spo2: spo2,
      heartRate: hr,
      notes: notes,
    );

    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
    await vitalsProvider.saveVitals(vital);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Vitals', style: context.titleLarge),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: context.labelSmall.copyWith(color: context.colors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: context.colors.textPrimary),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.history, color: context.colors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/vitals/history'),
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
                padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding, vertical: 8.0),
                child: Column(
                  children: [
                    _buildBPInputCard(context),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    _buildSugarInputCard(context),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    _buildTempInputCard(context),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    _buildWeightInputCard(context),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    _buildSpO2InputCard(context),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    _buildHeartRateInputCard(context),
                    const SizedBox(height: MediTrackSpacing.large),
                  ],
                ),
              ),
            ),
            // Pinned Bottom Button Area
            Container(
              padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
              decoration: BoxDecoration(
                color: context.colors.background,
                border: Border(
                  top: BorderSide(color: context.colors.dividerColor, width: 0.8),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveVitals,
                      child: const Text("Save Today's Vitals"),
                    ),
                  ),
                  const SizedBox(height: MediTrackSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: context.colors.textSecondary),
                      const SizedBox(width: MediTrackSpacing.small),
                      Text(
                        'All data saved offline on your device',
                        style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Base card wrapper helper with custom visual styles
  Widget _buildVitalCardWrapper({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String rangeInfo,
    required Widget inputRow,
    Widget? additionalWidget,
    String? hintText,
    required TextEditingController notesController,
  }) {
    return Card(
      margin: EdgeInsets.zero,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight, // 40px circle, primaryLight background
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: context.colors.primary), // primary icon color
                ),
                const SizedBox(width: MediTrackSpacing.medium),
                Text(
                  title,
                  style: context.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.info_outline, color: context.colors.textSecondary),
                  onPressed: () => showVitalInfoDialog(context, title, rangeInfo),
                ),
              ],
            ),
            const SizedBox(height: MediTrackSpacing.medium),
            inputRow,
            if (hintText != null) ...[
              const SizedBox(height: 6),
              Text(
                hintText,
                style: context.labelSmall.copyWith(color: context.colors.textSecondary),
              ),
            ],
            if (additionalWidget != null) ...[
              const SizedBox(height: MediTrackSpacing.medium),
              additionalWidget,
            ],
            const SizedBox(height: MediTrackSpacing.medium),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(Icons.notes_outlined, color: context.colors.textSecondary),
                title: Text('Add note', style: context.bodySmall),
                tilePadding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    style: context.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Enter notes about this entry...',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card 1 - Blood Pressure
  Widget _buildBPInputCard(BuildContext context) {
    return _buildVitalCardWrapper(
      context: context,
      icon: Icons.favorite,
      title: 'Blood Pressure',
      rangeInfo: 'Normal: below 120/80 mmHg\nElevated: 120-129/below 80 mmHg\nStage 1 Hypertension: 130-139/80-89 mmHg\nStage 2 Hypertension: 140/90 mmHg or higher',
      hintText: 'Normal: below 120/80',
      notesController: _bpNotesController,
      inputRow: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _sysController,
              style: context.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Systolic',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final n = double.tryParse(val.trim());
                if (n == null) return 'Must be a number';
                if (n < 50 || n > 250) return 'Invalid range (50-250)';
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text('/', style: context.headlineMedium.copyWith(color: context.colors.dividerColor)),
          ),
          Expanded(
            child: TextFormField(
              controller: _diaController,
              style: context.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Diastolic',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final n = double.tryParse(val.trim());
                if (n == null) return 'Must be a number';
                if (n < 30 || n > 150) return 'Invalid range (30-150)';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Text('mmHg', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  // Card 2 - Blood Sugar
  Widget _buildSugarInputCard(BuildContext context) {
    return _buildVitalCardWrapper(
      context: context,
      icon: Icons.water_drop,
      title: 'Blood Sugar',
      rangeInfo: 'Fasting: 70-99 mg/dL (Normal)\nPost-meal: Under 140 mg/dL (Normal)',
      notesController: _sugarNotesController,
      inputRow: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _sugarController,
              style: context.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Blood Sugar value',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final n = double.tryParse(val.trim());
                if (n == null) return 'Must be a number';
                if (n < 20 || n > 600) return 'Invalid range (20-600)';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Text('mg/dL', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)),
        ],
      ),
      additionalWidget: Center(
        child: ToggleButtons(
          isSelected: _sugarToggleSelected,
          onPressed: (index) {
            setState(() {
              for (int i = 0; i < _sugarToggleSelected.length; i++) {
                _sugarToggleSelected[i] = i == index;
              }
            });
          },
          borderRadius: BorderRadius.circular(MediTrackRadius.inputFields),
          borderColor: context.colors.dividerColor,
          selectedBorderColor: context.colors.primary,
          selectedColor: Colors.white,
          fillColor: context.colors.primary,
          color: context.colors.textSecondary,
          constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
          children: const [
            Text('Fasting'),
            Text('Post-meal'),
          ],
        ),
      ),
    );
  }

  // Card 3 - Temperature
  Widget _buildTempInputCard(BuildContext context) {
    return _buildVitalCardWrapper(
      context: context,
      icon: Icons.thermostat,
      title: 'Temperature',
      rangeInfo: 'Normal: 36.1°C to 37.2°C (97°F to 99°F)\nFever: 38°C (100.4°F) or higher',
      hintText: 'Normal: 36.1 – 37.2 °C',
      notesController: _tempNotesController,
      inputRow: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _tempController,
              style: context.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Temperature',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final n = double.tryParse(val.trim());
                if (n == null) return 'Must be a number';
                if (n < 30 || n > 45) return 'Invalid range (30-45)';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Text('°C', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  // Card 4 - Weight
  Widget _buildWeightInputCard(BuildContext context) {
    return _buildVitalCardWrapper(
      context: context,
      icon: Icons.monitor_weight_outlined,
      title: 'Weight',
      rangeInfo: 'Track weight trends regularly to help monitor water retention, BMI, and overall metabolic health.',
      hintText: 'Enter weight in kilograms',
      notesController: _weightNotesController,
      inputRow: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _weightController,
              style: context.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final n = double.tryParse(val.trim());
                if (n == null) return 'Must be a number';
                if (n < 10 || n > 300) return 'Invalid range (10-300)';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Text('kg', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  // Card 5 - SpO2
  Widget _buildSpO2InputCard(BuildContext context) {
    return _buildVitalCardWrapper(
      context: context,
      icon: Icons.air,
      title: 'SpO2',
      rangeInfo: 'Normal: 95% - 100%\nLow Oxygen (Hypoxia): below 95%',
      hintText: 'Normal: 95 – 100%',
      notesController: _spo2NotesController,
      inputRow: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _spo2Controller,
              style: context.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Oxygen Saturation',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final n = double.tryParse(val.trim());
                if (n == null) return 'Must be a number';
                if (n < 50 || n > 100) return 'Invalid range (50-100)';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Text('%', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  // Card 6 - Heart Rate
  Widget _buildHeartRateInputCard(BuildContext context) {
    return _buildVitalCardWrapper(
      context: context,
      icon: Icons.speed,
      title: 'Heart Rate',
      rangeInfo: 'Normal: 60 - 100 bpm (at rest)\nAthletes: 40 - 60 bpm\nTachycardia: above 100 bpm\nBradycardia: below 60 bpm',
      hintText: 'Normal: 60 – 100 bpm',
      notesController: _hrNotesController,
      inputRow: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _hrController,
              style: context.bodyMedium,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Heart Rate',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final n = double.tryParse(val.trim());
                if (n == null) return 'Must be a number';
                if (n < 30 || n > 220) return 'Invalid range (30-220)';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Text('bpm', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}
