import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/vitals_providers.dart';
import '../widgets/vital_card.dart';
import 'vitals_history_screen.dart';
import 'add_edit_vital_screen.dart';
import '../../domain/entities/vital_types.dart';

/// The main dashboard screen for the Vitals Tracking Module.
class VitalsDashboardScreen extends ConsumerWidget {
  static const String routeName = '/vitals-dashboard';

  const VitalsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayVitalsAsync = ref.watch(todayVitalsProvider);
    
    // Watch latest historical entries to display on the summary cards
    final bpList = ref.watch(watchBloodPressureProvider).value ?? [];
    final sugarList = ref.watch(watchBloodSugarProvider).value ?? [];
    final tempList = ref.watch(watchTemperatureProvider).value ?? [];
    final weightList = ref.watch(watchWeightProvider).value ?? [];
    final spo2List = ref.watch(watchSpO2Provider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vitals', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          // Background Sync Status Button
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Local Cache',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing with cloud...'), duration: Duration(seconds: 1)),
              );
              await ref.read(vitalsActionNotifierProvider.notifier).sync();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(vitalsActionNotifierProvider.notifier).sync();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sync Queue Warning Banner if offline pending items exist
              const _SyncQueueBanner(),

              // 2. Summary Grid Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Latest Measurements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              // 3. Grid of Vitals Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                childAspectRatio: 1.15,
                children: [
                  _VitalSummaryGridCard(
                    title: 'Blood Pressure',
                    icon: Icons.favorite,
                    iconColor: const Color(0xFFE57373),
                    value: bpList.isNotEmpty ? '${bpList.first.systolic}/${bpList.first.diastolic}' : '--',
                    subtitle: bpList.isNotEmpty ? bpList.first.classification.displayName : 'No records',
                    unit: ' mmHg',
                    onTap: () => Navigator.pushNamed(
                      context,
                      VitalsHistoryScreen.routeName,
                      arguments: VitalType.bloodPressure,
                    ),
                  ),
                  _VitalSummaryGridCard(
                    title: 'Blood Sugar',
                    icon: Icons.bloodtype,
                    iconColor: const Color(0xFF64B5F6),
                    value: sugarList.isNotEmpty ? sugarList.first.value.toStringAsFixed(0) : '--',
                    subtitle: sugarList.isNotEmpty ? sugarList.first.classification.displayName : 'No records',
                    unit: ' mg/dL',
                    onTap: () => Navigator.pushNamed(
                      context,
                      VitalsHistoryScreen.routeName,
                      arguments: VitalType.bloodSugar,
                    ),
                  ),
                  _VitalSummaryGridCard(
                    title: 'Temperature',
                    icon: Icons.thermostat,
                    iconColor: const Color(0xFFFFB74D),
                    value: tempList.isNotEmpty ? tempList.first.value.toStringAsFixed(1) : '--',
                    subtitle: tempList.isNotEmpty ? tempList.first.classification.displayName : 'No records',
                    unit: tempList.isNotEmpty ? tempList.first.unit.displayName : ' °C',
                    onTap: () => Navigator.pushNamed(
                      context,
                      VitalsHistoryScreen.routeName,
                      arguments: VitalType.temperature,
                    ),
                  ),
                  _VitalSummaryGridCard(
                    title: 'Weight',
                    icon: Icons.monitor_weight,
                    iconColor: const Color(0xFF81C784),
                    value: weightList.isNotEmpty ? weightList.first.value.toStringAsFixed(1) : '--',
                    subtitle: weightList.isNotEmpty ? 'Last tracked' : 'No records',
                    unit: weightList.isNotEmpty ? ' ${weightList.first.unit.displayName}' : ' kg',
                    onTap: () => Navigator.pushNamed(
                      context,
                      VitalsHistoryScreen.routeName,
                      arguments: VitalType.weight,
                    ),
                  ),
                  _VitalSummaryGridCard(
                    title: 'Oxygen (SpO₂)',
                    icon: Icons.bubble_chart,
                    iconColor: const Color(0xFF4DB6AC),
                    value: spo2List.isNotEmpty ? '${spo2List.first.percentage}' : '--',
                    subtitle: spo2List.isNotEmpty ? spo2List.first.classification.displayName : 'No records',
                    unit: '%',
                    onTap: () => Navigator.pushNamed(
                      context,
                      VitalsHistoryScreen.routeName,
                      arguments: VitalType.spo2,
                    ),
                  ),
                  // Quick Analytics navigation card
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // Navigate to generic history with defaults
                        Navigator.pushNamed(
                          context,
                          VitalsHistoryScreen.routeName,
                          arguments: VitalType.bloodPressure,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'View History',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Charts & Trends',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Today's Daily Logs Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "Today's Health Logs",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              todayVitalsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('Error loading today\'s logs: $err'),
                  ),
                ),
                data: (todayState) {
                  if (todayState.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Flatten all today's logs into a single chronological list
                  final List<Object> allTodayRecords = [
                    ...todayState.bp,
                    ...todayState.sugar,
                    ...todayState.temp,
                    ...todayState.weight,
                    ...todayState.spo2,
                  ];

                  // Sort descending by timestamp
                  allTodayRecords.sort((a, b) {
                    DateTime getTimestamp(Object obj) {
                      if (obj is BloodPressureEntity) return obj.timestamp;
                      if (obj is BloodSugarEntity) return obj.timestamp;
                      if (obj is TemperatureEntity) return obj.timestamp;
                      if (obj is WeightEntity) return obj.timestamp;
                      if (obj is SpO2Entity) return obj.timestamp;
                      return DateTime.now();
                    }
                    return getTimestamp(b).compareTo(getTimestamp(a));
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allTodayRecords.length,
                    itemBuilder: (context, index) {
                      final record = allTodayRecords[index];
                      return VitalCard(
                        record: record,
                        onEdit: () {
                          Navigator.pushNamed(
                            context,
                            AddEditVitalScreen.routeName,
                            arguments: record,
                          );
                        },
                        onDelete: () => _confirmDeletion(context, ref, record),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 100), // Spacing for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVitalOptions(context),
        label: const Text('Add Vital'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
        child: Column(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No vitals recorded today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep track of your vitals regularly to monitor your health trends.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context, WidgetRef ref, Object record) {
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

  void _showAddVitalOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Text(
                  'Record Vital Measurement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildBottomSheetItem(
                context,
                title: 'Blood Pressure',
                icon: Icons.favorite,
                color: const Color(0xFFE57373),
                vitalType: VitalType.bloodPressure,
              ),
              _buildBottomSheetItem(
                context,
                title: 'Blood Sugar',
                icon: Icons.bloodtype,
                color: const Color(0xFF64B5F6),
                vitalType: VitalType.bloodSugar,
              ),
              _buildBottomSheetItem(
                context,
                title: 'Body Temperature',
                icon: Icons.thermostat,
                color: const Color(0xFFFFB74D),
                vitalType: VitalType.temperature,
              ),
              _buildBottomSheetItem(
                context,
                title: 'Body Weight',
                icon: Icons.monitor_weight,
                color: const Color(0xFF81C784),
                vitalType: VitalType.weight,
              ),
              _buildBottomSheetItem(
                context,
                title: 'Oxygen Level (SpO₂)',
                icon: Icons.bubble_chart,
                color: const Color(0xFF4DB6AC),
                vitalType: VitalType.spo2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VitalType vitalType,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        Navigator.pushNamed(
          context,
          AddEditVitalScreen.routeName,
          arguments: vitalType, // Pass VitalType to tell form what to render
        );
      },
    );
  }
}

class _VitalSummaryGridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String subtitle;
  final String unit;
  final VoidCallback onTap;

  const _VitalSummaryGridCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.subtitle,
    required this.unit,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.extrabold,
                          fontSize: 20,
                        ),
                      ),
                      if (value != '--')
                        Text(
                          unit,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncQueueBanner extends ConsumerWidget {
  const _SyncQueueBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if sync queue has items
    final syncQueueAsync = ref.watch(vitalsLocalDataSourceProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<SyncQueueItem>>(
      future: syncQueueAsync.getSyncQueue(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final count = snapshot.data!.length;
          return Container(
            color: theme.colorScheme.errorContainer.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.offline_bolt_outlined, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$count updates pending offline sync.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.sync_problem, size: 16),
                  label: const Text('Sync'),
                  onPressed: () async {
                    await ref.read(vitalsActionNotifierProvider.notifier).sync();
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
