import 'package:flutter/material.dart';

import 'pet_controller.dart';

// Visual placeholder for the pet until pet.riv is ready.
// Wrapped in RepaintBoundary per CLAUDE.md §8.2 note 4.
class PlaceholderPetWidget extends StatefulWidget {
  const PlaceholderPetWidget({
    super.key,
    required this.controller,
    this.size = 160.0,
  });

  final PetController controller;
  final double size;

  @override
  State<PlaceholderPetWidget> createState() => _PlaceholderPetWidgetState();
}

class _PlaceholderPetWidgetState extends State<PlaceholderPetWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late Animation<double> _scale;
  String? _lastTrigger;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = _scaleFor(1.3);
    widget.controller.addListener(_onControllerNotify);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerNotify);
    _anim.dispose();
    super.dispose();
  }

  void _onControllerNotify() {
    final trigger = widget.controller.activeTrigger;
    if (trigger != null && trigger != _lastTrigger) {
      _lastTrigger = trigger;
      _scale = _scaleFor(_peakFor(trigger));
      _anim.forward(from: 0);
    } else if (trigger == null) {
      _lastTrigger = null;
    }
  }

  Animation<double> _scaleFor(double peak) => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: peak), weight: 40),
        TweenSequenceItem(tween: Tween(begin: peak, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));

  double _peakFor(String trigger) => switch (trigger) {
        'poke' => 1.3,
        'celebrate' => 1.5,
        'cry' => 0.8,
        _ => 1.15,
      };

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_anim, widget.controller]),
        builder: (_, _) {
          final mood = widget.controller.mood;
          final trigger = widget.controller.activeTrigger;

          final bgColor = Color.lerp(
            const Color(0xFFB2DFDB), // teal-100 (happy)
            const Color(0xFFFFCDD2), // red-100 (distressed)
            mood,
          )!;
          final borderColor = Color.lerp(
            const Color(0xFF26A69A), // teal (happy)
            const Color(0xFFEF5350), // red (distressed)
            mood,
          )!;

          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.5),
              ),
              child: Center(
                child: Text(
                  _emoji(mood, trigger),
                  style: TextStyle(fontSize: widget.size * 0.4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _emoji(double mood, String? trigger) {
    return switch (trigger) {
      'poke' => '😲',
      'celebrate' => '🎉',
      'cry' => '😭',
      'greet' || 'wave' => '👋',
      _ => switch (mood) {
          < 0.25 => '😊',
          < 0.5 => '😟',
          < 0.75 => '🥺',
          _ => '😭',
        },
    };
  }
}
