// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_goals.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyGoalAdapter extends TypeAdapter<BodyGoal> {
  @override
  final int typeId = 16;

  @override
  BodyGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyGoal(
      id: fields[0] as String?,
      field: fields[1] as BodyField,
      target: fields[2] as double,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BodyGoal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.field)
      ..writeByte(2)
      ..write(obj.target)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
