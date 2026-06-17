import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first replacement for ente's `BaseConfiguration`-driven
/// `Configuration`.
///
/// GhostKey is a demo with no server, no `ente_crypto_api`, no
/// `EnteBaseDatabase`, no online/offline account split. This version keeps
/// only what the rest of the app actually reads:
///   - `offlineAuthSecretKey` in `flutter_secure_storage` (for at-rest
///     encryption of TOTP secrets — wired in a later crypto pass).
///   - `hasOptedForOfflineMode` flag in `shared_preferences`.
///   - `autoBackupPassword` in `flutter_secure_storage`.
///
/// Server-coupled fields (`key`, `secretKey`, `authSecretKey`) are dropped.
class Configuration {
  Configuration._privateConstructor();

  static final Configuration instance = Configuration._privateConstructor();

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------
  static const offlineAuthSecretKey = 'offline_auth_secret_key';
  static const hasOptedForOfflineModeKey = 'has_opted_for_offline_mode';
  static const autoBackupPasswordKey = 'autoBackupPassword';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  late SharedPreferences _preferences;
  String? _offlineAuthKey;
  late FlutterSecureStorage _secureStorage;

  bool get hasInitialized => _initialized;
  bool _initialized = false;

  /// Initialize once at app startup.
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    _offlineAuthKey = await _secureStorage.read(key: offlineAuthSecretKey);
    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Account mode (always offline in GhostKey demo)
  // ---------------------------------------------------------------------------

  bool hasConfiguredAccount() => false; // local-only, no online signup

  bool hasOptedForOfflineMode() =>
      _preferences.getBool(hasOptedForOfflineModeKey) ?? true; // default true

  Future<void> optForOfflineMode() async {
    if (!await _secureStorage.containsKey(key: offlineAuthSecretKey)) {
      // Placeholder until crypto pass wires a real key. A 32-byte random
      // hex string is enough to round-trip the secure storage field.
      final placeholder = _generatePlaceholderKey();
      await _secureStorage.write(
        key: offlineAuthSecretKey,
        value: placeholder,
      );
      _offlineAuthKey = placeholder;
    }
    await _preferences.setBool(hasOptedForOfflineModeKey, true);
  }

  // ---------------------------------------------------------------------------
  // Auth key accessors (return raw bytes when present)
  // ---------------------------------------------------------------------------

  Uint8List? getOfflineSecretKey() {
    final raw = _offlineAuthKey;
    if (raw == null) return null;
    return _hexToBytes(raw);
  }

  // ---------------------------------------------------------------------------
  // Backup password (placeholder; used by future local-backup feature)
  // ---------------------------------------------------------------------------

  Future<String?> getBackupPassword() =>
      _secureStorage.read(key: autoBackupPasswordKey);

  Future<void> setBackupPassword(String password) =>
      _secureStorage.write(key: autoBackupPasswordKey, value: password);

  Future<void> clearBackupPassword() =>
      _secureStorage.delete(key: autoBackupPasswordKey);

  // ---------------------------------------------------------------------------
  // Logout — clears the in-memory key but keeps offlineAuthSecretKey
  // intentionally (mirrors ente's behaviour for offline mode).
  // ---------------------------------------------------------------------------

  Future<void> logout({bool autoLogout = false}) async {
    // No-op for local-only. Server-side fields don't exist.
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _generatePlaceholderKey() {
    // 32 random bytes hex-encoded. Real crypto pass will replace with
    // an Argon2id-derived key from the user's master password.
    final rnd = List<int>.generate(32, (_) => DateTime.now().microsecond % 256);
    return rnd
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Uint8List? _hexToBytes(String hex) {
    if (hex.length % 2 != 0) return null;
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      final byte = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      if (byte == null) return null;
      out[i] = byte;
    }
    return out;
  }
}
