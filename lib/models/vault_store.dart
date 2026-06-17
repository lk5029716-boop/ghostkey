import 'package:flutter/foundation.dart';

enum TimerStatus { active, warning, expired }

class VaultStore extends ChangeNotifier {
  bool _isLoggedIn = false;

  TimerStatus get timerStatus => TimerStatus.active;
  int get daysRemaining => 65;
  bool get isLoggedIn => _isLoggedIn;

  void checkIn() {
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  List<String> get secrets => [];
  void addSecret(Map<String, String> secret) {}
  void removeSecret(int index) {}
}