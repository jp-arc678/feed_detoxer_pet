// ignore_for_file: deprecated_member_use
import 'package:rive/rive.dart' show BooleanInput, NumberInput, TriggerInput;

import 'pet_controller.dart';

// Drives the real Rive animation. Enable by setting AppConfig.useRivePet = true.
// Inputs are null until RivePetWidget calls bindInputs() after loading pet.riv.
// The file-level ignore suppresses deprecation warnings on the Rive input
// accessor methods — the data-binding alternative requires editor setup and is
// not suitable for code-controlled animations.
class RivePetController extends PetController {
  double _mood = 0.3;
  String? _activeTrigger;
  bool _isDragging = false;

  NumberInput? _moodInput;
  final Map<String, TriggerInput> _triggerInputs = {};
  BooleanInput? _isDraggingInput;

  // Called by RivePetWidget once the .riv file is loaded and the state machine
  // is initialised. Immediately pushes current state into the Rive inputs.
  void bindInputs({
    required NumberInput? moodInput,
    required Map<String, TriggerInput> triggerInputs,
    required BooleanInput? isDraggingInput,
  }) {
    _moodInput = moodInput;
    _triggerInputs
      ..clear()
      ..addAll(triggerInputs);
    _isDraggingInput = isDraggingInput;
    _moodInput?.value = _mood;
    _isDraggingInput?.value = _isDragging;
  }

  // Called by RivePetWidget in dispose() to avoid dangling references after
  // the widget tree removes the renderer.
  void clearInputs() {
    _moodInput = null;
    _triggerInputs.clear();
    _isDraggingInput = null;
  }

  @override
  double get mood => _mood;

  @override
  String? get activeTrigger => _activeTrigger;

  @override
  bool get isDragging => _isDragging;

  @override
  void setMood(double value) {
    _mood = value.clamp(0.0, 1.0);
    _moodInput?.value = _mood;
    notifyListeners();
  }

  @override
  void fire(String trigger) {
    _activeTrigger = trigger;
    _triggerInputs[trigger]?.fire();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () {
      _activeTrigger = null;
      notifyListeners();
    });
  }

  @override
  void setDragging(bool value) {
    _isDragging = value;
    _isDraggingInput?.value = value;
    notifyListeners();
  }
}
