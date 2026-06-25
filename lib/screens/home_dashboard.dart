import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../providers/user_provider.dart';
import '../providers/vitals_provider.dart';
import '../providers/medicine_provider.dart';
import '../services/sos_service.dart';
import '../core/models.dart';
import '../widgets/animated_vital_cards.dart';
import 'symptom_diary.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

<<<<<<< HEAD
class _HomeDashboardState extends State<HomeDashboard> with SingleTickerProviderStateMixin {
=======
class _HomeDashboardState extends State<HomeDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
>>>>>>> b0efc377602ecaaacbc9044e3b7a858a3db563af
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

<<<<<<< HEAD
  @override
  void initState() {
    super.initState();
    
=======
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<DueDose> _localDueDoses = [];
  final Set<String> _takenDoseKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

>>>>>>> b0efc377602ecaaacbc9044e3b7a858a3db563af
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
<<<<<<< HEAD
    
=======

>>>>>>> b0efc377602ecaaacbc9044e3b7a858a3db563af
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );
<<<<<<< HEAD
    
=======

>>>>>>> b0efc377602ecaaacbc9044e3b7a858a3db563af
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
<<<<<<< HEAD
    _entranceController.dispose();
    super.dispose();
=======
    WidgetsBinding.instance.removeObserver(this);
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<MedicineProvider>(context, listen: false)
          .loadTodayDueMedicines();
    }
  }

  void _syncDueDoses(List<DueDose> newDoses) {
    bool needsUpdate = false;
    if (_localDueDoses.length != newDoses.length) {
      needsUpdate = true;
    } else {
      for (int i = 0; i < newDoses.length; i++) {
        if (_localDueDoses[i].medicineId != newDoses[i].medicineId ||
            _localDueDoses[i].scheduledTime != newDoses[i].scheduledTime) {
          needsUpdate = true;
          break;
        }
      }
    }

    if (!needsUpdate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_localDueDoses.isEmpty) {
        setState(() {
          _localDueDoses = List.from(newDoses);
        });
        for (int i = 0; i < newDoses.length; i++) {
          _listKey.currentState
              ?.insertItem(i, duration: const Duration(milliseconds: 200));
        }
        return;
      }

      // Remove items
      for (int i = _localDueDoses.length - 1; i >= 0; i--) {
        final item = _localDueDoses[i];
        final exists = newDoses.any((d) =>
            d.medicineId == item.medicineId &&
            d.scheduledTime == item.scheduledTime);
        if (!exists) {
          final removedItem = _localDueDoses[i];
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildDoseTile(
                context, removedItem, animation, i,
                isRemoving: true),
            duration: const Duration(milliseconds: 300),
          );
          setState(() {
            _localDueDoses.removeAt(i);
          });
        }
      }

      // Add items
      for (int i = 0; i < newDoses.length; i++) {
        final item = newDoses[i];
        final idx = _localDueDoses.indexWhere((d) =>
            d.medicineId == item.medicineId &&
            d.scheduledTime == item.scheduledTime);
        if (idx == -1) {
          setState(() {
            _localDueDoses.insert(i, item);
          });
          _listKey.currentState
              ?.insertItem(i, duration: const Duration(milliseconds: 200));
        }
      }
    });
>>>>>>> b0efc377602ecaaacbc9044e3b7a858a3db563af
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

    return FloatingNodesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: StaggeredEntry(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: MediTrackSpacing.screenHorizontalPadding,
                  top: 8,
                  bottom: 8),
              child: CircleAvatar(
                backgroundColor: context.colors.primaryLight,
                child: Text(
                  userInitials,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
<<<<<<< HEAD
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
=======
>>>>>>> b0efc377602ecaaacbc9044e3b7a858a3db563af
              ),
            ),
          ),
          title: StaggeredEntry(
            index: 1,
            child: Text(userGreeting, style: context.titleLarge),
          ),
          actions: [
            StaggeredEntry(
              index: 2,
              child: IconButton(
                icon: Badge(
                  label: const Text('2'),
                  isLabelVisible:
                      !hasLoggedToday, // Alert badge visible if today's vitals not logged
                  backgroundColor: context.colors.errorSos,
                  textColor: Colors.white,
                  child: Icon(Icons.notifications_outlined,
                      color: context.colors.textPrimary),
                ),
                onPressed: () {},
              ),
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
                  Icon(Icons.cloud_off,
                      size: 14, color: context.colors.primary),
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
                      padding: const EdgeInsets.all(
                          MediTrackSpacing.screenHorizontalPadding),
                      child: Builder(
                        builder: (context) {
                          final double screenWidth = MediaQuery.of(context).size.width;
                          final bool isWideScreen = screenWidth >= 900;

                          final Widget bannerWidget = Container(
                            margin: const EdgeInsets.only(
                                bottom: MediTrackSpacing.sectionGap),
                            height: isWideScreen ? 180 : 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(MediTrackRadius.cards),
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.shadowColor
                                      .withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(MediTrackRadius.cards),
                              child: Stack(
                                children: [
                                  // Background Banner Image
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/dashboard_banner.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Glassmorphic Frosted Overlay
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.15),
                                            Colors.white.withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Banner Text Info
                                  Positioned(
                                    left: 16,
                                    top: 0,
                                    bottom: 0,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: context.colors.primary
                                                .withOpacity(0.85),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.auto_awesome,
                                                  size: 10,
                                                  color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ANTI-GRAVITY MODE ACTIVE',
                                                style:
                                                    context.labelSmall.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Track Your Health in Real-Time',
                                          style: context.titleMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              const Shadow(
                                                color: Colors.black38,
                                                blurRadius: 4,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Coordinated dynamic metrics active',
                                          style: context.labelSmall.copyWith(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          final Widget vitalsWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                context: context,
                                title: "Today's Vitals",
                                actionText: "Log Now →",
                                onActionTap: () =>
                                    Navigator.pushNamed(context, '/vitals/log'),
                              ),
                              const SizedBox(
                                  height: MediTrackSpacing.titleToContentGap),
                              _buildVitalsHorizontalList(
                                  context, today, vitalsProvider),
                            ],
                          );

                          final Widget quickActionsWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: context.titleMedium,
                              ),
                              const SizedBox(
                                  height: MediTrackSpacing.titleToContentGap),
                              _buildQuickActionsGrid(context,
                                  crossAxisCount: isWideScreen ? 4 : 2),
                            ],
                          );

                          final Widget bpSparklineWidget = _buildBPSparklineCard(
                              context, vitalsProvider.vitals);

                          final Widget medicinesWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                context: context,
                                title: "Medicines Due Today",
                                actionText: "View All →",
                                onActionTap: () =>
                                    Navigator.pushNamed(context, '/medicines'),
                              ),
                              const SizedBox(
                                  height: MediTrackSpacing.titleToContentGap),
                              Consumer<MedicineProvider>(
                                builder: (context, medProv, child) {
                                  return _buildMedicinesList(context, medProv);
                                },
                              ),
                            ],
                          );

                          if (isWideScreen) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      bannerWidget,
                                      const SizedBox(height: MediTrackSpacing.large),
                                      vitalsWidget,
                                      const SizedBox(height: MediTrackSpacing.large),
                                      quickActionsWidget,
                                      const SizedBox(height: MediTrackSpacing.large),
                                      bpSparklineWidget,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: MediTrackSpacing.large),
                                Expanded(
                                  flex: 2,
                                  child: medicinesWidget,
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bannerWidget,
                              vitalsWidget,
                              const SizedBox(height: MediTrackSpacing.large),
                              medicinesWidget,
                              const SizedBox(height: MediTrackSpacing.large),
                              quickActionsWidget,
                              const SizedBox(height: MediTrackSpacing.large),
                              bpSparklineWidget,
                              const SizedBox(height: 80),
                            ],
                          );
                        },
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
              SosService.callEmergencyContact(context,
                  user.ecName ?? 'Emergency Contact', user.ecPhone ?? '');
            }
          },
          icon: const Icon(Icons.emergency, color: Colors.white),
          label: Text(
            'SOS',
            style: context.bodyMedium
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: context.colors.errorSos,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
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

  Widget _buildVitalsHorizontalList(
      BuildContext context, Vital? today, VitalsProvider vitalsProvider) {
    final successColor = context.colors.success;
    final warningColor = context.colors.warning;
    final errorColor = context.colors.errorSos;
    final greyColor = context.colors.textHint;

    // Status colors
    final bpStatusColor = today != null
        ? vitalsProvider.getBPSystolicColor(
            today.bpSystolic ?? 0, successColor, warningColor, errorColor)
        : greyColor;
    final sysColor = today != null
        ? vitalsProvider.getBPSystolicColor(
            today.bpSystolic ?? 0, successColor, warningColor, errorColor)
        : greyColor;
    final diaColor = today != null
        ? vitalsProvider.getBPDiastolicColor(
            today.bpDiastolic ?? 0, successColor, warningColor, errorColor)
        : greyColor;

    final sugarStatusColor = today != null
        ? vitalsProvider.getBloodSugarColor(
            today.bloodSugar ?? 0, successColor, warningColor, errorColor)
        : greyColor;
    final tempStatusColor = today != null
        ? vitalsProvider.getTemperatureColor(
            today.temperature ?? 0.0, successColor, warningColor, errorColor)
        : greyColor;
    final weightStatusColor = today != null ? successColor : greyColor;
    final spo2StatusColor = today != null
        ? vitalsProvider.getSpO2Color(
            today.spo2 ?? 0, successColor, warningColor, errorColor)
        : greyColor;
    final hrStatusColor = today != null
        ? vitalsProvider.getHeartRateColor(
            today.heartRate ?? 0, successColor, warningColor, errorColor)
        : greyColor;

    // Retrieve previous weight
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double? prevWeight;
    for (var v in vitalsProvider.vitals) {
      if (v.date != todayStr && v.weight != null) {
        prevWeight = v.weight;
        break;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 1. Blood Pressure Card
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vitals/log'),
            child: BPVitalCard(
              systolic: today?.bpSystolic,
              diastolic: today?.bpDiastolic,
              statusColor: bpStatusColor,
              sysColor: sysColor,
              diaColor: diaColor,
            ),
          ),
          // 2. Blood Sugar Card
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vitals/log'),
            child: BloodSugarVitalCard(
              sugar: today?.bloodSugar,
              type: today?.sugarType,
              vitalsHistory: vitalsProvider.vitals,
              statusColor: sugarStatusColor,
            ),
          ),
          // 3. Temperature Card
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vitals/log'),
            child: TemperatureVitalCard(
              temp: today?.temperature,
              statusColor: tempStatusColor,
            ),
          ),
          // 4. Weight Card
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vitals/log'),
            child: WeightVitalCard(
              weight: today?.weight,
              prevWeight: prevWeight,
              statusColor: weightStatusColor,
            ),
          ),
          // 5. SpO2 Card
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vitals/log'),
            child: SpO2VitalCard(
              spo2: today?.spo2,
              statusColor: spo2StatusColor,
            ),
          ),
          // 6. Heart Rate Card
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vitals/log'),
            child: HeartRateVitalCard(
              heartRate: today?.heartRate,
              statusColor: hrStatusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesList(BuildContext context, MedicineProvider provider) {
    if (provider.medicines.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('No active medicines', style: context.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/medicines'),
                child: const Text('Go to Medicines →'),
              ),
            ],
          ),
        ),
      );
    }

    // Sync provider list with animated list local copy
    _syncDueDoses(provider.todayDueMedicines);

    if (_localDueDoses.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: context.colors.success, size: 20),
              const SizedBox(width: 8),
              Text('All doses done for now 🎉',
                  style:
                      context.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _localDueDoses.length,
      itemBuilder: (context, index, animation) {
        if (index >= _localDueDoses.length) return const SizedBox.shrink();
        final dose = _localDueDoses[index];
        return _buildDoseTile(context, dose, animation, index);
      },
    );
  }

  Widget _buildDoseTile(BuildContext context, DueDose dose,
      Animation<double> animation, int index,
      {bool isRemoving = false}) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildDoseCard(context, dose, index, isRemoving),
      ),
    );
  }

  Widget _buildDoseCard(
      BuildContext context, DueDose dose, int index, bool isRemoving) {
    // Left border strip color logic
    bool isNeutral = false;
    try {
      final now = DateTime.now();
      final parts = dose.scheduledTime.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      final sched = DateTime(now.year, now.month, now.day, hour, min);
      if (sched.difference(now).inMinutes > 60) {
        isNeutral = true;
      }
    } catch (_) {}

    Color stripColor = isNeutral
        ? context.colors.dividerColor
        : (dose.isOverdue ? context.colors.errorSos : context.colors.success);

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

    final key = '${dose.medicineId}-${dose.scheduledTime}';
    final isLoggedTaken = _takenDoseKeys.contains(key);

    return OverduePulsingCard(
      isOverdue: dose.isOverdue,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left strip indicator
            Container(
              width: 4,
              color: stripColor,
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
                    dose.medicineName,
                    style: context.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${dose.dosage.toInt()}${dose.unit} • ${dose.scheduledTime}',
                    style: context.bodySmall,
                  ),
                ],
              ),
            ),
            // Actions
            if (!isRemoving)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Taken Button
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isLoggedTaken
                          ? const Icon(Icons.check,
                              color: Colors.white, key: ValueKey('done'))
                          : Icon(Icons.check_circle_outline,
                              color: context.colors.success,
                              key: ValueKey('todo')),
                    ),
                    tooltip: 'Taken',
                    style: IconButton.styleFrom(
                      backgroundColor: isLoggedTaken
                          ? context.colors.success
                          : context.colors.successLight,
                    ),
                    onPressed: isLoggedTaken
                        ? null
                        : () async {
                            setState(() {
                              _takenDoseKeys.add(key);
                            });
                            await Future.delayed(
                                const Duration(milliseconds: 300));
                            if (!mounted) return;
                            final provider = Provider.of<MedicineProvider>(
                                context,
                                listen: false);
                            await provider.logDose(
                                dose.medicineId, dose.scheduledTime, 'taken');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('✓ Marked as taken')),
                            );
                          },
                  ),
                  const SizedBox(width: 4),
                  // Snooze Button
                  IconButton(
                    icon: Icon(Icons.snooze, color: context.colors.warning),
                    tooltip: 'Snooze',
                    style: IconButton.styleFrom(
                        backgroundColor: context.colors.warningLight),
                    onPressed: isLoggedTaken
                        ? null
                        : () async {
                            final provider = Provider.of<MedicineProvider>(
                                context,
                                listen: false);
                            await provider.logDose(
                                dose.medicineId, dose.scheduledTime, 'snoozed');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Snoozed ${dose.medicineName} reminder for 15 minutes.')),
                            );
                          },
                  ),
                  const SizedBox(width: 4),
                  // Skip Button
                  IconButton(
                    icon: Icon(Icons.cancel_outlined,
                        color: context.colors.errorSos),
                    tooltip: 'Skip',
                    style: IconButton.styleFrom(
                        side: BorderSide(
                            color: context.colors.errorSos, width: 1)),
                    onPressed: isLoggedTaken
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: context.colors.card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      MediTrackRadius.cards),
                                  side: BorderSide(
                                      color: context.colors.dividerColor,
                                      width: 0.8),
                                ),
                                title: const Text('Skip Dose?'),
                                content: Text(
                                    'Are you sure you want to skip ${dose.medicineName} scheduled for ${dose.scheduledTime}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel',
                                        style: TextStyle(
                                            color:
                                                context.colors.textSecondary)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final provider =
                                          Provider.of<MedicineProvider>(context,
                                              listen: false);
                                      await provider.logDose(dose.medicineId,
                                          dose.scheduledTime, 'skipped');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Skipped ${dose.medicineName} dose.')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            context.colors.errorSos),
                                    child: const Text('Skip',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
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
  }

  Widget _buildQuickActionsGrid(BuildContext context, {int crossAxisCount = 2}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: crossAxisCount == 4 ? 2.0 : 1.5,
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
          onTap: () => SymptomDiaryScreen.showAddSymptomBottomSheet(context,
              Provider.of<VitalsProvider>(context, listen: false).vitals),
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
    final bpLogs = logs
        .where((v) => v.bpSystolic != null && v.bpDiastolic != null)
        .take(7)
        .toList()
        .reversed
        .toList();

    double avgSys = 0;
    double avgDia = 0;
    if (bpLogs.isNotEmpty) {
      avgSys = bpLogs.map((l) => l.bpSystolic!).reduce((a, b) => a + b) /
          bpLogs.length;
      avgDia = bpLogs.map((l) => l.bpDiastolic!).reduce((a, b) => a + b) /
          bpLogs.length;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(
            MediTrackSpacing.cardInternalPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blood Pressure — Last 7 Days',
                  style:
                      context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/analytics'),
                  child: Text('View All →',
                      style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: MediTrackSpacing.medium),
            if (bpLogs.isEmpty)
              SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'No BP logs to display.',
                    style: context.bodySmall
                        .copyWith(color: context.colors.textSecondary),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 140,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOutCubic,
                  builder: (context, drawProgress, child) {
                    final double maxVisibleX =
                        (bpLogs.length - 1) * drawProgress;

                    List<FlSpot> getAnimatedSpots(List<FlSpot> fullSpots) {
                      if (fullSpots.isEmpty) return [];
                      final animated = <FlSpot>[];
                      for (final spot in fullSpots) {
                        if (spot.x <= maxVisibleX) {
                          animated.add(spot);
                        } else {
                          int prevIdx = spot.x.floor();
                          int nextIdx = spot.x.ceil();
                          if (prevIdx < fullSpots.length &&
                              nextIdx < fullSpots.length &&
                              prevIdx != nextIdx) {
                            double t =
                                (maxVisibleX - prevIdx) / (nextIdx - prevIdx);
                            if (t >= 0 && t <= 1) {
                              double interpolatedY = fullSpots[prevIdx].y +
                                  (fullSpots[nextIdx].y -
                                          fullSpots[prevIdx].y) *
                                      t;
                              animated.add(FlSpot(maxVisibleX, interpolatedY));
                            }
                          }
                          break;
                        }
                      }
                      if (animated.isEmpty) {
                        animated.add(fullSpots.first);
                      }
                      return animated;
                    }

                    final systolicSpots =
                        getAnimatedSpots(List.generate(bpLogs.length, (idx) {
                      return FlSpot(idx.toDouble(), bpLogs[idx].bpSystolic!);
                    }));

                    final diastolicSpots =
                        getAnimatedSpots(List.generate(bpLogs.length, (idx) {
                      return FlSpot(idx.toDouble(), bpLogs[idx].bpDiastolic!);
                    }));

                    return LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < bpLogs.length) {
                                  try {
                                    final parsedDate =
                                        DateTime.parse(bpLogs[idx].date);
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 4,
                                      child: Text(
                                        DateFormat('dd/MM').format(parsedDate),
                                        style: context.labelSmall.copyWith(
                                            fontSize: 8,
                                            color:
                                                context.colors.textSecondary),
                                      ),
                                    );
                                  } catch (_) {}
                                }
                                return const SizedBox();
                              },
                              reservedSize: 16,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) =>
                                context.colors.primary.withOpacity(0.95),
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final isSystolic = spot.barIndex == 0;
                                final title = isSystolic ? 'Sys' : 'Dia';
                                return LineTooltipItem(
                                  '$title: ${spot.y.toInt()} mmHg',
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10),
                                );
                              }).toList();
                            },
                          ),
                          getTouchedSpotIndicator: (LineChartBarData barData,
                              List<int> spotIndexes) {
                            return spotIndexes.map((index) {
                              return TouchedSpotIndicatorData(
                                FlLine(
                                  color:
                                      context.colors.primary.withOpacity(0.4),
                                  strokeWidth: 1.5,
                                  dashArray: [4, 4],
                                ),
                                FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 6,
                                      color: context.colors.primary,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                              );
                            }).toList();
                          },
                          handleBuiltInTouches: true,
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: 120,
                              color: context.colors.warning.withOpacity(0.6),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                style: context.labelSmall.copyWith(
                                    color: context.colors.warning,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                                labelResolver: (line) => '120 Ceiling',
                              ),
                            ),
                            HorizontalLine(
                              y: 80,
                              color: context.colors.success.withOpacity(0.6),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.bottomRight,
                                style: context.labelSmall.copyWith(
                                    color: context.colors.success,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                                labelResolver: (line) => '80 Floor',
                              ),
                            ),
                          ],
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: systolicSpots,
                            isCurved: true,
                            color: context.colors.primary,
                            barWidth: 3.5,
                            dotData: const FlDotData(show: true),
                          ),
                          LineChartBarData(
                            spots: diastolicSpots,
                            isCurved: true,
                            color: context.colors.accent,
                            barWidth: 3.5,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Legend and Average summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Systolic (Avg: ${avgSys.round()} mmHg)',
                        style: context.labelSmall.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Dashed line representation
                      Row(
                        children: List.generate(
                            3,
                            (i) => Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5),
                                  decoration: BoxDecoration(
                                    color: context.colors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                )),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Diastolic (Avg: ${avgDia.round()} mmHg)',
                        style: context.labelSmall.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FloatingNodesBackground extends StatefulWidget {
  final Widget child;
  const FloatingNodesBackground({super.key, required this.child});

  @override
  State<FloatingNodesBackground> createState() =>
      _FloatingNodesBackgroundState();
}

class _FloatingNodesBackgroundState extends State<FloatingNodesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _velocities = [];
  final List<Offset> _positions = [];
  final List<double> _radii = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _positions.add(Offset(_random.nextDouble(), _random.nextDouble()));
      _velocities.add(Offset((_random.nextDouble() - 0.5) * 0.08,
          (_random.nextDouble() - 0.5) * 0.08));
      _radii.add(_random.nextDouble() * 100 + 150);
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParallaxNodesPainter(
            positions: _positions,
            velocities: _velocities,
            radii: _radii,
            progress: _controller.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ParallaxNodesPainter extends CustomPainter {
  final List<Offset> positions;
  final List<Offset> velocities;
  final List<double> radii;
  final double progress;

  ParallaxNodesPainter({
    required this.positions,
    required this.velocities,
    required this.radii,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid light Ice Blue canvas (#E0F7FA)
    final bgPaint = Paint()..color = const Color(0xFFE0F7FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw soft floating gradient nodes using non-linear physics path
    for (int i = 0; i < positions.length; i++) {
      final double dx = (positions[i].dx +
              velocities[i].dx * math.sin(progress * 2 * math.pi)) *
          size.width;
      final double dy = (positions[i].dy +
              velocities[i].dy * math.cos(progress * 2 * math.pi)) *
          size.height;
      final center =
          Offset(dx.clamp(0.0, size.width), dy.clamp(0.0, size.height));

      final radius = radii[i];
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x280D9488), // Primary teal with opacity
            const Color(0x0C10B981), // Accent green with very low opacity
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParallaxNodesPainter oldDelegate) => true;
}

class StaggeredEntry extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggeredEntry({super.key, required this.index, required this.child});

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) {
        _controller.forward();
      }
    });

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(curve);
    _translateY = Tween<double>(begin: -15.0, end: 0.0).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: widget.child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class OverduePulsingCard extends StatefulWidget {
  final Widget child;
  final bool isOverdue;
  const OverduePulsingCard(
      {super.key, required this.child, required this.isOverdue});

  @override
  State<OverduePulsingCard> createState() => _OverduePulsingCardState();
}

class _OverduePulsingCardState extends State<OverduePulsingCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Color?>? _colorAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isOverdue) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant OverduePulsingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOverdue && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
    } else if (!widget.isOverdue && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOverdue || _controller == null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      );
    }

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: context.colors.errorLight.withOpacity(0.5),
    ).animate(_controller!);

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        return Card(
          color: _colorAnimation!.value,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        );
      },
    );
  }
}
