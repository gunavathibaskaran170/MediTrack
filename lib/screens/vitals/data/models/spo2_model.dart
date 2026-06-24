import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/spo2_entity.dart';

/// Data Model representing SpO2, extending the Domain Entity.
class SpO2Model extends SpO2Entity {
  const SpO2Model({
    required super.id,
    required super.percentage,
    required super.timestamp,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Map from Firestore Document Data.
  factory SpO2Model.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return SpO2Model(
      id: map['id'] as String? ?? '',
      percentage: map['percentage'] as int? ?? 98,
      timestamp: parseDate(map['timestamp']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  /// Converts to Firestore Document Data.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'percentage': percentage,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Map from Domain Entity.
  factory SpO2Model.fromEntity(SpO2Entity entity) {
    return SpO2Model(
      id: entity.id,
      percentage: entity.percentage,
      timestamp: entity.timestamp,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Manual Hive TypeAdapter to store SpO2Model locally.
class SpO2ModelAdapter extends TypeAdapter<SpO2Model> {
  @override
  final int typeId = 5;

  @override
  SpO2Model read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpO2Model(
      id: fields[0] as String,
      percentage: fields[1] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
    );
  }

  @override
  void write(BinaryWriter writer, SpO2Model obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.percentage)
      ..writeByte(2)
      ..write(obj.timestamp.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
