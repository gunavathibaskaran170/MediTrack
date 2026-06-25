import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/database_helper.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class DoctorVisitsProvider with ChangeNotifier {
  List<DoctorVisit> _visits = [];
  List<Prescription> _prescriptions = [];
  bool _isLoading = false;

  List<DoctorVisit> get visits => _visits;
  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;

  // Upcoming follow-ups (today or future)
  List<DoctorVisit> get upcomingFollowups {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final today = DateTime.parse(todayStr);

    final followups = _visits.where((v) {
      if (v.followUpDate == null || v.followUpDate!.isEmpty) return false;
      try {
        final fDate = DateTime.parse(v.followUpDate!);
        return fDate.isAfter(today) || fDate.isAtSameMomentAs(today);
      } catch (_) {
        return false;
      }
    }).toList();

    // Sort by nearest follow-up date
    followups.sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));
    return followups;
  }

  // Overdue follow-ups (past)
  List<DoctorVisit> get overdueFollowups {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final today = DateTime.parse(todayStr);

    final followups = _visits.where((v) {
      if (v.followUpDate == null || v.followUpDate!.isEmpty) return false;
      try {
        final fDate = DateTime.parse(v.followUpDate!);
        return fDate.isBefore(today);
      } catch (_) {
        return false;
      }
    }).toList();

    // Sort by oldest overdue first
    followups.sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));
    return followups;
  }

  // Group visits by doctor for Diagnoses tab
  Map<String, List<DoctorVisit>> get visitsByDoctor {
    final Map<String, List<DoctorVisit>> map = {};
    for (var v in _visits) {
      final docName = v.doctorName.trim();
      if (!map.containsKey(docName)) {
        map[docName] = [];
      }
      map[docName]!.add(v);
    }
    return map;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _visits = await DatabaseHelper.instance.getDoctorVisits();
      _prescriptions = await DatabaseHelper.instance.getPrescriptions();
    } catch (e) {
      debugPrint("Error loading doctor visits: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVisit(DoctorVisit visit) async {
    try {
      final id = await DatabaseHelper.instance.insertDoctorVisit(visit);
      if (visit.followUpDate != null && visit.followUpDate!.isNotEmpty) {
        await NotificationService().scheduleAppointmentReminder(
          visitId: id,
          doctorName: visit.doctorName,
          hospital: visit.hospital,
          followUpDateStr: visit.followUpDate!,
        );
      }
      await loadAll();
    } catch (e) {
      debugPrint("Error adding doctor visit: $e");
    }
  }

  Future<void> updateVisit(DoctorVisit visit) async {
    try {
      await DatabaseHelper.instance.updateDoctorVisit(visit);
      
      // Cancel previous notification and reschedule if follow up date is set
      if (visit.id != null) {
        await NotificationService().cancelAppointmentReminder(visit.id!);
        if (visit.followUpDate != null && visit.followUpDate!.isNotEmpty) {
          await NotificationService().scheduleAppointmentReminder(
            visitId: visit.id!,
            doctorName: visit.doctorName,
            hospital: visit.hospital,
            followUpDateStr: visit.followUpDate!,
          );
        }
      }
      await loadAll();
    } catch (e) {
      debugPrint("Error updating doctor visit: $e");
    }
  }

  Future<void> deleteVisit(int id) async {
    try {
      await DatabaseHelper.instance.deleteDoctorVisit(id);
      await NotificationService().cancelAppointmentReminder(id);
      await loadAll();
    } catch (e) {
      debugPrint("Error deleting doctor visit: $e");
    }
  }

  Future<void> markFollowupDone(int visitId) async {
    try {
      final index = _visits.indexWhere((v) => v.id == visitId);
      if (index != -1) {
        final original = _visits[index];
        final updated = DoctorVisit(
          id: original.id,
          userId: original.userId,
          doctorName: original.doctorName,
          hospital: original.hospital,
          visitDate: original.visitDate,
          diagnosis: original.diagnosis,
          notes: original.notes,
          followUpDate: null, // Clear follow-up date to mark as done
          prescriptionId: original.prescriptionId,
        );
        await updateVisit(updated);
      }
    } catch (e) {
      debugPrint("Error marking follow-up done: $e");
    }
  }
}
