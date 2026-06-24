import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../core/models.dart';

class PdfService {
  static final PdfColor primaryColor = PdfColor.fromHex('#3D3B8E'); // Deep Indigo
  static final PdfColor primaryLightColor = PdfColor.fromHex('#EEEDFE'); // Lavender
  static final PdfColor errorColor = PdfColor.fromHex('#C0392B'); // Rich Red
  static final PdfColor warningColor = PdfColor.fromHex('#E08C00'); // Deep Amber
  static final PdfColor successColor = PdfColor.fromHex('#27760A'); // Forest Green
  static final PdfColor textPrimaryColor = PdfColor.fromHex('#1A1A2E');
  static final PdfColor textSecondaryColor = PdfColor.fromHex('#5F5E7A');
  static final PdfColor dividerColor = PdfColor.fromHex('#E2E1EF');

  Future<Uint8List> generateHealthReport({
    required User user,
    required List<Vital> vitals,
    required List<Medicine> medicines,
    required List<MedicationLog> logs,
    required List<Symptom> symptoms,
    required List<DoctorVisit> visits,
    required DateTime fromDate,
    required DateTime toDate,
    required Map<String, bool> sectionsEnabled,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    // Filter data by date range
    final filteredVitals = vitals.where((v) {
      final date = DateTime.tryParse(v.date) ?? DateTime.now();
      return date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          date.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();

    final filteredLogs = logs.where((l) {
      final date = DateTime.tryParse(l.date) ?? DateTime.now();
      return date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          date.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();

    final filteredSymptoms = symptoms.where((s) {
      final date = s.date != null ? DateTime.tryParse(s.date!) : null;
      if (date == null) return false;
      return date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          date.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();

    final filteredVisits = visits.where((v) {
      final date = DateTime.tryParse(v.visitDate);
      if (date == null) return false;
      return date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          date.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();

    // 1. PAGE 1: COVER PAGE
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Spacer(flex: 1),
              pw.Center(
                child: pw.Text(
                  'MediTrack',
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Personal Health Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: textSecondaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Divider(color: dividerColor, thickness: 2),
              pw.SizedBox(height: 24),
              pw.Text('Patient Profile', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Name: ${user.name}', style: const pw.TextStyle(fontSize: 14)),
                  pw.Text('Age: ${user.age ?? "N/A"} yrs', style: const pw.TextStyle(fontSize: 14)),
                  pw.Text('Blood Type: ${user.bloodGroup ?? "N/A"}', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('Existing Conditions: ${user.conditions ?? "None"}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Allergies: ${user.allergies ?? "None"}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 32),
              pw.Divider(color: dividerColor, thickness: 0.8),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Report Period:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${dateFormat.format(fromDate)} to ${dateFormat.format(toDate)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated On:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateFormat.format(DateTime.now())),
                ],
              ),
              pw.Spacer(flex: 2),
              _buildFooterWidget(context, 1, 1), // Simple page footer placeholder
            ],
          );
        },
      ),
    );

    // 2. PAGE 2: VITALS SUMMARY
    if (sectionsEnabled['vitals'] == true) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPageHeader('Vitals Summary'),
          footer: (context) => _buildFooterWidget(context, context.pageNumber, context.pagesCount),
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: dividerColor, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryLightColor),
                    children: [
                      _tableHeaderCell('Date'),
                      _tableHeaderCell('BP (mmHg)'),
                      _tableHeaderCell('Sugar (mg/dL)'),
                      _tableHeaderCell('Temp (°C)'),
                      _tableHeaderCell('Weight (kg)'),
                      _tableHeaderCell('SpO2 (%)'),
                      _tableHeaderCell('HR (bpm)'),
                    ],
                  ),
                  ...List.generate(filteredVitals.length, (idx) {
                    final v = filteredVitals[idx];
                    final rowBg = idx % 2 == 0 ? PdfColors.white : primaryLightColor;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _tableTextCell(v.date),
                        _bpTableCell(v.bpSystolic, v.bpDiastolic),
                        _sugarTableCell(v.bloodSugar),
                        _tempTableCell(v.temperature),
                        _tableTextCell(v.weight != null ? v.weight!.toStringAsFixed(1) : '--', color: successColor), // Weight is always green
                        _spo2TableCell(v.spo2),
                        _hrTableCell(v.heartRate),
                      ],
                    );
                  })
                ],
              )
            ];
          },
        ),
      );
    }

    // 3. PAGE 3: MEDICATION LOGS
    if (sectionsEnabled['medicines'] == true) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPageHeader('Medication Compliance'),
          footer: (context) => _buildFooterWidget(context, context.pageNumber, context.pagesCount),
          build: (pw.Context context) {
            // Compute adherence per medicine
            final medRows = <pw.TableRow>[];
            double overallAdherence = 0.0;
            int totalLogsCount = filteredLogs.length;
            int totalTakenCount = filteredLogs.where((l) => l.status == 'taken').length;

            if (totalLogsCount > 0) {
              overallAdherence = totalTakenCount / totalLogsCount;
            }

            for (var med in medicines) {
              final medLogs = filteredLogs.where((l) => l.medicineId == med.id).toList();
              final countTotal = medLogs.length;
              final countTaken = medLogs.where((l) => l.status == 'taken').length;
              final countMissed = medLogs.where((l) => l.status == 'missed').length;
              double adherence = 0.0;
              if (countTotal > 0) {
                adherence = countTaken / countTotal;
              }

              medRows.add(
                pw.TableRow(
                  children: [
                    _tableTextCell(med.name),
                    _tableTextCell('${med.dosage ?? "--"} ${med.unit ?? ""}'),
                    _tableTextCell(med.frequency ?? 'N/A'),
                    _tableTextCell('${(adherence * 100).toStringAsFixed(0)}%',
                        color: adherence >= 0.85 ? successColor : errorColor, fontWeight: pw.FontWeight.bold),
                    _tableTextCell(countMissed.toString(), color: countMissed > 0 ? errorColor : textPrimaryColor),
                  ],
                ),
              );
            }

            return [
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: dividerColor, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryLightColor),
                    children: [
                      _tableHeaderCell('Medicine Name'),
                      _tableHeaderCell('Dosage'),
                      _tableHeaderCell('Frequency'),
                      _tableHeaderCell('Adherence %'),
                      _tableHeaderCell('Missed Doses'),
                    ],
                  ),
                  ...medRows,
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryLightColor),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Overall Adherence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      _tableTextCell(''),
                      _tableTextCell(''),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${(overallAdherence * 100).toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: overallAdherence >= 0.85 ? successColor : errorColor,
                            )),
                      ),
                      _tableTextCell(''),
                    ],
                  )
                ],
              )
            ];
          },
        ),
      );
    }

    // 4. PAGE 4: SYMPTOM DIARY
    if (sectionsEnabled['symptoms'] == true) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPageHeader('Symptom Timeline'),
          footer: (context) => _buildFooterWidget(context, context.pageNumber, context.pagesCount),
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: dividerColor, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryLightColor),
                    children: [
                      _tableHeaderCell('Date / Time'),
                      _tableHeaderCell('Symptom'),
                      _tableHeaderCell('Severity'),
                      _tableHeaderCell('Notes'),
                    ],
                  ),
                  ...List.generate(filteredSymptoms.length, (idx) {
                    final sym = filteredSymptoms[idx];
                    final rowBg = idx % 2 == 0 ? PdfColors.white : primaryLightColor;
                    String severityText = 'Mild';
                    PdfColor sevColor = successColor;
                    if (sym.severity == 3) {
                      severityText = 'Severe';
                      sevColor = errorColor;
                    } else if (sym.severity == 2) {
                      severityText = 'Moderate';
                      sevColor = warningColor;
                    }
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _tableTextCell('${sym.date ?? "--"}  ${sym.time ?? ""}'),
                        _tableTextCell(sym.symptomName ?? '--'),
                        _tableTextCell(severityText, color: sevColor, fontWeight: pw.FontWeight.bold),
                        _tableTextCell(sym.notes ?? '', maxLines: 3),
                      ],
                    );
                  })
                ],
              )
            ];
          },
        ),
      );
    }

    // 5. PAGE 5: DOCTOR VISITS
    if (sectionsEnabled['visits'] == true) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPageHeader('Doctor Consultation Records'),
          footer: (context) => _buildFooterWidget(context, context.pageNumber, context.pagesCount),
          build: (pw.Context context) {
            final visitWidgets = <pw.Widget>[];
            for (var v in filteredVisits) {
              visitWidgets.addAll([
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Doctor: ${v.doctorName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: primaryColor)),
                    pw.Text('Date: ${v.visitDate}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('Hospital/Clinic: ${v.hospital}', style: pw.TextStyle(color: textSecondaryColor, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Diagnosis: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.TextSpan(text: v.diagnosis ?? 'None', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Consultation Notes: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.TextSpan(text: v.notes ?? 'None', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Follow-up Date: ${v.followUpDate ?? "None Scheduled"}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: v.followUpDate != null ? warningColor : textSecondaryColor,
                    )),
                pw.SizedBox(height: 12),
                pw.Divider(color: dividerColor, thickness: 0.5),
              ]);
            }

            return [
              pw.SizedBox(height: 16),
              if (filteredVisits.isEmpty)
                pw.Center(child: pw.Text('No doctor visits logged in this period.', style: pw.TextStyle(color: textSecondaryColor)))
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: visitWidgets,
                )
            ];
          },
        ),
      );
    }

    return await pdf.save();
  }

  // Header & Footer Builders
  static pw.Widget _buildPageHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MediTrack Health Report',
              style: pw.TextStyle(fontSize: 10, color: textSecondaryColor, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 12, color: primaryColor, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: dividerColor, thickness: 0.5),
      ],
    );
  }

  static pw.Widget _buildFooterWidget(pw.Context context, int pageNum, int totalPages) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(color: dividerColor, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MediTrack — Not a diagnostic tool.',
              style: pw.TextStyle(fontSize: 9, color: textSecondaryColor, fontStyle: pw.FontStyle.italic),
            ),
            pw.Text(
              'Page $pageNum of $totalPages',
              style: pw.TextStyle(fontSize: 9, color: textSecondaryColor),
            ),
          ],
        ),
      ],
    );
  }

  // Custom Table cells with range colors
  static pw.Widget _tableHeaderCell(String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableTextCell(String text, {PdfColor? color, pw.FontWeight? fontWeight, int maxLines = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? textPrimaryColor,
          fontWeight: fontWeight ?? pw.FontWeight.normal,
        ),
        maxLines: maxLines,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Status mapping cells
  static pw.Widget _bpTableCell(double? sys, double? dia) {
    if (sys == null || dia == null) return _tableTextCell('--');
    PdfColor color = successColor;
    if (sys < 90 || sys >= 140) {
      color = errorColor;
    } else if (sys >= 120 && sys <= 139) {
      color = warningColor;
    }
    return _tableTextCell('${sys.toInt()}/${dia.toInt()}', color: color, fontWeight: pw.FontWeight.bold);
  }

  static pw.Widget _sugarTableCell(double? val) {
    if (val == null) return _tableTextCell('--');
    PdfColor color = successColor;
    if (val < 70 || val >= 126) {
      color = errorColor;
    } else if (val >= 100 && val <= 125) {
      color = warningColor;
    }
    return _tableTextCell('${val.toInt()}', color: color, fontWeight: pw.FontWeight.bold);
  }

  static pw.Widget _tempTableCell(double? val) {
    if (val == null) return _tableTextCell('--');
    PdfColor color = successColor;
    if (val > 38.0) {
      color = errorColor;
    } else if (val < 36.0 || (val >= 37.3 && val <= 38.0)) {
      color = warningColor;
    }
    return _tableTextCell(val.toStringAsFixed(1), color: color, fontWeight: pw.FontWeight.bold);
  }

  static pw.Widget _spo2TableCell(double? val) {
    if (val == null) return _tableTextCell('--');
    PdfColor color = successColor;
    if (val < 90) {
      color = errorColor;
    } else if (val >= 90 && val <= 94) {
      color = warningColor;
    }
    return _tableTextCell('${val.toInt()}%', color: color, fontWeight: pw.FontWeight.bold);
  }

  static pw.Widget _hrTableCell(double? val) {
    if (val == null) return _tableTextCell('--');
    PdfColor color = successColor;
    if (val > 140) {
      color = errorColor;
    } else if (val < 60 || (val > 100 && val <= 140)) {
      color = warningColor;
    }
    return _tableTextCell('${val.toInt()}', color: color, fontWeight: pw.FontWeight.bold);
  }
}
