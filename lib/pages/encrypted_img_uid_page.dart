
import 'dart:io' ;

import 'package:app_integrity_checker/app_integrity_checker.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import '../services/ecc_channel.dart';
import '../services/encryption.dart';
import 'dart:convert';
import 'package:flutter/material.dart' ;
import 'package:encrypt/encrypt.dart' as encrypt;// Import the encryption service
import 'package:http/http.dart' as http;

class EncryptedImgUIDPage extends StatefulWidget {
  final String deviceInfo;
  final File image;
  final String publicKey;

  const EncryptedImgUIDPage({super.key,
    required this.deviceInfo,
    required this.image, required this.publicKey,
  });

  @override
  State<EncryptedImgUIDPage> createState() => _EncryptedImgUIDPageState();
}

class _EncryptedImgUIDPageState extends State<EncryptedImgUIDPage> {
  String _digest = '';
  String _encryptedHash = '';
  bool _hashCopied = false;
  final EncryptionService _encryptionService = EncryptionService();
  bool isLoading = true;
  String  imageBase64 = "";
  String encryptedDataString = "";  // This is the AES-encrypted data
  String encryptedKeyString = "";
  String devicePublicKey = "";
  String rsaPublicKeyPem = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7tO2w97gC7b7E2aBvYDQ
H5Hb6iFdfdJ9XeM7h9/O2n15+0tZz6W5tDCb4cq5RYQROVwdV/4RbrkNRGJ0qzp+
R1cV79rB2bZ7Ws5Qfbpg9mwvwfKopk22mbC3gOeW6O3a+fRUHpGLUpiEKtvVqfOC
+IkpNnt6z+rLKFmlgPOojSldp9y8vH+mRO8NwtwFDHiMP3e0qAC8UQwJ0rpX4v5+a
z8l6U3XJwF1KKMEni8v0Vdd0q6orffvFJh/FSPwZkJ7yn7OrU4wJg2pXUSOhjF9c
vYO2hZT2r0vhdYEnQehHD8QjMckChFZEK69t6FgbsNjbbR5pM25AWxHg5HOf+ZgF
wIDAQAB
-----END PUBLIC KEY-----''';
  String checksum='';
  String signature='';

  final String apiUrl = "http://192.168.137.73:3000/api/send-data"; // Replace with your API endpoint

  // Function to call the API
  Future<void> _submitData() async {
    if (isLoading) {
      // Ensure data is initialized
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data is still being prepared. Please wait.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Prepare the request payload
      final payload = {
        "devicePublicKey": devicePublicKey,
        "encryptedData": encryptedDataString,
        "encryptedKey": encryptedKeyString,
        "deviceInfo": widget.deviceInfo,
        "deviceInfoSign": _encryptedHash,
        "appSign":signature,
      };
      // print(payload.toString());




      // Make the API POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      // Delay the invocation of the SnackBar by 5 seconds
      Future.delayed(Duration(seconds: 5), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3), // Optional: Set how long it should be visible
          ),
        );
      });


    } catch (e) {
      // Handle exceptions
      // print('DEBUG: Error while submitting data: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error submitting data: $e'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    }
  }

  @override
  void initState() {
    super.initState();
    _computeHashAndEncrypt();
    _initializeData();
    _getSignature();
  }

  Future<void> _getSignature() async{
    String checksum = await AppIntegrityChecker.getchecksum() ?? "checksum retrieval failed";     //retrieve app checksum value in SHA256
    String signature = await AppIntegrityChecker.getsignature() ?? "signature retrieval failed";
    print("checksum $checksum");
    print("signature $signature");
  }



  Future<void> _initializeData() async {
    try {
      final keys = await ECCKeyManager.getKeys();

      // Convert image to base64
      String imgBase64 = base64Encode(widget.image.readAsBytesSync());
      print("Imagebase64 length :::: ${imgBase64.length}");

      // Concatenate device info and image data
      String dataToEncrypt = '${widget.deviceInfo}~$imgBase64';

      // 1. Generate a random AES symmetric key
      final key = encrypt.Key.fromSecureRandom(32); // AES-256
      final iv = encrypt.IV.fromLength(16); // AES block size (128 bits)

      // 2. Encrypt the concatenated data (device info + image data) using AES
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encryptedData = encrypter.encrypt(dataToEncrypt, iv: iv);

      print("Encrypted data (AES) length: ${encryptedData.bytes.length}");
      print(encryptedData);

      // 3. Encrypt the AES symmetric key using RSA
      // Assuming you have RSA public key available (use a proper public key loading mechanism)
      // String rsaPublicKeyPem = "YOUR_RSA_PUBLIC_KEY"; // replace with your actual RSA public key
      final dynamic publicKey = encrypt.RSAKeyParser().parse(rsaPublicKeyPem);
      final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));

      // Encrypt the AES key with RSA
      final encryptedKey = rsaEncrypter.encryptBytes(key.bytes);
      print(encryptedKey);

      // Store encrypted data and key
      setState(() {
        encryptedDataString = encryptedData.base64;  // This is the AES-encrypted data
        encryptedKeyString = encryptedKey.base64;    // This is the RSA-encrypted AES key
        imageBase64 = imgBase64;
        isLoading=false;
        devicePublicKey = keys['publicKey'] ?? '';
      });
      
      print('DEBUG: Encryption completed');
      print('DEBUG: Encrypted data length: ${encryptedDataString.length}');
      print('DEBUG: Encrypted AES key length: ${encryptedKeyString.length}');

    } catch (e) {
      print('DEBUG: Error in initialization:');
      print(e);
      setState(() {
        encryptedDataString = 'Error processing data: $e';
        encryptedKeyString = 'Error processing data: $e';
      });
    }
  }

  Future<void> _computeHashAndEncrypt() async {
    try {
      var bytes1 = utf8.encode(widget.deviceInfo);
      var digest = sha256.convert(bytes1);
      String digestString = digest.toString();
      String encryptedData = await EncryptionService.encryptData(digestString);

      setState(() {
        _encryptedHash = encryptedData;
        _digest = digestString;
      });

      print('DEBUG: Encryption completed');
      print('DEBUG: Encrypted data length: ${encryptedData?.length}');
      print(encryptedData);
      print(widget.deviceInfo);
    } catch (e) {
      print('DEBUG: Error in initialization:');
      print(e);
      setState(() {
        _encryptedHash = 'Error processing data: $e';
      });
    }
  }

  // Rest of the code remains the same...
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
    double screenHeight = MediaQuery.of(context).size.height;
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // -----------------------
                const SizedBox(height: 20),
                _buildInfoCard(
                  'Public Key',
                  _buildCopyableText(
                      devicePublicKey, 'Public Key copied to clipboard'),
                ),

                const SizedBox(height: 20),
                _buildInfoCard(
                  'Device + Image Data',
                  _buildCopyableText(
                      "${widget.deviceInfo}\n\n${imageBase64.isNotEmpty ? imageBase64.substring(0,300) : ""}...", 'Device + Image Data copied to clipboard'),
                ),

                const SizedBox(height: 20),
                _buildInfoCard(
                  'Encrypted(Image + Device)',
                  _buildCopyableText(
                      "${encryptedDataString.isNotEmpty ? encryptedDataString.substring(0,300) : ""}...", 'Encrypted hash copied to clipboard'),
                ),

                const SizedBox(height: 20),
                _buildInfoCard(
                  'Device Info Hash (SHA-256)',
                  _buildCopyableText(_digest, 'Digest copied to clipboard'),
                ),
                const SizedBox(height: 20),
                _buildInfoCard(
                  'Encrypted Signature',
                  _buildCopyableText(
                      _encryptedHash, 'Encrypted hash copied to clipboard'),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _submitData,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white,),
                  label: const Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
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
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
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
