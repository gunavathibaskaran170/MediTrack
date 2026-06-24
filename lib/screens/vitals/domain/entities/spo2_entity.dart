import 'vital_types.dart';

/// Entity representing an SpO2 (Blood Oxygen Saturation) reading.
class SpO2Entity {
  final String id;
  final int percentage; // percentage range 0 - 100
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpO2Entity({
    required this.id,
    required this.percentage,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validates the percentage range.
  bool get isValid => percentage >= 0 && percentage <= 100;

  /// Classifies oxygen saturation levels.
  /// Normal: >= 95%
  /// Low: 90% - 94%
  /// Critical: < 90%
  SpO2Classification get classification {
    if (percentage >= 95) {
      return SpO2Classification.normal;
    } else if (percentage >= 90) {
      return SpO2Classification.low;
    } else {
      return SpO2Classification.critical;
    }
  }

  SpO2Entity copyWith({
    String? id,
    int? percentage,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpO2Entity(
      id: id ?? this.percentage, // Note: fixing field mismatch if copyWith was using wrong field name
      percentage: percentage ?? this.percentage,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
