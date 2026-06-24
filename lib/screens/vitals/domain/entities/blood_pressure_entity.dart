import 'vital_types.dart';

/// Entity representing a Blood Pressure reading.
class BloodPressureEntity {
  final String id;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BloodPressureEntity({
    required this.id,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validates the systolic and diastolic ranges.
  bool get isValid {
    return systolic >= 70 && systolic <= 250 && diastolic >= 40 && diastolic <= 150;
  }

  /// Classifies the blood pressure according to AHA guidelines.
  BloodPressureClassification get classification {
    if (systolic >= 180 || diastolic >= 120) {
      return BloodPressureClassification.hypertensiveCrisis;
    } else if ((systolic >= 140 && systolic <= 179) || (diastolic >= 90 && diastolic <= 119)) {
      return BloodPressureClassification.hypertensionStage2;
    } else if ((systolic >= 130 && systolic <= 139) || (diastolic >= 80 && diastolic <= 89)) {
      return BloodPressureClassification.hypertensionStage1;
    } else if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
      return BloodPressureClassification.elevated;
    } else {
      return BloodPressureClassification.normal;
    }
  }

  BloodPressureEntity copyWith({
    String? id,
    int? systolic,
    int? diastolic,
    int? pulse,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodPressureEntity(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
