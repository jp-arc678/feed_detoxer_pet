import 'package:flutter/services.dart';

// Dart-side bridge to the Kotlin BrainService.
// All session events flow through here as typed objects.
class BrainChannel {
  static const _control = MethodChannel('com.example.feeddetoxer/brain_control');
  static const _events = EventChannel('com.example.feeddetoxer/brain_events');

  static Future<void> start() => _control.invokeMethod('start');
  static Future<void> stop() => _control.invokeMethod('stop');

  static Future<void> setTargetApps(List<String> packages) =>
      _control.invokeMethod('setTargetApps', {'packages': packages});

  static Future<String> getManufacturer() async =>
      (await _control.invokeMethod<String>('getManufacturer') ?? '').toLowerCase();

  // Returns true if the MIUI auto-start settings screen was successfully opened.
  static Future<bool> openMiuiAutoStart() async =>
      (await _control.invokeMethod<bool>('openMiuiAutoStart')) ?? false;

  // Lazily cached so every caller gets the SAME broadcast stream.
  // Each call to receiveBroadcastStream() registers a NEW message handler,
  // silently replacing the previous one — only the last subscriber would ever
  // receive events. Caching here means setMessageHandler is called exactly
  // once regardless of how many listeners subscribe.
  static Stream<BrainEvent>? _eventsCache;
  static Stream<BrainEvent> get events {
    _eventsCache ??= _events
        .receiveBroadcastStream()
        .map((data) =>
            BrainEvent.fromMap(Map<String, dynamic>.from(data as Map)));
    return _eventsCache!;
  }
}

// ---------------------------------------------------------------------------
// Typed event model
// ---------------------------------------------------------------------------

enum BrainEventType { sessionStarted, thresholdCrossed, sessionEnded, unknown }

class BrainEvent {
  final BrainEventType type;
  final String packageName;
  final int? elapsedMinutes; // thresholdCrossed only
  final int? durationSec;    // sessionEnded only
  final String? outcome;     // sessionEnded only

  const BrainEvent({
    required this.type,
    required this.packageName,
    this.elapsedMinutes,
    this.durationSec,
    this.outcome,
  });

  factory BrainEvent.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? '';
    final type = switch (typeStr) {
      'sessionStarted'   => BrainEventType.sessionStarted,
      'thresholdCrossed' => BrainEventType.thresholdCrossed,
      'sessionEnded'     => BrainEventType.sessionEnded,
      _                  => BrainEventType.unknown,
    };
    return BrainEvent(
      type: type,
      packageName: map['packageName'] as String? ?? '',
      elapsedMinutes: map['elapsedMinutes'] as int?,
      durationSec: map['durationSec'] as int?,
      outcome: map['outcome'] as String?,
    );
  }

  @override
  String toString() => 'BrainEvent($type, pkg=$packageName, '
      'elapsed=$elapsedMinutes, dur=$durationSec, outcome=$outcome)';
}
