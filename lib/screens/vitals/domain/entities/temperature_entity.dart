import 'vital_types.dart';

/// Entity representing a Body Temperature reading.
class TemperatureEntity {
  final String id;
  final double value;
  final TemperatureUnit unit;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemperatureEntity({
    required this.id,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Validates the reading is within humanly survivable/plausible limits.
  bool get isValid {
    return switch (unit) {
      TemperatureUnit.celsius => value >= 34.0 && value <= 43.0,
      TemperatureUnit.fahrenheit => value >= 93.2 && value <= 109.4,
    };
  }

  /// Converts the reading to Celsius if it is in Fahrenheit.
  double get valueInCelsius {
    return switch (unit) {
      TemperatureUnit.celsius => value,
      TemperatureUnit.fahrenheit => (value - 32) * 5 / 9,
    };
  }

  /// Converts the reading to Fahrenheit if it is in Celsius.
  double get valueInFahrenheit {
    return switch (unit) {
      TemperatureUnit.celsius => (value * 9 / 5) + 32,
      TemperatureUnit.fahrenheit => value,
    };
  }

  /// Classifies the temperature based on fever thresholds.
  TemperatureClassification get classification {
    final celsius = valueInCelsius;
    if (celsius >= 39.1) {
      return TemperatureClassification.highFever;
    } else if (celsius >= 37.6) {
      return TemperatureClassification.fever;
    } else {
      return TemperatureClassification.normal;
    }
  }

  TemperatureEntity copyWith({
    String? id,
    double? value,
    TemperatureUnit? unit,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemperatureEntity(
      id: id ?? this.id,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
