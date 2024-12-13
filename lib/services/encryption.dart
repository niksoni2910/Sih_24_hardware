import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:flutter/services.dart' show rootBundle;

class EncryptionService {
  static Future<String> encryptData(String data) async {
    try {
      final publicPem = await rootBundle.loadString('assets/public.pem');
      final publicKey = RSAKeyParser().parse(publicPem) as RSAPublicKey;
      // final publicKey = await parseKeyFromFile<RSAPublicKey>('../public.pem');
      final encrypter = Encrypter(RSA(publicKey: publicKey));
      final encrypted = encrypter.encrypt(data);
      print(encrypted.base64);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return 'Encryption failed: $e';
    }
  }
}
