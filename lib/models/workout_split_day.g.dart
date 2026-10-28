// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_split_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSplitDayAdapter extends TypeAdapter<WorkoutSplitDay> {
  @override
  final int typeId = 13;

  @override
  WorkoutSplitDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSplitDay(
      id: fields[0] as String?,
      name: fields[1] as String,
      focus: fields[2] as String,
      isRestDay: fields[3] as bool,
      exercises: (fields[4] as List?)?.cast<WorkoutSplitExercise>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSplitDay obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.focus)
      ..writeByte(3)
      ..write(obj.isRestDay)
      ..writeByte(4)
      ..write(obj.exercises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSplitDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
