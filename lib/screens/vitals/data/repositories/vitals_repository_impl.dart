import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/spo2_entity.dart';
import '../../domain/entities/vital_types.dart';
import '../../domain/repositories/vitals_repository.dart';
import '../datasources/vitals_local_data_source.dart';
import '../datasources/vitals_remote_data_source.dart';
import '../models/blood_pressure_model.dart';
import '../models/blood_sugar_model.dart';
import '../models/temperature_model.dart';
import '../models/weight_model.dart';
import '../models/spo2_model.dart';

/// Offline-first implementation of VitalsRepository.
class VitalsRepositoryImpl implements VitalsRepository {
  final VitalsRemoteDataSource _remoteDataSource;
  final VitalsLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();

  VitalsRepositoryImpl({
    required VitalsRemoteDataSource remoteDataSource,
    required VitalsLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  // =========================================================================
  // Blood Pressure
  // =========================================================================

  @override
  Stream<List<BloodPressureEntity>> watchBloodPressure(String userId) async* {
    // 1. Return local cache immediately
    final cached = await _localDataSource.getBloodPressure();
    yield cached;

    // 2. Trigger fetch from remote to update local cache in the background
    _fetchAndMergeBloodPressure(userId);

    // 3. Listen to local changes
    final box = _getHiveBox<BloodPressureModel>('vitals_bp_box');
    yield* box.watch().map((_) => box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  Future<void> _fetchAndMergeBloodPressure(String userId) async {
    try {
      final remote = await _remoteDataSource.fetchBloodPressure(userId);
      final local = await _localDataSource.getBloodPressure();

      for (final rModel in remote) {
        final lModel = local.firstWhere((l) => l.id == rModel.id, orElse: () => const BloodPressureModel(id: '', systolic: 0, diastolic: 0, timestamp: nullDate, createdAt: nullDate, updatedAt: nullDate));
        if (lModel.id.isEmpty) {
          await _localDataSource.saveBloodPressureLocal(rModel);
        } else {
          // Conflict resolution: latest updatedAt wins
          if (rModel.updatedAt.isAfter(lModel.updatedAt)) {
            await _localDataSource.saveBloodPressureLocal(rModel);
          }
        }
      }
    } catch (_) {
      // Ignore remote errors to keep UI offline-first
    }
  }

  @override
  Future<void> saveBloodPressure(String userId, BloodPressureEntity record) async {
    final model = BloodPressureModel.fromEntity(record);
    // 1. Save locally first
    await _localDataSource.saveBloodPressureLocal(model);

    // 2. Sync to cloud
    try {
      await _remoteDataSource.saveBloodPressure(userId, model);
    } catch (_) {
      // 3. Queue offline sync
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'save',
        vitalType: 'blood_pressure',
        recordId: model.id,
        payload: model.toMap(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> deleteBloodPressure(String userId, String recordId) async {
    // 1. Delete locally first
    await _localDataSource.deleteBloodPressureLocal(recordId);

    // 2. Sync deletion to cloud
    try {
      await _remoteDataSource.deleteBloodPressure(userId, recordId);
    } catch (_) {
      // 3. Queue offline deletion
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'delete',
        vitalType: 'blood_pressure',
        recordId: recordId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  // =========================================================================
  // Blood Sugar
  // =========================================================================

  @override
  Stream<List<BloodSugarEntity>> watchBloodSugar(String userId) async* {
    final cached = await _localDataSource.getBloodSugar();
    yield cached;

    _fetchAndMergeBloodSugar(userId);

    final box = _getHiveBox<BloodSugarModel>('vitals_sugar_box');
    yield* box.watch().map((_) => box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  Future<void> _fetchAndMergeBloodSugar(String userId) async {
    try {
      final remote = await _remoteDataSource.fetchBloodSugar(userId);
      final local = await _localDataSource.getBloodSugar();

      for (final rModel in remote) {
        final lModel = local.firstWhere((l) => l.id == rModel.id, orElse: () => const BloodSugarModel(id: '', value: 0, readingType: BloodSugarReadingType.random, timestamp: nullDate, createdAt: nullDate, updatedAt: nullDate));
        if (lModel.id.isEmpty) {
          await _localDataSource.saveBloodSugarLocal(rModel);
        } else {
          if (rModel.updatedAt.isAfter(lModel.updatedAt)) {
            await _localDataSource.saveBloodSugarLocal(rModel);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> saveBloodSugar(String userId, BloodSugarEntity record) async {
    final model = BloodSugarModel.fromEntity(record);
    await _localDataSource.saveBloodSugarLocal(model);

    try {
      await _remoteDataSource.saveBloodSugar(userId, model);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'save',
        vitalType: 'blood_sugar',
        recordId: model.id,
        payload: model.toMap(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> deleteBloodSugar(String userId, String recordId) async {
    await _localDataSource.deleteBloodSugarLocal(recordId);

    try {
      await _remoteDataSource.deleteBloodSugar(userId, recordId);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'delete',
        vitalType: 'blood_sugar',
        recordId: recordId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  // =========================================================================
  // Temperature
  // =========================================================================

  @override
  Stream<List<TemperatureEntity>> watchTemperature(String userId) async* {
    final cached = await _localDataSource.getTemperature();
    yield cached;

    _fetchAndMergeTemperature(userId);

    final box = _getHiveBox<TemperatureModel>('vitals_temp_box');
    yield* box.watch().map((_) => box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  Future<void> _fetchAndMergeTemperature(String userId) async {
    try {
      final remote = await _remoteDataSource.fetchTemperature(userId);
      final local = await _localDataSource.getTemperature();

      for (final rModel in remote) {
        final lModel = local.firstWhere((l) => l.id == rModel.id, orElse: () => const TemperatureModel(id: '', value: 0, unit: TemperatureUnit.celsius, timestamp: nullDate, createdAt: nullDate, updatedAt: nullDate));
        if (lModel.id.isEmpty) {
          await _localDataSource.saveTemperatureLocal(rModel);
        } else {
          if (rModel.updatedAt.isAfter(lModel.updatedAt)) {
            await _localDataSource.saveTemperatureLocal(rModel);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> saveTemperature(String userId, TemperatureEntity record) async {
    final model = TemperatureModel.fromEntity(record);
    await _localDataSource.saveTemperatureLocal(model);

    try {
      await _remoteDataSource.saveTemperature(userId, model);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'save',
        vitalType: 'temperature',
        recordId: model.id,
        payload: model.toMap(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> deleteTemperature(String userId, String recordId) async {
    await _localDataSource.deleteTemperatureLocal(recordId);

    try {
      await _remoteDataSource.deleteTemperature(userId, recordId);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'delete',
        vitalType: 'temperature',
        recordId: recordId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  // =========================================================================
  // Weight
  // =========================================================================

  @override
  Stream<List<WeightEntity>> watchWeight(String userId) async* {
    final cached = await _localDataSource.getWeight();
    yield cached;

    _fetchAndMergeWeight(userId);

    final box = _getHiveBox<WeightModel>('vitals_weight_box');
    yield* box.watch().map((_) => box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  Future<void> _fetchAndMergeWeight(String userId) async {
    try {
      final remote = await _remoteDataSource.fetchWeight(userId);
      final local = await _localDataSource.getWeight();

      for (final rModel in remote) {
        final lModel = local.firstWhere((l) => l.id == rModel.id, orElse: () => const WeightModel(id: '', value: 0, unit: WeightUnit.kg, timestamp: nullDate, createdAt: nullDate, updatedAt: nullDate));
        if (lModel.id.isEmpty) {
          await _localDataSource.saveWeightLocal(rModel);
        } else {
          if (rModel.updatedAt.isAfter(lModel.updatedAt)) {
            await _localDataSource.saveWeightLocal(rModel);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> saveWeight(String userId, WeightEntity record) async {
    final model = WeightModel.fromEntity(record);
    await _localDataSource.saveWeightLocal(model);

    try {
      await _remoteDataSource.saveWeight(userId, model);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'save',
        vitalType: 'weight',
        recordId: model.id,
        payload: model.toMap(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> deleteWeight(String userId, String recordId) async {
    await _localDataSource.deleteWeightLocal(recordId);

    try {
      await _remoteDataSource.deleteWeight(userId, recordId);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'delete',
        vitalType: 'weight',
        recordId: recordId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  // =========================================================================
  // SpO2
  // =========================================================================

  @override
  Stream<List<SpO2Entity>> watchSpO2(String userId) async* {
    final cached = await _localDataSource.getSpO2();
    yield cached;

    _fetchAndMergeSpO2(userId);

    final box = _getHiveBox<SpO2Model>('vitals_spo2_box');
    yield* box.watch().map((_) => box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  Future<void> _fetchAndMergeSpO2(String userId) async {
    try {
      final remote = await _remoteDataSource.fetchSpO2(userId);
      final local = await _localDataSource.getSpO2();

      for (final rModel in remote) {
        final lModel = local.firstWhere((l) => l.id == rModel.id, orElse: () => const SpO2Model(id: '', percentage: 0, timestamp: nullDate, createdAt: nullDate, updatedAt: nullDate));
        if (lModel.id.isEmpty) {
          await _localDataSource.saveSpO2Local(rModel);
        } else {
          if (rModel.updatedAt.isAfter(lModel.updatedAt)) {
            await _localDataSource.saveSpO2Local(rModel);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> saveSpO2(String userId, SpO2Entity record) async {
    final model = SpO2Model.fromEntity(record);
    await _localDataSource.saveSpO2Local(model);

    try {
      await _remoteDataSource.saveSpO2(userId, model);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'save',
        vitalType: 'spo2',
        recordId: model.id,
        payload: model.toMap(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> deleteSpO2(String userId, String recordId) async {
    await _localDataSource.deleteSpO2Local(recordId);

    try {
      await _remoteDataSource.deleteSpO2(userId, recordId);
    } catch (_) {
      await _localDataSource.addToSyncQueue(SyncQueueItem(
        id: _uuid.v4(),
        action: 'delete',
        vitalType: 'spo2',
        recordId: recordId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  // =========================================================================
  // Synchronization Queue Logic (Conflict Resolution)
  // =========================================================================

  @override
  Future<void> syncPendingRecords(String userId) async {
    final queue = await _localDataSource.getSyncQueue();
    if (queue.isEmpty) return;

    for (final item in queue) {
      try {
        if (item.action == 'save') {
          final payload = item.payload;
          if (payload == null) {
            await _localDataSource.removeFromSyncQueue(item.id);
            continue;
          }

          // Conflict resolution: query remote first before writing
          final isConflictResolved = await _resolveSyncConflict(userId, item);
          if (isConflictResolved) {
            // Either updated remote or pulled remote to local
            await _localDataSource.removeFromSyncQueue(item.id);
          }
        } else if (item.action == 'delete') {
          // Sync deletion
          await _deleteRemoteRecordDirect(userId, item.vitalType, item.recordId);
          await _localDataSource.removeFromSyncQueue(item.id);
        }
      } catch (_) {
        // Failed syncing a specific item, stop execution to preserve queue ordering
        break;
      }
    }
  }

  /// Resolve conflict: compares local updatedAt with remote updatedAt.
  /// Returns true if resolved successfully and safe to remove from queue.
  Future<bool> _resolveSyncConflict(String userId, SyncQueueItem item) async {
    final localUpdatedAtMs = item.payload?['updatedAt'] != null 
        ? (item.payload!['updatedAt'] is int 
            ? item.payload!['updatedAt'] as int 
            : 0) 
        : 0;
    
    // In real app, we check Firestore document's updatedAt:
    // If remote has newer update, we fetch it, overwrite our Hive local cache, and skip sending local update.
    // If local has newer update, we write it to remote.
    // Let's implement this logic:
    final remoteMap = await _fetchRemoteRecordDirect(userId, item.vitalType, item.recordId);
    if (remoteMap != null) {
      final remoteUpdatedAt = remoteMap['updatedAt'];
      DateTime rDate = DateTime.now();
      if (remoteUpdatedAt is Timestamp) {
        rDate = remoteUpdatedAt.toDate();
      } else if (remoteUpdatedAt is String) {
        rDate = DateTime.parse(remoteUpdatedAt);
      }

      final lDate = DateTime.fromMillisecondsSinceEpoch(localUpdatedAtMs);

      if (rDate.isAfter(lDate)) {
        // Remote is newer, pull to local cache
        await _saveRemoteRecordToLocalCache(item.vitalType, remoteMap);
        return true;
      }
    }

    // Remote does not exist, or local is newer: upload local payload to remote
    await _saveLocalPayloadToRemote(userId, item.vitalType, item.recordId, item.payload!);
    return true;
  }

  // Direct fetch helpers for synchronization
  Future<Map<String, dynamic>?> _fetchRemoteRecordDirect(String userId, String vitalType, String recordId) async {
    try {
      final path = _remoteDataSource as VitalsFirestoreDataSource; // cast to access inner firestore if needed, or implement generic API
      final doc = await path._vitalsCollection(userId, vitalType).doc(recordId).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocalPayloadToRemote(String userId, String vitalType, String recordId, Map<String, dynamic> payload) async {
    final firestoreDS = _remoteDataSource as VitalsFirestoreDataSource;
    await firestoreDS._vitalsCollection(userId, vitalType).doc(recordId).set(payload);
  }

  Future<void> _deleteRemoteRecordDirect(String userId, String vitalType, String recordId) async {
    final firestoreDS = _remoteDataSource as VitalsFirestoreDataSource;
    await firestoreDS._vitalsCollection(userId, vitalType).doc(recordId).delete();
  }

  Future<void> _saveRemoteRecordToLocalCache(String vitalType, Map<String, dynamic> data) async {
    switch (vitalType) {
      case 'blood_pressure':
        await _localDataSource.saveBloodPressureLocal(BloodPressureModel.fromMap(data));
        break;
      case 'blood_sugar':
        await _localDataSource.saveBloodSugarLocal(BloodSugarModel.fromMap(data));
        break;
      case 'temperature':
        await _localDataSource.saveTemperatureLocal(TemperatureModel.fromMap(data));
        break;
      case 'weight':
        await _localDataSource.saveWeightLocal(WeightModel.fromMap(data));
        break;
      case 'spo2':
        await _localDataSource.saveSpO2Local(SpO2Model.fromMap(data));
        break;
    }
  }

  // Box helper
  Box<T> _getHiveBox<T>(String boxName) {
    return Hive.box<T>(boxName);
  }
}

const DateTime nullDate = DateTime(1970);
