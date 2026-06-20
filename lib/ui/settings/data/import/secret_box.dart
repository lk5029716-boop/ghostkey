// Pure-Dart XChaCha20-Poly1305 secretbox (libsodium compatible).
// Ente Auth exports use XChaCha20-Poly1305, not XSalsa20-Poly1305.
// Based on: https://github.com/jedisct1/libsodium (crypto_secretbox_xchacha20poly1305)

import 'dart:typed_data';

import 'package:pointycastle/api.dart' show KeyParameter;
import 'package:pointycastle/macs/poly1305.dart';

const int _cryptoSecretBoxKeyBytes = 32;
const int _cryptoSecretBoxNonceBytes = 24;
const int _cryptoSecretBoxMacBytes = 16;

int _csum32(int a, int b) => (a + b) & 0xFFFFFFFF;

class SecretBoxMacException implements Exception {
  const SecretBoxMacException();
  @override
  String toString() => 'SecretBox: MAC verification failed';
}

/// Decrypts a libsodium XChaCha20-Poly1305 secretbox ciphertext.
/// Layout: ciphertext || 16-byte MAC tag
/// Nonce: 24 bytes (XChaCha20: 16 bytes for HChaCha20 + 8 bytes ChaCha20 IV)
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

  // Step 1: Derive subkey using HChaCha20(key, nonce[0:16])
  final subkey = _hChaCha20(key, Uint8List.sublistView(nonce, 0, 16));

  // Step 2: Derive Poly1305 one-time key (ChaCha20 block 0, first 32 bytes)
  final polyKey = _chacha20Keystream(subkey, Uint8List.sublistView(nonce, 16, 24), 0, 32);

  // Step 3: Verify MAC
  final poly = Poly1305()..init(KeyParameter(polyKey));
  poly.update(ciphertext, 0, ciphertext.length);
  final computed = Uint8List(_cryptoSecretBoxMacBytes);
  poly.doFinal(computed, 0);
  if (!_constantTimeEquals(mac, computed)) {
    throw const SecretBoxMacException();
  }

  // Step 4: Decrypt with ChaCha20 block starting at counter=1
  final keystream = _chacha20Keystream(subkey, Uint8List.sublistView(nonce, 16, 24), 1, ciphertext.length);
  final plaintext = Uint8List(ciphertext.length);
  for (var i = 0; i < ciphertext.length; i++) {
    plaintext[i] = (ciphertext[i] ^ keystream[i]) & 0xFF;
  }
  return plaintext;
}

/// HChaCha20: derives a 32-byte subkey from a 32-byte key and 16-byte input.
/// State: constant(4) + key(8) + nonce(4) = 16 words.
/// Output: words 0..3 and 12..15 of final state + initial.
Uint8List _hChaCha20(Uint8List key, Uint8List input) {
  final s = _initState(key);
  s[12] = _load32LE(input, 0);
  s[13] = _load32LE(input, 4);
  s[14] = _load32LE(input, 8);
  s[15] = _load32LE(input, 12);
  final initial = List<int>.from(s);

  _chachaCore(s);

  final out = Uint8List(32);
  _store32LE(out, 0, _csum32(s[0], initial[0]));
  _store32LE(out, 4, _csum32(s[1], initial[1]));
  _store32LE(out, 8, _csum32(s[2], initial[2]));
  _store32LE(out, 12, _csum32(s[3], initial[3]));
  _store32LE(out, 16, _csum32(s[12], initial[12]));
  _store32LE(out, 20, _csum32(s[13], initial[13]));
  _store32LE(out, 24, _csum32(s[14], initial[14]));
  _store32LE(out, 28, _csum32(s[15], initial[15]));
  return out;
}

/// Generate [length] bytes of ChaCha20 keystream with key, 8-byte IV, starting at [counter].
Uint8List _chacha20Keystream(Uint8List key, Uint8List iv, int counter, int length) {
  final out = Uint8List(length);
  var off = 0;
  var block = counter;
  while (off < length) {
    final s = _initState(key);
    s[12] = block & 0xFFFFFFFF;
    s[13] = (block >> 32) & 0xFFFFFFFF;
    s[14] = _load32LE(iv, 0);
    s[15] = _load32LE(iv, 4);
    final initial = List<int>.from(s);
    _chachaCore(s);
    for (var i = 0; i < 16 && off < length; i++) {
      _store32LE(out, off, _csum32(s[i], initial[i]));
      off += 4;
    }
    block++;
  }
  return out;
}

/// Build initial ChaCha20 state: constants + key (counter & IV to be filled).
List<int> _initState(Uint8List key) {
  const sigma = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];
  return [
    sigma[0], sigma[1], sigma[2], sigma[3],
    _load32LE(key, 0), _load32LE(key, 4), _load32LE(key, 8), _load32LE(key, 12),
    _load32LE(key, 16), _load32LE(key, 20), _load32LE(key, 24), _load32LE(key, 28),
    0, 0, 0, 0,
  ];
}

/// ChaCha20 core: 20 rounds (10 double rounds) on state s (mutated in-place).
void _chachaCore(List<int> s) {
  var x00 = s[0], x01 = s[1], x02 = s[2], x03 = s[3];
  var x04 = s[4], x05 = s[5], x06 = s[6], x07 = s[7];
  var x08 = s[8], x09 = s[9], x10 = s[10], x11 = s[11];
  var x12 = s[12], x13 = s[13], x14 = s[14], x15 = s[15];

  for (var i = 20; i > 0; i -= 2) {
    // Column round
    x00 += x04; x12 = _rotl32(x12 ^ x00, 16);
    x08 += x12; x04 = _rotl32(x04 ^ x08, 12);
    x00 += x04; x12 = _rotl32(x12 ^ x00, 8);
    x08 += x12; x04 = _rotl32(x04 ^ x08, 7);

    x01 += x05; x13 = _rotl32(x13 ^ x01, 16);
    x09 += x13; x05 = _rotl32(x05 ^ x09, 12);
    x01 += x05; x13 = _rotl32(x13 ^ x01, 8);
    x09 += x13; x05 = _rotl32(x05 ^ x09, 7);

    x02 += x06; x14 = _rotl32(x14 ^ x02, 16);
    x10 += x14; x06 = _rotl32(x06 ^ x10, 12);
    x02 += x06; x14 = _rotl32(x14 ^ x02, 8);
    x10 += x14; x06 = _rotl32(x06 ^ x10, 7);

    x03 += x07; x15 = _rotl32(x15 ^ x03, 16);
    x11 += x15; x07 = _rotl32(x07 ^ x11, 12);
    x03 += x07; x15 = _rotl32(x15 ^ x03, 8);
    x11 += x15; x07 = _rotl32(x07 ^ x11, 7);

    // Diagonal round
    x00 += x05; x15 = _rotl32(x15 ^ x00, 16);
    x10 += x15; x05 = _rotl32(x05 ^ x10, 12);
    x00 += x05; x15 = _rotl32(x15 ^ x00, 8);
    x10 += x15; x05 = _rotl32(x05 ^ x10, 7);

    x01 += x06; x12 = _rotl32(x12 ^ x01, 16);
    x11 += x12; x06 = _rotl32(x06 ^ x11, 12);
    x01 += x06; x12 = _rotl32(x12 ^ x01, 8);
    x11 += x12; x06 = _rotl32(x06 ^ x11, 7);

    x02 += x07; x13 = _rotl32(x13 ^ x02, 16);
    x08 += x13; x07 = _rotl32(x07 ^ x08, 12);
    x02 += x07; x13 = _rotl32(x13 ^ x02, 8);
    x08 += x13; x07 = _rotl32(x07 ^ x08, 7);

    x03 += x04; x14 = _rotl32(x14 ^ x03, 16);
    x09 += x14; x04 = _rotl32(x04 ^ x09, 12);
    x03 += x04; x14 = _rotl32(x14 ^ x03, 8);
    x09 += x14; x04 = _rotl32(x04 ^ x09, 7);
  }

  s[0] = x00; s[1] = x01; s[2] = x02; s[3] = x03;
  s[4] = x04; s[5] = x05; s[6] = x06; s[7] = x07;
  s[8] = x08; s[9] = x09; s[10] = x10; s[11] = x11;
  s[12] = x12; s[13] = x13; s[14] = x14; s[15] = x15;
}

int _rotl32(int x, int n) =>
    ((x << n) | ((x >> (32 - n)) & ((1 << n) - 1))) & 0xFFFFFFFF;

int _load32LE(Uint8List data, int offset) =>
    (data[offset]) |
    (data[offset + 1] << 8) |
    (data[offset + 2] << 16) |
    (data[offset + 3] << 24);

void _store32LE(Uint8List data, int offset, int value) {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >> 8) & 0xFF;
  data[offset + 2] = (value >> 16) & 0xFF;
  data[offset + 3] = (value >> 24) & 0xFF;
}

bool _constantTimeEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
