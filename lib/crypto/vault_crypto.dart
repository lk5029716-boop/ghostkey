import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/modes/gcm.dart';
import 'package:crypto/crypto.dart';

class VaultCrypto {
  static Uint8List deriveKey(String password, Uint8List salt) {
    final pbkdf2 = Pbkdf2KeyDerivator(HMac(sha256, 64));
    pbkdf2.init(Pbkdf2Parameters(salt, 10000, 32));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List encrypt(Uint8List key, String plaintext) {
    final plain = Uint8List.fromList(utf8.encode(plaintext));
    final iv = Uint8List(12);
    final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
    final cipher = GCMBlockCipher(AESFastEngine());
    cipher.init(true, params);
    return cipher.process(plain);
  }

  static String? decrypt(Uint8List key, Uint8List cipherText) {
    try {
      final iv = Uint8List(12);
      final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
      final cipher = GCMBlockCipher(AESFastEngine());
      cipher.init(false, params);
      return utf8.decode(cipher.process(cipherText));
    } catch (_) {
      return null;
    }
  }
}