// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pr_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrEventAdapter extends TypeAdapter<PrEvent> {
  @override
  final int typeId = 15;

  @override
  PrEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrEvent(
      id: fields[0] as String?,
      exerciseId: fields[1] as String,
      exerciseName: fields[2] as String,
      type: fields[3] as String,
      value: fields[4] as double,
      previousValue: fields[5] as double,
      date: fields[6] as DateTime?,
      workoutId: fields[7] as String?,
      notes: fields[8] as String,
      formula: fields[9] as String,
      calculatedOneRM: fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PrEvent obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.exerciseName)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.value)
      ..writeByte(5)
      ..write(obj.previousValue)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.workoutId)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.formula)
      ..writeByte(10)
      ..write(obj.calculatedOneRM);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
