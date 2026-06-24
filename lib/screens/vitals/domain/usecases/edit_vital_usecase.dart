import '../entities/blood_pressure_entity.dart';
import '../entities/blood_sugar_entity.dart';
import '../entities/temperature_entity.dart';
import '../entities/weight_entity.dart';
import '../entities/spo2_entity.dart';
import '../repositories/vitals_repository.dart';

/// Use case to edit (update) vital records.
class EditVitalUseCase {
  final VitalsRepository _repository;

  const EditVitalUseCase(this._repository);

  /// Updates a Blood Pressure reading.
  Future<void> editBloodPressure(String userId, BloodPressureEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid blood pressure range.');
    }
    final updatedRecord = record.copyWith(updatedAt: DateTime.now());
    return _repository.saveBloodPressure(userId, updatedRecord);
  }

  /// Updates a Blood Sugar reading.
  Future<void> editBloodSugar(String userId, BloodSugarEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid blood sugar range.');
    }
    final updatedRecord = record.copyWith(updatedAt: DateTime.now());
    return _repository.saveBloodSugar(userId, updatedRecord);
  }

  /// Updates a Temperature reading.
  Future<void> editTemperature(String userId, TemperatureEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid temperature range.');
    }
    final updatedRecord = record.copyWith(updatedAt: DateTime.now());
    return _repository.saveTemperature(userId, updatedRecord);
  }

  /// Updates a Weight reading.
  Future<void> editWeight(String userId, WeightEntity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid weight range.');
    }
    final updatedRecord = record.copyWith(updatedAt: DateTime.now());
    return _repository.saveWeight(userId, updatedRecord);
  }

  /// Updates an SpO2 reading.
  Future<void> editSpO2(String userId, SpO2Entity record) {
    if (!record.isValid) {
      throw ArgumentError('Invalid SpO2 range.');
    }
    final updatedRecord = record.copyWith(updatedAt: DateTime.now());
    return _repository.saveSpO2(userId, updatedRecord);
  }
}
