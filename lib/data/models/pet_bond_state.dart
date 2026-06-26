import 'package:hive/hive.dart';

part 'pet_bond_state.g.dart';

@HiveType(typeId: 3)
class PetBondState {
  @HiveField(0)
  final double bondScore;

  @HiveField(1)
  final double moodBaseline;

  @HiveField(2)
  final int streakDays;

  @HiveField(3)
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
