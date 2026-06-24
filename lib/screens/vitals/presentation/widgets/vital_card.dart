import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/spo2_entity.dart';
import '../../domain/entities/vital_types.dart';
import 'classification_badge.dart';

/// Card widget to display a single vital record.
class VitalCard extends StatelessWidget {
  final Object record; // Can be one of the 5 vital entities
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VitalCard({
    Key? key,
    required this.record,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTime = _getFormattedTime();
    final title = _getTitle();
    final valueString = _getValueString();
    final iconData = _getIcon();
    final iconColor = _getIconColor(theme);
    final badge = _getBadge();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Side: Vital Icon
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Middle Section: Values and Timestamps
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formattedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        valueString,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (badge != null) badge,
                    ],
                  ),
                ],
              ),
            ),

            // Actions Menu
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit' && onEdit != null) onEdit!();
                  if (val == 'delete' && onDelete != null) onDelete!();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getFormattedTime() {
    DateTime timestamp;
    if (record is BloodPressureEntity) {
      timestamp = (record as BloodPressureEntity).timestamp;
    } else if (record is BloodSugarEntity) {
      timestamp = (record as BloodSugarEntity).timestamp;
    } else if (record is TemperatureEntity) {
      timestamp = (record as TemperatureEntity).timestamp;
    } else if (record is WeightEntity) {
      timestamp = (record as WeightEntity).timestamp;
    } else if (record is SpO2Entity) {
      timestamp = (record as SpO2Entity).timestamp;
    } else {
      return '';
    }
    return DateFormat('hh:mm a').format(timestamp);
  }

  String _getTitle() {
    if (record is BloodPressureEntity) return 'Blood Pressure';
    if (record is BloodSugarEntity) {
      final sugar = record as BloodSugarEntity;
      return 'Blood Sugar (${sugar.readingType.displayName})';
    }
    if (record is TemperatureEntity) return 'Body Temperature';
    if (record is WeightEntity) return 'Weight';
    if (record is SpO2Entity) return 'Blood Oxygen (SpO₂)';
    return 'Vital';
  }

  String _getValueString() {
    if (record is BloodPressureEntity) {
      final bp = record as BloodPressureEntity;
      return '${bp.systolic}/${bp.diastolic}';
    }
    if (record is BloodSugarEntity) {
      final sugar = record as BloodSugarEntity;
      return '${sugar.value.toStringAsFixed(0)} mg/dL';
    }
    if (record is TemperatureEntity) {
      final temp = record as TemperatureEntity;
      return '${temp.value.toStringAsFixed(1)}${temp.unit.displayName}';
    }
    if (record is WeightEntity) {
      final weight = record as WeightEntity;
      return '${weight.value.toStringAsFixed(1)} ${weight.unit.displayName}';
    }
    if (record is SpO2Entity) {
      final spo2 = record as SpO2Entity;
      return '${spo2.percentage}%';
    }
    return '';
  }

  IconData _getIcon() {
    if (record is BloodPressureEntity) return Icons.favorite;
    if (record is BloodSugarEntity) return Icons.bloodtype;
    if (record is TemperatureEntity) return Icons.thermostat;
    if (record is WeightEntity) return Icons.monitor_weight;
    if (record is SpO2Entity) return Icons.bubble_chart;
    return Icons.health_and_safety;
  }

  Color _getIconColor(ThemeData theme) {
    if (record is BloodPressureEntity) return const Color(0xFFE57373); // Soft Coral Red
    if (record is BloodSugarEntity) return const Color(0xFF64B5F6); // Soft Blue
    if (record is TemperatureEntity) return const Color(0xFFFFB74D); // Soft Orange
    if (record is WeightEntity) return const Color(0xFF81C784); // Soft Green
    if (record is SpO2Entity) return const Color(0xFF4DB6AC); // Teal
    return theme.colorScheme.primary;
  }

  Widget? _getBadge() {
    if (record is BloodPressureEntity) {
      return ClassificationBadge.fromBP((record as BloodPressureEntity).classification);
    }
    if (record is BloodSugarEntity) {
      return ClassificationBadge.fromBloodSugar((record as BloodSugarEntity).classification);
    }
    if (record is TemperatureEntity) {
      return ClassificationBadge.fromTemperature((record as TemperatureEntity).classification);
    }
    if (record is SpO2Entity) {
      return ClassificationBadge.fromSpO2((record as SpO2Entity).classification);
    }
    return null; // Weight doesn't have a categorical alert badge
  }
}
