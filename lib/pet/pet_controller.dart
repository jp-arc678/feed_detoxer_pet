import 'package:flutter/foundation.dart';

// Trigger name constants — must match the Rive PetSM input names exactly.
// See PET_RIVE_CONTRACT.md for the full contract.
abstract class PetController extends ChangeNotifier {
  static const greet = 'greet';
  static const poke = 'poke';
  static const celebrate = 'celebrate';
  static const cry = 'cry';
  static const wave = 'wave';

  double get mood;          // 0.0 = cheerful … 1.0 = distressed
  bool get isDragging;
  String? get activeTrigger;

  void setMood(double value);
  void fire(String trigger);
  void setDragging(bool value);
}
