import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:pointycastle/asymmetric/api.dart';

class EncryptionService {
  static Future<String> encryptData(String data) async {
    try {
      final publicKey = await parseKeyFromFile<RSAPublicKey>('../public.pem');
      final encrypter = Encrypter(RSA(publicKey: publicKey));
      final encrypted = encrypter.encrypt(data);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return 'Encryption failed: $e';
    }
  }
}
