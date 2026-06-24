import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blood_pressure_model.dart';
import '../models/blood_sugar_model.dart';
import '../models/temperature_model.dart';
import '../models/weight_model.dart';
import '../models/spo2_model.dart';

/// Remote data source interface for Vitals.
abstract class VitalsRemoteDataSource {
  // Blood Pressure
  Stream<List<BloodPressureModel>> watchBloodPressure(String userId);
  Future<List<BloodPressureModel>> fetchBloodPressure(String userId);
  Future<void> saveBloodPressure(String userId, BloodPressureModel model);
  Future<void> deleteBloodPressure(String userId, String recordId);

  // Blood Sugar
  Stream<List<BloodSugarModel>> watchBloodSugar(String userId);
  Future<List<BloodSugarModel>> fetchBloodSugar(String userId);
  Future<void> saveBloodSugar(String userId, BloodSugarModel model);
  Future<void> deleteBloodSugar(String userId, String recordId);

  // Temperature
  Stream<List<TemperatureModel>> watchTemperature(String userId);
  Future<List<TemperatureModel>> fetchTemperature(String userId);
  Future<void> saveTemperature(String userId, TemperatureModel model);
  Future<void> deleteTemperature(String userId, String recordId);

  // Weight
  Stream<List<WeightModel>> watchWeight(String userId);
  Future<List<WeightModel>> fetchWeight(String userId);
  Future<void> saveWeight(String userId, WeightModel model);
  Future<void> deleteWeight(String userId, String recordId);

  // SpO2
  Stream<List<SpO2Model>> watchSpO2(String userId);
  Future<List<SpO2Model>> fetchSpO2(String userId);
  Future<void> saveSpO2(String userId, SpO2Model model);
  Future<void> deleteSpO2(String userId, String recordId);
}

/// Firebase Firestore implementation of VitalsRemoteDataSource.
class VitalsFirestoreDataSource implements VitalsRemoteDataSource {
  final FirebaseFirestore _firestore;

  VitalsFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper to get subcollection for a given user and vital type.
  CollectionReference<Map<String, dynamic>> _vitalsCollection(String userId, String vitalType) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vitals')
        .doc(vitalType)
        .collection('records');
  }

  // =========================================================================
  // Blood Pressure
  // =========================================================================

  @override
  Stream<List<BloodPressureModel>> watchBloodPressure(String userId) {
    return _vitalsCollection(userId, 'blood_pressure')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => BloodPressureModel.fromMap(doc.data())).toList());
  }

  @override
  Future<List<BloodPressureModel>> fetchBloodPressure(String userId) async {
    final snapshot = await _vitalsCollection(userId, 'blood_pressure')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => BloodPressureModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> saveBloodPressure(String userId, BloodPressureModel model) async {
    await _vitalsCollection(userId, 'blood_pressure').doc(model.id).set(model.toMap());
  }

  @override
  Future<void> deleteBloodPressure(String userId, String recordId) async {
    await _vitalsCollection(userId, 'blood_pressure').doc(recordId).delete();
  }

  // =========================================================================
  // Blood Sugar
  // =========================================================================

  @override
  Stream<List<BloodSugarModel>> watchBloodSugar(String userId) {
    return _vitalsCollection(userId, 'blood_sugar')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => BloodSugarModel.fromMap(doc.data())).toList());
  }

  @override
  Future<List<BloodSugarModel>> fetchBloodSugar(String userId) async {
    final snapshot = await _vitalsCollection(userId, 'blood_sugar')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => BloodSugarModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> saveBloodSugar(String userId, BloodSugarModel model) async {
    await _vitalsCollection(userId, 'blood_sugar').doc(model.id).set(model.toMap());
  }

  @override
  Future<void> deleteBloodSugar(String userId, String recordId) async {
    await _vitalsCollection(userId, 'blood_sugar').doc(recordId).delete();
  }

  // =========================================================================
  // Temperature
  // =========================================================================

  @override
  Stream<List<TemperatureModel>> watchTemperature(String userId) {
    return _vitalsCollection(userId, 'temperature')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TemperatureModel.fromMap(doc.data())).toList());
  }

  @override
  Future<List<TemperatureModel>> fetchTemperature(String userId) async {
    final snapshot = await _vitalsCollection(userId, 'temperature')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => TemperatureModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> saveTemperature(String userId, TemperatureModel model) async {
    await _vitalsCollection(userId, 'temperature').doc(model.id).set(model.toMap());
  }

  @override
  Future<void> deleteTemperature(String userId, String recordId) async {
    await _vitalsCollection(userId, 'temperature').doc(recordId).delete();
  }

  // =========================================================================
  // Weight
  // =========================================================================

  @override
  Stream<List<WeightModel>> watchWeight(String userId) {
    return _vitalsCollection(userId, 'weight')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => WeightModel.fromMap(doc.data())).toList());
  }

  @override
  Future<List<WeightModel>> fetchWeight(String userId) async {
    final snapshot = await _vitalsCollection(userId, 'weight')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => WeightModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> saveWeight(String userId, WeightModel model) async {
    await _vitalsCollection(userId, 'weight').doc(model.id).set(model.toMap());
  }

  @override
  Future<void> deleteWeight(String userId, String recordId) async {
    await _vitalsCollection(userId, 'weight').doc(recordId).delete();
  }

  // =========================================================================
  // SpO2
  // =========================================================================

  @override
  Stream<List<SpO2Model>> watchSpO2(String userId) {
    return _vitalsCollection(userId, 'spo2')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => SpO2Model.fromMap(doc.data())).toList());
  }

  @override
  Future<List<SpO2Model>> fetchSpO2(String userId) async {
    final snapshot = await _vitalsCollection(userId, 'spo2')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => SpO2Model.fromMap(doc.data())).toList();
  }

  @override
  Future<void> saveSpO2(String userId, SpO2Model model) async {
    await _vitalsCollection(userId, 'spo2').doc(model.id).set(model.toMap());
  }

  @override
  Future<void> deleteSpO2(String userId, String recordId) async {
    await _vitalsCollection(userId, 'spo2').doc(recordId).delete();
  }
}
