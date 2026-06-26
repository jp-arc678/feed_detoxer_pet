// Single source of truth for all tunable constants.
// Adjust values here without touching logic files.

class AppConfig {
  // --- Session detection ---
  static const int sessionDebounceSeconds = 3;
  static const int usagePollIntervalSeconds = 1;

  // --- Default per-app threshold ---
  static const int defaultThresholdMinutes = 10;

  // --- Overlay cadence ---
  static const int overlayRepeatIntervalMinutes = 5;
  static const int guardPageDurationSeconds = 10;

  // --- Mood / bond weights (§8.4) ---
  static const double bondGainOnCompliance = 5.0;
  static const double bondGainOnStreak = 3.0;
  static const double bondGainOnInteraction = 1.0;
  static const double bondDecayOnOverrun = 2.0;
  static const double bondDecayOnNeglect = 1.0;
  static const double bondMax = 100.0;
  static const double bondMin = 0.0;

  // --- Mood baseline calculation ---
  // Number of recent days used to compute baseline
  static const int moodBaselineLookbackDays = 3;
  // Blend factor: how much bond score shifts the baseline
  static const double moodBaselineBondWeight = 0.3;

  // --- Mood intensity escalation (session) ---
  // mood = clamp01(elapsedMinutes / thresholdMinutes)
  // cry trigger fires when intensity exceeds this value
  static const double cryTriggerThreshold = 0.85;

  // --- Streak ---
  static const int streakResetAfterMissedDays = 1;

  // --- Pet rendering ---
  // Set to true in Phase 10 once pet.riv is ready; no other code changes needed.
  static const bool useRivePet = false;
}
