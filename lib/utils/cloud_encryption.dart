import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';

class CloudEncryption {
  static Uint8List _deriveKey(String password, Uint8List salt) {
    final iterations = 100000;
    var hmac = Hmac(sha256, salt);
    var derived = Uint8List.fromList(utf8.encode(password));

    for (var i = 0; i < iterations; i++) {
      derived = Uint8List.fromList(hmac.convert(derived).bytes);
    }

    return Uint8List.fromList(derived.sublist(0, 32));
  }

  static Map<String, String> encrypt(
    String plaintext,
    String password,
    Uint8List salt,
  ) {
    final key = enc.Key(_deriveKey(password, salt));
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'encrypted': encrypted.base64,
      'iv': iv.base64,
    };
  }

  static String decrypt(
    String encryptedBase64,
    String ivBase64,
    String password,
    Uint8List salt,
  ) {
    final key = enc.Key(_deriveKey(password, salt));
    final iv = enc.IV.fromBase64(ivBase64);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
    return decrypted;
  }

  static String generateSaltBase64() {
    final salt = enc.IV.fromSecureRandom(16);
    return base64.encode(salt.bytes);
  }

  static Uint8List saltFromBase64(String saltBase64) {
    return Uint8List.fromList(base64.decode(saltBase64));
  }
}
