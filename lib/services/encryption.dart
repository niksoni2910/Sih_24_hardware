import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  factory EncryptionService() {
    return _instance;
  }

  EncryptionService._internal();

  String encryptData(String plainText, {String? publicKeyString}) {
    try {
      print('DEBUG: Starting encryption process');

      // Use AES encryption instead of RSA for large data
      final key = Key.fromSecureRandom(32);
      final iv = IV.fromSecureRandom(16);

      // Create AES encrypter
      final encrypter = Encrypter(AES(key));

      // Encrypt the data
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Combine the encrypted data with the IV and key
      final combined = {
        'iv': base64Encode(iv.bytes),
        'key': base64Encode(key.bytes),
        'data': encrypted.base64,
      };

      return json.encode(combined);
    } catch (e, stackTrace) {
      print('DEBUG: Encryption error:');
      print(e);
      print('DEBUG: Stack trace:');
      print(stackTrace);
      throw Exception('Encryption failed: $e');
    }
  }
}
