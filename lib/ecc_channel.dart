import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class ECCKeyManager {
  static const _channel = MethodChannel('native_ecc');
  static const _storage = FlutterSecureStorage();
  static const _privateKeyKey = 'private_key';
  static const _publicKeyKey = 'public_key';
  static const _lastGeneratedKey = 'last_generated_key';

  static const _keyExpirationDuration = Duration(minutes: 1);

  /// Generate ECC key pair via native code
  static Future<Map<String, String>> _generateECCKeyPair() async {
    final keys = await _channel.invokeMapMethod<String, String>('generateKeyPair');
    if (keys == null) throw Exception('Failed to generate ECC key pair');
    return keys;
  }

  /// Check if the key has expired
  static Future<bool> _hasKeyExpired() async {
    final lastGenerated = await _storage.read(key: _lastGeneratedKey);
    if (lastGenerated == null) return true; // Key doesn't exist, treat as expired

    final lastGeneratedTime = DateTime.parse(lastGenerated);
    return DateTime.now().difference(lastGeneratedTime) > _keyExpirationDuration;
  }

  /// Save the key pair securely
  static Future<void> _saveKeys(String privateKey, String publicKey) async {
    await _storage.write(key: _privateKeyKey, value: privateKey);
    await _storage.write(key: _publicKeyKey, value: publicKey);
    await _storage.write(key: _lastGeneratedKey, value: DateTime.now().toIso8601String());
  }

  /// Load the key pair, generating a new pair if necessary
  static Future<Map<String, String>> getKeys() async {
    // Check if keys are expired or non-existent
    if (await _hasKeyExpired()) {
      // Generate new keys
      final newKeys = await _generateECCKeyPair();
      await _saveKeys(newKeys['privateKey']!, newKeys['publicKey']!);
      return newKeys;
    }

    // Retrieve stored keys
    final privateKey = await _storage.read(key: _privateKeyKey);
    final publicKey = await _storage.read(key: _publicKeyKey);
    if (privateKey == null || publicKey == null) throw Exception('Keys not found');

    return {'privateKey': privateKey, 'publicKey': publicKey};
  }
}
