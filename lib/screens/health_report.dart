import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../theme/meditrack_theme.dart';
import '../services/pdf_service.dart';
import '../providers/user_provider.dart';
import '../providers/vitals_provider.dart';
import '../providers/medicine_provider.dart';
import '../core/database_helper.dart';
import '../core/models.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  bool _isReportGenerated = false;

  bool _includeVitals = true;
  bool _includeMeds = true;
  bool _includeSymptoms = true;
  bool _includeVisits = false;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  // Selected date chip state
  String _selectedDateRangeChip = '30d'; // '7d', '30d', '3m', 'custom'
  String _selectedTemplate = 'Monthly'; // 'Doctor', 'Monthly', 'Diabetes', 'Custom'

  // Counts for reactive preview
  int _vitalsCount = 0;
  int _symptomsCount = 0;
  int _visitsCount = 0;
  int _prescriptionsCount = 0;
  String _bpAvgStr = '--';
  String _sugarAvgStr = '--';
  String _complianceStr = '--';
  String _patientName = 'Patient';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
      Provider.of<VitalsProvider>(context, listen: false).loadVitals();
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
      _applyTemplate('Monthly'); // Default template
    });
  }

  void _setDateRange(int days) {
    setState(() {
      _toDate = DateTime.now();
      _fromDate = DateTime.now().subtract(Duration(days: days));
      _isReportGenerated = false;
    });
    _updatePreviewDetails();
  }

  void _applyTemplate(String templateName) {
    setState(() {
      _selectedTemplate = templateName;
      _isReportGenerated = false;
      if (templateName == 'Doctor') {
        _includeVitals = true;
        _includeMeds = false;
        _includeSymptoms = false;
        _includeVisits = true;
        _selectedDateRangeChip = '7d';
        _toDate = DateTime.now();
        _fromDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (templateName == 'Monthly') {
        _includeVitals = true;
        _includeMeds = true;
        _includeSymptoms = true;
        _includeVisits = true;
        _selectedDateRangeChip = '30d';
        _toDate = DateTime.now();
        _fromDate = DateTime.now().subtract(const Duration(days: 30));
      } else if (templateName == 'Diabetes') {
        _includeVitals = true;
        _includeMeds = true;
        _includeSymptoms = false;
        _includeVisits = false;
        _selectedDateRangeChip = '3m';
        _toDate = DateTime.now();
        _fromDate = DateTime.now().subtract(const Duration(days: 90));
      }
    });
    _updatePreviewDetails();
  }

  Future<void> _updatePreviewDetails() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);

    _patientName = userProvider.currentUser?.name ?? 'Patient';

    final db = DatabaseHelper.instance;
    final visits = await db.getDoctorVisits();
    final logs = await db.getMedicationLogs();
    final symptoms = await db.getSymptoms();
    final prescriptions = await db.getPrescriptions();

    // Filter doctor visits in period
    final filteredVisits = visits.where((v) {
      try {
        final d = DateTime.parse(v.visitDate);
        return d.isAfter(_fromDate.subtract(const Duration(days: 1))) && d.isBefore(_toDate.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
    _visitsCount = filteredVisits.length;

    // Filter prescriptions in period
    final filteredPresc = prescriptions.where((p) {
      if (p.visitDate == null) return false;
      try {
        final d = DateTime.parse(p.visitDate!);
        return d.isAfter(_fromDate.subtract(const Duration(days: 1))) && d.isBefore(_toDate.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
    _prescriptionsCount = filteredPresc.length;

    // Filter logs in period
    final filteredLogs = logs.where((l) {
      try {
        final d = DateTime.parse(l.date);
        return d.isAfter(_fromDate.subtract(const Duration(days: 1))) && d.isBefore(_toDate.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
    final takenCount = filteredLogs.where((l) => l.status == 'taken').length;
    _complianceStr = filteredLogs.isNotEmpty ? '${((takenCount / filteredLogs.length) * 100).round()}%' : '--';

    // Filter symptoms in period
    final filteredSymptoms = symptoms.where((s) {
      if (s.date == null) return false;
      try {
        final d = DateTime.parse(s.date!);
        return d.isAfter(_fromDate.subtract(const Duration(days: 1))) && d.isBefore(_toDate.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
    _symptomsCount = filteredSymptoms.length;

    // Filter vitals in period
    final filteredVitals = vitalsProvider.vitals.where((v) {
      try {
        final d = DateTime.parse(v.date);
        return d.isAfter(_fromDate.subtract(const Duration(days: 1))) && d.isBefore(_toDate.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
    _vitalsCount = filteredVitals.length;

    final avgs = vitalsProvider.getAverages(filteredVitals);
    final sys = avgs['systolic'] ?? 0.0;
    final dia = avgs['diastolic'] ?? 0.0;
    _bpAvgStr = sys > 0 && dia > 0 ? '${sys.round()}/${dia.round()} mmHg' : '--';

    final sugar = avgs['blood_sugar'] ?? 0.0;
    _sugarAvgStr = sugar > 0 ? '${sugar.toStringAsFixed(1)} mg/dL' : '--';

    setState(() {});
  }

  Future<Uint8List> _generatePdfBytes() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);

    final user = userProvider.currentUser ?? User(name: 'Patient');
    final vitals = vitalsProvider.vitals;
    final medicines = medicineProvider.medicines;

    final db = DatabaseHelper.instance;
    final logs = await db.getMedicationLogs();
    final symptoms = await db.getSymptoms();
    final visits = await db.getDoctorVisits();

    final sections = {
      'vitals': _includeVitals,
      'medicines': _includeMeds,
      'symptoms': _includeSymptoms,
      'visits': _includeVisits,
    };

    return await PdfService().generateHealthReport(
      user: user,
      vitals: vitals,
      medicines: medicines,
      logs: logs,
      symptoms: symptoms,
      visits: visits,
      fromDate: _fromDate,
      toDate: _toDate,
      sectionsEnabled: sections,
    );
  }

  void _downloadPdf() async {
    try {
      final bytes = await _generatePdfBytes();
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'meditrack_health_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint("Error generating PDF for print: $e");
    }
  }

  void _sharePdf() async {
    try {
      final bytes = await _generatePdfBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'meditrack_health_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint("Error generating PDF for share: $e");
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
        title: Text('Health Report', style: context.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preset Templates Card list
            _buildTemplatesRow(),
            const SizedBox(height: 12),

            // Main config sheet
            _buildReportConfigCard(context),
            const SizedBox(height: MediTrackSpacing.sectionGap),

            // Live preview panel with watermark
            if (_isReportGenerated) ...[
              _buildReportPreviewCard(context),
              const SizedBox(height: MediTrackSpacing.large),
            ],
          ],
        ),
      ),
    );
  }

  // --- PRESET TEMPLATES ROW ---
  Widget _buildTemplatesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Report Template',
          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTemplateCard('Monthly', 'Monthly Review', Icons.calendar_month, context.colors.primary),
              _buildTemplateCard('Doctor', 'Doctor Summary', Icons.local_hospital, context.colors.warning),
              _buildTemplateCard('Diabetes', 'Diabetes Tracker', Icons.bloodtype, context.colors.errorSos),
              _buildTemplateCard('Custom', 'Custom Configuration', Icons.tune, context.colors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(String key, String title, IconData icon, Color color) {
    final isSelected = _selectedTemplate == key;

    return GestureDetector(
      onTap: () => _applyTemplate(key),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : context.colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : context.colors.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: context.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : context.colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- CONFIGURE CARD ---
  Widget _buildReportConfigCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Date Range Selection',
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick select date chips
            Row(
              children: [
                _buildDateChip('7d', 'Last 7 Days', 7),
                const SizedBox(width: 8),
                _buildDateChip('30d', 'Last 30 Days', 30),
                const SizedBox(width: 8),
                _buildDateChip('3m', 'Last 3 Months', 90),
              ],
            ),
            const SizedBox(height: 12),

            // Date pickers row
            Row(
              children: [
                Text('From: ', style: context.bodySmall),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _fromDate = date;
                          _selectedDateRangeChip = 'custom';
                          _selectedTemplate = 'Custom';
                          _isReportGenerated = false;
                        });
                        _updatePreviewDetails();
                      }
                    },
                    child: Text(DateFormat('dd MMM yyyy').format(_fromDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('To: ', style: context.bodySmall),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _toDate = date;
                          _selectedDateRangeChip = 'custom';
                          _selectedTemplate = 'Custom';
                          _isReportGenerated = false;
                        });
                        _updatePreviewDetails();
                      }
                    },
                    child: Text(DateFormat('dd MMM yyyy').format(_toDate)),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            Text(
              'Include in report',
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _includeVitals,
              onChanged: (val) {
                setState(() {
                  _includeVitals = val ?? false;
                  _selectedTemplate = 'Custom';
                  _isReportGenerated = false;
                });
                _updatePreviewDetails();
              },
              secondary: Icon(Icons.favorite_outline, color: context.colors.primary),
              title: Text('Vitals Summary', style: context.bodyMedium),
              subtitle: Text('$_vitalsCount readings logged in period', style: context.labelSmall),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            CheckboxListTile(
              value: _includeMeds,
              onChanged: (val) {
                setState(() {
                  _includeMeds = val ?? false;
                  _selectedTemplate = 'Custom';
                  _isReportGenerated = false;
                });
                _updatePreviewDetails();
              },
              secondary: Icon(Icons.medication_outlined, color: context.colors.primary),
              title: Text('Medication Log', style: context.bodyMedium),
              subtitle: Text('Compliance: $_complianceStr', style: context.labelSmall),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            CheckboxListTile(
              value: _includeSymptoms,
              onChanged: (val) {
                setState(() {
                  _includeSymptoms = val ?? false;
                  _selectedTemplate = 'Custom';
                  _isReportGenerated = false;
                });
                _updatePreviewDetails();
              },
              secondary: Icon(Icons.sick_outlined, color: context.colors.primary),
              title: Text('Symptom Diary', style: context.bodyMedium),
              subtitle: Text('$_symptomsCount symptoms logged in period', style: context.labelSmall),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            CheckboxListTile(
              value: _includeVisits,
              onChanged: (val) {
                setState(() {
                  _includeVisits = val ?? false;
                  _selectedTemplate = 'Custom';
                  _isReportGenerated = false;
                });
                _updatePreviewDetails();
              },
              secondary: Icon(Icons.local_hospital_outlined, color: context.colors.primary),
              title: Text('Doctor Visits', style: context.bodyMedium),
              subtitle: Text('$_visitsCount visits, $_prescriptionsCount prescriptions linked', style: context.labelSmall),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await _updatePreviewDetails();
                setState(() {
                  _isReportGenerated = true;
                });
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String key, String label, int days) {
    final isSelected = _selectedDateRangeChip == key;
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: context.labelSmall.copyWith(
          color: isSelected ? context.colors.primary : context.colors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selectedColor: context.colors.primaryLight,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedDateRangeChip = key;
              _selectedTemplate = 'Custom'; // Modifying dates overrides templates
            });
            _setDateRange(days);
          }
        },
      ),
    );
  }

  // --- REPORT PREVIEW CARD ---
  Widget _buildReportPreviewCard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.remove_red_eye_outlined, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Live Preview',
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Preview sheet with rotated Watermark
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: context.colors.dividerColor, width: 0.8),
                    borderRadius: BorderRadius.circular(MediTrackRadius.cards),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'MediTrack Health Report',
                          style: context.titleLarge.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Patient: $_patientName  |  ${dateFormat.format(_fromDate)} - ${dateFormat.format(_toDate)}',
                          style: context.labelSmall.copyWith(color: context.colors.textSecondary),
                        ),
                      ),
                      const Divider(height: 20),
                      if (_includeVitals) ...[
                        Text('Vitals Summary', style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Table(
                          border: TableBorder.all(color: context.colors.dividerColor, width: 0.5),
                          children: [
                            TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.all(6.0), child: Text('Metric', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                                Padding(padding: const EdgeInsets.all(6.0), child: Text('Average', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.all(6.0), child: Text('Blood Pressure', style: context.bodySmall)),
                                Padding(padding: const EdgeInsets.all(6.0), child: Text(_bpAvgStr, style: context.bodySmall)),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: const EdgeInsets.all(6.0), child: Text('Blood Sugar', style: context.bodySmall)),
                                Padding(padding: const EdgeInsets.all(6.0), child: Text(_sugarAvgStr, style: context.bodySmall)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_includeMeds) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Medication Adherence:', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                            Text(_complianceStr, style: context.bodySmall.copyWith(color: context.colors.success, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_includeSymptoms) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Symptoms Recorded:', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                            Text('$_symptomsCount entries', style: context.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_includeVisits) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Doctor Consultations:', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                            Text('$_visitsCount visits | $_prescriptionsCount linked', style: context.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 12, color: context.colors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            'Preview only — generate PDF to save, share, or print',
                            style: context.labelSmall.copyWith(fontStyle: FontStyle.italic, color: context.colors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Diagonal semi-transparent watermark
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.4,
                        child: Text(
                          'MEDITRACK PREVIEW',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primary.withOpacity(0.06),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save / Print / Share stacked actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.print),
                  label: const Text('Print Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _downloadPdf, // Layout PDF operates as download/save locally
                        icon: const Icon(Icons.download),
                        label: const Text('Save PDF'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sharePdf,
                        icon: const Icon(Icons.share),
                        label: const Text('Share PDF'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
