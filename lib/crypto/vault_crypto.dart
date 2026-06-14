import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ecb_key_generator.dart';
import 'package:pointycastle/modes/gcm.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:crypto/crypto.dart';

class VaultCrypto {
  static Future<Uint8List> generateKey(int bits) async {
    final keyGen = KeyGenerator('AES');
    keyGen.init(KeyParameter(Uint8List(bits ~/ 8)));
    return keyGen.generateKey();
  }

  static Uint8List? encrypt(Uint8List key, String plaintext) {
    try {
      final plain = Uint8List.fromList(utf8.encode(plaintext));
      final iv = Uint8List(12);
      final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
      final cipher = GCMBlockCipher(AESFastEngine());
      cipher.init(true, params);
      final encrypted = cipher.process(plain);
      return encrypted;
    } catch (e) {
      return null;
    }
  }

  static String? decrypt(Uint8List key, Uint8List cipherText) {
    try {
      final iv = Uint8List(12);
      final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
      final cipher = GCMBlockCipher(AESFastEngine());
      cipher.init(false, params);
      final decrypted = cipher.process(cipherText);
      return utf8.decode(decrypted);
    } catch (e) {
      return null;
    }
  }

  static String hash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
}