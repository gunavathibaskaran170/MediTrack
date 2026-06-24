import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/blood_pressure_entity.dart';

/// Data Model representing Blood Pressure, extending the Domain Entity.
class BloodPressureModel extends BloodPressureEntity {
  const BloodPressureModel({
    required super.id,
    required super.systolic,
    required super.diastolic,
    super.pulse,
    required super.timestamp,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Map from Firestore Document Data.
  factory BloodPressureModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return BloodPressureModel(
      id: map['id'] as String? ?? '',
      systolic: map['systolic'] as int? ?? 120,
      diastolic: map['diastolic'] as int? ?? 80,
      pulse: map['pulse'] as int?,
      timestamp: parseDate(map['timestamp']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  /// Converts to Firestore Document Data.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Map from Domain Entity.
  factory BloodPressureModel.fromEntity(BloodPressureEntity entity) {
    return BloodPressureModel(
      id: entity.id,
      systolic: entity.systolic,
      diastolic: entity.diastolic,
      pulse: entity.pulse,
      timestamp: entity.timestamp,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Manual Hive TypeAdapter to store BloodPressureModel locally.
class BloodPressureModelAdapter extends TypeAdapter<BloodPressureModel> {
  @override
  final int typeId = 1;

  @override
  BloodPressureModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BloodPressureModel(
      id: fields[0] as String,
      systolic: fields[1] as int,
      diastolic: fields[2] as int,
      pulse: fields[3] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
    );
  }

  @override
  void write(BinaryWriter writer, BloodPressureModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.systolic)
      ..writeByte(2)
      ..write(obj.diastolic)
      ..writeByte(3)
      ..write(obj.pulse)
      ..writeByte(4)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
