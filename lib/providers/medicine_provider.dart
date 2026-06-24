import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import '../core/database_helper.dart';
import '../services/notification_service.dart';

class MedicineProvider with ChangeNotifier {
  List<Medicine> _medicines = [];
  List<Medicine> _todayMedicines = [];
  List<MedicationLog> _todayLogs = [];
  double _weeklyAdherence = 0.0;
  int _takenThisWeek = 0;
  int _missedThisWeek = 0;
  bool _isLoading = false;

  List<Medicine> get medicines => _medicines;
  List<Medicine> get todayMedicines => _todayMedicines;
  List<MedicationLog> get todayLogs => _todayLogs;
  double get weeklyAdherence => _weeklyAdherence;
  int get takenThisWeek => _takenThisWeek;
  int get missedThisWeek => _missedThisWeek;
  bool get isLoading => _isLoading;

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();

    try {
      _medicines = await DatabaseHelper.instance.getMedicines();
      await loadTodayMedicines();
      await loadTodayLogs();
      await loadWeeklyAdherence();
    } catch (e) {
      debugPrint("Error loading medicines: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayMedicines() async {
    // Today medicines are active medicines
    _todayMedicines = _medicines.where((m) => m.isActive).toList();
  }

  Future<void> loadTodayLogs() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'medication_logs',
      where: 'date = ?',
      whereArgs: [todayStr],
    );
    _todayLogs = maps.map((m) => MedicationLog.fromMap(m)).toList();
  }

  Future<void> addMedicine(Medicine m) async {
    try {
      final id = await DatabaseHelper.instance.insertMedicine(m);
      final newMed = Medicine(
        id: id,
        userId: m.userId,
        name: m.name,
        dosage: m.dosage,
        unit: m.unit,
        frequency: m.frequency,
        reminderTimes: m.reminderTimes,
        startDate: m.startDate,
        endDate: m.endDate,
        isActive: m.isActive,
        createdAt: m.createdAt,
      );

      // Schedule reminders
      for (var time in newMed.reminderTimes) {
        await NotificationService().scheduleMedicineReminder(
          medicineId: id,
          medicineName: newMed.name,
          dosage: newMed.dosage ?? 0.0,
          unit: newMed.unit ?? '',
          timeStr: time,
        );
      }

      await loadMedicines();
    } catch (e) {
      debugPrint("Error adding medicine: $e");
    }
  }

  Future<void> updateMedicine(Medicine m) async {
    try {
      await DatabaseHelper.instance.updateMedicine(m);
      if (m.id != null) {
        // Cancel old notifications first
        await NotificationService().cancelMedicineReminders(m.id!);
        // Re-schedule if active
        if (m.isActive) {
          for (var time in m.reminderTimes) {
            await NotificationService().scheduleMedicineReminder(
              medicineId: m.id!,
              medicineName: m.name,
              dosage: m.dosage ?? 0.0,
              unit: m.unit ?? '',
              timeStr: time,
            );
          }
        }
      }
      await loadMedicines();
    } catch (e) {
      debugPrint("Error updating medicine: $e");
    }
  }

  Future<void> deleteMedicine(int id) async {
    try {
      await DatabaseHelper.instance.deleteMedicine(id);
      await NotificationService().cancelMedicineReminders(id);
      await loadMedicines();
    } catch (e) {
      debugPrint("Error deleting medicine: $e");
    }
  }

  Future<void> toggleActive(int id, bool active) async {
    try {
      await DatabaseHelper.instance.toggleMedicineActive(id, active ? 1 : 0);
      if (active) {
        // Reschedule
        final med = _medicines.firstWhere((m) => m.id == id);
        for (var time in med.reminderTimes) {
          await NotificationService().scheduleMedicineReminder(
            medicineId: id,
            medicineName: med.name,
            dosage: med.dosage ?? 0.0,
            unit: med.unit ?? '',
            timeStr: time,
          );
        }
      } else {
        // Cancel
        await NotificationService().cancelMedicineReminders(id);
      }
      await loadMedicines();
    } catch (e) {
      debugPrint("Error toggling medicine active: $e");
    }
  }

  // --- LOG DOSE ---
  Future<void> logDose(int medicineId, String time, String status) async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final log = MedicationLog(
        medicineId: medicineId,
        userId: 1,
        date: todayStr,
        scheduledTime: time,
        actualTime: status == 'taken' ? DateFormat('HH:mm').format(DateTime.now()) : null,
        status: status,
      );
      await DatabaseHelper.instance.insertMedicationLog(log);

      // Handle Snooze action specifically
      if (status == 'snoozed') {
        final med = _medicines.firstWhere((m) => m.id == medicineId);
        await NotificationService().scheduleSnoozeReminder(
          medicineId: medicineId,
          medicineName: med.name,
          dosage: med.dosage ?? 0,
          unit: med.unit ?? '',
        );
      }

      await loadTodayLogs();
      await loadWeeklyAdherence();
    } catch (e) {
      debugPrint("Error logging dose: $e");
    }
  }

  // --- COMPUTE COMPLIANCE / ADHERENCE ---
  Future<void> loadWeeklyAdherence() async {
    try {
      final now = DateTime.now();
      // Monday of current calendar week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final dateFormat = DateFormat('yyyy-MM-dd');
      final mondayStr = dateFormat.format(monday);

      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'medication_logs',
        where: 'date >= ?',
        whereArgs: [mondayStr],
      );

      final weekLogs = maps.map((m) => MedicationLog.fromMap(m)).toList();
      final totalCount = weekLogs.length;
      final takenCount = weekLogs.where((l) => l.status == 'taken').length;

      _takenThisWeek = weekLogs.where((l) => l.status == 'taken').length;
      _missedThisWeek = weekLogs.where((l) => l.status == 'missed' || l.status == 'skipped').length;

      if (totalCount > 0) {
        _weeklyAdherence = takenCount / totalCount;
      } else {
        _weeklyAdherence = 0.0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error calculating adherence: $e");
    }
  }
}
