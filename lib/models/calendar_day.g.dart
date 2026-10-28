// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarDayAdapter extends TypeAdapter<CalendarDay> {
  @override
  final int typeId = 6;

  @override
  CalendarDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarDay(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      weight: fields[2] as double?,
      workoutCompleted: fields[3] as bool,
      sleepHours: fields[4] as double?,
      waterLitres: fields[5] as double?,
      mood: fields[6] as int?,
      notes: fields[7] as String,
      durationMinutes: fields[8] as int,
      photos: (fields[9] as List?)?.cast<String>(),
      photoThumbs: (fields[10] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CalendarDay obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.workoutCompleted)
      ..writeByte(4)
      ..write(obj.sleepHours)
      ..writeByte(5)
      ..write(obj.waterLitres)
      ..writeByte(6)
      ..write(obj.mood)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.durationMinutes)
      ..writeByte(9)
      ..write(obj.photos)
      ..writeByte(10)
      ..write(obj.photoThumbs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
