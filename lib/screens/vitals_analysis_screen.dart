import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../providers/vitals_provider.dart';
import '../providers/user_provider.dart';
import '../core/models.dart';
import '../widgets/animated_vital_cards.dart';

class VitalsAnalysisScreen extends StatefulWidget {
  const VitalsAnalysisScreen({super.key});

  @override
  State<VitalsAnalysisScreen> createState() => _VitalsAnalysisScreenState();
}

class _VitalsAnalysisScreenState extends State<VitalsAnalysisScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VitalsProvider>(context, listen: false).loadVitals();
      Provider.of<UserProvider>(context, listen: false).loadUser();
    });
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

  @override
  Widget build(BuildContext context) {
    final vitalsProvider = Provider.of<VitalsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final current = vitalsProvider.latestCheckup;
    final previous = vitalsProvider.previousCheckup;
    final user = userProvider.currentUser;

    final hasCheckup = current != null;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Vitals Analysis', style: context.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Health Summary',
            onPressed: () => Navigator.pushNamed(context, '/reports'),
          ),
          const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: vitalsProvider.isLoading && !hasCheckup
          ? const Center(child: CircularProgressIndicator())
          : !hasCheckup
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    await vitalsProvider.loadVitals();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Patient Profile Info Banner
                        _buildPatientProfileBanner(context, user),
                        const SizedBox(height: MediTrackSpacing.sectionGap),

                        // 2. Health Status Overview Banner (Compliment vs Focus alert)
                        _buildHealthOverviewBanner(context, current),
                        const SizedBox(height: MediTrackSpacing.sectionGap),

                        // 3. Grid of Interactive Cards
                        _buildInteractiveVitalsGrid(context, current, previous, vitalsProvider),
                        const SizedBox(height: MediTrackSpacing.sectionGap),

                        // 4. Quick Actions (Print Summary)
                        _buildActionsCard(context),
                      ],
                    ),
                  ),
                ),
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
            // Sync checkup button
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
      childAspectRatio: 1.25,
      children: [
        // Card 1: Blood Pressure
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
          animationWidget: BPDoubleRingGauge(
            systolic: current.bpSystolic ?? 120.0,
            diastolic: current.bpDiastolic ?? 80.0,
            sysColor: context.colors.primary,
            diaColor: context.colors.accent,
          ),
        ),

        // Card 2: Blood Sugar
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
          animationWidget: BloodSugarBeakerAnimation(
            sugar: current.bloodSugar ?? 94.0,
            color: context.colors.warning,
          ),
        ),

        // Card 3: Heart Rate
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
          animationWidget: HeartRatePulseAnimation(
            bpm: current.heartRate ?? 72.0,
            color: context.colors.errorSos,
          ),
        ),

        // Card 4: Blood Oxygen (SpO2)
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
          animationWidget: OxygenSatAnimation(
            spo2: current.spo2 ?? 98.0,
            color: Colors.teal,
          ),
        ),

        // Card 5: Temperature
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
          animationWidget: TemperatureMercuryAnimation(
            temp: current.temperature ?? 36.6,
            color: Colors.orange,
          ),
        ),

        // Card 6: Weight
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
          animationWidget: WeightScaleDialAnimation(
            weight: current.weight ?? 70.0,
            color: Colors.blueGrey,
          ),
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
    required Widget animationWidget,
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
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(currentVal, style: context.vitalValue.copyWith(fontSize: 26, color: color)),
                              const SizedBox(width: 4),
                              Text(unit, style: context.vitalUnit),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prevVal != null ? 'Prev: $prevVal $unit' : 'Prev: --',
                            style: context.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: animationWidget,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MediTrackRadius.cards),
        side: BorderSide(color: context.colors.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Medical Records & Printing', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Instead of checking every time in the hospital, you can export a clean, certified PDF summary of your health stats and vitals to keep for emergency situations.',
              style: context.bodySmall.copyWith(height: 1.3),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MediTrackRadius.buttons),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generate & Print Health Summary (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pushNamed(context, '/reports');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_heart_outlined, size: 80, color: context.colors.textHint),
            const SizedBox(height: 16),
            Text('No Checkup Data Available', style: context.titleLarge.copyWith(color: context.colors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Run the mock.py Python emulator to broadcast and insert live checkup vitals into the database.',
              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
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
    if (v.bpSystolic == null || v.bpDiastolic == null) return {'text': 'Stable', 'color': Colors.grey};
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
    if (v.bloodSugar == null) return {'text': 'Stable', 'color': Colors.grey};
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
    if (v.heartRate == null) return {'text': 'Stable', 'color': Colors.grey};
    final val = v.heartRate!;
    if (val >= 60 && val <= 100) return {'text': 'Normal', 'color': context.colors.success};
    return {'text': 'Irregular', 'color': context.colors.errorSos};
  }

  bool _isSpO2Abnormal(Vital v) {
    if (v.spo2 == null) return false;
    return v.spo2! < 95;
  }

  Map<String, dynamic> _getSpO2Status(Vital v) {
    if (v.spo2 == null) return {'text': 'Stable', 'color': Colors.grey};
    final val = v.spo2!;
    if (val >= 95) return {'text': 'Normal', 'color': context.colors.success};
    return {'text': 'Low Oxygen', 'color': context.colors.errorSos};
  }

  bool _isTempAbnormal(Vital v) {
    if (v.temperature == null) return false;
    return v.temperature! > 37.2 || v.temperature! < 36.0;
  }

  Map<String, dynamic> _getTempStatus(Vital v) {
    if (v.temperature == null) return {'text': 'Stable', 'color': Colors.grey};
    final val = v.temperature!;
    if (val >= 36.0 && val <= 37.2) return {'text': 'Normal', 'color': context.colors.success};
    if (val > 37.2 && val <= 38.0) return {'text': 'Low Fever', 'color': context.colors.warning};
    return {'text': 'High Fever', 'color': context.colors.errorSos};
  }
}
