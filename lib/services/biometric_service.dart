// ═══════════════════════════════════════════════════════════════
// BIOMETRIC SERVICE — real OS biometric authentication
// Wraps local_auth: checks device support, lists enrolled biometrics, and
// triggers a system BiometricPrompt. Falls back gracefully when the device
// has no fingerprint/face/iris enrolled or hardware is unavailable.
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const _kEnabledKey = 'biometric_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  // True if the user has opted in to biometric unlock. Default false.
  bool get isEnabled {
    return _prefs?.getBool(_kEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final p = await _ensurePrefs();
    await p.setBool(_kEnabledKey, value);
  }

  SharedPreferences? _prefs;
  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Can this device run biometric auth at all? (Hardware + enrolled
  /// fingerprint / face / iris.)
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// True if at least one biometric (fingerprint/face/iris) is enrolled.
  Future<bool> hasEnrolledBiometrics() async {
    try {
      if (!await _auth.canCheckBiometrics) return false;
      final available = await _auth.getAvailableBiometrics();
      // Treat anything stronger than "weak" as acceptable. We allow the user
      // to unlock the vault with whatever the OS offers.
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Trigger the OS biometric prompt. Returns true on success.
  /// On any error / cancel / no-hardware, returns false (callers fall back
  /// to PIN entry — never block the user).
  Future<bool> authenticate({
    String reason = 'Unlock GhostKey',
  }) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) return false;
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok;
    } on PlatformException catch (e) {
      // User cancel, lockout, no enrolled biometrics, hardware error…
      // All of these are non-fatal — the caller should fall back to PIN.
      // ignore: avoid_print
      print('[BiometricService] authenticate error: ${e.code} ${e.message}');
      return false;
    }
  }
}
