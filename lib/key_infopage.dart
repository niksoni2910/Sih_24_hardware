import 'dart:io';
import 'dart:convert'; // Import to use base64 encoding
import 'package:flutter/material.dart';

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
  late String imageBase64;

  @override
  void initState() {
    super.initState();
    // Convert image to base64 when the widget is initialized
    imageBase64 = base64Encode(widget.image.readAsBytesSync());
  }

  @override
  Widget build(BuildContext context) {
    // Get the height of the screen
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Key Info',
          style: TextStyle(color: Colors.white), // White text color for app bar title
        ),
        backgroundColor: Colors.blue, // Blue app bar background
        iconTheme: IconThemeData(color: Colors.white), // White color for back arrow
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1), // Light blue color for gradient start
              Colors.white, // White color for gradient end
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Public Key Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white, // White container background
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 2),
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
                          color: Colors.blue, // Blue color for headers
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.publicKey,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Concatenated Data Section
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
                        offset: Offset(0, 2),
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
                          color : Colors.blue
                        ),
                      ),
                      SizedBox(height: 10),
                      // Box for device info and base64 encoded image
                      Container(
                        height: screenHeight * 0.3, // Set height to 30% of screen height
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1), // Light gray background
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            '${widget.deviceInfo}\n\n$imageBase64', // Concatenate device info and base64 image string
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Selected Image Section
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
                        offset: Offset(0, 2),
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
                          color: Colors.blue, // Blue for header text
                        ),
                      ),
                      SizedBox(height: 10),
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
