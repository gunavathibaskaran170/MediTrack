import 'vital_types.dart';

/// Entity representing a Weight measurement.
class WeightEntity {
  final String id;
  final double value;
  final WeightUnit unit;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeightEntity({
    required this.id,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validates that the weight is a positive value.
  bool get isValid => value > 0 && value <= 600; // 600 kg is standard max for heavy-duty scales

  /// Returns weight value in Kilograms.
  double get valueInKg {
    return switch (unit) {
      WeightUnit.kg => value,
      WeightUnit.lbs => value * 0.45359237,
    };
  }

  /// Returns weight value in Pounds.
  double get valueInLbs {
    return switch (unit) {
      WeightUnit.kg => value / 0.45359237,
      WeightUnit.lbs => value,
    };
  }

  WeightEntity copyWith({
    String? id,
    double? value,
    WeightUnit? unit,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightEntity(
      id: id ?? this.id,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
