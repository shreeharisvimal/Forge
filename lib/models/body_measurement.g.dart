// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyMeasurementAdapter extends TypeAdapter<BodyMeasurement> {
  @override
  final int typeId = 8;

  @override
  BodyMeasurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMeasurement(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      weight: fields[2] as double?,
      waist: fields[3] as double?,
      neck: fields[4] as double?,
      chest: fields[5] as double?,
      shoulders: fields[6] as double?,
      leftArm: fields[7] as double?,
      rightArm: fields[8] as double?,
      leftForearm: fields[9] as double?,
      rightForearm: fields[10] as double?,
      leftThigh: fields[11] as double?,
      rightThigh: fields[12] as double?,
      leftCalf: fields[13] as double?,
      rightCalf: fields[14] as double?,
      bodyFat: fields[15] as double?,
      hip: fields[16] as double?,
      notes: fields[17] as String,
      photos: (fields[18] as List?)?.cast<String>(),
      photoThumbs: (fields[19] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, BodyMeasurement obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.waist)
      ..writeByte(4)
      ..write(obj.neck)
      ..writeByte(5)
      ..write(obj.chest)
      ..writeByte(6)
      ..write(obj.shoulders)
      ..writeByte(7)
      ..write(obj.leftArm)
      ..writeByte(8)
      ..write(obj.rightArm)
      ..writeByte(9)
      ..write(obj.leftForearm)
      ..writeByte(10)
      ..write(obj.rightForearm)
      ..writeByte(11)
      ..write(obj.leftThigh)
      ..writeByte(12)
      ..write(obj.rightThigh)
      ..writeByte(13)
      ..write(obj.leftCalf)
      ..writeByte(14)
      ..write(obj.rightCalf)
      ..writeByte(15)
      ..write(obj.bodyFat)
      ..writeByte(16)
      ..write(obj.hip)
      ..writeByte(17)
      ..write(obj.notes)
      ..writeByte(18)
      ..write(obj.photos)
      ..writeByte(19)
      ..write(obj.photoThumbs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
