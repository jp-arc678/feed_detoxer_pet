import 'package:hive/hive.dart';

part 'pet_persona.g.dart';

@HiveType(typeId: 2)
class PetPersona {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String userNickname;

  @HiveField(2)
  final String tone;

  @HiveField(3)
  final String language;

  @HiveField(4)
  final String reminderNotes;

  const PetPersona({
    this.name = 'Peto',
    this.userNickname = 'buddy',
    this.tone = 'friendly',
    this.language = 'English',
    this.reminderNotes = '',
  });

  PetPersona copyWith({
    String? name,
    String? userNickname,
    String? tone,
    String? language,
    String? reminderNotes,
  }) {
    return PetPersona(
      name: name ?? this.name,
      userNickname: userNickname ?? this.userNickname,
      tone: tone ?? this.tone,
      language: language ?? this.language,
      reminderNotes: reminderNotes ?? this.reminderNotes,
    );
  }
}
