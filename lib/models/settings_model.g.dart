// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 11;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      id: fields[0] as String?,
      themeMode: fields[1] as String,
      accentColor: fields[2] as String,
      weightUnit: fields[3] as String,
      lengthUnit: fields[4] as String,
      restTimer: fields[5] as int,
      goalWeight: fields[7] as double?,
      oneRepMaxFormula: fields[8] as String,
      amoledMode: fields[9] as bool,
      dynamicColors: fields[10] as bool,
      language: fields[11] as String,
      hapticsEnabled: fields[12] as bool,
      countdownSound: fields[13] as bool,
      autoStartRestTimer: fields[14] as bool,
      warmUpSets: fields[15] as int,
      warmUpWeightPercent: fields[16] as int,
      weightIncrement: fields[17] as double,
      plateWeight: fields[18] as double,
      barWeight: fields[19] as double,
      unitSystem: fields[20] as String,
      waterUnit: fields[21] as String,
      workoutRemindersEnabled: fields[22] as bool,
      restRemindersEnabled: fields[23] as bool,
      dailyReminderEnabled: fields[24] as bool,
      weeklySummaryEnabled: fields[25] as bool,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.themeMode)
      ..writeByte(2)
      ..write(obj.accentColor)
      ..writeByte(3)
      ..write(obj.weightUnit)
      ..writeByte(4)
      ..write(obj.lengthUnit)
      ..writeByte(5)
      ..write(obj.restTimer)
      ..writeByte(7)
      ..write(obj.goalWeight)
      ..writeByte(8)
      ..write(obj.oneRepMaxFormula)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.amoledMode)
      ..writeByte(10)
      ..write(obj.dynamicColors)
      ..writeByte(11)
      ..write(obj.language)
      ..writeByte(12)
      ..write(obj.hapticsEnabled)
      ..writeByte(13)
      ..write(obj.countdownSound)
      ..writeByte(14)
      ..write(obj.autoStartRestTimer)
      ..writeByte(15)
      ..write(obj.warmUpSets)
      ..writeByte(16)
      ..write(obj.warmUpWeightPercent)
      ..writeByte(17)
      ..write(obj.weightIncrement)
      ..writeByte(18)
      ..write(obj.plateWeight)
      ..writeByte(19)
      ..write(obj.barWeight)
      ..writeByte(20)
      ..write(obj.unitSystem)
      ..writeByte(21)
      ..write(obj.waterUnit)
      ..writeByte(22)
      ..write(obj.workoutRemindersEnabled)
      ..writeByte(23)
      ..write(obj.restRemindersEnabled)
      ..writeByte(24)
      ..write(obj.dailyReminderEnabled)
      ..writeByte(25)
      ..write(obj.weeklySummaryEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
