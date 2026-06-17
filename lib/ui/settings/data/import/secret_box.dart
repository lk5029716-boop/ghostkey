// Pure-Dart XSalsa20-Poly1305 secretbox (libsodium compatible).
// Based on DJB's NaCl spec. Used for decrypting Ente Auth encrypted exports.

import 'dart:typed_data';

import 'package:pointycastle/api.dart' show ParametersWithIV, KeyParameter;
import 'package:pointycastle/macs/poly1305.dart';
import 'package:pointycastle/stream/salsa20.dart';

const int _cryptoSecretBoxKeyBytes = 32;
const int _cryptoSecretBoxNonceBytes = 24;
const int _cryptoSecretBoxMacBytes = 16;

class SecretBoxMacException implements Exception {
  const SecretBoxMacException();
  @override
  String toString() => 'SecretBox: MAC verification failed';
}

/// Decrypts a libsodium secretbox ciphertext.
/// Layout: ciphertext || tag (16 bytes MAC at the end).
/// Nonce: 24 bytes (XSalsa20).
Uint8List secretBoxOpenEasy({
  required Uint8List ciphertextWithTag,
  required Uint8List nonce,
  required Uint8List key,
}) {
  if (key.length != _cryptoSecretBoxKeyBytes) {
    throw ArgumentError('SecretBox: key must be 32 bytes');
  }
  if (nonce.length != _cryptoSecretBoxNonceBytes) {
    throw ArgumentError('SecretBox: nonce must be 24 bytes');
  }
  if (ciphertextWithTag.length < _cryptoSecretBoxMacBytes) {
    throw ArgumentError('SecretBox: ciphertext too short');
  }

  final tagStart = ciphertextWithTag.length - _cryptoSecretBoxMacBytes;
  final ciphertext = Uint8List.sublistView(ciphertextWithTag, 0, tagStart);
  final mac = Uint8List.sublistView(ciphertextWithTag, tagStart);

  // Step 1: derive Poly1305 one-time key using HSalsa20(key, nonce[0:16])
  // HSalsa20 is just Salsa20 with 16-byte IV and a 16-byte zero input.
  final hsalsa = Salsa20Engine()
    ..init(false, ParametersWithIV<KeyParameter>(
      KeyParameter(key),
      Uint8List.sublistView(nonce, 0, 16),
    ));
  final polyKey = Uint8List(32);
  hsalsa.processBytes(Uint8List(16), 0, 16, polyKey, 0);

  // Step 2: verify MAC
  final poly = Poly1305()..init(KeyParameter(polyKey));
  poly.update(ciphertext, 0, ciphertext.length);
  final computed = Uint8List(_cryptoSecretBoxMacBytes);
  poly.doFinal(computed, 0);

  if (!_constantTimeEquals(mac, computed)) {
    throw const SecretBoxMacException();
  }

  // Step 3: decrypt with full XSalsa20(key, nonce) starting at counter 0
  final xsalsa = Salsa20Engine()
    ..init(false, ParametersWithIV<KeyParameter>(
      KeyParameter(key),
      nonce,
    ));
  final plaintext = Uint8List(ciphertext.length);
  xsalsa.processBytes(ciphertext, 0, ciphertext.length, plaintext, 0);
  return plaintext;
}

bool _constantTimeEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
