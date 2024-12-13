import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/encryption.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class KeyInfoPage extends StatefulWidget {
  final String publicKey;
  final String deviceInfo;
  final File image;

  const KeyInfoPage({
    Key? key,
    required this.publicKey,
    required this.deviceInfo,
    required this.image,
  }) : super(key: key);

  @override
  State<KeyInfoPage> createState() => _KeyInfoPageState();
}

class _KeyInfoPageState extends State<KeyInfoPage> {
  bool isLoading = true;
  String  imageBase64 = "";
  // String concatenatedData = "";
  // String encryptedData = "";
  String encryptedDataString = "";  // This is the AES-encrypted data
  String encryptedKeyString = "";
  final EncryptionService _encryptionService = EncryptionService();
  String rsaPublicKeyPem = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7tO2w97gC7b7E2aBvYDQ
H5Hb6iFdfdJ9XeM7h9/O2n15+0tZz6W5tDCb4cq5RYQROVwdV/4RbrkNRGJ0qzp+
R1cV79rB2bZ7Ws5Qfbpg9mwvwfKopk22mbC3gOeW6O3a+fRUHpGLUpiEKtvVqfOC
+IkpNnt6z+rLKFmlgPOojSldp9y8vH+mRO8NwtwFDHiMP3e0qAC8UQwJ0rpX4v5+a
z8l6U3XJwF1KKMEni8v0Vdd0q6orffvFJh/FSPwZkJ7yn7OrU4wJg2pXUSOhjF9c
vYO2hZT2r0vhdYEnQehHD8QjMckChFZEK69t6FgbsNjbbR5pM25AWxHg5HOf+ZgF
wIDAQAB
-----END PUBLIC KEY-----''';


  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // try {
    //   // String imgBase64 = base64Encode(widget.image.readAsBytesSync());
    //   // Convert image to base64
    //   String imgBase64 = base64Encode(widget.image.readAsBytesSync());
    //   print("Imagebase64 length :::: ${imgBase64.length}");
    //   // Split base64 string into chunks of 256 characters
    //   List<String> chunks = [];
    //   int chunkSize = 244;
    //   for (var i = 0; i < imgBase64.length; i += chunkSize) {
    //     int end = (i + chunkSize < imgBase64.length) ? i + chunkSize : imgBase64.length;
    //     chunks.add(imgBase64.substring(i, end));
    //   }

    //   print('DEBUG: Number of chunks created: ${chunks.length}');
      
    //   // Encrypt each chunk and combine with device info
    //   List<String> encryptedChunks = [];
    //   for (int i = 0; i < chunks.length; i++) {
    //     // Add chunk index to ensure correct order during decryption
    //     String encrypted = await EncryptionService.encryptData(chunks[i]);
    //     encryptedChunks.add(encrypted);
    //     print('DEBUG: Chunk $i encrypted successfully');
    //   }
    //   // Encrypt the data
    //   // String encrypted = await EncryptionService.encryptData(concated);

    //   setState(() {
    //     encryptedData = encryptedChunks[0];
    //     concatenatedData = '${widget.deviceInfo}~$imageBase64';
    //     imageBase64 = imgBase64;
    //   });

    //   print('DEBUG: Encryption completed');
    //   print('DEBUG: Encrypted data length: ${encryptedData?.length}');
    // } catch (e) {
    //   print('DEBUG: Error in initialization:');
    //   print(e);
    //   setState(() {
    //     encryptedData = 'Error processing data: $e';
    //   });
    // }
    try {
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

    // 3. Encrypt the AES symmetric key using RSA
    // Assuming you have RSA public key available (use a proper public key loading mechanism)
    // String rsaPublicKeyPem = "YOUR_RSA_PUBLIC_KEY"; // replace with your actual RSA public key
    final dynamic publicKey = encrypt.RSAKeyParser().parse(rsaPublicKeyPem);
    final rsaEncrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));

    // Encrypt the AES key with RSA
    final encryptedKey = rsaEncrypter.encryptBytes(key.bytes);
    
    // Store encrypted data and key
    setState(() {
      encryptedDataString = encryptedData.base64;  // This is the AES-encrypted data
      encryptedKeyString = encryptedKey.base64;    // This is the RSA-encrypted AES key
      imageBase64 = imgBase64;
    });

    print('DEBUG: Encryption completed');
    // print('DEBUG: Encrypted data length: ${encryptedDataString?.length}');
    // print('DEBUG: Encrypted AES key length: ${encryptedKeyString?.length}');
    
  } catch (e) {
    print('DEBUG: Error in initialization:');
    print(e);
    // setState(() {
    //   encryptedDataString = 'Error processing data: $e';
    //   encryptedKeyString = 'Error processing data: $e';
    // });
  }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Key Info',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child:
          isLoading ? const Center(child: CircularProgressIndicator()) :
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Public Key Container
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Public Key:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.publicKey,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Concatenated Data Container
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Concatenated Data:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: screenHeight * 0.3,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            "${widget.deviceInfo}\n\n" + imageBase64,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Encrypted Data Container
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Encrypted Data:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: screenHeight * 0.3,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            encryptedKeyString + "~" + encryptedDataString,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Image Container
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Image:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            widget.image,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
