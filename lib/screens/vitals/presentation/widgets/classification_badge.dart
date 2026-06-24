import 'package:flutter/material.dart';
import '../../domain/entities/vital_types.dart';

/// A premium, customizable status badge widget for vital classifications.
class ClassificationBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const ClassificationBadge({
    Key? key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  }) : super(key: key);

  /// Factory constructors for different vital classifications.
  factory ClassificationBadge.fromBP(BloodPressureClassification classification) {
    return switch (classification) {
      BloodPressureClassification.normal => const ClassificationBadge(
          label: 'Normal',
          backgroundColor: Color(0xFFE8F5E9), // soft green
          textColor: Color(0xFF2E7D32),
        ),
      BloodPressureClassification.elevated => const ClassificationBadge(
          label: 'Elevated',
          backgroundColor: Color(0xFFFFF9C4), // soft yellow
          textColor: Color(0xFFF57F17),
        ),
      BloodPressureClassification.hypertensionStage1 => const ClassificationBadge(
          label: 'Hypertension Stage 1',
          backgroundColor: Color(0xFFFFE0B2), // soft orange
          textColor: Color(0xFFE65100),
        ),
      BloodPressureClassification.hypertensionStage2 => const ClassificationBadge(
          label: 'Hypertension Stage 2',
          backgroundColor: Color(0xFFFFCDD2), // soft red
          textColor: Color(0xFFC62828),
        ),
      BloodPressureClassification.hypertensiveCrisis => const ClassificationBadge(
          label: 'Hypertensive Crisis',
          backgroundColor: Color(0xFFF8BBD0), // soft deep pink
          textColor: Color(0xFF880E4F),
        ),
    };
  }

  factory ClassificationBadge.fromBloodSugar(BloodSugarClassification classification) {
    return switch (classification) {
      BloodSugarClassification.low => const ClassificationBadge(
          label: 'Low Sugar',
          backgroundColor: Color(0xFFE1F5FE), // soft blue
          textColor: Color(0xFF0277BD),
        ),
      BloodSugarClassification.normal => const ClassificationBadge(
          label: 'Normal',
          backgroundColor: Color(0xFFE8F5E9), // soft green
          textColor: Color(0xFF2E7D32),
        ),
      BloodSugarClassification.high => const ClassificationBadge(
          label: 'High Sugar',
          backgroundColor: Color(0xFFFFE0B2), // soft orange
          textColor: Color(0xFFE65100),
        ),
      BloodSugarClassification.critical => const ClassificationBadge(
          label: 'Critical Sugar',
          backgroundColor: Color(0xFFFFCDD2), // soft red
          textColor: Color(0xFFC62828),
        ),
    };
  }

  factory ClassificationBadge.fromTemperature(TemperatureClassification classification) {
    return switch (classification) {
      TemperatureClassification.normal => const ClassificationBadge(
          label: 'Normal',
          backgroundColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
        ),
      TemperatureClassification.fever => const ClassificationBadge(
          label: 'Fever',
          backgroundColor: Color(0xFFFFE0B2),
          textColor: Color(0xFFE65100),
        ),
      TemperatureClassification.highFever => const ClassificationBadge(
          label: 'High Fever',
          backgroundColor: Color(0xFFFFCDD2),
          textColor: Color(0xFFC62828),
        ),
    };
  }

  factory ClassificationBadge.fromSpO2(SpO2Classification classification) {
    return switch (classification) {
      SpO2Classification.normal => const ClassificationBadge(
          label: 'Normal',
          backgroundColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
        ),
      SpO2Classification.low => const ClassificationBadge(
          label: 'Low Oxygen',
          backgroundColor: Color(0xFFFFE0B2),
          textColor: Color(0xFFE65100),
        ),
      SpO2Classification.critical => const ClassificationBadge(
          label: 'Critical Low',
          backgroundColor: Color(0xFFFFCDD2),
          textColor: Color(0xFFC62828),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
