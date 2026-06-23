// @HiveType annotations added in Phase 4.
class PetPersona {
  final String name;
  final String userNickname;
  final String tone;
  final String language;
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
