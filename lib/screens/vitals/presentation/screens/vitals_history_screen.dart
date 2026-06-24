import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/vitals_providers.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/vital_card.dart';
import 'add_edit_vital_screen.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/spo2_entity.dart';
import '../../domain/entities/vital_types.dart';

/// Screen representing the detailed history and charts for vital records.
class VitalsHistoryScreen extends ConsumerStatefulWidget {
  static const String routeName = '/vitals-history';

  final VitalType initialType;

  const VitalsHistoryScreen({
    Key? key,
    required this.initialType,
  }) : super(key: key);

  @override
  ConsumerState<VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends ConsumerState<VitalsHistoryScreen> with SingleTickerProviderStateMixin {
  late VitalType _selectedType;
  int _daysFilter = 7; // Default 7 days

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analytics = ref.watch(vitalsAnalyticsProvider(_daysFilter));

    // Get current record lists for history view
    final bpAsync = ref.watch(watchBloodPressureProvider);
    final sugarAsync = ref.watch(watchBloodSugarProvider);
    final tempAsync = ref.watch(watchTemperatureProvider);
    final weightAsync = ref.watch(watchWeightProvider);
    final spo2Async = ref.watch(watchSpO2Provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getVitalName(_selectedType)} History',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Timeframe Selection Bar (Segmented Button)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 Days'), icon: Icon(Icons.date_range)),
                  ButtonSegment(value: 30, label: Text('30 Days'), icon: Icon(Icons.calendar_month)),
                ],
                selected: {_daysFilter},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _daysFilter = newSelection.first;
                  });
                },
              ),
            ),

            // 2. Vital Type Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: VitalType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(_getVitalName(type)),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                      selectedColor: _getVitalColor(type).withOpacity(0.15),
                      checkmarkColor: _getVitalColor(type),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? _getVitalColor(type) : theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Analytics Chart Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Trend',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildChart(analytics),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Statistics Dashboard Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildStatsGrid(analytics),
            ),

            const SizedBox(height: 20),

            // 5. Historical Entries Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recorded History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AddEditVitalScreen.routeName,
                        arguments: _selectedType,
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                  )
                ],
              ),
            ),

            // 6. Chronological List of Records
            _buildHistoryList(
              bpAsync: bpAsync,
              sugarAsync: sugarAsync,
              tempAsync: tempAsync,
              weightAsync: weightAsync,
              spo2Async: spo2Async,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(VitalsAnalyticsReport analytics) {
    return switch (_selectedType) {
      VitalType.bloodPressure => VitalsLineChart(
          dates: analytics.bp.dates,
          values: analytics.bp.systolicValues.map((e) => e.toDouble()).toList(),
          secondaryValues: analytics.bp.diastolicValues.map((e) => e.toDouble()).toList(),
          label: 'BP',
          primaryColor: const Color(0xFFE57373),
          secondaryColor: const Color(0xFF90CAF9),
        ),
      VitalType.bloodSugar => VitalsLineChart(
          dates: analytics.sugar.dates,
          values: analytics.sugar.values,
          label: 'Sugar',
          primaryColor: const Color(0xFF64B5F6),
        ),
      VitalType.temperature => VitalsLineChart(
          dates: analytics.temp.dates,
          values: analytics.temp.values,
          label: 'Temp',
          primaryColor: const Color(0xFFFFB74D),
        ),
      VitalType.weight => VitalsLineChart(
          dates: analytics.weight.dates,
          values: analytics.weight.values,
          label: 'Weight',
          primaryColor: const Color(0xFF81C784),
        ),
      VitalType.spo2 => VitalsLineChart(
          dates: analytics.spo2.dates,
          values: analytics.spo2.values,
          label: 'SpO2',
          primaryColor: const Color(0xFF4DB6AC),
        ),
    };
  }

  Widget _buildStatsGrid(VitalsAnalyticsReport analytics) {
    final theme = Theme.of(context);
    final statsColor = _getVitalColor(_selectedType);

    if (_selectedType == VitalType.bloodPressure) {
      final bp = analytics.bp;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  'Avg Blood Pressure',
                  bp.dates.isNotEmpty ? '${bp.avgSystolic.toStringAsFixed(0)}/${bp.avgDiastolic.toStringAsFixed(0)}' : '--',
                  'mmHg',
                  statsColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  'Highest BP',
                  bp.dates.isNotEmpty ? '${bp.maxSystolic.toStringAsFixed(0)}/${bp.maxDiastolic.toStringAsFixed(0)}' : '--',
                  'mmHg',
                  const Color(0xFFEF9A9A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  'Lowest BP',
                  bp.dates.isNotEmpty ? '${bp.minSystolic.toStringAsFixed(0)}/${bp.minDiastolic.toStringAsFixed(0)}' : '--',
                  'mmHg',
                  const Color(0xFFA5D6A7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  'Overall Trend',
                  bp.trend.toUpperCase(),
                  bp.dates.isNotEmpty ? 'Based on Systolic' : 'No data',
                  bp.trend == 'improving' ? Colors.green : (bp.trend == 'worsening' ? Colors.red : Colors.grey),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final stats = switch (_selectedType) {
      VitalType.bloodSugar => analytics.sugar,
      VitalType.temperature => analytics.temp,
      VitalType.weight => analytics.weight,
      VitalType.spo2 => analytics.spo2,
      _ => GeneralAnalyticsStats.empty(),
    };

    final unit = _getVitalUnit(_selectedType);
    final lowerIsBetter = _selectedType != VitalType.spo2;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Average Value',
                stats.dates.isNotEmpty ? stats.average.toStringAsFixed(1) : '--',
                unit,
                statsColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Highest Value',
                stats.dates.isNotEmpty ? stats.highest.toStringAsFixed(1) : '--',
                unit,
                const Color(0xFFEF9A9A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                'Lowest Value',
                stats.dates.isNotEmpty ? stats.lowest.toStringAsFixed(1) : '--',
                unit,
                const Color(0xFFA5D6A7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                'Overall Trend',
                stats.trend.toUpperCase().replaceAll('_', ' '),
                stats.dates.isNotEmpty ? (stats.trend == 'improving' ? 'Improving health' : 'Review values') : 'No data',
                stats.trend == 'improving' ? Colors.green : (stats.trend == 'worsening' ? Colors.red : Colors.grey),
              ),
            ),
          ],
        ),
        if (_selectedType == VitalType.weight && stats.dates.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.trending_down, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight Change Analytics',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weekly change: ${analytics.weeklyWeightChange > 0 ? "+" : ""}${analytics.weeklyWeightChange.toStringAsFixed(1)} kg',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'Monthly change: ${analytics.monthlyWeightChange > 0 ? "+" : ""}${analytics.monthlyWeightChange.toStringAsFixed(1)} kg',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatTile(String label, String value, String unit, Color tintColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.extrabold,
                    color: tintColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList({
    required AsyncValue<List<BloodPressureEntity>> bpAsync,
    required AsyncValue<List<BloodSugarEntity>> sugarAsync,
    required AsyncValue<List<TemperatureEntity>> tempAsync,
    required AsyncValue<List<WeightEntity>> weightAsync,
    required AsyncValue<List<SpO2Entity>> spo2Async,
  }) {
    final theme = Theme.of(context);

    Widget buildList<T>(List<T> list) {
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'No logs recorded yet.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
            ),
          ),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index] as Object;
          return VitalCard(
            record: item,
            onEdit: () {
              Navigator.pushNamed(
                context,
                AddEditVitalScreen.routeName,
                arguments: item,
              );
            },
            onDelete: () => _confirmDeletion(context, item),
          );
        },
      );
    }

    return switch (_selectedType) {
      VitalType.bloodPressure => bpAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, s) => Text('Error: $err'),
          data: (list) => buildList(list),
        ),
      VitalType.bloodSugar => sugarAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, s) => Text('Error: $err'),
          data: (list) => buildList(list),
        ),
      VitalType.temperature => tempAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, s) => Text('Error: $err'),
          data: (list) => buildList(list),
        ),
      VitalType.weight => weightAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, s) => Text('Error: $err'),
          data: (list) => buildList(list),
        ),
      VitalType.spo2 => spo2Async.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, s) => Text('Error: $err'),
          data: (list) => buildList(list),
        ),
    };
  }

  void _confirmDeletion(BuildContext context, Object record) {
    String recordId = '';
    VitalType type = VitalType.bloodPressure;

    if (record is BloodPressureEntity) {
      recordId = record.id;
      type = VitalType.bloodPressure;
    } else if (record is BloodSugarEntity) {
      recordId = record.id;
      type = VitalType.bloodSugar;
    } else if (record is TemperatureEntity) {
      recordId = record.id;
      type = VitalType.temperature;
    } else if (record is WeightEntity) {
      recordId = record.id;
      type = VitalType.weight;
    } else if (record is SpO2Entity) {
      recordId = record.id;
      type = VitalType.spo2;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text('Are you sure you want to permanently delete this health record?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(vitalsActionNotifierProvider.notifier)
                  .deleteVital(type, recordId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Log deleted successfully.'
                        : 'Failed to delete log. Added to offline queue.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _getVitalName(VitalType type) {
    return switch (type) {
      VitalType.bloodPressure => 'Blood Pressure',
      VitalType.bloodSugar => 'Blood Sugar',
      VitalType.temperature => 'Body Temperature',
      VitalType.weight => 'Body Weight',
      VitalType.spo2 => 'Oxygen (SpO₂)',
    };
  }

  String _getVitalUnit(VitalType type) {
    return switch (type) {
      VitalType.bloodPressure => 'mmHg',
      VitalType.bloodSugar => 'mg/dL',
      VitalType.temperature => '°C',
      VitalType.weight => 'kg',
      VitalType.spo2 => '%',
    };
  }

  Color _getVitalColor(VitalType type) {
    return switch (type) {
      VitalType.bloodPressure => const Color(0xFFE57373),
      VitalType.bloodSugar => const Color(0xFF64B5F6),
      VitalType.temperature => const Color(0xFFFFB74D),
      VitalType.weight => const Color(0xFF81C784),
      VitalType.spo2 => const Color(0xFF4DB6AC),
    };
  }
}
