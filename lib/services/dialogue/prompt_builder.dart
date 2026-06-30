import 'pet_dialogue_provider.dart';

// Builds the system instruction and user message sent to the LLM.
// Kept separate so the prompt can be tuned without touching provider logic.
class PromptBuilder {
  static String systemInstruction(DialogueRequest req) {
    final p = req.persona;
    final notes = p.reminderNotes.isNotEmpty
        ? '\nExtra context the pet knows: ${p.reminderNotes}'
        : '';
    return '''You are a cute digital pet named ${p.name}.
Personality: ${p.tone}.
Speak in ${p.language}.
Call the user "${p.userNickname}".$notes

Rules (strictly follow):
- Maximum 140 characters total.
- Use the user's nickname naturally.
- Warm, supportive, never guilt-tripping.
- End the message with a tilde (~).
- Respond in ${p.language} only.
- No medical advice. No harmful content.''';
  }

  static String userMessage(DialogueRequest req) {
    return switch (req.trigger) {
      DialogueTrigger.alarm         => _alarm(req),
      DialogueTrigger.greeting      => 'Write a short warm greeting for the user.',
      DialogueTrigger.recordComment => _record(req),
      DialogueTrigger.interaction   => 'The user just poked you. React cutely in 1 sentence.',
    };
  }

  static String _alarm(DialogueRequest req) {
    final app = req.appDisplayName ?? 'this app';
    final elapsed = req.elapsedMinutes ?? 0;
    final threshold = req.thresholdMinutes ?? 10;
    final over = elapsed - threshold;
    final mood = req.moodIntensity;
    final style = mood <= 0.25
        ? 'gently remind'
        : mood <= 0.5
            ? 'express mild concern'
            : mood <= 0.75
                ? 'plead warmly'
                : 'sound genuinely worried but still loving';
    return 'The user has been in "$app" for $elapsed minutes '
        '(limit: $threshold min, ${over > 0 ? "$over min over" : "just hit the limit"}). '
        'Please $style. One or two short sentences.';
  }

  static String _record(DialogueRequest req) {
    final mood = req.moodIntensity;
    final u = req.usage;
    final usageNote = u != null
        ? ' They used tracked apps for ${u.totalSecToday ~/ 60} min today.'
        : '';
    final style = mood <= 0.3
        ? 'encouragingly — they are doing well'
        : mood <= 0.6
            ? 'with gentle encouragement — average day'
            : 'warmly and supportively — they are struggling';
    return 'Comment on the user\'s screen-time record $style.$usageNote '
        'Keep it uplifting. One or two sentences.';
  }
}
