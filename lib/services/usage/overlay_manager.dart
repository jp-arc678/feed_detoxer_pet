import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../core/config.dart';
import '../../data/repositories/target_app_repository.dart';
import 'brain_channel.dart';

// Listens to Brain events and drives the overlay window.
// Runs in the main Flutter engine (kept alive by the Brain foreground service).
class OverlayManager {
  OverlayManager._();
  static final OverlayManager instance = OverlayManager._();

  StreamSubscription<BrainEvent>? _sub;

  void start() {
    _sub?.cancel();
    _sub = BrainChannel.events.listen(_onEvent, onError: _onError);
    debugPrint('[OverlayManager] started');
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onEvent(BrainEvent event) {
    switch (event.type) {
      case BrainEventType.sessionStarted:
        _showGuard(event.packageName);

      case BrainEventType.thresholdCrossed:
        _maybeShowPet(
          packageName: event.packageName,
          elapsedMin: event.elapsedMinutes ?? 0,
        );

      case BrainEventType.sessionEnded:
        _close();

      case BrainEventType.unknown:
        break;
    }
  }

  Future<void> _showGuard(String packageName) async {
    if (!await _permissionGranted()) return;
    final config = TargetAppRepository().get(packageName);
    if (config == null || !config.enabled) return;

    await _ensureOverlayVisible();
    await FlutterOverlayWindow.shareData(<String, dynamic>{
      'type': 'guard',
      'packageName': packageName,
      'displayName': config.displayName,
      'guardSeconds': AppConfig.guardPageDurationSeconds,
    });
    debugPrint('[OverlayManager] guard shown for ${config.displayName}');
  }

  Future<void> _maybeShowPet({
    required String packageName,
    required int elapsedMin,
  }) async {
    if (!await _permissionGranted()) return;
    final config = TargetAppRepository().get(packageName);
    if (config == null || !config.enabled) return;

    final threshold = config.thresholdMinutes;

    // Only show once threshold is actually crossed.
    if (elapsedMin < threshold) return;

    // Show at the moment threshold is crossed, then every repeat interval.
    final minutesPast = elapsedMin - threshold;
    final isFirstCross = minutesPast == 0;
    final isRepeat =
        minutesPast > 0 && minutesPast % AppConfig.overlayRepeatIntervalMinutes == 0;
    if (!isFirstCross && !isRepeat) return;

    await _ensureOverlayVisible();
    await FlutterOverlayWindow.shareData(<String, dynamic>{
      'type': 'pet',
      'packageName': packageName,
      'displayName': config.displayName,
      'elapsedMinutes': elapsedMin,
      'thresholdMinutes': threshold,
    });
    debugPrint('[OverlayManager] pet overlay shown: '
        '${config.displayName} at ${elapsedMin}min (threshold ${threshold}min)');
  }

  Future<void> _close() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      debugPrint('[OverlayManager] overlay closed');
    } catch (e) {
      debugPrint('[OverlayManager] closeOverlay error: $e');
    }
  }

  Future<void> _ensureOverlayVisible() async {
    try {
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        enableDrag: false,
      );
    } catch (e) {
      debugPrint('[OverlayManager] showOverlay error: $e');
    }
  }

  Future<bool> _permissionGranted() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  void _onError(Object error) =>
      debugPrint('[OverlayManager] stream error: $error');
}
