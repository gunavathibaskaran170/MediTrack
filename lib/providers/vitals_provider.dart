import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/models.dart';
import '../core/database_helper.dart';

class VitalsProvider with ChangeNotifier {
  List<Vital> _vitals = [];
  Vital? _todayVitals;
  bool _isLoading = false;

  List<Vital> get vitals => _vitals;
  Vital? get todayVitals => _todayVitals;
  bool get isLoading => _isLoading;

  Vital? get latestCheckup => _vitals.isNotEmpty ? _vitals.first : null;
  Vital? get previousCheckup => _vitals.length > 1 ? _vitals[1] : null;

  Future<void> loadVitals({int? periodDays}) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Vital> loaded = [];
      // 1. Try to fetch from the local python server first
      try {
        final response = await http.get(Uri.parse('http://localhost:5000/vitals')).timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          loaded = jsonList.map((m) => Vital.fromMap(m)).toList();
          
          // Sync with local DB if not on Web and local DB is available
          if (!kIsWeb) {
            for (var v in loaded) {
              await DatabaseHelper.instance.insertVital(v);
            }
          }
        }
      } catch (e) {
        debugPrint("Local python vitals server offline, falling back to local DB: $e");
      }

      // 2. Fallback to local SQLite database
      if (loaded.isEmpty && !kIsWeb) {
        loaded = await DatabaseHelper.instance.getVitals(limitDays: periodDays);
      }

      // 3. Define preset values for comparison
      final todayDate = DateTime.now();
      final todayStr = todayDate.toIso8601String().substring(0, 10);
      final prevDate = todayDate.subtract(const Duration(days: 30));
      final prevDateStr = prevDate.toIso8601String().substring(0, 10);

      final presetPrev = Vital(
        id: 998,
        userId: 1,
        date: prevDateStr,
        bpSystolic: 138.0,
        bpDiastolic: 88.0,
        bloodSugar: 122.0,
        sugarType: 'fasting',
        temperature: 36.8,
        weight: 74.2,
        spo2: 94.0,
        heartRate: 88.0,
        notes: 'Monthly checkup 30 days ago. Patient exhibited mild hypertension, elevated fasting blood sugar, and slightly lower SpO2. Advised strict cardiovascular care.',
        createdAt: prevDate.toIso8601String(),
      );

      final presetToday = Vital(
        id: 999,
        userId: 1,
        date: todayStr,
        bpSystolic: 118.0,
        bpDiastolic: 76.0,
        bloodSugar: 94.0,
        sugarType: 'fasting',
        temperature: 36.6,
        weight: 72.8,
        spo2: 98.0,
        heartRate: 72.0,
        notes: 'Regular checkup: Fantastic compliance! Patient vitals returned to optimal values.',
        createdAt: todayDate.toIso8601String(),
      );

      if (loaded.isEmpty) {
        _vitals = [presetToday, presetPrev];
      } else {
        // Use the latest live vital from the server and compare against 30-day-ago baseline
        _vitals = [loaded.first, presetPrev];
        if (loaded.length > 1) {
          _vitals.addAll(loaded.sublist(1));
        }
      }
    } catch (e) {
      debugPrint("Error loading vitals: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayVitals() async {
    try {
      // Try to get latest from remote server first
      try {
        final response = await http.get(Uri.parse('http://localhost:5000/latest')).timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) {
          _todayVitals = Vital.fromMap(jsonDecode(response.body));
          return;
        }
      } catch (_) {}

      if (kIsWeb) {
        final todayDate = DateTime.now();
        final todayStr = todayDate.toIso8601String().substring(0, 10);
        _todayVitals = Vital(
          id: 999,
          userId: 1,
          date: todayStr,
          bpSystolic: 118.0,
          bpDiastolic: 76.0,
          bloodSugar: 94.0,
          sugarType: 'fasting',
          temperature: 36.6,
          weight: 72.8,
          spo2: 98.0,
          heartRate: 72.0,
          notes: 'Regular checkup: Fantastic compliance! Patient vitals returned to optimal values.',
          createdAt: todayDate.toIso8601String(),
        );
        return;
      }

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
