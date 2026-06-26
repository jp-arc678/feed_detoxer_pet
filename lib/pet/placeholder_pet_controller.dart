import 'pet_controller.dart';

class PlaceholderPetController extends PetController {
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
    notifyListeners();
  }

  @override
  void fire(String trigger) {
    _activeTrigger = trigger;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () {
      _activeTrigger = null;
      notifyListeners();
    });
  }

  @override
  void setDragging(bool value) {
    _isDragging = value;
    notifyListeners();
  }
}
