/// Enums and classifications for the Vitals Tracking Module.
library;

/// The types of vitals supported by the system.
enum VitalType {
  bloodPressure,
  bloodSugar,
  temperature,
  weight,
  spo2,
}

/// Blood Pressure classifications based on AHA guidelines.
enum BloodPressureClassification {
  normal,
  elevated,
  hypertensionStage1,
  hypertensionStage2,
  hypertensiveCrisis;

  String get displayName {
    return switch (this) {
      BloodPressureClassification.normal => 'Normal',
      BloodPressureClassification.elevated => 'Elevated',
      BloodPressureClassification.hypertensionStage1 => 'Hypertension Stage 1',
      BloodPressureClassification.hypertensionStage2 => 'Hypertension Stage 2',
      BloodPressureClassification.hypertensiveCrisis => 'Hypertensive Crisis',
    };
  }
}

/// Blood Sugar reading contexts.
enum BloodSugarReadingType {
  fasting,
  beforeMeal,
  afterMeal,
  random;

  String get displayName {
    return switch (this) {
      BloodSugarReadingType.fasting => 'Fasting',
      BloodSugarReadingType.beforeMeal => 'Before Meal',
      BloodSugarReadingType.afterMeal => 'After Meal',
      BloodSugarReadingType.random => 'Random',
    };
  }
}

/// Blood Sugar classification categories.
enum BloodSugarClassification {
  low,
  normal,
  high,
  critical;

  String get displayName {
    return switch (this) {
      BloodSugarClassification.low => 'Low',
      BloodSugarClassification.normal => 'Normal',
      BloodSugarClassification.high => 'High',
      BloodSugarClassification.critical => 'Critical',
    };
  }
}

/// Temperature units of measurement.
enum TemperatureUnit {
  celsius,
  fahrenheit;

  String get displayName {
    return switch (this) {
      TemperatureUnit.celsius => '°C',
      TemperatureUnit.fahrenheit => '°F',
    };
  }
}

/// Temperature classifications.
enum TemperatureClassification {
  normal,
  fever,
  highFever;

  String get displayName {
    return switch (this) {
      TemperatureClassification.normal => 'Normal',
      TemperatureClassification.fever => 'Fever',
      TemperatureClassification.highFever => 'High Fever',
    };
  }
}

/// Weight units of measurement.
enum WeightUnit {
  kg,
  lbs;

  String get displayName {
    return switch (this) {
      WeightUnit.kg => 'kg',
      WeightUnit.lbs => 'lbs',
    };
  }
}

/// SpO2 classification categories.
enum SpO2Classification {
  normal,
  low,
  critical;

  String get displayName {
    return switch (this) {
      SpO2Classification.normal => 'Normal',
      SpO2Classification.low => 'Low Oxygen',
      SpO2Classification.critical => 'Critical',
    };
  }
}
