import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/database_helper.dart';

class VitalsProvider with ChangeNotifier {
  List<Vital> _vitals = [];
  Vital? _todayVitals;
  bool _isLoading = false;

  List<Vital> get vitals => _vitals;
  Vital? get todayVitals => _todayVitals;
  bool get isLoading => _isLoading;

  Future<void> loadVitals({int? periodDays}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _vitals = await DatabaseHelper.instance.getVitals(limitDays: periodDays);
    } catch (e) {
      debugPrint("Error loading vitals: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayVitals() async {
    try {
      _todayVitals = await DatabaseHelper.instance.getTodayVitals();
    } catch (e) {
      debugPrint("Error loading today's vitals: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveVitals(Vital v) async {
    try {
      await DatabaseHelper.instance.insertVital(v);
      await loadTodayVitals();
      await loadVitals();
    } catch (e) {
      debugPrint("Error saving vitals: $e");
    }
  }

  Future<void> updateVitals(Vital v) async {
    try {
      await DatabaseHelper.instance.updateVital(v);
      await loadTodayVitals();
      await loadVitals();
    } catch (e) {
      debugPrint("Error updating vitals: $e");
    }
  }

  Future<void> deleteVitals(int id) async {
    try {
      await DatabaseHelper.instance.deleteVital(id);
      await loadTodayVitals();
      await loadVitals();
    } catch (e) {
      debugPrint("Error deleting vitals: $e");
    }
  }

  // --- STATS AVERAGES ---
  Map<String, double> getAverages(List<Vital> list) {
    if (list.isEmpty) return {};

    double sumSys = 0, sumDia = 0, sumSugar = 0, sumTemp = 0, sumWeight = 0, sumSpO2 = 0, sumHR = 0;
    int countSys = 0, countDia = 0, countSugar = 0, countTemp = 0, countWeight = 0, countSpO2 = 0, countHR = 0;

    for (var v in list) {
      if (v.bpSystolic != null) {
        sumSys += v.bpSystolic!;
        countSys++;
      }
      if (v.bpDiastolic != null) {
        sumDia += v.bpDiastolic!;
        countDia++;
      }
      if (v.bloodSugar != null) {
        sumSugar += v.bloodSugar!;
        countSugar++;
      }
      if (v.temperature != null) {
        sumTemp += v.temperature!;
        countTemp++;
      }
      if (v.weight != null) {
        sumWeight += v.weight!;
        countWeight++;
      }
      if (v.spo2 != null) {
        sumSpO2 += v.spo2!;
        countSpO2++;
      }
      if (v.heartRate != null) {
        sumHR += v.heartRate!;
        countHR++;
      }
    }

    return {
      'systolic': countSys > 0 ? sumSys / countSys : 0.0,
      'diastolic': countDia > 0 ? sumDia / countDia : 0.0,
      'blood_sugar': countSugar > 0 ? sumSugar / countSugar : 0.0,
      'temperature': countTemp > 0 ? sumTemp / countTemp : 0.0,
      'weight': countWeight > 0 ? sumWeight / countWeight : 0.0,
      'spo2': countSpO2 > 0 ? sumSpO2 / countSpO2 : 0.0,
      'heart_rate': countHR > 0 ? sumHR / countHR : 0.0,
    };
  }

  // --- TREND COMPUTATION ---
  /// Compares averages of last `period` days vs previous `period` days.
  /// Returns a Map of String directions: 'up', 'down', 'flat' per metric.
  Map<String, String> getTrend(List<Vital> list, int periodDays) {
    final now = DateTime.now();
    final cutoff1 = now.subtract(Duration(days: periodDays));
    final cutoff2 = now.subtract(Duration(days: periodDays * 2));

    final recentList = list.where((v) {
      final date = DateTime.tryParse(v.date) ?? now;
      return date.isAfter(cutoff1);
    }).toList();

    final baselineList = list.where((v) {
      final date = DateTime.tryParse(v.date) ?? now;
      return date.isAfter(cutoff2) && date.isBefore(cutoff1);
    }).toList();

    final recentAvgs = getAverages(recentList);
    final baselineAvgs = getAverages(baselineList);

    final Map<String, String> trends = {};
    final metrics = ['systolic', 'diastolic', 'blood_sugar', 'temperature', 'weight', 'spo2', 'heart_rate'];

    for (var m in metrics) {
      final rVal = recentAvgs[m] ?? 0.0;
      final bVal = baselineAvgs[m] ?? 0.0;

      if (rVal == 0.0 || bVal == 0.0) {
        trends[m] = 'flat';
      } else {
        final diff = rVal - bVal;
        // Threshold check for negligible variance
        double threshold = 0.1;
        if (m == 'systolic' || m == 'diastolic' || m == 'blood_sugar' || m == 'heart_rate') {
          threshold = 1.0;
        }

        if (diff.abs() < threshold) {
          trends[m] = 'flat';
        } else if (diff > 0) {
          trends[m] = 'up';
        } else {
          trends[m] = 'down';
        }
      }
    }
    return trends;
  }

  // --- VITALS STATUS COLOR LOGIC ---
  Color getBPSystolicColor(double sys, Color success, Color warning, Color error) {
    if (sys < 90) return error; // Low
    if (sys >= 90 && sys <= 119) return success; // Normal
    if (sys >= 120 && sys <= 139) return warning; // Elevated / Stage 1
    return error; // Stage 2
  }

  Color getBPDiastolicColor(double dia, Color success, Color warning, Color error) {
    if (dia < 60) return error; // Low
    if (dia >= 60 && dia <= 79) return success; // Normal
    if (dia >= 80 && dia <= 89) return warning; // Elevated / Stage 1
    return error; // Stage 2
  }

  Color getBloodSugarColor(double val, Color success, Color warning, Color error) {
    if (val < 70) return error; // Low
    if (val >= 70 && val <= 99) return success; // Normal
    if (val >= 100 && val <= 125) return warning; // Pre-diabetic
    return error; // Diabetic range
  }

  Color getSpO2Color(double val, Color success, Color warning, Color error) {
    if (val >= 95) return success;
    if (val >= 90) return warning;
    return error;
  }

  Color getHeartRateColor(double val, Color success, Color warning, Color error) {
    if (val < 60) return warning; // Bradycardia
    if (val >= 60 && val <= 100) return success;
    if (val > 100 && val <= 140) return warning; // Tachycardia
    return error; // High tachycardia
  }

  Color getTemperatureColor(double val, Color success, Color warning, Color error) {
    if (val < 36.0) return warning; // Low
    if (val >= 36.0 && val <= 37.2) return success;
    if (val >= 37.3 && val <= 38.0) return warning; // Low fever
    return error; // Fever
  }
}
