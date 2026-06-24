import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/meditrack_theme.dart';
import '../widgets/dialogs.dart';
import '../core/models.dart';
import '../core/database_helper.dart';
import '../providers/analytics_provider.dart';

class SymptomDiaryScreen extends StatefulWidget {
  const SymptomDiaryScreen({super.key});

  static void showAddSymptomBottomSheet(BuildContext context, [VoidCallback? onRefresh]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MediTrackRadius.bottomSheets)),
      ),
      builder: (context) => AddSymptomBottomSheet(onRefresh: onRefresh),
    );
  }

  @override
  State<SymptomDiaryScreen> createState() => _SymptomDiaryScreenState();
}

class _SymptomDiaryScreenState extends State<SymptomDiaryScreen> {
  List<Symptom> _symptomsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.getSymptoms();
      setState(() {
        _symptomsList = list;
      });
    } catch (e) {
      debugPrint("Error loading symptoms: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      final formattedDate = DateFormat('dd MMM yyyy').format(date);
      if (timeStr != null && timeStr.isNotEmpty) {
        // Parse timeStr
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

  List<BarChartGroupData> _buildBarGroups() {
    final now = DateTime.now();
    final Map<String, int> countsByDate = {};

    for (int i = 0; i < 14; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      countsByDate[dateStr] = 0;
    }

    for (var s in _symptomsList) {
      if (s.date != null && countsByDate.containsKey(s.date)) {
        countsByDate[s.date!] = (countsByDate[s.date!] ?? 0) + 1;
      }
    }

    return List.generate(14, (index) {
      final daysAgo = 13 - index;
      final date = now.subtract(Duration(days: daysAgo));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final count = countsByDate[dateStr] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: context.colors.primary,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final hasData = _symptomsList.isNotEmpty;

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
        actions: const [
          SizedBox(width: MediTrackSpacing.screenHorizontalPadding),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasData
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    _buildMiniChartCard(context),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _symptomsList.length,
                        itemBuilder: (context, index) {
                          final item = _symptomsList[index];
                          return _buildSymptomTile(context, item, index);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => SymptomDiaryScreen.showAddSymptomBottomSheet(context, _loadSymptoms),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
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
            Icon(
              Icons.sentiment_dissatisfied,
              size: 80,
              color: context.colors.textHint,
            ),
            const SizedBox(height: MediTrackSpacing.large),
            Text(
              'No symptoms logged yet',
              style: context.titleLarge.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: MediTrackSpacing.large),
            ElevatedButton(
              onPressed: () => SymptomDiaryScreen.showAddSymptomBottomSheet(context, _loadSymptoms),
              child: const Text('Log a Symptom'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChartCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(MediTrackSpacing.screenHorizontalPadding),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptom frequency — Last 14 days',
              style: context.labelSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomTile(BuildContext context, Symptom item, int index) {
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
                await _loadSymptoms();
                if (context.mounted) {
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
        padding: const EdgeInsets.symmetric(horizontal: MediTrackSpacing.screenHorizontalPadding, vertical: 8.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: severityTextColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: context.colors.dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: MediTrackSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDateTime(item.date, item.time),
                          style: context.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: Icon(severityEmoji, size: 12, color: severityTextColor),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: -4),
                          padding: EdgeInsets.zero,
                          label: Text(
                            severityText,
                            style: context.labelSmall.copyWith(color: severityTextColor, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: severityBg,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    Text(
                      item.symptomName ?? 'Unknown Symptom',
                      style: context.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.notes ?? '',
                      style: context.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        await _loadSymptoms();
                        if (context.mounted) {
                          Provider.of<AnalyticsProvider>(context, listen: false).loadAnalytics();
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddSymptomBottomSheet extends StatefulWidget {
  final VoidCallback? onRefresh;
  const AddSymptomBottomSheet({super.key, this.onRefresh});

  @override
  State<AddSymptomBottomSheet> createState() => _AddSymptomBottomSheetState();
}

class _AddSymptomBottomSheetState extends State<AddSymptomBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symptomController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSeverity = 'Mild';
  DateTime _selectedDateTime = DateTime.now();

  final List<String> _suggestions = [
    'Headache', 'Dizziness', 'Fatigue', 'Chest Pain',
    'Shortness of Breath', 'Nausea', 'Swelling',
    'Blurred Vision', 'Palpitations', 'Joint Pain'
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: context.colors.card,
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log Symptom',
                        style: context.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text('Symptom', style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
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
                      // Keep controllers in sync
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
                  const SizedBox(height: 24),

                  Text('Severity', style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ChoiceChip(
                        label: const Text('😌 Mild'),
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
                        label: const Text('😐 Moderate'),
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
                        label: const Text('😣 Severe'),
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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 24),

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
                          if (date != null && context.mounted) {
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
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Log Symptom'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
