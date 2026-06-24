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
  bool _includePrescriptions = false; // Kept in config for UI integrity

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  int _visitsCount = 0;
  String _bpAvgStr = '--';
  String _sugarAvgStr = '--';
  String _complianceStr = '--';
  String _patientName = 'Rajan Kumar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
      Provider.of<VitalsProvider>(context, listen: false).loadVitals();
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
    });
  }

  Future<void> _updatePreviewDetails() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);

    _patientName = userProvider.currentUser?.name ?? 'Rajan Kumar';

    final db = DatabaseHelper.instance;
    final visits = await db.getDoctorVisits();
    final logs = await db.getMedicationLogs();

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

    // Filter vitals in period
    final filteredVitals = vitalsProvider.vitals.where((v) {
      try {
        final d = DateTime.parse(v.date);
        return d.isAfter(_fromDate.subtract(const Duration(days: 1))) && d.isBefore(_toDate.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();

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

    final user = userProvider.currentUser ?? User(name: 'Rajan Kumar');
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
          children: [
            _buildReportConfigCard(context),
            const SizedBox(height: MediTrackSpacing.sectionGap),
            if (_isReportGenerated) ...[
              _buildReportPreviewCard(context),
              const SizedBox(height: MediTrackSpacing.large),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportConfigCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Configure Report',
                  style: context.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: MediTrackSpacing.medium),
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
                          _isReportGenerated = false;
                        });
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
                          _isReportGenerated = false;
                        });
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
                  _isReportGenerated = false;
                });
              },
              secondary: Icon(Icons.favorite_outline, color: context.colors.primary),
              title: Text('Vitals Summary', style: context.bodyMedium),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            CheckboxListTile(
              value: _includeMeds,
              onChanged: (val) {
                setState(() {
                  _includeMeds = val ?? false;
                  _isReportGenerated = false;
                });
              },
              secondary: Icon(Icons.medication_outlined, color: context.colors.primary),
              title: Text('Medication Log', style: context.bodyMedium),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            CheckboxListTile(
              value: _includeSymptoms,
              onChanged: (val) {
                setState(() {
                  _includeSymptoms = val ?? false;
                  _isReportGenerated = false;
                });
              },
              secondary: Icon(Icons.sick_outlined, color: context.colors.primary),
              title: Text('Symptom Diary', style: context.bodyMedium),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            CheckboxListTile(
              value: _includeVisits,
              onChanged: (val) {
                setState(() {
                  _includeVisits = val ?? false;
                  _isReportGenerated = false;
                });
              },
              secondary: Icon(Icons.local_hospital_outlined, color: context.colors.primary),
              title: Text('Doctor Visits', style: context.bodyMedium),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            CheckboxListTile(
              value: _includePrescriptions,
              onChanged: (val) {
                setState(() {
                  _includePrescriptions = val ?? false;
                  _isReportGenerated = false;
                });
              },
              secondary: Icon(Icons.description_outlined, color: context.colors.primary),
              title: Text('Prescriptions', style: context.bodyMedium),
              contentPadding: EdgeInsets.zero,
              activeColor: context.colors.primary,
            ),
            const SizedBox(height: MediTrackSpacing.large),
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

  Widget _buildReportPreviewCard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.picture_as_pdf, color: context.colors.errorSos),
                const SizedBox(width: 8),
                Text(
                  'Report Preview',
                  style: context.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
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
                      style: context.titleLarge.copyWith(color: context.colors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Patient: $_patientName  |  ${dateFormat.format(_fromDate)} - ${dateFormat.format(_toDate)}',
                      style: context.labelSmall,
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
                    const SizedBox(height: 12),
                  ],
                  if (_includeMeds) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Medication Adherence:', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                        Text(_complianceStr, style: context.bodySmall.copyWith(color: context.colors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_includeVisits) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Doctor Visits:', style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                        Text('$_visitsCount Visits', style: context.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 12, color: context.colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Preview only — download for full report',
                        style: context.labelSmall.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sharePdf,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
