// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_set.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSetAdapter extends TypeAdapter<WorkoutSet> {
  @override
  final int typeId = 3;

  @override
  WorkoutSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSet(
      id: fields[0] as String?,
      weight: fields[1] as double,
      reps: fields[2] as int,
      rpe: fields[3] as double?,
      restSeconds: fields[4] as int,
      completed: fields[5] as bool,
      isFailure: fields[6] as bool,
      isWarmup: fields[8] as bool,
      isDropSet: fields[9] as bool,
      isSuperSet: fields[10] as bool,
      tempo: fields[11] as String?,
      notes: fields[12] as String,
      timestamp: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.rpe)
      ..writeByte(4)
      ..write(obj.restSeconds)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.isFailure)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.isWarmup)
      ..writeByte(9)
      ..write(obj.isDropSet)
      ..writeByte(10)
      ..write(obj.isSuperSet)
      ..writeByte(11)
      ..write(obj.tempo)
      ..writeByte(12)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
