import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/meditrack_theme.dart';
import '../providers/analytics_provider.dart';
import '../providers/vitals_provider.dart';
import '../providers/user_provider.dart';
import '../core/models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalyticsProvider>(context, listen: false).loadAnalytics();
      Provider.of<VitalsProvider>(context, listen: false).loadVitals();
      Provider.of<UserProvider>(context, listen: false).loadUser();
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
    final vitalsProvider = Provider.of<VitalsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final current = vitalsProvider.latestCheckup;
    final previous = vitalsProvider.previousCheckup;
    final user = userProvider.currentUser;

    final hasCheckup = current != null;
    final data = analyticsProvider.analyticsData;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text('Health Analytics', style: context.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Print Health Summary',
            onPressed: () => Navigator.pushNamed(context, '/reports'),
          ),
          const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
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
                  // 1. Hospital Vitals Checkup Comparison
                  if (hasCheckup) ...[
                    Row(
                      children: [
                        Icon(Icons.compare_arrows_rounded, size: 18, color: context.colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Checkup Vitals — Current vs Previous',
                          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: MediTrackSpacing.titleToContentGap),
                    _buildPatientProfileBanner(context, user),
                    const SizedBox(height: 12),
                    _buildHealthOverviewBanner(context, current),
                    const SizedBox(height: 16),
                    _buildInteractiveVitalsGrid(context, current, previous, vitalsProvider),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                    const Divider(thickness: 1),
                    const SizedBox(height: MediTrackSpacing.sectionGap),
                  ],

                  // 2. Historical Trend Charts
                  Row(
                    children: [
                      Icon(Icons.show_chart_rounded, size: 18, color: context.colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Historical Trend Charts',
                        style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: MediTrackSpacing.titleToContentGap),
                  _buildBPTrendCard(context, data),
                  const SizedBox(height: MediTrackSpacing.sectionGap),
                  _buildBloodSugarCard(context, data),
                  const SizedBox(height: MediTrackSpacing.sectionGap),

                  // 3. Average Metrics
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 18, color: context.colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Key Metric Averages',
                        style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
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

  // --- MANUAL SYNC FROM HOSPITAL ---
  Future<void> _syncFromHospital() async {
    setState(() {
      _isSyncing = true;
    });

    // Simulate connection delay for presentation realism
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      await Provider.of<VitalsProvider>(context, listen: false).loadVitals();
      setState(() {
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: context.colors.success),
              const SizedBox(width: 8),
              const Text('Successfully synced latest checkup data from hospital!'),
            ],
          ),
          backgroundColor: context.colors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- COMPUTE GLOBAL HEALTH STATUS ---
  bool _areAllVitalsNormal(Vital current) {
    if (current.heartRate != null && (current.heartRate! > 100 || current.heartRate! < 60)) return false;
    if (current.spo2 != null && current.spo2! < 95) return false;
    if (current.bpSystolic != null && (current.bpSystolic! >= 120 || current.bpDiastolic! >= 80)) return false;
    if (current.temperature != null && (current.temperature! > 37.2 || current.temperature! < 36.0)) return false;
    
    if (current.bloodSugar != null) {
      final isFasting = current.sugarType == 'fasting';
      final sugarLimit = isFasting ? 100.0 : 140.0;
      if (current.bloodSugar! >= sugarLimit) return false;
    }
    return true;
  }

  // --- AI ADVICE DIALOGS ON CARD CLICK ---
  void _showAiInsightsDialog({
    required BuildContext context,
    required String name,
    required IconData icon,
    required Color color,
    required String currentVal,
    required String? prevVal,
    required String unit,
    required bool isAbnormal,
    required String aiText,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediTrackRadius.cards),
            side: BorderSide(color: context.colors.dividerColor, width: 0.8),
          ),
          title: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text('AI Health Insights: $name', style: context.titleLarge),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Current', style: context.labelSmall),
                        Text('$currentVal $unit', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (prevVal != null) ...[
                      const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 16),
                      Column(
                        children: [
                          Text('Previous', style: context.labelSmall),
                          Text('$prevVal $unit', style: context.bodyMedium),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isAbnormal ? Icons.tips_and_updates : Icons.stars_rounded,
                    color: isAbnormal ? context.colors.warning : context.colors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAbnormal ? 'AI RECOMMENDATION' : 'AI COMPLIMENT & MOTIVATION',
                          style: context.labelSmall.copyWith(
                            color: isAbnormal ? context.colors.warning : context.colors.success,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          aiText,
                          style: context.bodyMedium.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MediTrackRadius.buttons),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientProfileBanner(BuildContext context, User? user) {
    final name = user?.name ?? 'Rajan Kumar';
    final age = user?.age ?? 58;
    final gender = user?.gender ?? 'Male';
    final bloodGroup = user?.bloodGroup ?? 'O+';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MediTrackRadius.cards),
        side: BorderSide(color: context.colors.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: context.colors.primaryLight,
              child: Icon(Icons.local_hospital_outlined, color: context.colors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          bloodGroup,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$age years  •  $gender  •  Patient ID: PT-4021',
                    style: context.bodySmall,
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSyncing ? context.colors.textHint : context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MediTrackRadius.buttons),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: _isSyncing ? null : _syncFromHospital,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: Text(
                _isSyncing ? 'Syncing...' : 'Sync Checkup',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthOverviewBanner(BuildContext context, Vital current) {
    final allNormal = _areAllVitalsNormal(current);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: allNormal ? context.colors.successLight : context.colors.warningLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MediTrackRadius.cards),
        side: BorderSide(
          color: allNormal ? context.colors.success.withOpacity(0.3) : context.colors.warning.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              allNormal ? Icons.verified_user : Icons.tips_and_updates,
              color: allNormal ? context.colors.success : context.colors.warning,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allNormal ? '🌟 HEALTH CHAMPION!' : '💡 HEALTH FOCUS REQUIRED',
                    style: context.titleMedium.copyWith(
                      color: allNormal ? context.colors.success : context.colors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    allNormal
                        ? 'All of your vitals are currently in the normal healthy range. Your daily habits are paying off beautifully. Keep doing a fantastic job maintaining your health compliance!'
                        : 'Some checkup vitals are currently irregular or elevated. Click on the respective vital boxes below to see custom AI suggestions on diet, workouts, and tips to bring them back to normal levels.',
                    style: context.bodyMedium.copyWith(
                      color: allNormal ? context.colors.primaryDark : context.colors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveVitalsGrid(BuildContext context, Vital current, Vital? previous, VitalsProvider vitalsProvider) {
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth >= 900) {
      crossAxisCount = 3;
    } else if (screenWidth < 600) {
      crossAxisCount = 1;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: [
        _buildVitalGridCard(
          context: context,
          name: 'Blood Pressure',
          icon: Icons.biotech_rounded,
          color: context.colors.primary,
          currentVal: current.bpSystolic != null && current.bpDiastolic != null
              ? '${current.bpSystolic!.toInt()}/${current.bpDiastolic!.toInt()}'
              : '--',
          prevVal: previous?.bpSystolic != null && previous?.bpDiastolic != null
              ? '${previous!.bpSystolic!.toInt()}/${previous!.bpDiastolic!.toInt()}'
              : null,
          unit: 'mmHg',
          status: _getBPStatus(current),
          onTap: () {
            final isAbnormal = _isBPAbnormal(current);
            final aiText = isAbnormal
                ? 'Your Blood Pressure is elevated. AI Suggestion: Limit sodium intake to under 1500mg/day. Incorporate potassium-rich foods (bananas, avocados, spinach) into your diet. Dedicate 30 minutes to moderate physical activity (like brisk walking) 5 times a week, and perform deep breathing exercises twice daily to manage stress.'
                : 'Excellent! Your blood pressure is in the ideal range. Your blood vessels are healthy and strong, minimizing strain on your cardiovascular system. Continue your balanced, active lifestyle to keep it here!';
            _showAiInsightsDialog(
              context: context,
              name: 'Blood Pressure',
              icon: Icons.biotech_rounded,
              color: context.colors.primary,
              currentVal: '${current.bpSystolic!.toInt()}/${current.bpDiastolic!.toInt()}',
              prevVal: previous != null ? '${previous.bpSystolic!.toInt()}/${previous.bpDiastolic!.toInt()}' : null,
              unit: 'mmHg',
              isAbnormal: isAbnormal,
              aiText: aiText,
            );
          },
        ),
        _buildVitalGridCard(
          context: context,
          name: 'Blood Sugar',
          icon: Icons.water_drop_rounded,
          color: context.colors.warning,
          currentVal: current.bloodSugar != null ? '${current.bloodSugar!.toInt()}' : '--',
          prevVal: previous?.bloodSugar != null ? '${previous!.bloodSugar!.toInt()}' : null,
          unit: 'mg/dL',
          status: _getSugarStatus(current),
          onTap: () {
            final isAbnormal = _isSugarAbnormal(current);
            final typeStr = current.sugarType == 'fasting' ? 'fasting' : 'post-meal';
            final aiText = isAbnormal
                ? 'Your Blood Sugar is currently elevated ($typeStr). AI Suggestion: Swap simple sugars and white flour with complex carbohydrates (oats, brown rice, beans). Stay active for 10-15 minutes immediately after meals (such as a light walk) to lower glucose spikes. Stay hydrated, prioritize dietary fiber, and monitor these levels closely.'
                : 'Sensational! Your blood sugar levels are healthy and in range. Your insulin response is functioning optimally. Continue focusing on high-fiber foods, healthy fats, and lean proteins to maintain this balance!';
            _showAiInsightsDialog(
              context: context,
              name: 'Blood Sugar',
              icon: Icons.water_drop_rounded,
              color: context.colors.warning,
              currentVal: '${current.bloodSugar!.toInt()}',
              prevVal: previous?.bloodSugar != null ? '${previous!.bloodSugar!.toInt()}' : null,
              unit: 'mg/dL (${current.sugarType ?? 'fasting'})',
              isAbnormal: isAbnormal,
              aiText: aiText,
            );
          },
        ),
        _buildVitalGridCard(
          context: context,
          name: 'Heart Rate',
          icon: Icons.favorite_rounded,
          color: context.colors.errorSos,
          currentVal: current.heartRate != null ? '${current.heartRate!.toInt()}' : '--',
          prevVal: previous?.heartRate != null ? '${previous!.heartRate!.toInt()}' : null,
          unit: 'bpm',
          status: _getHRStatus(current),
          onTap: () {
            final isAbnormal = _isHRAbnormal(current);
            final aiText = isAbnormal
                ? 'Your heart rate is outside the standard 60-100 bpm resting range. AI Suggestion: If elevated, limit stimulant consumption (caffeine, tea, energy drinks) and practice mindful meditation. If too low and accompanied by dizziness or fatigue, seek immediate medical attention. Perform cardiovascular exercises regularly to strengthen heart muscle efficiency.'
                : 'Marvelous! Your resting heart rate indicates a strong, well-conditioned heart muscle that pumps oxygen-rich blood efficiently. Keep up your active routine!';
            _showAiInsightsDialog(
              context: context,
              name: 'Heart Rate',
              icon: Icons.favorite_rounded,
              color: context.colors.errorSos,
              currentVal: '${current.heartRate!.toInt()}',
              prevVal: previous?.heartRate != null ? '${previous!.heartRate!.toInt()}' : null,
              unit: 'bpm',
              isAbnormal: isAbnormal,
              aiText: aiText,
            );
          },
        ),
        _buildVitalGridCard(
          context: context,
          name: 'Oxygen Saturation',
          icon: Icons.air_rounded,
          color: Colors.teal,
          currentVal: current.spo2 != null ? '${current.spo2!.toInt()}' : '--',
          prevVal: previous?.spo2 != null ? '${previous!.spo2!.toInt()}' : null,
          unit: '%',
          status: _getSpO2Status(current),
          onTap: () {
            final isAbnormal = _isSpO2Abnormal(current);
            final aiText = isAbnormal
                ? 'Your SpO2 oxygen levels are below the optimal 95% threshold. AI Suggestion: Open windows to allow fresh air flow, practice pursed-lip or deep belly breathing, and avoid smoking/second-hand smoke. If you experience shortness of breath or if it drops below 92%, consult a doctor immediately.'
                : 'Splendid! Your oxygen saturation levels are perfect. Your respiratory system is working beautifully to deliver oxygen to your vital organs. Keep breathing easy!';
            _showAiInsightsDialog(
              context: context,
              name: 'Blood Oxygen (SpO2)',
              icon: Icons.air_rounded,
              color: Colors.teal,
              currentVal: '${current.spo2!.toInt()}',
              prevVal: previous?.spo2 != null ? '${previous!.spo2!.toInt()}' : null,
              unit: '%',
              isAbnormal: isAbnormal,
              aiText: aiText,
            );
          },
        ),
        _buildVitalGridCard(
          context: context,
          name: 'Body Temperature',
          icon: Icons.thermostat_rounded,
          color: Colors.orange,
          currentVal: current.temperature != null ? '${current.temperature!.toStringAsFixed(1)}' : '--',
          prevVal: previous?.temperature != null ? '${previous!.temperature!.toStringAsFixed(1)}' : null,
          unit: '°C',
          status: _getTempStatus(current),
          onTap: () {
            final isAbnormal = _isTempAbnormal(current);
            final aiText = isAbnormal
                ? 'Your body temperature is outside the healthy range. AI Suggestion: If high (fever), rest, drink plenty of water or electrolyte-rich fluids, and use cool compresses. If below 36°C, keep warm with layers. Measure again in 30 minutes, and seek clinical advice if it exceeds 38.5°C.'
                : 'Excellent! Your body temperature is in the ideal resting range, indicating healthy metabolic and thermoregulatory stability.';
            _showAiInsightsDialog(
              context: context,
              name: 'Body Temperature',
              icon: Icons.thermostat_rounded,
              color: Colors.orange,
              currentVal: '${current.temperature!.toStringAsFixed(1)}',
              prevVal: previous?.temperature != null ? '${previous!.temperature!.toStringAsFixed(1)}' : null,
              unit: '°C',
              isAbnormal: isAbnormal,
              aiText: aiText,
            );
          },
        ),
        _buildVitalGridCard(
          context: context,
          name: 'Body Weight',
          icon: Icons.scale_rounded,
          color: Colors.blueGrey,
          currentVal: current.weight != null ? '${current.weight!.toStringAsFixed(1)}' : '--',
          prevVal: previous?.weight != null ? '${previous!.weight!.toStringAsFixed(1)}' : null,
          unit: 'kg',
          status: const {'text': 'Stable', 'color': Colors.grey},
          onTap: () {
            final double change = previous?.weight != null ? current.weight! - previous!.weight! : 0.0;
            final isGain = change > 0.5;
            final isLoss = change < -0.5;
            final aiText = isGain
                ? 'Your weight has shown a slight increase since your last checkup. AI Suggestion: Ensure you maintain daily light activity (such as walking 10,000 steps), track sodium to reduce fluid retention, and focus on lean proteins and vegetable portions.'
                : isLoss
                    ? 'Your weight has decreased slightly since your last checkup. AI Compliment: Great progress! This weight shift reduces overall heart workload. Keep up the clean, healthy eating!'
                    : 'Your body weight remains highly stable. This consistency is excellent for steady cardio fitness. Keep eating balanced meals!';
            _showAiInsightsDialog(
              context: context,
              name: 'Body Weight',
              icon: Icons.scale_rounded,
              color: Colors.blueGrey,
              currentVal: '${current.weight!.toStringAsFixed(1)}',
              prevVal: previous?.weight != null ? '${previous!.weight!.toStringAsFixed(1)}' : null,
              unit: 'kg',
              isAbnormal: false,
              aiText: aiText,
            );
          },
        ),
      ],
    );
  }

  Widget _buildVitalGridCard({
    required BuildContext context,
    required String name,
    required IconData icon,
    required Color color,
    required String currentVal,
    required String? prevVal,
    required String unit,
    required Map<String, dynamic> status,
    required VoidCallback onTap,
  }) {
    final statusText = status['text'] as String;
    final statusColor = status['color'] as Color;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MediTrackRadius.cards),
        side: BorderSide(color: context.colors.dividerColor, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MediTrackRadius.cards),
        splashColor: color.withOpacity(0.08),
        hoverColor: color.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 8),
                      Text(name, style: context.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(currentVal, style: context.vitalValue.copyWith(fontSize: 26, color: color)),
                  const SizedBox(width: 4),
                  Text(unit, style: context.vitalUnit),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prevVal != null ? 'Prev: $prevVal $unit' : 'Prev: --',
                    style: context.bodySmall.copyWith(fontSize: 11),
                  ),
                  Row(
                    children: [
                      Text(
                        'AI Advice',
                        style: context.labelSmall.copyWith(
                          fontSize: 10,
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 12, color: context.colors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEALTH STATUS HELPERS ---
  bool _isBPAbnormal(Vital v) {
    if (v.bpSystolic == null || v.bpDiastolic == null) return false;
    return v.bpSystolic! >= 120 || v.bpDiastolic! >= 80;
  }

  Map<String, dynamic> _getBPStatus(Vital v) {
    if (v.bpSystolic == null || v.bpDiastolic == null) return const {'text': 'Stable', 'color': Colors.grey};
    final sys = v.bpSystolic!;
    final dia = v.bpDiastolic!;
    if (sys < 120 && dia < 80) return {'text': 'Normal', 'color': context.colors.success};
    if (sys < 130 && dia < 80) return {'text': 'Elevated', 'color': context.colors.warning};
    return {'text': 'Hypertension', 'color': context.colors.errorSos};
  }

  bool _isSugarAbnormal(Vital v) {
    if (v.bloodSugar == null) return false;
    final limit = v.sugarType == 'fasting' ? 100.0 : 140.0;
    return v.bloodSugar! >= limit;
  }

  Map<String, dynamic> _getSugarStatus(Vital v) {
    if (v.bloodSugar == null) return const {'text': 'Stable', 'color': Colors.grey};
    final val = v.bloodSugar!;
    final limit = v.sugarType == 'fasting' ? 100.0 : 140.0;
    if (val < limit) return {'text': 'Normal', 'color': context.colors.success};
    if (val < (limit + 25)) return {'text': 'Pre-Diabetic', 'color': context.colors.warning};
    return {'text': 'High Sugar', 'color': context.colors.errorSos};
  }

  bool _isHRAbnormal(Vital v) {
    if (v.heartRate == null) return false;
    return v.heartRate! > 100 || v.heartRate! < 60;
  }

  Map<String, dynamic> _getHRStatus(Vital v) {
    if (v.heartRate == null) return const {'text': 'Stable', 'color': Colors.grey};
    final val = v.heartRate!;
    if (val >= 60 && val <= 100) return {'text': 'Normal', 'color': context.colors.success};
    return {'text': 'Irregular', 'color': context.colors.errorSos};
  }

  bool _isSpO2Abnormal(Vital v) {
    if (v.spo2 == null) return false;
    return v.spo2! < 95;
  }

  Map<String, dynamic> _getSpO2Status(Vital v) {
    if (v.spo2 == null) return const {'text': 'Stable', 'color': Colors.grey};
    final val = v.spo2!;
    if (val >= 95) return {'text': 'Normal', 'color': context.colors.success};
    return {'text': 'Low Oxygen', 'color': context.colors.errorSos};
  }

  bool _isTempAbnormal(Vital v) {
    if (v.temperature == null) return false;
    return v.temperature! > 37.2 || v.temperature! < 36.0;
  }

  Map<String, dynamic> _getTempStatus(Vital v) {
    if (v.temperature == null) return const {'text': 'Stable', 'color': Colors.grey};
    final val = v.temperature!;
    if (val >= 36.0 && val <= 37.2) return {'text': 'Normal', 'color': context.colors.success};
    if (val > 37.2 && val <= 38.0) return {'text': 'Low Fever', 'color': context.colors.warning};
    return {'text': 'High Fever', 'color': context.colors.errorSos};
  }
}
