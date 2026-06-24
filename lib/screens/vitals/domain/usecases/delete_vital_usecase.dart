import '../entities/vital_types.dart';
import '../repositories/vitals_repository.dart';

/// Use case to delete vital records.
class DeleteVitalUseCase {
  final VitalsRepository _repository;

  const DeleteVitalUseCase(this._repository);

  /// Deletes a vital record based on its type and ID.
  Future<void> execute(String userId, VitalType type, String recordId) {
    return switch (type) {
      VitalType.bloodPressure => _repository.deleteBloodPressure(userId, recordId),
      VitalType.bloodSugar => _repository.deleteBloodSugar(userId, recordId),
      VitalType.temperature => _repository.deleteTemperature(userId, recordId),
      VitalType.weight => _repository.deleteWeight(userId, recordId),
      VitalType.spo2 => _repository.deleteSpO2(userId, recordId),
    };
  }
}
