import '../../core/config.dart';
import '../../data/models/pet_bond_state.dart';

// All mood/bond calculations. Named constants live in AppConfig (config.dart).
// Three timescales per CLAUDE.md §8.4:
//   1. Bond score (slow/persistent) — updated on session outcome & interaction
//   2. Mood baseline (medium) — derived from bond score, stored in PetBondState
//   3. Session intensity (fast/transient) — computed live from elapsed vs threshold
class MoodEngine {
  // ── Fast: session intensity ──────────────────────────────────────────────
  // mood = clamp01(elapsedMinutes / thresholdMinutes)
  static double sessionIntensity(int elapsedMin, int thresholdMin) =>
      (elapsedMin / thresholdMin.toDouble()).clamp(0.0, 1.0);

  // ── Medium: mood baseline from bond score ────────────────────────────────
  // Bond 0  → baseline 0.5 (neutral/slightly worried)
  // Bond 100 → baseline ~0.2 (clearly happy)
  static double bondToBaseline(double bondScore) {
    final factor = (bondScore / AppConfig.bondMax).clamp(0.0, 1.0);
    return (0.5 - factor * AppConfig.moodBaselineBondWeight).clamp(0.0, 1.0);
  }

  // ── Slow: bond updates ───────────────────────────────────────────────────

  // Called when a session ends. withinThreshold = user stopped in time.
  static PetBondState applySessionOutcome(
    PetBondState s, {
    required bool withinThreshold,
  }) {
    final delta = withinThreshold
        ? AppConfig.bondGainOnCompliance
        : -AppConfig.bondDecayOnOverrun;
    final newScore =
        (s.bondScore + delta).clamp(AppConfig.bondMin, AppConfig.bondMax);
    return s.copyWith(
      bondScore: newScore,
      moodBaseline: bondToBaseline(newScore),
    );
  }

  // Called when user interacts with the pet (poke, etc.).
  static PetBondState applyInteraction(PetBondState s) {
    final newScore = (s.bondScore + AppConfig.bondGainOnInteraction)
        .clamp(AppConfig.bondMin, AppConfig.bondMax);
    return s.copyWith(
      bondScore: newScore,
      moodBaseline: bondToBaseline(newScore),
      lastInteractionAt: DateTime.now(),
    );
  }
}
