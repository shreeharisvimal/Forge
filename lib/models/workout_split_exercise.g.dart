// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_split_exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSplitExerciseAdapter extends TypeAdapter<WorkoutSplitExercise> {
  @override
  final int typeId = 14;

  @override
  WorkoutSplitExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSplitExercise(
      id: fields[0] as String?,
      exerciseId: fields[1] as String,
      exerciseName: fields[2] as String,
      order: fields[3] as int,
      sets: fields[4] as int,
      reps: fields[5] as int,
      rpe: fields[6] as double?,
      restSeconds: fields[7] as int,
      tempo: fields[8] as String,
      notes: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSplitExercise obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.exerciseName)
      ..writeByte(3)
      ..write(obj.order)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.reps)
      ..writeByte(6)
      ..write(obj.rpe)
      ..writeByte(7)
      ..write(obj.restSeconds)
      ..writeByte(8)
      ..write(obj.tempo)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSplitExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
