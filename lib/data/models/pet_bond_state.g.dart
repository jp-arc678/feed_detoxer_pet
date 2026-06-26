// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_bond_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetBondStateAdapter extends TypeAdapter<PetBondState> {
  @override
  final int typeId = 3;

  @override
  PetBondState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetBondState(
      bondScore: fields[0] as double,
      moodBaseline: fields[1] as double,
      streakDays: fields[2] as int,
      lastInteractionAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PetBondState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.bondScore)
      ..writeByte(1)
      ..write(obj.moodBaseline)
      ..writeByte(2)
      ..write(obj.streakDays)
      ..writeByte(3)
      ..write(obj.lastInteractionAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetBondStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
