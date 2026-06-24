import 'vital_types.dart';

/// Entity representing a Blood Sugar (glucose) reading.
class BloodSugarEntity {
  final String id;
  final double value; // in mg/dL
  final BloodSugarReadingType readingType;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BloodSugarEntity({
    required this.id,
    required this.value,
    required this.readingType,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validates that the blood sugar value is positive.
  bool get isValid => value > 0 && value <= 600; // 600 mg/dL is typically the upper limit of glucometers

  /// Classifies blood sugar values based on standard clinical ranges.
  BloodSugarClassification get classification {
    if (value < 70) {
      return BloodSugarClassification.low;
    }

    return switch (readingType) {
      BloodSugarReadingType.fasting => _classifyFasting(),
      BloodSugarReadingType.beforeMeal => _classifyBeforeMeal(),
      BloodSugarReadingType.afterMeal => _classifyAfterMeal(),
      BloodSugarReadingType.random => _classifyRandom(),
    };
  }

  BloodSugarClassification _classifyFasting() {
    if (value >= 126) {
      return BloodSugarClassification.critical;
    } else if (value >= 100) {
      return BloodSugarClassification.high;
    } else {
      return BloodSugarClassification.normal;
    }
  }

  BloodSugarClassification _classifyBeforeMeal() {
    if (value >= 180) {
      return BloodSugarClassification.critical;
    } else if (value >= 130) {
      return BloodSugarClassification.high;
    } else {
      return BloodSugarClassification.normal;
    }
  }

  BloodSugarClassification _classifyAfterMeal() {
    if (value >= 200) {
      return BloodSugarClassification.critical;
    } else if (value >= 140) {
      return BloodSugarClassification.high;
    } else {
      return BloodSugarClassification.normal;
    }
  }

  BloodSugarClassification _classifyRandom() {
    if (value >= 200) {
      return BloodSugarClassification.critical;
    } else if (value >= 140) {
      return BloodSugarClassification.high;
    } else {
      return BloodSugarClassification.normal;
    }
  }

  BloodSugarEntity copyWith({
    String? id,
    double? value,
    BloodSugarReadingType? readingType,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodSugarEntity(
      id: id ?? this.id,
      value: value ?? this.value,
      readingType: readingType ?? this.readingType,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
