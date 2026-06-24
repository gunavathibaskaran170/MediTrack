import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../core/database_helper.dart';

class AnalyticsProvider with ChangeNotifier {
  String _selectedPeriod = '7days'; // '7days', '30days', '3months'
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = false;

  String get selectedPeriod => _selectedPeriod;
  Map<String, dynamic> get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;

  void setPeriod(String period) {
    _selectedPeriod = period;
    loadAnalytics();
  }

  int _getPeriodDays() {
    switch (_selectedPeriod) {
      case '30days':
        return 30;
      case '3months':
        return 90;
      default:
        return 7;
    }
  }

  Future<void> loadAnalytics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final days = _getPeriodDays();
      final db = await DatabaseHelper.instance.database;

      final dateFormat = DateFormat('yyyy-MM-dd');
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final cutoffStr = dateFormat.format(cutoffDate);

      // 1. Fetch Vitals in date range
      final vitalMaps = await db.query(
        'vitals',
        where: 'date >= ?',
        whereArgs: [cutoffStr],
        orderBy: 'date ASC',
      );
      final vitalsList = vitalMaps.map((m) => Vital.fromMap(m)).toList();

      // 2. Fetch Medication Logs in date range
      final logMaps = await db.query(
        'medication_logs',
        where: 'date >= ?',
        whereArgs: [cutoffStr],
      );
      final logsList = logMaps.map((m) => MedicationLog.fromMap(m)).toList();

      // 3. Fetch Symptoms in date range
      final symptomMaps = await db.query(
        'symptoms',
        where: 'date >= ?',
        whereArgs: [cutoffStr],
      );
      final symptomsList = symptomMaps.map((m) => Symptom.fromMap(m)).toList();

      // 4. PROCESS VITALS: BP and Blood Sugar datasets, averages
      final List<Map<String, dynamic>> bpData = [];
      final List<Map<String, dynamic>> sugarData = [];

      double sumHR = 0, sumSpO2 = 0, sumWeight = 0, sumTemp = 0;
      int countHR = 0, countSpO2 = 0, countWeight = 0, countTemp = 0;

      for (var v in vitalsList) {
        // BP Trend spots mapping
        if (v.bpSystolic != null && v.bpDiastolic != null) {
          bpData.add({
            'date': v.date,
            'systolic': v.bpSystolic!,
            'diastolic': v.bpDiastolic!,
          });
        }

        // Blood Sugar values mapping
        if (v.bloodSugar != null) {
          String category = 'Normal';
          if (v.bloodSugar! > 180) {
            category = 'Very High';
          } else if (v.bloodSugar! > 140) {
            category = 'High';
          }
          sugarData.add({
            'date': v.date,
            'value': v.bloodSugar!,
            'category': category,
          });
        }

        // Averages
        if (v.heartRate != null && v.heartRate! > 0) {
          sumHR += v.heartRate!;
          countHR++;
        }
        if (v.spo2 != null && v.spo2! > 0) {
          sumSpO2 += v.spo2!;
          countSpO2++;
        }
        if (v.weight != null && v.weight! > 0) {
          sumWeight += v.weight!;
          countWeight++;
        }
        if (v.temperature != null && v.temperature! > 0) {
          sumTemp += v.temperature!;
          countTemp++;
        }
      }

      // Key metric summaries
      final Map<String, dynamic> statSummaries = {
        'avg_hr': countHR > 0 ? (sumHR / countHR).roundToDouble() : 0.0,
        'avg_spo2': countSpO2 > 0 ? (sumSpO2 / countSpO2).roundToDouble() : 0.0,
        'avg_weight': countWeight > 0 ? double.parse((sumWeight / countWeight).toStringAsFixed(1)) : 0.0,
        'avg_temp': countTemp > 0 ? double.parse((sumTemp / countTemp).toStringAsFixed(1)) : 0.0,
      };

      // 5. PROCESS MEDICATION LOGS: Adherence PieChart counts
      int taken = 0, missed = 0, snoozed = 0, skipped = 0;
      for (var l in logsList) {
        if (l.status == 'taken') taken++;
        if (l.status == 'missed') missed++;
        if (l.status == 'snoozed') snoozed++;
        if (l.status == 'skipped') skipped++;
      }

      // 6. PROCESS SYMPTOMS: Symptom Frequency Map
      final Map<String, int> symptomFrequency = {};
      for (var s in symptomsList) {
        if (s.symptomName != null) {
          symptomFrequency[s.symptomName!] = (symptomFrequency[s.symptomName!] ?? 0) + 1;
        }
      }

      // Compile all processed analytics data
      _analyticsData = {
        'bpData': bpData,
        'sugarData': sugarData,
        'adherenceData': {
          'taken': taken,
          'missed': missed,
          'snoozed': snoozed + skipped, // Group skipped with snoozed for the chart legend
        },
        'symptomFrequency': symptomFrequency,
        'statSummaries': statSummaries,
      };
    } catch (e) {
      debugPrint("Error loading analytics: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
