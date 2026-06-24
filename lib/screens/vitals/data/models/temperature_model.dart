import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/temperature_entity.dart';
import '../../domain/entities/vital_types.dart';

/// Data Model representing Temperature, extending the Domain Entity.
class TemperatureModel extends TemperatureEntity {
  const TemperatureModel({
    required super.id,
    required super.value,
    required super.unit,
    required super.timestamp,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Map from Firestore Document Data.
  factory TemperatureModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final unitName = map['unit'] as String? ?? 'celsius';
    final unit = TemperatureUnit.values.firstWhere(
      (e) => e.name == unitName,
      orElse: () => TemperatureUnit.celsius,
    );

    return TemperatureModel(
      id: map['id'] as String? ?? '',
      value: (map['value'] as num? ?? 37.0).toDouble(),
      unit: unit,
      timestamp: parseDate(map['timestamp']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  /// Converts to Firestore Document Data.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'value': value,
      'unit': unit.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Map from Domain Entity.
  factory TemperatureModel.fromEntity(TemperatureEntity entity) {
    return TemperatureModel(
      id: entity.id,
      value: entity.value,
      unit: entity.unit,
      timestamp: entity.timestamp,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Manual Hive TypeAdapter to store TemperatureModel locally.
class TemperatureModelAdapter extends TypeAdapter<TemperatureModel> {
  @override
  final int typeId = 3;

  @override
  TemperatureModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final unitName = fields[2] as String;
    final unit = TemperatureUnit.values.firstWhere(
      (e) => e.name == unitName,
      orElse: () => TemperatureUnit.celsius,
    );

    return TemperatureModel(
      id: fields[0] as String,
      value: fields[1] as double,
      unit: unit,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
    );
  }

  @override
  void write(BinaryWriter writer, TemperatureModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.unit.name)
      ..writeByte(3)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
