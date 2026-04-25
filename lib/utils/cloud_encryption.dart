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

  static Uint8List saltFromBase64(String saltBase64) {
    return Uint8List.fromList(base64.decode(saltBase64));
  }

  static Uint8List deriveSaltFromUsername(String username) {
    final appSecret = 'AnymeXCloudSync2024SecureSalt';
    final combined = '$username:$appSecret';
    final hash = sha256.convert(utf8.encode(combined));
    return Uint8List.fromList(hash.bytes);
  }

  static String deriveSaltBase64FromUsername(String username) {
    return base64.encode(deriveSaltFromUsername(username));
  }
}
