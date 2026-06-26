import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../core/models.dart';
import '../core/database_helper.dart';
import '../providers/analytics_provider.dart';
import 'doctor_visits.dart';
import 'package:lottie/lottie.dart';

class SymptomDiaryScreen extends StatefulWidget {
  const SymptomDiaryScreen({super.key});

  static void showAddSymptomBottomSheet(BuildContext context, List<Vital> vitals, [VoidCallback? onRefresh]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
      ),
      builder: (context) => AddSymptomBottomSheet(vitals: vitals, onRefresh: onRefresh),
    );
  }

  @override
  State<SymptomDiaryScreen> createState() => _SymptomDiaryScreenState();
}

class _SymptomDiaryScreenState extends State<SymptomDiaryScreen> {
  List<Symptom> _symptomsList = [];
  List<Vital> _vitalsList = [];
  bool _isLoading = true;

  // Filtering states
  String? _selectedDateFilter; // Format: "yyyy-MM-dd"
  final Set<String> _selectedSymptomNames = {};
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final symptoms = await DatabaseHelper.instance.getSymptoms();
      final vitals = await DatabaseHelper.instance.getVitals();
      setState(() {
        _symptomsList = symptoms;
        _vitalsList = vitals;
      });
    } catch (e) {
      debugPrint("Error loading symptom data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<DateTime> _getLast14Days() {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));
  }

  List<String> _getAbnormalVitalsForDay(String dateStr) {
    // Find vital for dateStr
    final vital = _vitalsList.firstWhere(
      (v) => v.date == dateStr,
      orElse: () => Vital(date: dateStr),
    );

    if (vital.id == null) return [];

    final List<String> warnings = [];

    if (vital.bpSystolic != null && vital.bpDiastolic != null) {
      if (vital.bpSystolic! > 130 || vital.bpDiastolic! > 85) {
        warnings.add('BP ${vital.bpSystolic!.toInt()}/${vital.bpDiastolic!.toInt()} ⚠');
      }
    }
    if (vital.bloodSugar != null) {
      final limit = (vital.sugarType == 'fasting') ? 100.0 : 140.0;
      if (vital.bloodSugar! > limit) {
        warnings.add('Sugar ${vital.bloodSugar!.toInt()} ⚠');
      }
    }
    if (vital.temperature != null) {
      if (vital.temperature! > 37.5 || vital.temperature! < 36.0) {
        warnings.add('Temp ${vital.temperature!.toStringAsFixed(1)}°C ⚠');
      }
    }
    if (vital.spo2 != null) {
      if (vital.spo2! < 95.0) {
        warnings.add('SpO2 ${vital.spo2!.toInt()}% ⚠');
      }
    }
    if (vital.heartRate != null) {
      if (vital.heartRate! > 100 || vital.heartRate! < 60) {
        warnings.add('HR ${vital.heartRate!.toInt()} ⚠');
      }
    }

    return warnings;
  }

  Map<String, String>? _calculateInsights() {
    // Analyze symptoms in last 14 days
    final now = DateTime.now();
    final limitDate = now.subtract(const Duration(days: 14));

    final recentSymptoms = _symptomsList.where((s) {
      if (s.date == null) return false;
      try {
        final date = DateTime.parse(s.date!);
        return date.isAfter(limitDate);
      } catch (_) {
        return false;
      }
    }).toList();

    if (recentSymptoms.isEmpty) return null;

    // Count symptoms
    final Map<String, int> counts = {};
    for (var s in recentSymptoms) {
      final name = s.symptomName ?? 'Unknown';
      counts[name] = (counts[name] ?? 0) + 1;
    }

    // Find most frequent
    String mostFreqSymptom = '';
    int maxCount = 0;
    counts.forEach((key, val) {
      if (val > maxCount) {
        maxCount = val;
        mostFreqSymptom = key;
      }
    });

    if (mostFreqSymptom.isEmpty) return null;

    // Find most frequent weekday for this symptom
    final Map<String, int> weekdayCounts = {};
    for (var s in recentSymptoms) {
      if (s.symptomName == mostFreqSymptom && s.date != null) {
        try {
          final date = DateTime.parse(s.date!);
          final weekday = DateFormat('EEEE').format(date); // e.g. "Monday"
          weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
        } catch (_) {}
      }
    }

    String mostFreqDay = 'any day';
    int maxDayCount = 0;
    weekdayCounts.forEach((key, val) {
      if (val > maxDayCount) {
        maxDayCount = val;
        mostFreqDay = key;
      }
    });

    return {
      'symptom': mostFreqSymptom,
      'count': '$maxCount',
      'day': mostFreqDay,
    };
  }

  List<Symptom> _getFilteredSymptoms() {
    return _symptomsList.where((s) {
      // 1. Date filter
      if (_selectedDateFilter != null && s.date != _selectedDateFilter) {
        return false;
      }

      // 2. Chip filters
      if (_selectedSymptomNames.isNotEmpty && !_selectedSymptomNames.contains(s.symptomName)) {
        return false;
      }

      // 3. Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (s.symptomName ?? '').toLowerCase();
        final notes = (s.notes ?? '').toLowerCase();
        final region = (s.bodyRegion ?? '').toLowerCase();
        if (!name.contains(query) && !notes.contains(query) && !region.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _formatDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      final formattedDate = DateFormat('dd MMM yyyy').format(date);
      if (timeStr != null && timeStr.isNotEmpty) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final time = DateTime(2026, 1, 1, hour, min);
        final formattedTime = DateFormat('hh:mm a').format(time);
        return '$formattedDate, $formattedTime';
      }
      return formattedDate;
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final filteredList = _getFilteredSymptoms();
    final uniqueSymptoms = _symptomsList.map((s) => s.symptomName ?? 'Unknown').toSet().toList();
    final insights = _calculateInsights();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text('Symptom Diary', style: context.titleLarge),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 14-Day Heatmap Grid
                _buildHeatmapGrid(),

                // Active Filter Banner
                if (_selectedDateFilter != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtering symptoms logged on ${DateFormat('dd MMM yyyy').format(DateTime.parse(_selectedDateFilter!))}',
                            style: context.bodySmall.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: context.colors.primary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedDateFilter = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // Collapsible Search and Filter Chips
                _buildSearchAndFilters(uniqueSymptoms),

                // Insights Card
                if (insights != null) _buildInsightsCard(insights),

                const Divider(height: 1),

                // Symptoms List
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 120,
                                child: Lottie.network(
                                  'https://lottie.host/a82d02c7-063a-4f51-b847-197e415fb5ba/xVd2qG8qA9.json',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No matching symptoms found',
                                style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _buildSymptomTile(item, index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => SymptomDiaryScreen.showAddSymptomBottomSheet(context, _vitalsList, _loadData),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- 14-DAY HEATMAP GRID ---
  Widget _buildHeatmapGrid() {
    final days = _getLast14Days();

    // Group symptom count by date
    final Map<String, int> countsByDate = {};
    for (var s in _symptomsList) {
      if (s.date != null) {
        countsByDate[s.date!] = (countsByDate[s.date!] ?? 0) + 1;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '14-Day Activity Heatmap',
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tap cell to filter date',
                  style: context.labelSmall.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // 7 days in a week row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = days[index];
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final count = countsByDate[dateStr] ?? 0;
                final isSelected = _selectedDateFilter == dateStr;

                // Color based on symptom counts
                Color cellColor = context.colors.dividerColor.withOpacity(0.2);
                Color textColor = context.colors.textPrimary;
                if (count > 0) {
                  if (count == 1) {
                    cellColor = context.colors.primary.withOpacity(0.35);
                    textColor = context.colors.primary;
                  } else if (count == 2) {
                    cellColor = context.colors.primary.withOpacity(0.65);
                    textColor = Colors.white;
                  } else {
                    cellColor = context.colors.primary;
                    textColor = Colors.white;
                  }
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDateFilter = null;
                      } else {
                        _selectedDateFilter = dateStr;
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: context.colors.primary, width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: context.colors.primary.withOpacity(0.3), blurRadius: 4)]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          DateFormat('E').format(date).substring(0, 1),
                          style: TextStyle(
                            fontSize: 8,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- SEARCH AND FILTERS ---
  Widget _buildSearchAndFilters(List<String> uniqueSymptoms) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Collapsible Search Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_isSearching) ...[
                Text('Symptom Log History', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ] else ...[
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      style: context.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search symptoms, notes, regions...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _isSearching = false;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 6),

          // Horizontal Filter Chips
          if (uniqueSymptoms.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: uniqueSymptoms.map((name) {
                  final isSelected = _selectedSymptomNames.contains(name);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      selectedColor: context.colors.primaryLight,
                      labelStyle: context.labelSmall.copyWith(
                        color: isSelected ? context.colors.primary : context.colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSymptomNames.add(name);
                          } else {
                            _selectedSymptomNames.remove(name);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --- INSIGHTS CARD ---
  Widget _buildInsightsCard(Map<String, String> insights) {
    final symptom = insights['symptom']!;
    final count = insights['count']!;
    final day = insights['day']!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: context.colors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: context.colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pattern Insights',
                  style: context.titleMedium.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your most frequent symptom recently is "$symptom", logged $count times in the last 14 days. It occurs most often on ${day}s.',
              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.forum_outlined, size: 16, color: context.colors.primary),
                  label: Text('Discuss with Doctor', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // Open Doctor Visit Sheet with pre-filled notes
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
                      ),
                      builder: (context) => AddVisitBottomSheet(
                        initialNotes: 'I want to discuss a repeating pattern: "$symptom" occurred $count times in the last 14 days, particularly on ${day}s.',
                        initialDiagnosis: '$symptom Pattern Discussion',
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- SYMPTOM TILE ---
  Widget _buildSymptomTile(Symptom item, int index) {
    Color severityBg;
    Color severityTextColor;
    IconData severityEmoji;
    String severityText = 'Mild';

    switch (item.severity) {
      case 3:
        severityBg = context.colors.errorLight;
        severityTextColor = context.colors.errorSos;
        severityEmoji = Icons.sentiment_very_dissatisfied;
        severityText = 'Severe';
        break;
      case 2:
        severityBg = context.colors.warningLight;
        severityTextColor = context.colors.warning;
        severityEmoji = Icons.sentiment_neutral;
        severityText = 'Moderate';
        break;
      default:
        severityBg = context.colors.successLight;
        severityTextColor = context.colors.success;
        severityEmoji = Icons.sentiment_satisfied;
        severityText = 'Mild';
    }

    // Cross-reference abnormal vitals for the same day
    final abnormalVitals = item.date != null ? _getAbnormalVitalsForDay(item.date!) : <String>[];

    return Slidable(
      key: ValueKey(item.id ?? index),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showConfirmDeleteDialog(
                context,
                title: 'Delete Symptom',
                content: 'Are you sure you want to delete this symptom log?',
              );
              if (confirm == true && item.id != null) {
                await DatabaseHelper.instance.deleteSymptom(item.id!);
                await _loadData();
                if (mounted) {
                  Provider.of<AnalyticsProvider>(context, listen: false).loadAnalytics();
                }
              }
            },
            backgroundColor: context.colors.errorSos,
            foregroundColor: Colors.white,
            icon: Icons.delete_forever,
            label: 'Delete',
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.dividerColor.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 44,
                  decoration: BoxDecoration(
                    color: severityTextColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDateTime(item.date, item.time),
                            style: context.labelSmall.copyWith(color: context.colors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: severityBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(severityEmoji, size: 10, color: severityTextColor),
                                const SizedBox(width: 2),
                                Text(
                                  severityText,
                                  style: context.labelSmall.copyWith(color: severityTextColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.symptomName ?? 'Unknown Symptom',
                        style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (item.bodyRegion != null || item.duration != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.bodyRegion != null)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.colors.dividerColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('📍 ${item.bodyRegion}', style: context.labelSmall),
                              ),
                            if (item.duration != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.colors.dividerColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('⏱ ${item.duration}', style: context.labelSmall),
                              ),
                          ],
                        ),
                      ],
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.notes!,
                          style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                        ),
                      ],

                      // Abnormal vitals correlation tag
                      if (abnormalVitals.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: abnormalVitals.map((warning) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.colors.errorLight,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: context.colors.errorSos.withOpacity(0.3)),
                              ),
                              child: Text(
                                warning,
                                style: context.labelSmall.copyWith(color: context.colors.errorSos, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: context.colors.errorSos),
                  onPressed: () async {
                    final confirm = await showConfirmDeleteDialog(
                      context,
                      title: 'Delete Symptom',
                      content: 'Are you sure you want to delete this symptom log?',
                    );
                    if (confirm == true && item.id != null) {
                      await DatabaseHelper.instance.deleteSymptom(item.id!);
                      await _loadData();
                      if (mounted) {
                        Provider.of<AnalyticsProvider>(context, listen: false).loadAnalytics();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- ADD SYMPTOM BOTTOM SHEET ---
class AddSymptomBottomSheet extends StatefulWidget {
  final List<Vital> vitals;
  final VoidCallback? onRefresh;
  const AddSymptomBottomSheet({super.key, required this.vitals, this.onRefresh});

  @override
  State<AddSymptomBottomSheet> createState() => _AddSymptomBottomSheetState();
}

class _AddSymptomBottomSheetState extends State<AddSymptomBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symptomController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSeverity = 'Mild';
  DateTime _selectedDateTime = DateTime.now();

  String _selectedBodyRegion = 'General';
  String _selectedDuration = 'A few minutes';

  final List<String> _suggestions = [
    'Headache', 'Dizziness', 'Fatigue', 'Chest Pain',
    'Shortness of Breath', 'Nausea', 'Swelling',
    'Blurred Vision', 'Palpitations', 'Joint Pain'
  ];

  final List<String> _regions = ['General', 'Head', 'Chest', 'Stomach', 'Limbs'];
  final List<String> _durations = [
    'A few minutes',
    'Less than 1 hour',
    '1-4 hours',
    '4-12 hours',
    '12-24 hours',
    'Multiple days'
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _getAbnormalVitalsForToday() {
    final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDateTime);
    final vital = widget.vitals.firstWhere(
      (v) => v.date == todayStr,
      orElse: () => Vital(date: todayStr),
    );

    if (vital.id == null) return [];

    final List<String> warnings = [];

    if (vital.bpSystolic != null && vital.bpDiastolic != null) {
      if (vital.bpSystolic! > 130 || vital.bpDiastolic! > 85) {
        warnings.add('BP: ${vital.bpSystolic!.toInt()}/${vital.bpDiastolic!.toInt()}');
      }
    }
    if (vital.bloodSugar != null) {
      final limit = (vital.sugarType == 'fasting') ? 100.0 : 140.0;
      if (vital.bloodSugar! > limit) {
        warnings.add('Sugar: ${vital.bloodSugar!.toInt()}');
      }
    }
    if (vital.temperature != null) {
      if (vital.temperature! > 37.5 || vital.temperature! < 36.0) {
        warnings.add('Temp: ${vital.temperature!.toStringAsFixed(1)}°C');
      }
    }
    if (vital.spo2 != null) {
      if (vital.spo2! < 95.0) {
        warnings.add('SpO2: ${vital.spo2!.toInt()}%');
      }
    }
    if (vital.heartRate != null) {
      if (vital.heartRate! > 100 || vital.heartRate! < 60) {
        warnings.add('HR: ${vital.heartRate!.toInt()}');
      }
    }

    return warnings;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _symptomController.text.trim();
    if (name.isEmpty) return;

    final s = Symptom(
      date: DateFormat('yyyy-MM-dd').format(_selectedDateTime),
      time: DateFormat('HH:mm').format(_selectedDateTime),
      symptomName: name,
      severity: _selectedSeverity == 'Mild' ? 1 : (_selectedSeverity == 'Moderate' ? 2 : 3),
      notes: _notesController.text.trim(),
      bodyRegion: _selectedBodyRegion,
      duration: _selectedDuration,
    );

    await DatabaseHelper.instance.insertSymptom(s);
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }

    if (mounted) {
      Provider.of<AnalyticsProvider>(context, listen: false).loadAnalytics();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final abnormalToday = _getAbnormalVitalsForToday();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: context.colors.card,
          appBar: AppBar(
            backgroundColor: context.colors.card,
            title: Text('Log Symptom', style: context.titleLarge),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Advisory Abnormal Vitals Warning Banner
                        if (abnormalToday.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colors.errorLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.colors.errorSos.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: context.colors.errorSos, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Abnormal Vitals Logged Today!',
                                        style: context.bodyMedium.copyWith(color: context.colors.errorSos, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Today\'s readings (${abnormalToday.join(", ")}) are outside normal bounds. Please monitor yourself closely and contact your doctor if needed.',
                                        style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text('Symptom Name', style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _suggestions;
                            }
                            return _suggestions.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                            if (textEditingController.text != _symptomController.text) {
                              textEditingController.text = _symptomController.text;
                            }
                            textEditingController.addListener(() {
                              _symptomController.text = textEditingController.text;
                            });

                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              style: context.bodyMedium,
                              decoration: const InputDecoration(
                                labelText: 'Search or Enter Symptom',
                                prefixIcon: Icon(Icons.sick_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Symptom name is required';
                                return null;
                              },
                            );
                          },
                          onSelected: (String selection) {
                            setState(() {
                              _symptomController.text = selection;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        Text('Severity', style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ChoiceChip(
                              label: const Text('Mild'),
                              selected: _selectedSeverity == 'Mild',
                              selectedColor: context.colors.successLight,
                              labelStyle: TextStyle(
                                color: _selectedSeverity == 'Mild' ? context.colors.success : context.colors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedSeverity = 'Mild');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Moderate'),
                              selected: _selectedSeverity == 'Moderate',
                              selectedColor: context.colors.warningLight,
                              labelStyle: TextStyle(
                                color: _selectedSeverity == 'Moderate' ? context.colors.warning : context.colors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedSeverity = 'Moderate');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Severe'),
                              selected: _selectedSeverity == 'Severe',
                              selectedColor: context.colors.errorLight,
                              labelStyle: TextStyle(
                                color: _selectedSeverity == 'Severe' ? context.colors.errorSos : context.colors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedSeverity = 'Severe');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Body Region Selector
                        Text('Body Region', style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _regions.map((region) {
                              final isSelected = _selectedBodyRegion == region;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(region),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedBodyRegion = region;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Duration Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedDuration,
                          style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          items: _durations.map((duration) {
                            return DropdownMenuItem<String>(
                              value: duration,
                              child: Text(duration),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDuration = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        Text('Notes (optional)', style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          style: context.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Enter details...',
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date & Time Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: context.colors.primary),
                                const SizedBox(width: 8),
                                Text('Date & Time', style: context.bodyMedium),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDateTime,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null && mounted) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              child: Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(_selectedDateTime),
                                style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    border: Border(top: BorderSide(color: context.colors.dividerColor, width: 0.8)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Log Symptom'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
