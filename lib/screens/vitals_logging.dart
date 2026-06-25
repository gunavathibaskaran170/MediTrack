import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../providers/vitals_provider.dart';
import '../core/models.dart';
import '../services/notification_service.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final double shakeOffset;
  const ShakeWidget({super.key, required this.child, this.shakeOffset = 6.0});

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: -1.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -1.0, end: 0.8), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: -0.8), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -0.8, end: 0.5), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 0.0), weight: 1),
    ]).animate(_controller);

    return AnimatedBuilder(
      animation: offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(offsetAnimation.value * widget.shakeOffset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

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

  // Shake keys
  final _bpShakeKey = GlobalKey<ShakeWidgetState>();
  final _sugarShakeKey = GlobalKey<ShakeWidgetState>();
  final _tempShakeKey = GlobalKey<ShakeWidgetState>();
  final _weightShakeKey = GlobalKey<ShakeWidgetState>();
  final _spo2ShakeKey = GlobalKey<ShakeWidgetState>();
  final _hrShakeKey = GlobalKey<ShakeWidgetState>();

  Vital? _existingTodayVitals;

  @override
  void initState() {
    super.initState();
    _checkTodayVitals();
  }

  void _checkTodayVitals() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
      await vitalsProvider.loadTodayVitals();
      if (vitalsProvider.todayVitals != null) {
        final today = vitalsProvider.todayVitals!;
        setState(() {
          _existingTodayVitals = today;
          _sysController.text = today.bpSystolic != null ? today.bpSystolic!.toInt().toString() : '';
          _diaController.text = today.bpDiastolic != null ? today.bpDiastolic!.toInt().toString() : '';
          _sugarController.text = today.bloodSugar != null ? today.bloodSugar!.toInt().toString() : '';
          if (today.sugarType == 'post_meal') {
            _sugarToggleSelected[0] = false;
            _sugarToggleSelected[1] = true;
          } else {
            _sugarToggleSelected[0] = true;
            _sugarToggleSelected[1] = false;
          }
          _tempController.text = today.temperature != null ? today.temperature!.toStringAsFixed(1) : '';
          _weightController.text = today.weight != null ? today.weight!.toStringAsFixed(1) : '';
          _spo2Controller.text = today.spo2 != null ? today.spo2!.toInt().toString() : '';
          _hrController.text = today.heartRate != null ? today.heartRate!.toInt().toString() : '';

          // Populate notes
          if (today.notes != null) {
            final parts = today.notes!.split(' | ');
            for (var p in parts) {
              if (p.startsWith('BP: ')) _bpNotesController.text = p.substring(4);
              if (p.startsWith('Sugar: ')) _sugarNotesController.text = p.substring(7);
              if (p.startsWith('Temp: ')) _tempNotesController.text = p.substring(6);
              if (p.startsWith('Weight: ')) _weightNotesController.text = p.substring(8);
              if (p.startsWith('SpO2: ')) _spo2NotesController.text = p.substring(6);
              if (p.startsWith('HR: ')) _hrNotesController.text = p.substring(4);
            }
          }
        });
      }
    });
  }

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

  bool _validateBP() {
    final sys = _sysController.text.trim();
    final dia = _diaController.text.trim();
    if (sys.isEmpty && dia.isEmpty) return true;
    if (sys.isNotEmpty && dia.isEmpty) return false;
    if (sys.isEmpty && dia.isNotEmpty) return false;
    final sysVal = double.tryParse(sys);
    final diaVal = double.tryParse(dia);
    if (sysVal == null || diaVal == null) return false;
    if (sysVal < 50 || sysVal > 250) return false;
    if (diaVal < 30 || diaVal > 150) return false;
    return true;
  }

  bool _validateSugar() {
    final val = _sugarController.text.trim();
    if (val.isEmpty) return true;
    final numVal = double.tryParse(val);
    if (numVal == null) return false;
    if (numVal < 20 || numVal > 600) return false;
    return true;
  }

  bool _validateTemp() {
    final val = _tempController.text.trim();
    if (val.isEmpty) return true;
    final numVal = double.tryParse(val);
    if (numVal == null) return false;
    if (numVal < 30 || numVal > 45) return false;
    return true;
  }

  bool _validateWeight() {
    final val = _weightController.text.trim();
    if (val.isEmpty) return true;
    final numVal = double.tryParse(val);
    if (numVal == null) return false;
    if (numVal < 10 || numVal > 300) return false;
    return true;
  }

  bool _validateSpO2() {
    final val = _spo2Controller.text.trim();
    if (val.isEmpty) return true;
    final numVal = double.tryParse(val);
    if (numVal == null) return false;
    if (numVal < 50 || numVal > 100) return false;
    return true;
  }

  bool _validateHR() {
    final val = _hrController.text.trim();
    if (val.isEmpty) return true;
    final numVal = double.tryParse(val);
    if (numVal == null) return false;
    if (numVal < 30 || numVal > 220) return false;
    return true;
  }

  void _shakeAndScroll(GlobalKey<ShakeWidgetState> key) {
    key.currentState?.shake();
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveVitals() async {
    final isValidForm = _formKey.currentState!.validate();
    
    // Check specific cards
    if (!_validateBP()) {
      _shakeAndScroll(_bpShakeKey);
      return;
    }
    if (!_validateSugar()) {
      _shakeAndScroll(_sugarShakeKey);
      return;
    }
    if (!_validateTemp()) {
      _shakeAndScroll(_tempShakeKey);
      return;
    }
    if (!_validateWeight()) {
      _shakeAndScroll(_weightShakeKey);
      return;
    }
    if (!_validateSpO2()) {
      _shakeAndScroll(_spo2ShakeKey);
      return;
    }
    if (!_validateHR()) {
      _shakeAndScroll(_hrShakeKey);
      return;
    }

    if (!isValidForm) return;

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
      id: _existingTodayVitals?.id,
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
    if (_existingTodayVitals != null) {
      await vitalsProvider.updateVitals(vital);
    } else {
      await vitalsProvider.saveVitals(vital);
    }

    // Cancel daily vitals reminder if logged today
    try {
      await NotificationService().cancelDailyVitalsReminder();
    } catch (e) {
      debugPrint("Error canceling daily vitals reminder: $e");
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingTodayVitals != null;
    Widget? banner;
    if (isEditing && _existingTodayVitals!.createdAt != null) {
      String timeLogged = '';
      try {
        final parsed = DateTime.parse(_existingTodayVitals!.createdAt!);
        timeLogged = DateFormat('hh:mm a').format(parsed);
      } catch (_) {
        timeLogged = 'Previously';
      }
      banner = Container(
        color: context.colors.warningLight,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.edit_note, color: context.colors.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              'Editing today\'s entry — logged at $timeLogged',
              style: context.bodySmall.copyWith(color: context.colors.warning, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

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
            Text(isEditing ? 'Update Today\'s Vitals' : 'Log Vitals', style: context.titleLarge),
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
            if (banner != null) banner,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding, vertical: 8.0),
                child: Column(
                  children: [
                    ShakeWidget(
                      key: _bpShakeKey,
                      child: _buildBPInputCard(context),
                    ),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    ShakeWidget(
                      key: _sugarShakeKey,
                      child: _buildSugarInputCard(context),
                    ),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    ShakeWidget(
                      key: _tempShakeKey,
                      child: _buildTempInputCard(context),
                    ),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    ShakeWidget(
                      key: _weightShakeKey,
                      child: _buildWeightInputCard(context),
                    ),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    ShakeWidget(
                      key: _spo2ShakeKey,
                      child: _buildSpO2InputCard(context),
                    ),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    ShakeWidget(
                      key: _hrShakeKey,
                      child: _buildHeartRateInputCard(context),
                    ),
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
                      child: Text(isEditing ? "Update Vitals" : "Save Today's Vitals"),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickLogBottomSheet,
        icon: const Icon(Icons.bolt),
        label: const Text('Quick Fill'),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showQuickLogBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Log Shortcuts',
                style: context.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Same as Yesterday'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: context.colors.primaryLight,
                  foregroundColor: context.colors.primary,
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _fillSameAsYesterday();
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('All Normal Values'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: context.colors.accentLight,
                  foregroundColor: context.colors.accent,
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _fillAllNormalValues();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Enter Manually'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: context.colors.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _fillSameAsYesterday() {
    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Vital? yesterday;
    for (var v in vitalsProvider.vitals) {
      if (v.date != todayStr) {
        yesterday = v;
        break;
      }
    }

    if (yesterday != null) {
      setState(() {
        _sysController.text = yesterday!.bpSystolic != null ? yesterday!.bpSystolic!.toInt().toString() : '';
        _diaController.text = yesterday!.bpDiastolic != null ? yesterday!.bpDiastolic!.toInt().toString() : '';
        _sugarController.text = yesterday!.bloodSugar != null ? yesterday!.bloodSugar!.toInt().toString() : '';
        if (yesterday!.sugarType == 'post_meal') {
          _sugarToggleSelected[0] = false;
          _sugarToggleSelected[1] = true;
        } else {
          _sugarToggleSelected[0] = true;
          _sugarToggleSelected[1] = false;
        }
        _tempController.text = yesterday!.temperature != null ? yesterday!.temperature!.toStringAsFixed(1) : '';
        _weightController.text = yesterday!.weight != null ? yesterday!.weight!.toStringAsFixed(1) : '';
        _spo2Controller.text = yesterday!.spo2 != null ? yesterday!.spo2!.toInt().toString() : '';
        _hrController.text = yesterday!.heartRate != null ? yesterday!.heartRate!.toInt().toString() : '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied yesterday\'s vitals.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous entry found to copy.')),
      );
    }
  }

  void _fillAllNormalValues() {
    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);

    double? lastWeight;
    for (var v in vitalsProvider.vitals) {
      if (v.weight != null) {
        lastWeight = v.weight;
        break;
      }
    }

    setState(() {
      _sysController.text = '120';
      _diaController.text = '80';
      _sugarController.text = '90';
      _sugarToggleSelected[0] = true; // Fasting
      _sugarToggleSelected[1] = false;
      _tempController.text = '36.6';
      _spo2Controller.text = '98';
      _hrController.text = '72';
      _weightController.text = lastWeight != null ? lastWeight.toStringAsFixed(1) : '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filled normal baseline values.')),
    );
  }

  String _getLastReadingHint(String field) {
    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Vital? match;
    for (var v in vitalsProvider.vitals) {
      if (v.date == todayStr) continue;

      if (field == 'bp' && v.bpSystolic != null && v.bpDiastolic != null) {
        match = v;
        break;
      } else if (field == 'sugar' && v.bloodSugar != null) {
        match = v;
        break;
      } else if (field == 'temp' && v.temperature != null) {
        match = v;
        break;
      } else if (field == 'weight' && v.weight != null) {
        match = v;
        break;
      } else if (field == 'spo2' && v.spo2 != null) {
        match = v;
        break;
      } else if (field == 'hr' && v.heartRate != null) {
        match = v;
        break;
      }
    }

    if (match == null) return 'No previous entry';

    String formattedDate = match.date;
    try {
      formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(match.date));
    } catch (_) {}

    if (field == 'bp') {
      return 'Last: ${match.bpSystolic!.toInt()}/${match.bpDiastolic!.toInt()} mmHg on $formattedDate';
    } else if (field == 'sugar') {
      final type = match.sugarType == 'fasting' ? 'Fasting' : (match.sugarType == 'post_meal' ? 'Post-Meal' : '');
      final typeStr = type.isNotEmpty ? ' ($type)' : '';
      return 'Last: ${match.bloodSugar!.toInt()} mg/dL$typeStr on $formattedDate';
    } else if (field == 'temp') {
      return 'Last: ${match.temperature!.toStringAsFixed(1)} °C on $formattedDate';
    } else if (field == 'weight') {
      return 'Last: ${match.weight!.toStringAsFixed(1)} kg on $formattedDate';
    } else if (field == 'spo2') {
      return 'Last: ${match.spo2!.toInt()}% on $formattedDate';
    } else if (field == 'hr') {
      return 'Last: ${match.heartRate!.toInt()} bpm on $formattedDate';
    }

    return 'No previous entry';
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
    String? lastReading,
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
                    color: context.colors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: context.colors.primary),
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
            if (lastReading != null) ...[
              const SizedBox(height: 8),
              Text(
                lastReading,
                style: context.labelSmall.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (hintText != null) ...[
              const SizedBox(height: 4),
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
      lastReading: _getLastReadingHint('bp'),
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
      lastReading: _getLastReadingHint('sugar'),
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
      lastReading: _getLastReadingHint('temp'),
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
      lastReading: _getLastReadingHint('weight'),
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
      lastReading: _getLastReadingHint('spo2'),
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
      lastReading: _getLastReadingHint('hr'),
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
