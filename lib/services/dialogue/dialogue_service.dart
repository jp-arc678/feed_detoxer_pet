import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../core/config.dart';
import '../../data/database.dart';
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

  // Tracks cache keys currently being generated — prevents duplicate concurrent calls.
  final _inFlight = <String>{};

  // After a quota/rate-limit error, pause all AI calls for this duration.
  // Persisted to Hive so the backoff survives app restarts.
  static const _backoffDuration = Duration(seconds: 60);
  static const _kBackoffKey = 'dialogue_backoff_until';

  bool get _isBackingOff {
    final stored = Hive.box<dynamic>(kBoxSettings).get(_kBackoffKey) as DateTime?;
    return stored != null && DateTime.now().isBefore(stored);
  }

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

  // Async: returns cached line instantly if available; otherwise generates once.
  // Does NOT schedule a background refresh — pregen() handles that at session start.
  Future<String> getLine(DialogueRequest request) async {
    final cached = _cache.get(request.cacheKey);
    if (cached != null) return cached;

    final line = await _generateWithFallback(request);
    _cache.put(request.cacheKey, line);
    return line;
  }

  // Fire-and-forget pre-generation.
  // Idempotent: skips if in-flight, already cached, or currently backing off.
  void pregen(DialogueRequest request) {
    final key = request.cacheKey;
    if (_inFlight.contains(key)) return;
    if (_cache.get(key) != null) return;
    if (_isBackingOff) {
      debugPrint('[DialogueService] pregen skipped — backing off');
      return;
    }
    _pregenAsync(request);
  }

  Future<void> _pregenAsync(DialogueRequest request) async {
    final key = request.cacheKey;
    _inFlight.add(key);
    try {
      final line = _ai != null
          ? await _ai!.generateLine(request)
          : CannedDialogueProvider.pick(request);
      _cache.put(key, line);
      debugPrint('[DialogueService] cached: $key');
    } catch (e) {
      _handleAiError(e, context: 'pregen');
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<String> _generateWithFallback(DialogueRequest request) async {
    if (_ai == null) return CannedDialogueProvider.pick(request);
    if (_isBackingOff) {
      debugPrint('[DialogueService] getLine backing off — using canned');
      return CannedDialogueProvider.pick(request);
    }
    try {
      return await _ai!
          .generateLine(request)
          .timeout(Duration(seconds: AppConfig.dialogueTimeoutSeconds),
              onTimeout: () => CannedDialogueProvider.pick(request));
    } catch (e) {
      _handleAiError(e, context: 'getLine');
      return CannedDialogueProvider.pick(request);
    }
  }

  void _handleAiError(Object e, {required String context}) {
    final msg = e.toString();
    final isQuota = msg.contains('quota') ||
        msg.contains('RESOURCE_EXHAUSTED') ||
        msg.contains('429') ||
        msg.contains('rateLimitExceeded');
    if (isQuota) {
      Hive.box<dynamic>(kBoxSettings)
          .put(_kBackoffKey, DateTime.now().add(_backoffDuration));
      debugPrint(
          '[DialogueService] [$context] rate limit — backing off ${_backoffDuration.inSeconds}s');
    } else {
      debugPrint('[DialogueService] [$context] AI error, using canned: $e');
    }
  }
}
