// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 4;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      id: fields[0] as String?,
      name: fields[1] as String,
      muscleGroup: fields[2] as String,
      equipment: fields[3] as String,
      isCompound: fields[4] as bool,
      notes: fields[5] as String,
      instructions: fields[8] as String,
      defaultRestSeconds: fields[9] as int,
      defaultSets: fields[10] as int,
      defaultReps: fields[11] as int,
      defaultRpe: fields[12] as double?,
      tempo: fields[13] as String,
      tags: (fields[14] as List?)?.cast<String>(),
      secondaryMuscles: (fields[15] as List?)?.cast<String>(),
      favorite: fields[16] as bool,
      source: fields[17] as String,
      archived: fields[18] as bool,
      usageCount: fields[19] as int,
      lastUsedAt: fields[20] as DateTime?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.muscleGroup)
      ..writeByte(3)
      ..write(obj.equipment)
      ..writeByte(4)
      ..write(obj.isCompound)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.instructions)
      ..writeByte(9)
      ..write(obj.defaultRestSeconds)
      ..writeByte(10)
      ..write(obj.defaultSets)
      ..writeByte(11)
      ..write(obj.defaultReps)
      ..writeByte(12)
      ..write(obj.defaultRpe)
      ..writeByte(13)
      ..write(obj.tempo)
      ..writeByte(14)
      ..write(obj.tags)
      ..writeByte(15)
      ..write(obj.secondaryMuscles)
      ..writeByte(16)
      ..write(obj.favorite)
      ..writeByte(17)
      ..write(obj.source)
      ..writeByte(18)
      ..write(obj.archived)
      ..writeByte(19)
      ..write(obj.usageCount)
      ..writeByte(20)
      ..write(obj.lastUsedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
