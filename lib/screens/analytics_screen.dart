import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/meditrack_theme.dart';
import '../providers/analytics_provider.dart';
import '../providers/vitals_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalyticsProvider>(context, listen: false).loadAnalytics();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    final provider = Provider.of<AnalyticsProvider>(context, listen: false);
    if (_tabController.index == 0) {
      provider.setPeriod('7days');
    } else if (_tabController.index == 1) {
      provider.setPeriod('30days');
    } else {
      provider.setPeriod('3months');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getDaysCount() {
    if (_tabController.index == 0) return 7;
    if (_tabController.index == 1) return 30;
    return 90;
  }

  @override
  Widget build(BuildContext context) {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);
    final data = analyticsProvider.analyticsData;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text('Health Analytics', style: context.titleLarge),
        actions: const [
          SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: context.colors.primary,
          tabs: const [
            Tab(text: '7 Days'),
            Tab(text: '30 Days'),
            Tab(text: '3 Months'),
          ],
        ),
      ),
      body: analyticsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBPTrendCard(context, data),
                  const SizedBox(height: MediTrackSpacing.sectionGap),
                  _buildBloodSugarCard(context, data),
                  const SizedBox(height: MediTrackSpacing.sectionGap),
                  Text(
                    'Key Metric Averages',
                    style: context.titleMedium,
                  ),
                  const SizedBox(height: MediTrackSpacing.titleToContentGap),
                  _buildStatsGrid(context, data),
                  const SizedBox(height: MediTrackSpacing.sectionGap),
                  _buildAdherencePieCard(context, data),
                  const SizedBox(height: MediTrackSpacing.sectionGap),
                  _buildSymptomFrequencyCard(context, data),
                  const SizedBox(height: MediTrackSpacing.large),
                ],
              ),
            ),
    );
  }

  Widget _buildBPTrendCard(BuildContext context, Map<String, dynamic> data) {
    final List<dynamic> bpData = data['bpData'] ?? [];
    final List<FlSpot> systolicSpots = [];
    final List<FlSpot> diastolicSpots = [];

    double sumSys = 0;
    double sumDia = 0;

    for (int i = 0; i < bpData.length; i++) {
      final double sys = (bpData[i]['systolic'] as num).toDouble();
      final double dia = (bpData[i]['diastolic'] as num).toDouble();
      systolicSpots.add(FlSpot(i.toDouble(), sys));
      diastolicSpots.add(FlSpot(i.toDouble(), dia));
      sumSys += sys;
      sumDia += dia;
    }

    final avgSys = bpData.isNotEmpty ? (sumSys / bpData.length).round() : 0;
    final avgDia = bpData.isNotEmpty ? (sumDia / bpData.length).round() : 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Blood Pressure',
                  style: context.titleMedium,
                ),
                const SizedBox(width: 6),
                Icon(Icons.info_outline, size: 16, color: context.colors.textSecondary),
              ],
            ),
            const SizedBox(height: MediTrackSpacing.medium),
            SizedBox(
              height: 200,
              child: bpData.isEmpty
                  ? Center(child: Text('No BP data recorded', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)))
                  : LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: 120,
                              color: context.colors.warning,
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                            HorizontalLine(
                              y: 80,
                              color: context.colors.warning,
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ],
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: systolicSpots,
                            isCurved: true,
                            color: context.colors.primary,
                            barWidth: 3,
                          ),
                          LineChartBarData(
                            spots: diastolicSpots,
                            isCurved: true,
                            color: context.colors.accent,
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: context.colors.primary),
                const SizedBox(width: 4),
                Text('Systolic', style: context.labelSmall),
                const SizedBox(width: 24),
                Icon(Icons.circle, size: 10, color: context.colors.accent),
                const SizedBox(width: 4),
                Text('Diastolic', style: context.labelSmall),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Avg Systolic: $avgSys mmHg',
                  style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Avg Diastolic: $avgDia mmHg',
                  style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarCard(BuildContext context, Map<String, dynamic> data) {
    final List<dynamic> sugarData = data['sugarData'] ?? [];
    final List<BarChartGroupData> barGroups = [];
    double sumSugar = 0;

    for (int i = 0; i < sugarData.length; i++) {
      final double val = (sugarData[i]['value'] as num).toDouble();
      sumSugar += val;

      Color barColor = context.colors.success;
      if (val > 180) {
        barColor = context.colors.errorSos;
      } else if (val > 140) {
        barColor = context.colors.warning;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: barColor,
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )
          ],
        ),
      );
    }

    final avgSugar = sugarData.isNotEmpty ? (sumSugar / sugarData.length).toStringAsFixed(1) : '0';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blood Sugar',
              style: context.titleMedium,
            ),
            const SizedBox(height: MediTrackSpacing.medium),
            SizedBox(
              height: 180,
              child: sugarData.isEmpty
                  ? Center(child: Text('No sugar data recorded', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)))
                  : BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        barGroups: barGroups,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: context.colors.success),
                const SizedBox(width: 4),
                Text('Normal', style: context.labelSmall),
                const SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: context.colors.warning),
                const SizedBox(width: 4),
                Text('High', style: context.labelSmall),
                const SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: context.colors.errorSos),
                const SizedBox(width: 4),
                Text('Very High', style: context.labelSmall),
              ],
            ),
            const Divider(height: 24),
            Center(
              child: Text(
                'Average: $avgSugar mg/dL',
                style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> data) {
    final statSummaries = data['statSummaries'] ?? {};
    final double avgHR = (statSummaries['avg_hr'] ?? 0.0).toDouble();
    final double avgSpO2 = (statSummaries['avg_spo2'] ?? 0.0).toDouble();
    final double avgWeight = (statSummaries['avg_weight'] ?? 0.0).toDouble();
    final double avgTemp = (statSummaries['avg_temp'] ?? 0.0).toDouble();

    final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
    final trends = vitalsProvider.getTrend(vitalsProvider.vitals, _getDaysCount());

    IconData getTrendIcon(String trend) {
      if (trend == 'up') return Icons.arrow_upward;
      if (trend == 'down') return Icons.arrow_downward;
      return Icons.remove;
    }

    Color getTrendColor(String trend, bool isNegativeIndicator) {
      if (trend == 'flat') return context.colors.warning;
      if (trend == 'up') {
        return isNegativeIndicator ? context.colors.errorSos : context.colors.success;
      } else {
        return isNegativeIndicator ? context.colors.success : context.colors.errorSos;
      }
    }

    final hrTrend = trends['heart_rate'] ?? 'flat';
    final spo2Trend = trends['spo2'] ?? 'flat';
    final weightTrend = trends['weight'] ?? 'flat';
    final tempTrend = trends['temperature'] ?? 'flat';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      mainAxisSpacing: MediTrackSpacing.listItemGap,
      crossAxisSpacing: MediTrackSpacing.listItemGap,
      children: [
        _buildStatCard(
          context,
          Icons.speed,
          'Avg Heart Rate',
          avgHR > 0 ? avgHR.round().toString() : '--',
          'bpm',
          getTrendIcon(hrTrend),
          getTrendColor(hrTrend, true),
        ),
        _buildStatCard(
          context,
          Icons.air,
          'Avg SpO2',
          avgSpO2 > 0 ? avgSpO2.round().toString() : '--',
          '%',
          getTrendIcon(spo2Trend),
          getTrendColor(spo2Trend, false),
        ),
        _buildStatCard(
          context,
          Icons.monitor_weight_outlined,
          'Avg Weight',
          avgWeight > 0 ? avgWeight.toStringAsFixed(1) : '--',
          'kg',
          getTrendIcon(weightTrend),
          getTrendColor(weightTrend, true),
        ),
        _buildStatCard(
          context,
          Icons.thermostat,
          'Avg Temp',
          avgTemp > 0 ? avgTemp.toStringAsFixed(1) : '--',
          '°C',
          getTrendIcon(tempTrend),
          getTrendColor(tempTrend, true),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    String unit,
    IconData trendIcon,
    Color trendColor,
  ) {
    return Card(
      color: context.colors.primaryLight,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: context.colors.primary),
                Icon(trendIcon, size: 16, color: trendColor),
              ],
            ),
            Text(
              label,
              style: context.bodySmall.copyWith(color: context.colors.textSecondary),
            ),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  value,
                  style: context.vitalValue.copyWith(color: context.colors.primary),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: context.vitalUnit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherencePieCard(BuildContext context, Map<String, dynamic> data) {
    final adherence = data['adherenceData'] ?? {'taken': 0, 'missed': 0, 'snoozed': 0};
    final double taken = (adherence['taken'] as num).toDouble();
    final double missed = (adherence['missed'] as num).toDouble();
    final double snoozed = (adherence['snoozed'] as num).toDouble();

    final total = taken + missed + snoozed;
    final int pct = total > 0 ? ((taken / total) * 100).round() : 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medication Adherence',
              style: context.titleMedium,
            ),
            const SizedBox(height: MediTrackSpacing.medium),
            SizedBox(
              height: 180,
              child: total == 0
                  ? Center(child: Text('No doses logged yet', style: context.bodyMedium.copyWith(color: context.colors.textSecondary)))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(value: taken > 0 ? taken : 0.001, color: context.colors.success, title: '', radius: 20),
                              PieChartSectionData(value: missed > 0 ? missed : 0.001, color: context.colors.errorSos, title: '', radius: 20),
                              PieChartSectionData(value: snoozed > 0 ? snoozed : 0.001, color: context.colors.warning, title: '', radius: 20),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$pct%', style: context.displayLarge.copyWith(color: context.colors.primary)),
                            Text('Adherence', style: context.labelSmall),
                          ],
                        )
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: context.colors.success),
                const SizedBox(width: 4),
                Text('Taken', style: context.labelSmall),
                const SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: context.colors.errorSos),
                const SizedBox(width: 4),
                Text('Missed', style: context.labelSmall),
                const SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: context.colors.warning),
                const SizedBox(width: 4),
                Text('Snoozed/Skipped', style: context.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomFrequencyCard(BuildContext context, Map<String, dynamic> data) {
    final Map<String, int> symFreq = Map<String, int>.from(data['symptomFrequency'] ?? {});

    final sortedSymptoms = symFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSymptoms = sortedSymptoms.take(3).toList();
    final maxCount = topSymptoms.isNotEmpty ? topSymptoms.first.value : 1;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Frequent Symptoms',
              style: context.titleMedium,
            ),
            const SizedBox(height: MediTrackSpacing.medium),
            topSymptoms.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('No symptoms logged', style: context.bodyMedium.copyWith(color: context.colors.textSecondary))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topSymptoms.length,
                    itemBuilder: (context, index) {
                      final item = topSymptoms[index];
                      final pct = item.value / maxCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                item.key,
                                style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 12,
                                  backgroundColor: context.colors.primaryLight,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${item.value}',
                                style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
