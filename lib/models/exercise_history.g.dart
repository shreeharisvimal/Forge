// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseHistoryAdapter extends TypeAdapter<ExerciseHistory> {
  @override
  final int typeId = 5;

  @override
  ExerciseHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseHistory(
      id: fields[0] as String?,
      exerciseId: fields[1] as String,
      date: fields[2] as DateTime,
      bestWeight: fields[3] as double,
      bestReps: fields[4] as int,
      estimatedOneRM: fields[5] as double,
      totalVolume: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseHistory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.bestWeight)
      ..writeByte(4)
      ..write(obj.bestReps)
      ..writeByte(5)
      ..write(obj.estimatedOneRM)
      ..writeByte(6)
      ..write(obj.totalVolume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
