// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_split.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSplitAdapter extends TypeAdapter<WorkoutSplit> {
  @override
  final int typeId = 12;

  @override
  WorkoutSplit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSplit(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String,
      color: fields[3] as int,
      iconCodePoint: fields[4] as int,
      isActive: fields[5] as bool,
      days: (fields[6] as List?)?.cast<WorkoutSplitDay>(),
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSplit obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.iconCodePoint)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.days)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSplitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
