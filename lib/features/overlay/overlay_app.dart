import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../core/theme.dart';
import 'guard_page.dart';
import 'pet_overlay.dart';

// Root widget for the overlay Flutter engine.
// Receives data from the main engine via FlutterOverlayWindow.shareData().
class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const _OverlayRoot(),
    );
  }
}

class _OverlayRoot extends StatefulWidget {
  const _OverlayRoot();

  @override
  State<_OverlayRoot> createState() => _OverlayRootState();
}

class _OverlayRootState extends State<_OverlayRoot> {
  Map<String, dynamic>? _data;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FlutterOverlayWindow.overlayListener.listen(_onData);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onData(dynamic raw) {
    if (!mounted || raw == null) return;
    setState(() {
      _data = Map<String, dynamic>.from(raw as Map);
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = _data?['type'] as String?;
    return switch (type) {
      'guard' => GuardPage(data: _data!),
      'pet' => PetOverlayPage(data: _data!),
      _ => const SizedBox.shrink(),
    };
  }
}
