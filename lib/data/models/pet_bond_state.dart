// @HiveType annotations added in Phase 4.
class PetBondState {
  final double bondScore;
  final double moodBaseline;
  final int streakDays;
  final DateTime lastInteractionAt;

  const PetBondState({
    this.bondScore = 50.0,
    this.moodBaseline = 0.3,
    this.streakDays = 0,
    required this.lastInteractionAt,
  });

  PetBondState copyWith({
    double? bondScore,
    double? moodBaseline,
    int? streakDays,
    DateTime? lastInteractionAt,
  }) {
    return PetBondState(
      bondScore: bondScore ?? this.bondScore,
      moodBaseline: moodBaseline ?? this.moodBaseline,
      streakDays: streakDays ?? this.streakDays,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
    );
  }
}
