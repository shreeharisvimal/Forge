// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement_fields.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyFieldAdapter extends TypeAdapter<BodyField> {
  @override
  final int typeId = 17;

  @override
  BodyField read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BodyField.weight;
      case 1:
        return BodyField.waist;
      case 2:
        return BodyField.hip;
      case 3:
        return BodyField.chest;
      case 4:
        return BodyField.neck;
      case 5:
        return BodyField.shoulders;
      case 6:
        return BodyField.leftArm;
      case 7:
        return BodyField.rightArm;
      case 8:
        return BodyField.leftForearm;
      case 9:
        return BodyField.rightForearm;
      case 10:
        return BodyField.leftThigh;
      case 11:
        return BodyField.rightThigh;
      case 12:
        return BodyField.leftCalf;
      case 13:
        return BodyField.rightCalf;
      case 14:
        return BodyField.bodyFat;
      default:
        return BodyField.weight;
    }
  }

  @override
  void write(BinaryWriter writer, BodyField obj) {
    switch (obj) {
      case BodyField.weight:
        writer.writeByte(0);
        break;
      case BodyField.waist:
        writer.writeByte(1);
        break;
      case BodyField.hip:
        writer.writeByte(2);
        break;
      case BodyField.chest:
        writer.writeByte(3);
        break;
      case BodyField.neck:
        writer.writeByte(4);
        break;
      case BodyField.shoulders:
        writer.writeByte(5);
        break;
      case BodyField.leftArm:
        writer.writeByte(6);
        break;
      case BodyField.rightArm:
        writer.writeByte(7);
        break;
      case BodyField.leftForearm:
        writer.writeByte(8);
        break;
      case BodyField.rightForearm:
        writer.writeByte(9);
        break;
      case BodyField.leftThigh:
        writer.writeByte(10);
        break;
      case BodyField.rightThigh:
        writer.writeByte(11);
        break;
      case BodyField.leftCalf:
        writer.writeByte(12);
        break;
      case BodyField.rightCalf:
        writer.writeByte(13);
        break;
      case BodyField.bodyFat:
        writer.writeByte(14);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
