import '../entities/blood_pressure_entity.dart';
import '../entities/blood_sugar_entity.dart';
import '../entities/temperature_entity.dart';
import '../entities/weight_entity.dart';
import '../entities/spo2_entity.dart';
import '../repositories/vitals_repository.dart';

/// Use case to watch (stream) vital records of different types.
class GetVitalsUseCase {
  final VitalsRepository _repository;

  const GetVitalsUseCase(this._repository);

  /// Streams blood pressure readings.
  Stream<List<BloodPressureEntity>> watchBloodPressure(String userId) {
    return _repository.watchBloodPressure(userId);
  }

  /// Streams blood sugar readings.
  Stream<List<BloodSugarEntity>> watchBloodSugar(String userId) {
    return _repository.watchBloodSugar(userId);
  }

  /// Streams temperature readings.
  Stream<List<TemperatureEntity>> watchTemperature(String userId) {
    return _repository.watchTemperature(userId);
  }

  /// Streams weight readings.
  Stream<List<WeightEntity>> watchWeight(String userId) {
    return _repository.watchWeight(userId);
  }

  /// Streams SpO2 readings.
  Stream<List<SpO2Entity>> watchSpO2(String userId) {
    return _repository.watchSpO2(userId);
  }
}
