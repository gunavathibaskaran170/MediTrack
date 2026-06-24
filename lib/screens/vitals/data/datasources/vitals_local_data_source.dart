import 'package:hive/hive.dart';
import '../models/blood_pressure_model.dart';
import '../models/blood_sugar_model.dart';
import '../models/temperature_model.dart';
import '../models/weight_model.dart';
import '../models/spo2_model.dart';

/// Structure for storing pending sync operations.
class SyncQueueItem {
  final String id;
  final String action; // 'save' | 'delete'
  final String vitalType; // 'blood_pressure', 'blood_sugar', etc.
  final String recordId;
  final Map<String, dynamic>? payload;
  final int timestamp;

  const SyncQueueItem({
    required this.id,
    required this.action,
    required this.vitalType,
    required this.recordId,
    this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'vitalType': vitalType,
      'recordId': recordId,
      'payload': payload,
      'timestamp': timestamp,
    };
  }

  factory SyncQueueItem.fromMap(Map<dynamic, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      action: map['action'] as String,
      vitalType: map['vitalType'] as String,
      recordId: map['recordId'] as String,
      payload: map['payload'] != null ? Map<String, dynamic>.from(map['payload'] as Map) : null,
      timestamp: map['timestamp'] as int,
    );
  }
}

/// Local data source interface for Vitals caching and synchronization queue.
abstract class VitalsLocalDataSource {
  // Init
  Future<void> init();

  // Blood Pressure Cache
  Future<List<BloodPressureModel>> getBloodPressure();
  Future<void> cacheBloodPressure(List<BloodPressureModel> records);
  Future<void> saveBloodPressureLocal(BloodPressureModel model);
  Future<void> deleteBloodPressureLocal(String id);

  // Blood Sugar Cache
  Future<List<BloodSugarModel>> getBloodSugar();
  Future<void> cacheBloodSugar(List<BloodSugarModel> records);
  Future<void> saveBloodSugarLocal(BloodSugarModel model);
  Future<void> deleteBloodSugarLocal(String id);

  // Temperature Cache
  Future<List<TemperatureModel>> getTemperature();
  Future<void> cacheTemperature(List<TemperatureModel> records);
  Future<void> saveTemperatureLocal(TemperatureModel model);
  Future<void> deleteTemperatureLocal(String id);

  // Weight Cache
  Future<List<WeightModel>> getWeight();
  Future<void> cacheWeight(List<WeightModel> records);
  Future<void> saveWeightLocal(WeightModel model);
  Future<void> deleteWeightLocal(String id);

  // SpO2 Cache
  Future<List<SpO2Model>> getSpO2();
  Future<void> cacheSpO2(List<SpO2Model> records);
  Future<void> saveSpO2Local(SpO2Model model);
  Future<void> deleteSpO2Local(String id);

  // Sync Queue
  Future<void> addToSyncQueue(SyncQueueItem item);
  Future<List<SyncQueueItem>> getSyncQueue();
  Future<void> removeFromSyncQueue(String id);
  Future<void> clearSyncQueue();
}

/// Hive implementation of VitalsLocalDataSource.
class VitalsHiveDataSource implements VitalsLocalDataSource {
  static const String _bpBoxName = 'vitals_bp_box';
  static const String _sugarBoxName = 'vitals_sugar_box';
  static const String _tempBoxName = 'vitals_temp_box';
  static const String _weightBoxName = 'vitals_weight_box';
  static const String _spo2BoxName = 'vitals_spo2_box';
  static const String _queueBoxName = 'vitals_sync_queue_box';

  @override
  Future<void> init() async {
    // Register adapters if they haven't been registered yet
    _registerAdapterSafe(BloodPressureModelAdapter());
    _registerAdapterSafe(BloodSugarModelAdapter());
    _registerAdapterSafe(TemperatureModelAdapter());
    _registerAdapterSafe(WeightModelAdapter());
    _registerAdapterSafe(SpO2ModelAdapter());

    // Open boxes
    await Hive.openBox<BloodPressureModel>(_bpBoxName);
    await Hive.openBox<BloodSugarModel>(_sugarBoxName);
    await Hive.openBox<TemperatureModel>(_tempBoxName);
    await Hive.openBox<WeightModel>(_weightBoxName);
    await Hive.openBox<SpO2Model>(_spo2BoxName);
    await Hive.openBox<Map>(_queueBoxName);
  }

  void _registerAdapterSafe<T>(TypeAdapter<T> adapter) {
    try {
      Hive.registerAdapter(adapter);
    } catch (_) {
      // Adapter already registered
    }
  }

  // =========================================================================
  // Blood Pressure
  // =========================================================================

  @override
  Future<List<BloodPressureModel>> getBloodPressure() async {
    final box = Hive.box<BloodPressureModel>(_bpBoxName);
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> cacheBloodPressure(List<BloodPressureModel> records) async {
    final box = Hive.box<BloodPressureModel>(_bpBoxName);
    await box.clear();
    for (final r in records) {
      await box.put(r.id, r);
    }
  }

  @override
  Future<void> saveBloodPressureLocal(BloodPressureModel model) async {
    final box = Hive.box<BloodPressureModel>(_bpBoxName);
    await box.put(model.id, model);
  }

  @override
  Future<void> deleteBloodPressureLocal(String id) async {
    final box = Hive.box<BloodPressureModel>(_bpBoxName);
    await box.delete(id);
  }

  // =========================================================================
  // Blood Sugar
  // =========================================================================

  @override
  Future<List<BloodSugarModel>> getBloodSugar() async {
    final box = Hive.box<BloodSugarModel>(_sugarBoxName);
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> cacheBloodSugar(List<BloodSugarModel> records) async {
    final box = Hive.box<BloodSugarModel>(_sugarBoxName);
    await box.clear();
    for (final r in records) {
      await box.put(r.id, r);
    }
  }

  @override
  Future<void> saveBloodSugarLocal(BloodSugarModel model) async {
    final box = Hive.box<BloodSugarModel>(_sugarBoxName);
    await box.put(model.id, model);
  }

  @override
  Future<void> deleteBloodSugarLocal(String id) async {
    final box = Hive.box<BloodSugarModel>(_sugarBoxName);
    await box.delete(id);
  }

  // =========================================================================
  // Temperature
  // =========================================================================

  @override
  Future<List<TemperatureModel>> getTemperature() async {
    final box = Hive.box<TemperatureModel>(_tempBoxName);
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> cacheTemperature(List<TemperatureModel> records) async {
    final box = Hive.box<TemperatureModel>(_tempBoxName);
    await box.clear();
    for (final r in records) {
      await box.put(r.id, r);
    }
  }

  @override
  Future<void> saveTemperatureLocal(TemperatureModel model) async {
    final box = Hive.box<TemperatureModel>(_tempBoxName);
    await box.put(model.id, model);
  }

  @override
  Future<void> deleteTemperatureLocal(String id) async {
    final box = Hive.box<TemperatureModel>(_tempBoxName);
    await box.delete(id);
  }

  // =========================================================================
  // Weight
  // =========================================================================

  @override
  Future<List<WeightModel>> getWeight() async {
    final box = Hive.box<WeightModel>(_weightBoxName);
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> cacheWeight(List<WeightModel> records) async {
    final box = Hive.box<WeightModel>(_weightBoxName);
    await box.clear();
    for (final r in records) {
      await box.put(r.id, r);
    }
  }

  @override
  Future<void> saveWeightLocal(WeightModel model) async {
    final box = Hive.box<WeightModel>(_weightBoxName);
    await box.put(model.id, model);
  }

  @override
  Future<void> deleteWeightLocal(String id) async {
    final box = Hive.box<WeightModel>(_weightBoxName);
    await box.delete(id);
  }

  // =========================================================================
  // SpO2
  // =========================================================================

  @override
  Future<List<SpO2Model>> getSpO2() async {
    final box = Hive.box<SpO2Model>(_spo2BoxName);
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> cacheSpO2(List<SpO2Model> records) async {
    final box = Hive.box<SpO2Model>(_spo2BoxName);
    await box.clear();
    for (final r in records) {
      await box.put(r.id, r);
    }
  }

  @override
  Future<void> saveSpO2Local(SpO2Model model) async {
    final box = Hive.box<SpO2Model>(_spo2BoxName);
    await box.put(model.id, model);
  }

  @override
  Future<void> deleteSpO2Local(String id) async {
    final box = Hive.box<SpO2Model>(_spo2BoxName);
    await box.delete(id);
  }

  // =========================================================================
  // Sync Queue
  // =========================================================================

  @override
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    final box = Hive.box<Map>(_queueBoxName);
    await box.put(item.id, item.toMap());
  }

  @override
  Future<List<SyncQueueItem>> getSyncQueue() async {
    final box = Hive.box<Map>(_queueBoxName);
    final list = box.values.map((map) => SyncQueueItem.fromMap(map)).toList();
    // Sort chronologically by timestamp so they apply in correct order
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  @override
  Future<void> removeFromSyncQueue(String id) async {
    final box = Hive.box<Map>(_queueBoxName);
    await box.delete(id);
  }

  @override
  Future<void> clearSyncQueue() async {
    final box = Hive.box<Map>(_queueBoxName);
    await box.clear();
  }
}
