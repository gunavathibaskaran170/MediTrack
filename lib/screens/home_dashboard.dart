import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/meditrack_theme.dart';
import '../providers/user_provider.dart';
import '../providers/vitals_provider.dart';
import '../providers/medicine_provider.dart';
import '../services/sos_service.dart';
import '../core/models.dart';
import 'symptom_diary.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    // Fetch latest states
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
      Provider.of<VitalsProvider>(context, listen: false).loadTodayVitals();
      Provider.of<VitalsProvider>(context, listen: false).loadVitals();
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'JD';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getFirstName(String name) {
    if (name.isEmpty) return 'User';
    return name.split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final vitalsProvider = Provider.of<VitalsProvider>(context);
    final medicineProvider = Provider.of<MedicineProvider>(context);

    final user = userProvider.currentUser;
    final today = vitalsProvider.todayVitals;

    final userName = user?.name ?? 'John Doe';
    final userInitials = _getInitials(userName);
    final userGreeting = 'Good Morning, ${_getFirstName(userName)}';

    // Check if daily vitals are logged for notification check
    final hasLoggedToday = today != null;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: MediTrackSpacing.screenHorizontalPadding, top: 8, bottom: 8),
          child: CircleAvatar(
            backgroundColor: context.colors.primaryLight,
            child: Text(
              userInitials,
              style: context.bodyMedium.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(userGreeting, style: context.titleLarge),
        actions: [
          IconButton(
            icon: Badge(
              label: const Text('2'),
              isLabelVisible: !hasLoggedToday, // Alert badge visible if today's vitals not logged
              backgroundColor: context.colors.errorSos,
              textColor: Colors.white,
              child: Icon(Icons.notifications_outlined, color: context.colors.textPrimary),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: Column(
        children: [
          // Offline Banner
          Container(
            height: 34,
            width: double.infinity,
            color: context.colors.primaryLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 14, color: context.colors.primary),
                const SizedBox(width: MediTrackSpacing.iconToTextGap),
                Text(
                  'Data saved offline on your device',
                  style: context.labelSmall.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await userProvider.loadUser();
                    await vitalsProvider.loadTodayVitals();
                    await vitalsProvider.loadVitals();
                    await medicineProvider.loadMedicines();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1 - Today's Vitals
                        _buildSectionHeader(
                          context: context,
                          title: "Today's Vitals",
                          actionText: "Log Now →",
                          onActionTap: () => Navigator.pushNamed(context, '/vitals/log'),
                        ),
                        const SizedBox(height: MediTrackSpacing.titleToContentGap),
                        _buildVitalsHorizontalList(context, today, vitalsProvider),
                        const SizedBox(height: MediTrackSpacing.large),

                        // Section 2 - Medicines Due Today
                        _buildSectionHeader(
                          context: context,
                          title: "Medicines Due Today",
                          actionText: "View All →",
                          onActionTap: () => Navigator.pushNamed(context, '/medicines'),
                        ),
                        const SizedBox(height: MediTrackSpacing.titleToContentGap),
                        _buildMedicinesList(context, medicineProvider),
                        const SizedBox(height: MediTrackSpacing.large),

                        // Section 3 - Quick Actions
                        Text(
                          'Quick Actions',
                          style: context.titleMedium,
                        ),
                        const SizedBox(height: MediTrackSpacing.titleToContentGap),
                        _buildQuickActionsGrid(context),
                        const SizedBox(height: MediTrackSpacing.large),

                        // Section 4 - BP Sparkline
                        _buildBPSparklineCard(context, vitalsProvider.vitals),
                        const SizedBox(height: 80), // padding for bottom SOS FAB
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (user != null) {
            SosService.callEmergencyContact(context, user.ecName ?? 'Emergency Contact', user.ecPhone ?? '');
          }
        },
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: Text(
          'SOS',
          style: context.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.colors.errorSos,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: context.titleMedium,
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionText,
            style: context.bodyMedium.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsHorizontalList(BuildContext context, Vital? today, VitalsProvider provider) {
    final bpText = (today?.bpSystolic != null && today?.bpDiastolic != null)
        ? '${today!.bpSystolic!.toInt()}/${today.bpDiastolic!.toInt()}'
        : '--';
    final sugarText = today?.bloodSugar != null ? '${today!.bloodSugar!.toInt()}' : '--';
    final tempText = today?.temperature != null ? today!.temperature!.toStringAsFixed(1) : '--';
    final weightText = today?.weight != null ? today!.weight!.toStringAsFixed(1) : '--';
    final spo2Text = today?.spo2 != null ? '${today!.spo2!.toInt()}' : '--';
    final hrText = today?.heartRate != null ? '${today!.heartRate!.toInt()}' : '--';

    // Colors mapping based on readings status
    final successColor = context.colors.success;
    final warningColor = context.colors.warning;
    final errorColor = context.colors.errorSos;
    final greyColor = context.colors.textHint;

    final bpColor = today != null
        ? provider.getBPSystolicColor(today.bpSystolic ?? 0, successColor, warningColor, errorColor)
        : greyColor;
    final sugarColor = today != null
        ? provider.getBloodSugarColor(today.bloodSugar ?? 0, successColor, warningColor, errorColor)
        : greyColor;
    final tempColor = today != null
        ? provider.getTemperatureColor(today.temperature ?? 0.0, successColor, warningColor, errorColor)
        : greyColor;
    final weightColor = today != null ? successColor : greyColor;
    final spo2Color = today != null
        ? provider.getSpO2Color(today.spo2 ?? 0, successColor, warningColor, errorColor)
        : greyColor;
    final hrColor = today != null
        ? provider.getHeartRateColor(today.heartRate ?? 0, successColor, warningColor, errorColor)
        : greyColor;

    final List<Map<String, dynamic>> vitals = [
      {'icon': Icons.favorite, 'label': 'Blood Pressure', 'value': bpText, 'statusColor': bpColor},
      {'icon': Icons.water_drop, 'label': 'Blood Sugar', 'value': sugarText, 'statusColor': sugarColor},
      {'icon': Icons.thermostat, 'label': 'Temperature', 'value': tempText, 'statusColor': tempColor},
      {'icon': Icons.monitor_weight_outlined, 'label': 'Weight', 'value': weightText, 'statusColor': weightColor},
      {'icon': Icons.air, 'label': 'SpO2', 'value': spo2Text, 'statusColor': spo2Color},
      {'icon': Icons.speed, 'label': 'Heart Rate', 'value': hrText, 'statusColor': hrColor},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: vitals.map((vital) {
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vitals/log'),
            child: Container(
              width: 110,
              height: 90,
              margin: const EdgeInsets.only(right: 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(vital['icon'] as IconData, size: 18, color: context.colors.primary),
                          Text(
                            vital['label'] as String,
                            style: context.labelSmall.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            vital['value'] as String,
                            style: context.vitalValue.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: vital['statusColor'] as Color,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicinesList(BuildContext context, MedicineProvider provider) {
    // Show active medicines
    final activeMeds = provider.todayMedicines.take(3).toList();

    if (activeMeds.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No medicines scheduled for today.',
              style: context.bodySmall,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeMeds.length,
      itemBuilder: (context, index) {
        final med = activeMeds[index];

        // Mappings for color rotation
        Color iconBg;
        Color iconColor;
        int cycle = index % 3;
        if (cycle == 0) {
          iconBg = context.colors.primaryLight;
          iconColor = context.colors.primary;
        } else if (cycle == 1) {
          iconBg = context.colors.accentLight;
          iconColor = context.colors.accent;
        } else {
          iconBg = context.colors.warningLight;
          iconColor = context.colors.warning;
        }

        // Display scheduled time
        final timeStr = med.reminderTimes.isNotEmpty ? med.reminderTimes.first : '08:00';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 4px left strip indicator
                Container(
                  width: 4,
                  color: context.colors.accent,
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.medication, size: 20, color: iconColor),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${med.dosage?.toInt() ?? 500}${med.unit ?? "mg"} • $timeStr',
                        style: context.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check_circle_outline, color: context.colors.success),
                      tooltip: 'Taken',
                      style: IconButton.styleFrom(backgroundColor: context.colors.successLight),
                      onPressed: () {
                        provider.logDose(med.id ?? 1, timeStr, 'taken');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logged ${med.name} dose as taken.')),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.snooze, color: context.colors.warning),
                      tooltip: 'Snooze',
                      style: IconButton.styleFrom(backgroundColor: context.colors.warningLight),
                      onPressed: () {
                        provider.logDose(med.id ?? 1, timeStr, 'snoozed');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Snoozed ${med.name} reminder for 15 minutes.')),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.cancel_outlined, color: context.colors.errorSos),
                      tooltip: 'Skip',
                      style: IconButton.styleFrom(side: BorderSide(color: context.colors.errorSos, width: 1)),
                      onPressed: () {
                        provider.logDose(med.id ?? 1, timeStr, 'skipped');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Skipped ${med.name} dose.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: MediTrackSpacing.listItemGap,
      crossAxisSpacing: MediTrackSpacing.listItemGap,
      children: [
        _buildQuickActionCell(
          context: context,
          icon: Icons.favorite_border,
          label: "Log Vitals",
          iconBg: context.colors.primaryLight,
          iconColor: context.colors.primary,
          onTap: () => Navigator.pushNamed(context, '/vitals/log'),
        ),
        _buildQuickActionCell(
          context: context,
          icon: Icons.sick_outlined,
          label: "Add Symptom",
          iconBg: context.colors.accentLight,
          iconColor: context.colors.accent,
          onTap: () => SymptomDiaryScreen.showAddSymptomBottomSheet(context),
        ),
        _buildQuickActionCell(
          context: context,
          icon: Icons.local_hospital_outlined,
          label: "Doctor Visit",
          iconBg: context.colors.primaryLight,
          iconColor: context.colors.primary,
          onTap: () => Navigator.pushNamed(context, '/doctor-visits'),
        ),
        _buildQuickActionCell(
          context: context,
          icon: Icons.picture_as_pdf_outlined,
          label: "Generate Report",
          iconBg: context.colors.accentLight,
          iconColor: context.colors.accent,
          onTap: () => Navigator.pushNamed(context, '/reports'),
        ),
      ],
    );
  }

  Widget _buildQuickActionCell({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MediTrackRadius.cards),
        splashColor: context.colors.primaryLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: MediTrackSpacing.titleToContentGap),
            Text(
              label,
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBPSparklineCard(BuildContext context, List<Vital> logs) {
    // Filter out vitals that actually have blood pressure logged
    final bpLogs = logs.where((v) => v.bpSystolic != null && v.bpDiastolic != null).take(7).toList().reversed.toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blood Pressure — Last 7 Days',
                  style: context.titleMedium,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/analytics'),
                  child: Text('View All →', style: TextStyle(color: context.colors.primary)),
                ),
              ],
            ),
            const SizedBox(height: MediTrackSpacing.medium),
            if (bpLogs.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'No BP logs to display.',
                    style: context.bodySmall,
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 120,
                          color: context.colors.warning,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        )
                      ],
                    ),
                    lineBarsData: [
                      // Systolic
                      LineChartBarData(
                        spots: List.generate(bpLogs.length, (idx) {
                          return FlSpot(idx.toDouble(), bpLogs[idx].bpSystolic!);
                        }),
                        isCurved: true,
                        color: context.colors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                      // Diastolic
                      LineChartBarData(
                        spots: List.generate(bpLogs.length, (idx) {
                          return FlSpot(idx.toDouble(), bpLogs[idx].bpDiastolic!);
                        }),
                        isCurved: true,
                        color: context.colors.accent,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
