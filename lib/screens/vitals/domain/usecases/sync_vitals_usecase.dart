import '../repositories/vitals_repository.dart';

/// Use case to sync pending local cached records to Firestore.
class SyncVitalsUseCase {
  final VitalsRepository _repository;

  const SyncVitalsUseCase(this._repository);

  /// Synchronizes pending data.
  Future<void> execute(String userId) {
    return _repository.syncPendingRecords(userId);
  }
}
