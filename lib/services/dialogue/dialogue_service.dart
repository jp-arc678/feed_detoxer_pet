import 'package:flutter/foundation.dart';

import '../../core/config.dart';
import '../../data/repositories/persona_repository.dart';
import '../../data/models/pet_persona.dart';
import 'canned_dialogue_provider.dart';
import 'dialogue_cache.dart';
import 'firebase_ai_dialogue_provider.dart';
import 'pet_dialogue_provider.dart';

// Orchestrates the two providers: AI (optional) → cache → canned fallback.
// Call init() once from main() before runApp.
class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  PetDialogueProvider? _ai;
  final _cache = DialogueCache.instance;

  void init() {
    if (AppConfig.useFirebaseAi) {
      _ai = FirebaseAiDialogueProvider();
    }
    debugPrint('[DialogueService] started (AI=${AppConfig.useFirebaseAi})');
  }

  PetPersona get currentPersona => PersonaRepository().get();

  // Returns immediately: cached line first, canned fallback if nothing cached.
  // Safe to call from the overlay or any sync context.
  String getLineSync(DialogueRequest request) {
    return _cache.get(request.cacheKey) ?? CannedDialogueProvider.pick(request);
  }

  // Async: returns the best available line and refreshes the cache in background.
  Future<String> getLine(DialogueRequest request) async {
    final cached = _cache.get(request.cacheKey);
    if (cached != null) {
      _pregenAsync(request); // top up the cache while the cached line is served
      return cached;
    }
    final line = await _generateWithFallback(request);
    _cache.put(request.cacheKey, line);
    return line;
  }

  // Fire-and-forget pre-generation.
  // Call at session start so overlay lines are ready before they're needed.
  void pregen(DialogueRequest request) => _pregenAsync(request);

  Future<void> _pregenAsync(DialogueRequest request) async {
    try {
      final line = _ai != null
          ? await _ai!.generateLine(request)
          : CannedDialogueProvider.pick(request);
      _cache.put(request.cacheKey, line);
      debugPrint('[DialogueService] cached: ${request.cacheKey}');
    } catch (e) {
      debugPrint('[DialogueService] pregen error (ignored): $e');
    }
  }

  Future<String> _generateWithFallback(DialogueRequest request) async {
    if (_ai == null) return CannedDialogueProvider.pick(request);
    try {
      return await _ai!
          .generateLine(request)
          .timeout(Duration(seconds: AppConfig.dialogueTimeoutSeconds),
              onTimeout: () => CannedDialogueProvider.pick(request));
    } catch (e) {
      debugPrint('[DialogueService] AI error, using canned: $e');
      return CannedDialogueProvider.pick(request);
    }
  }
}
