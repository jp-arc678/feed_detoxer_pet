import '../../data/models/pet_persona.dart';

enum DialogueTrigger { greeting, recordComment, alarm, interaction }

class UsageSummary {
  final int totalSecToday;
  final int openCountToday;
  const UsageSummary({required this.totalSecToday, required this.openCountToday});
}

class DialogueRequest {
  final DialogueTrigger trigger;
  final PetPersona persona;
  final String? appDisplayName;
  final int? elapsedMinutes;
  final int? thresholdMinutes;
  final double moodIntensity;
  final UsageSummary? usage;

  const DialogueRequest({
    required this.trigger,
    required this.persona,
    required this.moodIntensity,
    this.appDisplayName,
    this.elapsedMinutes,
    this.thresholdMinutes,
    this.usage,
  });

  // Cache key — bucketed by mood (5 steps) so nearby intensities share variants.
  String get cacheKey {
    final bucket = (moodIntensity * 4).round();
    return '${trigger.name}_${bucket}_${appDisplayName ?? ""}';
  }
}

abstract class PetDialogueProvider {
  Future<String> generateLine(DialogueRequest request);
  void dispose() {}
}
