// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonalRecordAdapter extends TypeAdapter<PersonalRecord> {
  @override
  final int typeId = 10;

  @override
  PersonalRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonalRecord(
      id: fields[0] as String?,
      exerciseId: fields[1] as String,
      highestWeight: fields[2] as double,
      bestReps: fields[3] as int,
      estimatedOneRM: fields[4] as double,
      bestVolume: fields[5] as double,
      lastUpdated: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PersonalRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.highestWeight)
      ..writeByte(3)
      ..write(obj.bestReps)
      ..writeByte(4)
      ..write(obj.estimatedOneRM)
      ..writeByte(5)
      ..write(obj.bestVolume)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
