// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_persona.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetPersonaAdapter extends TypeAdapter<PetPersona> {
  @override
  final int typeId = 2;

  @override
  PetPersona read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetPersona(
      name: fields[0] as String,
      userNickname: fields[1] as String,
      tone: fields[2] as String,
      language: fields[3] as String,
      reminderNotes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PetPersona obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.userNickname)
      ..writeByte(2)
      ..write(obj.tone)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.reminderNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetPersonaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
