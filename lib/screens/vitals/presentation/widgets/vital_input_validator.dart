import '../../domain/entities/vital_types.dart';

/// Centralized validation logic for Vitals Tracking input fields.
class VitalInputValidator {
  /// Validates Systolic blood pressure (70-250)
  static String? validateSystolic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Systolic reading is required';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Must be an integer';
    }
    if (number < 70 || number > 250) {
      return 'Must be between 70 and 250 mmHg';
    }
    return null;
  }

  /// Validates Diastolic blood pressure (40-150)
  static String? validateDiastolic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Diastolic reading is required';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Must be an integer';
    }
    if (number < 40 || number > 150) {
      return 'Must be between 40 and 150 mmHg';
    }
    return null;
  }

  /// Validates Pulse (optional, but if entered must be between 30 and 220)
  static String? validatePulse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optional
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Must be an integer';
    }
    if (number < 30 || number > 220) {
      return 'Plausible pulse range is 30 to 220 bpm';
    }
    return null;
  }

  /// Validates Blood Sugar glucose value (> 0 and < 600)
  static String? validateBloodSugar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Blood sugar value is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Must be a number';
    }
    if (number <= 0) {
      return 'Must be greater than 0';
    }
    if (number > 600) {
      return 'Must be less than 600 mg/dL';
    }
    return null;
  }

  /// Validates body temperature based on its unit
  static String? validateTemperature(String? value, TemperatureUnit unit) {
    if (value == null || value.trim().isEmpty) {
      return 'Temperature value is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Must be a number';
    }
    
    return switch (unit) {
      TemperatureUnit.celsius => (number < 34.0 || number > 43.0)
          ? 'Celsius range must be 34.0°C to 43.0°C'
          : null,
      TemperatureUnit.fahrenheit => (number < 93.2 || number > 109.4)
          ? 'Fahrenheit range must be 93.2°F to 109.4°F'
          : null,
    };
  }

  /// Validates Weight (> 0)
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight value is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Must be a number';
    }
    if (number <= 0 || number > 600) {
      return 'Must be between 0 and 600';
    }
    return null;
  }

  /// Validates SpO2 percentage (0 - 100)
  static String? validateSpO2(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'SpO2 percentage is required';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Must be an integer';
    }
    if (number < 0 || number > 100) {
      return 'Percentage must be between 0 and 100';
    }
    if (number < 50) {
      return 'Plausible oxygen range is 50% to 100%';
    }
    return null;
  }
}
