import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/secret.dart';
import '../models/heir.dart';

class VaultStore extends ChangeNotifier {
  final SharedPreferences _prefs;

  List<Secret> _secrets = [];
  List<Heir> _heirs = [];
  int _timerDays = 30;
  int _daysRemaining = 30;
  bool _isPremium = false;
  bool _isLoggedIn = false;
  TimerStatus _timerStatus = TimerStatus.active;

  VaultStore(this._prefs) {
    _load();
  }

  // Getters
  List<Secret> get secrets => List.unmodifiable(_secrets);
  List<Heir> get heirs => List.unmodifiable(_heirs);
  int get timerDays => _timerDays;
  int get daysRemaining => _daysRemaining;
  bool get isPremium => _isPremium;
  bool get isLoggedIn => _isLoggedIn;
  TimerStatus get timerStatus => _timerStatus;
  bool get hasHeirs => _heirs.isNotEmpty;
  bool get hasSecrets => _secrets.isNotEmpty;

  void _load() {
    final secretsJson = _prefs.getString('secrets');
    if (secretsJson != null) {
      final list = jsonDecode(secretsJson) as List;
      _secrets = list.map((e) => Secret.fromJson(e)).toList();
    }
    final heirsJson = _prefs.getString('heirs');
    if (heirsJson != null) {
      final list = jsonDecode(heirsJson) as List;
      _heirs = list.map((e) => Heir(
        id: e['id'],
        name: e['name'],
        email: e['email'],
        phone: e['phone'],
        shareCount: e['shareCount'] ?? 1,
        notified: e['notified'] ?? false,
        addedAt: e['addedAt'] != null ? DateTime.parse(e['addedAt']) : DateTime.now(),
      )).toList();
    }
    _timerDays = _prefs.getInt('timerDays') ?? 30;
    _daysRemaining = _prefs.getInt('daysRemaining') ?? _timerDays;
    _isPremium = _prefs.getBool('isPremium') ?? false;
    _isLoggedIn = _prefs.getString('pin') != null;
    notifyListeners();
  }

  Future<void> _saveSecrets() async {
    await _prefs.setString('secrets', jsonEncode(_secrets.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveHeirs() async {
    await _prefs.setString('heirs', jsonEncode(_heirs.map((e) => {
      'id': e.id,
      'name': e.name,
      'email': e.email,
      'phone': e.phone,
      'shareCount': e.shareCount,
      'notified': e.notified,
      'addedAt': e.addedAt.toIso8601String(),
    }).toList()));
  }

  // Secrets
  void addSecret(Secret secret) {
    _secrets.add(secret);
    _saveSecrets();
    notifyListeners();
  }

  void removeSecret(String id) {
    _secrets.removeWhere((s) => s.id == id);
    _saveSecrets();
    notifyListeners();
  }

  // Heirs
  void addHeir(Heir heir) {
    _heirs.add(heir);
    _saveHeirs();
    notifyListeners();
  }

  void updateHeir(String id, Heir updated) {
    final idx = _heirs.indexWhere((h) => h.id == id);
    if (idx >= 0) {
      _heirs[idx] = updated;
      _saveHeirs();
      notifyListeners();
    }
  }

  void removeHeir(String id) {
    _heirs.removeWhere((h) => h.id == id);
    _saveHeirs();
    notifyListeners();
  }

  // Timer
  Future<void> setTimerDays(int days) async {
    _timerDays = days;
    _daysRemaining = days;
    await _prefs.setInt('timerDays', days);
    await _prefs.setInt('daysRemaining', days);
    _timerStatus = TimerStatus.active;
    notifyListeners();
  }

  Future<void> checkIn() async {
    _daysRemaining = _timerDays;
    _timerStatus = TimerStatus.active;
    await _prefs.setInt('daysRemaining', _daysRemaining);
    notifyListeners();
  }

  Future<void> decrementDay() async {
    if (_daysRemaining > 0) {
      _daysRemaining--;
      await _prefs.setInt('daysRemaining', _daysRemaining);
      if (_daysRemaining <= 3) {
        _timerStatus = TimerStatus.warning;
      }
      if (_daysRemaining <= 0) {
        _timerStatus = TimerStatus.expired;
      }
      notifyListeners();
    }
  }

  // Premium
  Future<void> setPremium(bool val) async {
    _isPremium = val;
    await _prefs.setBool('isPremium', val);
    notifyListeners();
  }

  // Auth
  Future<void> setLoggedIn(bool val) async {
    _isLoggedIn = val;
    notifyListeners();
  }

  Future<void> logout() async {
    await _prefs.remove('pin');
    _isLoggedIn = false;
    notifyListeners();
  }
}

enum TimerStatus { active, warning, expired }
