import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/vital_types.dart';

/// Data Model representing Blood Sugar, extending the Domain Entity.
class BloodSugarModel extends BloodSugarEntity {
  const BloodSugarModel({
    required super.id,
    required super.value,
    required super.readingType,
    required super.timestamp,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Map from Firestore Document Data.
  factory BloodSugarModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final readingTypeName = map['readingType'] as String? ?? 'random';
    final readingType = BloodSugarReadingType.values.firstWhere(
      (e) => e.name == readingTypeName,
      orElse: () => BloodSugarReadingType.random,
    );

    return BloodSugarModel(
      id: map['id'] as String? ?? '',
      value: (map['value'] as num? ?? 0.0).toDouble(),
      readingType: readingType,
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
      'readingType': readingType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Map from Domain Entity.
  factory BloodSugarModel.fromEntity(BloodSugarEntity entity) {
    return BloodSugarModel(
      id: entity.id,
      value: entity.value,
      readingType: entity.readingType,
      timestamp: entity.timestamp,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Manual Hive TypeAdapter to store BloodSugarModel locally.
class BloodSugarModelAdapter extends TypeAdapter<BloodSugarModel> {
  @override
  final int typeId = 2;

  @override
  BloodSugarModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final readingTypeName = fields[2] as String;
    final readingType = BloodSugarReadingType.values.firstWhere(
      (e) => e.name == readingTypeName,
      orElse: () => BloodSugarReadingType.random,
    );

    return BloodSugarModel(
      id: fields[0] as String,
      value: fields[1] as double,
      readingType: readingType,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
    );
  }

  @override
  void write(BinaryWriter writer, BloodSugarModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.readingType.name)
      ..writeByte(3)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
