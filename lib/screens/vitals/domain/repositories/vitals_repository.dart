import '../entities/blood_pressure_entity.dart';
import '../entities/blood_sugar_entity.dart';
import '../entities/temperature_entity.dart';
import '../entities/weight_entity.dart';
import '../entities/spo2_entity.dart';

/// Abstract repository contract for all Vitals operations.
abstract class VitalsRepository {
  // ==========================================
  // Blood Pressure
  // ==========================================
  Stream<List<BloodPressureEntity>> watchBloodPressure(String userId);
  Future<void> saveBloodPressure(String userId, BloodPressureEntity record);
  Future<void> deleteBloodPressure(String userId, String recordId);

  // ==========================================
  // Blood Sugar
  // ==========================================
  Stream<List<BloodSugarEntity>> watchBloodSugar(String userId);
  Future<void> saveBloodSugar(String userId, BloodSugarEntity record);
  Future<void> deleteBloodSugar(String userId, String recordId);

  // ==========================================
  // Temperature
  // ==========================================
  Stream<List<TemperatureEntity>> watchTemperature(String userId);
  Future<void> saveTemperature(String userId, TemperatureEntity record);
  Future<void> deleteTemperature(String userId, String recordId);

  // ==========================================
  // Weight
  // ==========================================
  Stream<List<WeightEntity>> watchWeight(String userId);
  Future<void> saveWeight(String userId, WeightEntity record);
  Future<void> deleteWeight(String userId, String recordId);

  // ==========================================
  // SpO2
  // ==========================================
  Stream<List<SpO2Entity>> watchSpO2(String userId);
  Future<void> saveSpO2(String userId, SpO2Entity record);
  Future<void> deleteSpO2(String userId, String recordId);

  // ==========================================
  // Synchronization
  // ==========================================
  /// Trigger manual synchronization of pending offline records to cloud.
  Future<void> syncPendingRecords(String userId);
}
