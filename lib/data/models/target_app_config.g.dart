// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_app_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TargetAppConfigAdapter extends TypeAdapter<TargetAppConfig> {
  @override
  final int typeId = 0;

  @override
  TargetAppConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TargetAppConfig(
      packageName: fields[0] as String,
      displayName: fields[1] as String,
      thresholdMinutes: fields[2] as int,
      enabled: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TargetAppConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.thresholdMinutes)
      ..writeByte(3)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetAppConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
