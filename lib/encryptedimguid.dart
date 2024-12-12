import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;  // Import the encrypt package for encryption

class EncryptedImgUIDPage extends StatefulWidget {
  final String deviceInfo;
  final File image;

  const EncryptedImgUIDPage({
    Key? key,
    required this.deviceInfo,
    required this.image,
  }) : super(key: key);

  @override
  State<EncryptedImgUIDPage> createState() => _EncryptedImgUIDPageState();
}

class _EncryptedImgUIDPageState extends State<EncryptedImgUIDPage> {
  String _digest = '';
  String _encryptedHash = '';
  bool _hashCopied = false;

  @override
  void initState() {
    super.initState();
    _computeHashAndEncrypt();
  }

  Future<void> _computeHashAndEncrypt() async {
    try {
      // Step 1: Generate SHA-256 hash
      List<int> deviceInfoData = [...widget.deviceInfo.codeUnits];
      var digest = sha256.convert(deviceInfoData);
      String digestString = digest.toString();

      // Step 2: Generate a random AES key and IV
      final key = encrypt.Key.fromLength(32);  // AES-256 key (256 bits = 32 bytes)
      final iv = encrypt.IV.fromLength(16);   // AES block size is 16 bytes (128 bits)

      // Step 3: Encrypt the digest using AES
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));  // CBC mode for AES encryption
      final encrypted = encrypter.encrypt(digestString, iv: iv);

      // Step 4: Update the state with the digest and encrypted hash
      setState(() {
        _digest = digestString;
        _encryptedHash = encrypted.base64;  // Store the encrypted hash as base64
      });
    } catch (e) {
      setState(() {
        _digest = 'Error generating digest: $e';
        _encryptedHash = 'Error encrypting digest';
      });
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _hashCopied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _hashCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verification Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Device Information',
                  _buildCopyableText(widget.deviceInfo, 'Device info copied to clipboard'),
                ),
                const SizedBox(height: 20),
                _buildInfoCard(
                  'Generated Digest (SHA-256)',
                  _buildCopyableText(_digest, 'Digest copied to clipboard'),
                ),
                const SizedBox(height: 20),
                _buildInfoCard(
                  'Encrypted Hash',
                  _buildCopyableText(_encryptedHash, 'Encrypted hash copied to clipboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableText(String text, String copyMessage) {
    return InkWell(
      onTap: () => _copyToClipboard(text, copyMessage),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _hashCopied ? Icons.check : Icons.copy,
              size: 20,
              color: _hashCopied ? Colors.green : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
