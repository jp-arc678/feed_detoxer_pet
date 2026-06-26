import 'pet_controller.dart';

// Phase 10: load assets/rive/pet.riv and wire PetSM inputs.
// Enable by setting AppConfig.useRivePet = true in lib/core/config.dart.
// The widget that renders this controller lives in RivePetWidget (Phase 10).
class RivePetController extends PetController {
  double _mood = 0.3;
  String? _activeTrigger;
  bool _isDragging = false;

  @override
  double get mood => _mood;

  @override
  String? get activeTrigger => _activeTrigger;

  @override
  bool get isDragging => _isDragging;

  @override
  void setMood(double value) {
    _mood = value.clamp(0.0, 1.0);
    // Phase 10: stateMachine.findInput<double>('mood')?.value = _mood;
    notifyListeners();
  }

  @override
  void fire(String trigger) {
    _activeTrigger = trigger;
    // Phase 10: stateMachine.findInput<RiveTriggerInput>(trigger)?.fire();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () {
      _activeTrigger = null;
      notifyListeners();
    });
  }

  @override
  void setDragging(bool value) {
    _isDragging = value;
    // Phase 10: stateMachine.findInput<bool>('isDragging')?.value = _isDragging;
    notifyListeners();
  }
}
