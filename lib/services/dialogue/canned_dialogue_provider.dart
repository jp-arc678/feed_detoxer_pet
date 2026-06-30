import 'dart:math';

import 'pet_dialogue_provider.dart';

// Offline-first provider: returns a line immediately from templated pools.
// Used as the instant fallback when the AI provider is unavailable or slow.
class CannedDialogueProvider implements PetDialogueProvider {
  static final _rng = Random();

  @override
  Future<String> generateLine(DialogueRequest request) async => pick(request);

  @override
  void dispose() {}

  static String pick(DialogueRequest request) {
    final n = request.persona.userNickname;
    final pet = request.persona.name;
    final app = request.appDisplayName ?? 'that app';
    final elapsed = request.elapsedMinutes ?? 0;
    final threshold = request.thresholdMinutes ?? 10;
    final intensity = request.moodIntensity;

    final pool = switch (request.trigger) {
      DialogueTrigger.alarm      => _alarm(n, app, elapsed, threshold, intensity),
      DialogueTrigger.greeting   => _greeting(n, pet),
      DialogueTrigger.recordComment => _record(n, intensity),
      DialogueTrigger.interaction => _interaction(n),
    };
    return pool[_rng.nextInt(pool.length)];
  }

  static List<String> _alarm(
      String n, String app, int elapsed, int threshold, double intensity) {
    if (intensity <= 0.25) {
      return [
        "hey $n~ it's been $elapsed minutes in $app already~",
        "just a little reminder $n~ $elapsed minutes in $app!",
        "psst $n~ $elapsed min in $app~ maybe a tiny stretch soon?",
      ];
    } else if (intensity <= 0.5) {
      return [
        "$n~ $elapsed minutes in $app... take a little break?~",
        "hey $n~ ${elapsed - threshold} minutes past the limit in $app~",
        "you've been in $app for $elapsed minutes $n~ i'm noticing~",
      ];
    } else if (intensity <= 0.75) {
      return [
        "$n~ $elapsed minutes in $app... i'm a little worried~",
        "are you okay $n~? that's $elapsed minutes in $app now~",
        "$n~ ${elapsed - threshold} min over the limit... can we take a break?~",
      ];
    } else {
      return [
        "$n~ $elapsed minutes... please come back~ i miss you~",
        "i'm really worried $n~ $elapsed minutes in $app is a lot~",
        "$n~! it's been so long~ please take a break from $app~",
      ];
    }
  }

  static List<String> _greeting(String n, String pet) {
    return [
      "hey $n~! so glad you're here~ i missed you!",
      "hi $n~! it's me, $pet~ let's have a great day together!",
      "hello $n~! i'm always here for you~",
      "good to see you $n~! how are you feeling today?~",
    ];
  }

  static List<String> _record(String n, double intensity) {
    if (intensity <= 0.3) {
      return [
        "you're doing amazing $n~! i'm so proud of you!",
        "wow $n~ such great progress! keep it up~",
        "look at you $n~ absolutely crushing it today!",
      ];
    } else if (intensity <= 0.6) {
      return [
        "let's do our best today $n~! i believe in you!",
        "today is a fresh start $n~! we can do this together~",
        "every day is a new chance $n~! let's make it great!",
      ];
    } else {
      return [
        "it's okay $n~~ every day is a new beginning~",
        "i'm still here for you $n~! let's try again today~",
        "no pressure $n~~ i care about you no matter what~",
      ];
    }
  }

  static List<String> _interaction(String n) {
    return [
      "hehe~ got me $n~!",
      "poke poke~ hi $n~!",
      "ehe~ $n you're so playful~",
      "that tickles $n~!",
      "hehehe~ do it again $n~!",
    ];
  }
}
