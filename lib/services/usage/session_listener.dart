import 'dart:async';
import 'package:flutter/foundation.dart';

import 'brain_channel.dart';
import '../../core/config.dart';
import '../../data/models/session_record.dart';
import '../../data/repositories/bond_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/target_app_repository.dart';
import '../../services/mood/mood_engine.dart';

// Listens to Brain events and persists completed sessions to Hive.
// Also updates the bond score on every session end.
// Single source of Hive writes for SessionRecord + PetBondState (per CLAUDE.md write rule).
class SessionListener {
  SessionListener._();
  static final SessionListener _instance = SessionListener._();
  static SessionListener get instance => _instance;

  StreamSubscription<BrainEvent>? _sub;
  final _sessionRepo = SessionRepository();
  final _bondRepo = BondRepository();
  final _targetRepo = TargetAppRepository();

  DateTime? _sessionStart;
  String? _activePackage;

  void start() {
    _sub?.cancel();
    _sub = BrainChannel.events.listen(_onEvent, onError: _onError);
    debugPrint('[SessionListener] started');
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onEvent(BrainEvent event) {
    switch (event.type) {
      case BrainEventType.sessionStarted:
        _sessionStart = DateTime.now();
        _activePackage = event.packageName;
        debugPrint('[SessionListener] session started: ${event.packageName}');

      case BrainEventType.sessionEnded:
        if (_sessionStart != null && _activePackage == event.packageName) {
          final record = SessionRecord(
            id: '${event.packageName}_${_sessionStart!.millisecondsSinceEpoch}',
            packageName: event.packageName,
            startTime: _sessionStart!,
            endTime: DateTime.now(),
            durationSec: event.durationSec ?? 0,
            outcome: event.outcome ?? 'completed',
          );
          _sessionRepo.append(record);
          debugPrint('[SessionListener] saved session: ${event.packageName} '
              '${record.durationSec}s');

          _updateBond(
            packageName: event.packageName,
            durationSec: event.durationSec ?? 0,
          );

          _sessionStart = null;
          _activePackage = null;
        }

      case BrainEventType.thresholdCrossed:
        debugPrint('[SessionListener] threshold crossed: '
            '${event.packageName} @ ${event.elapsedMinutes}min');

      case BrainEventType.unknown:
        break;
    }
  }

  void _updateBond({required String packageName, required int durationSec}) {
    final config = _targetRepo.get(packageName);
    final threshold =
        config?.thresholdMinutes ?? AppConfig.defaultThresholdMinutes;
    final withinThreshold = (durationSec / 60) <= threshold;

    final current = _bondRepo.get();
    final updated = MoodEngine.applySessionOutcome(
      current,
      withinThreshold: withinThreshold,
    );
    _bondRepo.save(updated);
    debugPrint('[SessionListener] bond updated: '
        '${current.bondScore.toStringAsFixed(1)} → ${updated.bondScore.toStringAsFixed(1)}');
  }

  void _onError(Object error) =>
      debugPrint('[SessionListener] stream error: $error');
}
