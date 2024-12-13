import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'dart:convert';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const String SERVER_PUBLIC_KEY = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2Q1PUcS1uiiFqm/D+mPQ
FAmMqPLrP+VzoXIMTGoOgWwHFMu3rGX+jZY8JOA/0yyAO7ej6PZ3CVxq/Orpr8aR
7tLYDfDtDYdQThgH8w3GMi+PYsFNtuaGsl1WZiuUrWVgUd/mAnrOl74bqAyFeXcY
ucmn/ml3KGSdmaDPdZn+KrRbcM/ydA1ShhSknGfHruoLGSx/xkfyrEa0q6c443IA
A/ePOh161vvr1ahqJRd7xYVPL/oTxPJ13Ahug+4sCUc9MgZN8BGKg/JLO0vmprLA
TPCADTB0qReuvx/nkP2SlgEi4722a38EhFtLEmFgdsCvgZXpwD7sHsfmDC3SKGcs
9wIDAQAB
-----END PUBLIC KEY-----''';

  RSAPublicKey _publicKey(String material) {
    return CryptoUtils.rsaPublicKeyFromDERBytes(
      base64.decode(
        material
            .replaceAll('\\n', '')
            .replaceAll('\n', '')
            .replaceAll('-----BEGIN PUBLIC KEY-----', '')
            .replaceAll('-----END PUBLIC KEY-----', ''),
      ),
    );
  }

  String encryptData(String data) {
    try {
      final publicKey = _publicKey(SERVER_PUBLIC_KEY);
      final encrypter = Encrypter(RSA(publicKey: publicKey));
      final encrypted = encrypter.encrypt(data);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return 'Encryption failed: $e';
    }
  }
}
