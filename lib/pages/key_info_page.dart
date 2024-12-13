import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/encryption.dart';

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
  String  imageBase64 = "";
  String concatenatedData = "";
  String encryptedData = "";
  final EncryptionService _encryptionService = EncryptionService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      String imgBase64 = base64Encode(widget.image.readAsBytesSync());
      String concated = '${widget.deviceInfo}~$imageBase64';

      // Encrypt the data
      String encrypted = await EncryptionService.encryptData(concated);

      setState(() {
        encryptedData = encrypted;
        concatenatedData = concated;
        imageBase64 = imgBase64;
      });

      print('DEBUG: Encryption completed');
      print('DEBUG: Encrypted data length: ${encryptedData?.length}');
    } catch (e) {
      print('DEBUG: Error in initialization:');
      print(e);
      setState(() {
        encryptedData = 'Error processing data: $e';
      });
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
          child: Padding(
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
                            encryptedData,
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
