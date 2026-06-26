import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// Guard page: shown when a target app session starts.
// Gives the user 10 seconds to reconsider; auto-closes after countdown.
class GuardPage extends StatefulWidget {
  const GuardPage({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  State<GuardPage> createState() => _GuardPageState();
}

class _GuardPageState extends State<GuardPage> {
  late int _secondsLeft;
  Timer? _timer;

  String get _displayName =>
      widget.data['displayName'] as String? ?? 'this app';
  int get _total => widget.data['guardSeconds'] as int? ?? 10;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _total;
    _startCountdown();
  }

  @override
  void didUpdateWidget(GuardPage old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _timer?.cancel();
      setState(() => _secondsLeft = _total);
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
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

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / _total;
    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 72, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              'Hold up!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "You're about to open $_displayName.\nAre you sure?",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    color: Colors.amber,
                    backgroundColor: Colors.white24,
                  ),
                  Center(
                    child: Text(
                      '$_secondsLeft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _dismiss,
              icon: const Icon(Icons.close),
              label: const Text('Skip — go in anyway'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
