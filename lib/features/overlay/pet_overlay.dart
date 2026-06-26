import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../pet/placeholder_pet_controller.dart';
import '../../pet/placeholder_pet_widget.dart';
import '../../pet/pet_controller.dart';
import '../../services/mood/mood_engine.dart';

// Pet overlay: shown when elapsed time crosses the app's threshold.
// Stateless — all data arrives via FlutterOverlayWindow.shareData().
// Auto-dismisses after 8 seconds; user can also tap to dismiss.
class PetOverlayPage extends StatefulWidget {
  const PetOverlayPage({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  State<PetOverlayPage> createState() => _PetOverlayPageState();
}

class _PetOverlayPageState extends State<PetOverlayPage> {
  static const _autoDismissSec = 8;

  late final PlaceholderPetController _controller;
  Timer? _timer;
  int _secondsLeft = _autoDismissSec;

  String get _displayName =>
      widget.data['displayName'] as String? ?? 'this app';
  int get _elapsed => widget.data['elapsedMinutes'] as int? ?? 0;
  int get _threshold => widget.data['thresholdMinutes'] as int? ?? 10;

  @override
  void initState() {
    super.initState();
    _controller = PlaceholderPetController();
    _applyMood();
    _startDismissTimer();
  }

  @override
  void didUpdateWidget(PetOverlayPage old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _applyMood();
      _timer?.cancel();
      setState(() => _secondsLeft = _autoDismissSec);
      _startDismissTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _applyMood() {
    final intensity = MoodEngine.sessionIntensity(_elapsed, _threshold);
    _controller.setMood(intensity);
    if (intensity >= 0.85) _controller.fire(PetController.cry);
  }

  void _startDismissTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    await FlutterOverlayWindow.closeOverlay();
  }

  String _cannedLine() {
    final nickname = 'buddy';
    if (_elapsed == _threshold) {
      return "hey $nickname~ it's been $_elapsed minutes in $_displayName already~";
    }
    return "$nickname~ $_elapsed minutes in $_displayName... are you okay?~";
  }

  @override
  Widget build(BuildContext context) {
    final intensity = MoodEngine.sessionIntensity(_elapsed, _threshold);
    final borderColor = Color.lerp(
      const Color(0xFF26A69A),
      const Color(0xFFEF5350),
      intensity,
    )!;

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.black.withValues(alpha: 0.82),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlaceholderPetWidget(controller: _controller, size: 140),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.07),
                ),
                child: Text(
                  _cannedLine(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Tap anywhere to dismiss  •  $_secondsLeft s',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
