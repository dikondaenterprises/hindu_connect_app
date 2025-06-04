import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

class SecureStorage {
  static const _secure = FlutterSecureStorage();
  static const _keyName = 'aes_key';

  /// get or create AES key
  // ignore: unused_element
  static Future<Encrypter> _getEncrypter() async {
    var keyString = await _secure.read(key: _keyName);
    if (keyString == null) {
      final key = Key.fromSecureRandom(32);
      await _secure.write(key: _keyName, value: key.base64);
      keyString = key.base64;
    }
    final key = Key.fromBase64(keyString);
    final iv = IV.fromLength(16);
    return Encrypter(AES(key, mode: AESMode.cbc))..encrypt('', iv: iv);
  }

  static Future<String> encrypt(String plain) async {
    final keyString = await _secure.read(key: _keyName);
    final key = Key.fromBase64(keyString!);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.encrypt(plain, iv: iv).base64;
  }

  static Future<String> decrypt(String cipher) async {
    final keyString = await _secure.read(key: _keyName);
    final key = Key.fromBase64(keyString!);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt64(cipher, iv: iv);
  }
}
