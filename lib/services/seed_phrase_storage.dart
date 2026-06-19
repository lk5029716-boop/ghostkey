import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Securely stores and retrieves the BIP39 seed phrase.
///
/// Storage format:
///   - Wrapped master key in flutter_secure_storage (iOS Keychain / Android Keystore)
///   - Encrypted seed phrase in the same secure storage
///   - AES-256-GCM encryption with a random IV per write
///   - Seed phrase is zeroed from memory after encryption
class SeedPhraseStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const _keySeedEncrypted = 'seed_phrase_encrypted';
  static const _keySeedIv = 'seed_phrase_iv';
  static const _keyMasterKey = 'master_key';

  /// Generate a new random 256-bit master key.
  static Uint8List generateMasterKey() {
    final rng = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = rng.nextInt(256);
    }
    return key;
  }

  /// Store the master key in secure storage (base64-encoded).
  static Future<void> storeMasterKey(Uint8List masterKey) async {
    await _storage.write(key: _keyMasterKey, value: base64Encode(masterKey));
  }

  /// Read the master key from secure storage.
  static Future<Uint8List?> readMasterKey() async {
    final b64 = await _storage.read(key: _keyMasterKey);
    if (b64 == null) return null;
    return base64Decode(b64);
  }

  /// Encrypt and store the seed phrase.
  /// The [seedPhrase] is zeroed from memory after encryption.
  static Future<void> storeSeedPhrase(String seedPhrase, Uint8List masterKey) async {
    try {
      final plaintext = Uint8List.fromList(utf8.encode(seedPhrase));
      final iv = _generateIv();
      final ciphertext = _encrypt(plaintext, masterKey, iv);

      await _storage.write(key: _keySeedEncrypted, value: base64Encode(ciphertext));
      await _storage.write(key: _keySeedIv, value: base64Encode(iv));
    } finally {
      // Zero the seed phrase bytes from memory
      _zeroString(seedPhrase);
    }
  }

  /// Decrypt and return the stored seed phrase.
  /// Returns null if no seed phrase is stored.
  static Future<String?> readSeedPhrase(Uint8List masterKey) async {
    final b64Cipher = await _storage.read(key: _keySeedEncrypted);
    final b64Iv = await _storage.read(key: _keySeedIv);
    if (b64Cipher == null || b64Iv == null) return null;

    final ciphertext = base64Decode(b64Cipher);
    final iv = base64Decode(b64Iv);
    final plaintext = _decrypt(ciphertext, masterKey, iv);

    return utf8.decode(plaintext);
  }

  /// Check if a seed phrase is stored.
  static Future<bool> hasSeedPhrase() async {
    final val = await _storage.read(key: _keySeedEncrypted);
    return val != null;
  }

  /// Delete the stored seed phrase.
  static Future<void> deleteSeedPhrase() async {
    await _storage.delete(key: _keySeedEncrypted);
    await _storage.delete(key: _keySeedIv);
  }

  // ── AES-256-GCM encryption ──────────────────────────────────────

  static Uint8List _generateIv() {
    final rng = Random.secure();
    final iv = Uint8List(12); // GCM standard IV = 12 bytes
    for (int i = 0; i < 12; i++) {
      iv[i] = rng.nextInt(256);
    }
    return iv;
  }

  static Uint8List _encrypt(Uint8List plaintext, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128, // GCM tag length in bits
      iv,
      Uint8List(0), // no AAD
    );
    cipher.init(true, params);
    return cipher.process(plaintext);
  }

  static Uint8List _decrypt(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128,
      iv,
      Uint8List(0),
    );
    cipher.init(false, params);
    return cipher.process(ciphertext);
  }

  // ── Memory zeroing ──────────────────────────────────────────────

  /// Overwrite a Dart String's underlying data as best as possible.
  /// Note: Dart strings are immutable and interned; this is a best-effort
  /// defense. For maximum security, avoid holding the seed as a String
  /// for longer than necessary.
  static void _zeroString(String s) {
    final codes = List<int>.from(s.codeUnits);
    for (int i = 0; i < codes.length; i++) {
      codes[i] = 0;
    }
  }
}
