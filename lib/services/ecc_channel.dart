import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class ECCKeyManager {
  static const _channel = MethodChannel('native_ecc');
  static const _storage = FlutterSecureStorage();
  static const _privateKeyKey = 'private_key';
  static const _publicKeyKey = 'public_key';
  static const _lastGeneratedKey = 'last_generated_key';
  static const _keyExpirationDuration = Duration(minutes: 1);

  static Future<Map<String, String>> _generateECCKeyPair() async {
    final keys =
        await _channel.invokeMapMethod<String, String>('generateKeyPair');
    if (keys == null) throw Exception('Failed to generate ECC key pair');
    return keys;
  }

  static Future<bool> _hasKeyExpired() async {
    final lastGenerated = await _storage.read(key: _lastGeneratedKey);
    if (lastGenerated == null) return true;
    final lastGeneratedTime = DateTime.parse(lastGenerated);
    return DateTime.now().difference(lastGeneratedTime) >
        _keyExpirationDuration;
  }

  static Future<void> _saveKeys(String privateKey, String publicKey) async {
    await _storage.write(key: _privateKeyKey, value: privateKey);
    await _storage.write(key: _publicKeyKey, value: publicKey);
    await _storage.write(
        key: _lastGeneratedKey, value: DateTime.now().toIso8601String());
  }

  static Future<Map<String, String>> getKeys() async {
    if (await _hasKeyExpired()) {
      final newKeys = await _generateECCKeyPair();
      await _saveKeys(newKeys['privateKey']!, newKeys['publicKey']!);
      return newKeys;
    }
    final privateKey = await _storage.read(key: _privateKeyKey);
    final publicKey = await _storage.read(key: _publicKeyKey);
    if (privateKey == null || publicKey == null)
      throw Exception('Keys not found');
    return {'privateKey': privateKey, 'publicKey': publicKey};
  }
}
