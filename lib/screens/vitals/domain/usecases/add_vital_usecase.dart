import '../entities/blood_pressure_entity.dart';
import '../entities/blood_sugar_entity.dart';
import '../entities/temperature_entity.dart';
import '../entities/weight_entity.dart';
import '../entities/spo2_entity.dart';
import '../repositories/vitals_repository.dart';

/// Use case to add vital records of any type.
class AddVitalUseCase {
  final VitalsRepository _repository;

  const AddVitalUseCase(this._repository);

  /// Saves a Blood Pressure reading.
  Future<void> addBloodPressure(String userId, BloodPressureEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid blood pressure range.');
    }
    return _repository.saveBloodPressure(userId, record);
  }

  /// Saves a Blood Sugar reading.
  Future<void> addBloodSugar(String userId, BloodSugarEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid blood sugar range.');
    }
    return _repository.saveBloodSugar(userId, record);
  }

  /// Saves a Temperature reading.
  Future<void> addTemperature(String userId, TemperatureEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid temperature range.');
    }
    return _repository.saveTemperature(userId, record);
  }

  /// Saves a Weight reading.
  Future<void> addWeight(String userId, WeightEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid weight range.');
    }
    return _repository.saveWeight(userId, record);
  }

  /// Saves an SpO2 reading.
  Future<void> addSpO2(String userId, SpO2Entity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid SpO2 range.');
    }
    return _repository.saveSpO2(userId, record);
  }
}
