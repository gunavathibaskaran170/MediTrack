import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/vitals_local_data_source.dart';
import '../../data/datasources/vitals_remote_data_source.dart';
import '../../data/repositories/vitals_repository_impl.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/spo2_entity.dart';
import '../../domain/entities/vital_types.dart';
import '../../domain/repositories/vitals_repository.dart';
import '../../domain/usecases/add_vital_usecase.dart';
import '../../domain/usecases/edit_vital_usecase.dart';
import '../../domain/usecases/delete_vital_usecase.dart';
import '../../domain/usecases/get_vitals_usecase.dart';
import '../../domain/usecases/sync_vitals_usecase.dart';
import '../../../../providers/global_providers.dart'; // import global userIdProvider

// =========================================================================
// Data Source & Repository Providers
// =========================================================================

final vitalsRemoteDataSourceProvider = Provider<VitalsRemoteDataSource>((ref) {
  return VitalsFirestoreDataSource();
});

final vitalsLocalDataSourceProvider = Provider<VitalsLocalDataSource>((ref) {
  final dataSource = VitalsHiveDataSource();
  dataSource.init(); // note: in a real app, you initialize this in main() before runApp
  return dataSource;
});

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  final remote = ref.watch(vitalsRemoteDataSourceProvider);
  final local = ref.watch(vitalsLocalDataSourceProvider);
  return VitalsRepositoryImpl(remoteDataSource: remote, localDataSource: local);
});

// =========================================================================
// Use Case Providers
// =========================================================================

final addVitalUseCaseProvider = Provider<AddVitalUseCase>((ref) {
  return AddVitalUseCase(ref.watch(vitalsRepositoryProvider));
});

final editVitalUseCaseProvider = Provider<EditVitalUseCase>((ref) {
  return EditVitalUseCase(ref.watch(vitalsRepositoryProvider));
});

final deleteVitalUseCaseProvider = Provider<DeleteVitalUseCase>((ref) {
  return DeleteVitalUseCase(ref.watch(vitalsRepositoryProvider));
});

final getVitalsUseCaseProvider = Provider<GetVitalsUseCase>((ref) {
  return GetVitalsUseCase(ref.watch(vitalsRepositoryProvider));
});

final syncVitalsUseCaseProvider = Provider<SyncVitalsUseCase>((ref) {
  return SyncVitalsUseCase(ref.watch(vitalsRepositoryProvider));
});

// =========================================================================
// Real-time Data Streams (Watching Vitals)
// =========================================================================

final watchBloodPressureProvider = StreamProvider<List<BloodPressureEntity>>((ref) {
  final userId = ref.watch(userIdProvider);
  return ref.watch(getVitalsUseCaseProvider).watchBloodPressure(userId);
});

final watchBloodSugarProvider = StreamProvider<List<BloodSugarEntity>>((ref) {
  final userId = ref.watch(userIdProvider);
  return ref.watch(getVitalsUseCaseProvider).watchBloodSugar(userId);
});

final watchTemperatureProvider = StreamProvider<List<TemperatureEntity>>((ref) {
  final userId = ref.watch(userIdProvider);
  return ref.watch(getVitalsUseCaseProvider).watchTemperature(userId);
});

final watchWeightProvider = StreamProvider<List<WeightEntity>>((ref) {
  final userId = ref.watch(userIdProvider);
  return ref.watch(getVitalsUseCaseProvider).watchWeight(userId);
});

final watchSpO2Provider = StreamProvider<List<SpO2Entity>>((ref) {
  final userId = ref.watch(userIdProvider);
  return ref.watch(getVitalsUseCaseProvider).watchSpO2(userId);
});

// =========================================================================
// Action Notifier (CRUD operations)
// =========================================================================

class VitalsActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  VitalsActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addBP(BloodPressureEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(addVitalUseCaseProvider).addBloodPressure(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> editBP(BloodPressureEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(editVitalUseCaseProvider).editBloodPressure(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> addBloodSugar(BloodSugarEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(addVitalUseCaseProvider).addBloodSugar(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> editBloodSugar(BloodSugarEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(editVitalUseCaseProvider).editBloodSugar(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> addTemperature(TemperatureEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(addVitalUseCaseProvider).addTemperature(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> editTemperature(TemperatureEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(editVitalUseCaseProvider).editTemperature(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> addWeight(WeightEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(addVitalUseCaseProvider).addWeight(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> editWeight(WeightEntity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(editVitalUseCaseProvider).editWeight(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> addSpO2(SpO2Entity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(addVitalUseCaseProvider).addSpO2(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> editSpO2(SpO2Entity record) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(editVitalUseCaseProvider).editSpO2(userId, record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteVital(VitalType type, String recordId) async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(deleteVitalUseCaseProvider).execute(userId, type, recordId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> sync() async {
    state = const AsyncValue.loading();
    try {
      final userId = _ref.read(userIdProvider);
      await _ref.read(syncVitalsUseCaseProvider).execute(userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final vitalsActionNotifierProvider =
    StateNotifierProvider<VitalsActionNotifier, AsyncValue<void>>((ref) {
  return VitalsActionNotifier(ref);
});

// =========================================================================
// Aggregated Today's Logs Provider (Daily Logs)
// =========================================================================

class TodayVitalsState {
  final List<BloodPressureEntity> bp;
  final List<BloodSugarEntity> sugar;
  final List<TemperatureEntity> temp;
  final List<WeightEntity> weight;
  final List<SpO2Entity> spo2;

  const TodayVitalsState({
    required this.bp,
    required this.sugar,
    required this.temp,
    required this.weight,
    required this.spo2,
  });

  bool get isEmpty => bp.isEmpty && sugar.isEmpty && temp.isEmpty && weight.isEmpty && spo2.isEmpty;
}

final todayVitalsProvider = Provider<AsyncValue<TodayVitalsState>>((ref) {
  final bpAsync = ref.watch(watchBloodPressureProvider);
  final sugarAsync = ref.watch(watchBloodSugarProvider);
  final tempAsync = ref.watch(watchTemperatureProvider);
  final weightAsync = ref.watch(watchWeightProvider);
  final spo2Async = ref.watch(watchSpO2Provider);

  if (bpAsync.isLoading ||
      sugarAsync.isLoading ||
      tempAsync.isLoading ||
      weightAsync.isLoading ||
      spo2Async.isLoading) {
    return const AsyncValue.loading();
  }

  if (bpAsync.hasError) return AsyncValue.error(bpAsync.error!, bpAsync.stackTrace!);
  if (sugarAsync.hasError) return AsyncValue.error(sugarAsync.error!, sugarAsync.stackTrace!);
  if (tempAsync.hasError) return AsyncValue.error(tempAsync.error!, tempAsync.stackTrace!);
  if (weightAsync.hasError) return AsyncValue.error(weightAsync.error!, weightAsync.stackTrace!);
  if (spo2Async.hasError) return AsyncValue.error(spo2Async.error!, spo2Async.stackTrace!);

  final today = DateTime.now();

  bool isToday(DateTime dt) {
    return dt.year == today.year && dt.month == today.month && dt.day == today.day;
  }

  final todayBP = (bpAsync.value ?? []).where((e) => isToday(e.timestamp)).toList();
  final todaySugar = (sugarAsync.value ?? []).where((e) => isToday(e.timestamp)).toList();
  final todayTemp = (tempAsync.value ?? []).where((e) => isToday(e.timestamp)).toList();
  final todayWeight = (weightAsync.value ?? []).where((e) => isToday(e.timestamp)).toList();
  final todaySpO2 = (spo2Async.value ?? []).where((e) => isToday(e.timestamp)).toList();

  return AsyncValue.data(TodayVitalsState(
    bp: todayBP,
    sugar: todaySugar,
    temp: todayTemp,
    weight: todayWeight,
    spo2: todaySpO2,
  ));
});

// =========================================================================
// Weekly & Monthly Analytics Provider
// =========================================================================

class GeneralAnalyticsStats {
  final double average;
  final double highest;
  final double lowest;
  final String trend; // 'improving' | 'stable' | 'worsening' | 'no_data'
  final List<DateTime> dates;
  final List<double> values;

  const GeneralAnalyticsStats({
    required this.average,
    required this.highest,
    required this.lowest,
    required this.trend,
    required this.dates,
    required this.values,
  });

  factory GeneralAnalyticsStats.empty() {
    return const GeneralAnalyticsStats(
      average: 0.0,
      highest: 0.0,
      lowest: 0.0,
      trend: 'no_data',
      dates: [],
      values: [],
    );
  }
}

class BPAnalyticsStats {
  final double avgSystolic;
  final double avgDiastolic;
  final double maxSystolic;
  final double minSystolic;
  final double maxDiastolic;
  final double minDiastolic;
  final String trend;
  final List<DateTime> dates;
  final List<int> systolicValues;
  final List<int> diastolicValues;

  const BPAnalyticsStats({
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.maxSystolic,
    required this.minSystolic,
    required this.maxDiastolic,
    required this.minDiastolic,
    required this.trend,
    required this.dates,
    required this.systolicValues,
    required this.diastolicValues,
  });

  factory BPAnalyticsStats.empty() {
    return const BPAnalyticsStats(
      avgSystolic: 0.0,
      avgDiastolic: 0.0,
      maxSystolic: 0.0,
      minSystolic: 0.0,
      maxDiastolic: 0.0,
      minDiastolic: 0.0,
      trend: 'no_data',
      dates: [],
      systolicValues: [],
      diastolicValues: [],
    );
  }
}

class VitalsAnalyticsReport {
  final BPAnalyticsStats bp;
  final GeneralAnalyticsStats sugar;
  final GeneralAnalyticsStats temp;
  final GeneralAnalyticsStats weight;
  final GeneralAnalyticsStats spo2;
  
  // Weight change calculations
  final double weeklyWeightChange; // current weight - weight 7 days ago
  final double monthlyWeightChange; // current weight - weight 30 days ago

  const VitalsAnalyticsReport({
    required this.bp,
    required this.sugar,
    required this.temp,
    required this.weight,
    required this.spo2,
    required this.weeklyWeightChange,
    required this.monthlyWeightChange,
  });
}

/// Generic provider that computes stats based on days filter (e.g. 7 days or 30 days)
final vitalsAnalyticsProvider = Provider.family<VitalsAnalyticsReport, int>((ref, daysCount) {
  final bpList = ref.watch(watchBloodPressureProvider).value ?? [];
  final sugarList = ref.watch(watchBloodSugarProvider).value ?? [];
  final tempList = ref.watch(watchTemperatureProvider).value ?? [];
  final weightList = ref.watch(watchWeightProvider).value ?? [];
  final spo2List = ref.watch(watchSpO2Provider).value ?? [];

  final cutoffDate = DateTime.now().subtract(Duration(days: daysCount));

  // Filter lists by cutoff date
  final filteredBP = bpList.where((e) => e.timestamp.isAfter(cutoffDate)).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final filteredSugar = sugarList.where((e) => e.timestamp.isAfter(cutoffDate)).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final filteredTemp = tempList.where((e) => e.timestamp.isAfter(cutoffDate)).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final filteredWeight = weightList.where((e) => e.timestamp.isAfter(cutoffDate)).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final filteredSpO2 = spo2List.where((e) => e.timestamp.isAfter(cutoffDate)).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // ==========================================
  // 1. Blood Pressure Analytics
  // ==========================================
  BPAnalyticsStats bpStats = BPAnalyticsStats.empty();
  if (filteredBP.isNotEmpty) {
    double sumSys = 0;
    double sumDia = 0;
    int maxSys = -999;
    int minSys = 999;
    int maxDia = -999;
    int minDia = 999;

    for (final e in filteredBP) {
      sumSys += e.systolic;
      sumDia += e.diastolic;
      if (e.systolic > maxSys) maxSys = e.systolic;
      if (e.systolic < minSys) minSys = e.systolic;
      if (e.diastolic > maxDia) maxDia = e.diastolic;
      if (e.diastolic < minDia) minDia = e.diastolic;
    }

    // Trend calculation (simplistic comparison of last half vs first half)
    String bpTrend = 'stable';
    if (filteredBP.length >= 2) {
      final mid = filteredBP.length ~/ 2;
      final firstHalfAvg = filteredBP.sublist(0, mid).map((e) => e.systolic).reduce((a, b) => a + b) / mid;
      final secondHalfAvg = filteredBP.sublist(mid).map((e) => e.systolic).reduce((a, b) => a + b) / (filteredBP.length - mid);
      if (secondHalfAvg < firstHalfAvg - 5) {
        bpTrend = 'improving'; // blood pressure decreasing is usually improving
      } else if (secondHalfAvg > firstHalfAvg + 5) {
        bpTrend = 'worsening';
      }
    }

    bpStats = BPAnalyticsStats(
      avgSystolic: sumSys / filteredBP.length,
      avgDiastolic: sumDia / filteredBP.length,
      maxSystolic: maxSys.toDouble(),
      minSystolic: minSys.toDouble(),
      maxDiastolic: maxDia.toDouble(),
      minDiastolic: minDia.toDouble(),
      trend: bpTrend,
      dates: filteredBP.map((e) => e.timestamp).toList(),
      systolicValues: filteredBP.map((e) => e.systolic).toList(),
      diastolicValues: filteredBP.map((e) => e.diastolic).toList(),
    );
  }

  // ==========================================
  // Helper for single value vitals
  // ==========================================
  GeneralAnalyticsStats computeGeneralStats(List<dynamic> items, double Function(dynamic) getValue, {bool lowerIsBetter = true}) {
    if (items.isEmpty) return GeneralAnalyticsStats.empty();
    
    double sum = 0;
    double maxVal = -999999.0;
    double minVal = 999999.0;

    for (final item in items) {
      final val = getValue(item);
      sum += val;
      if (val > maxVal) maxVal = val;
      if (val < minVal) minVal = val;
    }

    String trend = 'stable';
    if (items.length >= 2) {
      final mid = items.length ~/ 2;
      final fHalf = items.sublist(0, mid);
      final sHalf = items.sublist(mid);
      final firstAvg = fHalf.map(getValue).reduce((a, b) => a + b) / fHalf.length;
      final secondAvg = sHalf.map(getValue).reduce((a, b) => a + b) / sHalf.length;
      
      final diff = secondAvg - firstAvg;
      if (diff.abs() > 0.05) {
        if (lowerIsBetter) {
          trend = diff < 0 ? 'improving' : 'worsening';
        } else {
          trend = diff > 0 ? 'improving' : 'worsening'; // e.g. oxygen higher is better
        }
      }
    }

    return GeneralAnalyticsStats(
      average: sum / items.length,
      highest: maxVal,
      lowest: minVal,
      trend: trend,
      dates: items.map((e) => e.timestamp as DateTime).toList(),
      values: items.map(getValue).toList(),
    );
  }

  // Sugar
  final sugarStats = computeGeneralStats(filteredSugar, (e) => (e as BloodSugarEntity).value);
  // Temp (standardized in Celsius)
  final tempStats = computeGeneralStats(filteredTemp, (e) => (e as TemperatureEntity).valueInCelsius);
  // Weight
  final weightStats = computeGeneralStats(filteredWeight, (e) => (e as WeightEntity).valueInKg);
  // SpO2 (higher is better)
  final spo2Stats = computeGeneralStats(filteredSpO2, (e) => (e as SpO2Entity).percentage.toDouble(), lowerIsBetter: false);

  // ==========================================
  // Weight Change Calculations
  // ==========================================
  double weeklyWeight = 0.0;
  double monthlyWeight = 0.0;

  if (weightList.isNotEmpty) {
    final currentWeight = weightList.first.valueInKg; // weightList is sorted descending in stream

    // Weekly change: compare with weight closest to 7 days ago
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weight7DaysAgo = weightList.firstWhere(
      (e) => e.timestamp.isBefore(oneWeekAgo) || e.timestamp.isAtSameMomentAs(oneWeekAgo),
      orElse: () => weightList.last, // Fallback to oldest weight if not enough history
    );
    weeklyWeight = currentWeight - weight7DaysAgo.valueInKg;

    // Monthly change: compare with weight closest to 30 days ago
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final weight30DaysAgo = weightList.firstWhere(
      (e) => e.timestamp.isBefore(oneMonthAgo) || e.timestamp.isAtSameMomentAs(oneMonthAgo),
      orElse: () => weightList.last,
    );
    monthlyWeight = currentWeight - weight30DaysAgo.valueInKg;
  }

  return VitalsAnalyticsReport(
    bp: bpStats,
    sugar: sugarStats,
    temp: tempStats,
    weight: weightStats,
    spo2: spo2Stats,
    weeklyWeightChange: weeklyWeight,
    monthlyWeightChange: monthlyWeight,
  );
});
