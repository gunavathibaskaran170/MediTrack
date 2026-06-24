import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/weight_entity.dart';
import '../../domain/entities/vital_types.dart';

/// Data Model representing Weight, extending the Domain Entity.
class WeightModel extends WeightEntity {
  const WeightModel({
    required super.id,
    required super.value,
    required super.unit,
    required super.timestamp,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Map from Firestore Document Data.
  factory WeightModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final unitName = map['unit'] as String? ?? 'kg';
    final unit = WeightUnit.values.firstWhere(
      (e) => e.name == unitName,
      orElse: () => WeightUnit.kg,
    );

    return WeightModel(
      id: map['id'] as String? ?? '',
      value: (map['value'] as num? ?? 70.0).toDouble(),
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
  factory WeightModel.fromEntity(WeightEntity entity) {
    return WeightModel(
      id: entity.id,
      value: entity.value,
      unit: entity.unit,
      timestamp: entity.timestamp,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Manual Hive TypeAdapter to store WeightModel locally.
class WeightModelAdapter extends TypeAdapter<WeightModel> {
  @override
  final int typeId = 4;

  @override
  WeightModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final unitName = fields[2] as String;
    final unit = WeightUnit.values.firstWhere(
      (e) => e.name == unitName,
      orElse: () => WeightUnit.kg,
    );

    return WeightModel(
      id: fields[0] as String,
      value: fields[1] as double,
      unit: unit,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
    );
  }

  @override
  void write(BinaryWriter writer, WeightModel obj) {
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
