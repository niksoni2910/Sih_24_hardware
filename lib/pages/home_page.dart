import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../services/ecc_channel.dart';
import '../pages/key_info_page.dart';
import '../pages/encrypted_img_uid_page.dart';
import '../widgets/device_info_sheet.dart';
import '../services/device_info_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String _publicKey = '';
  String _deviceInfoString = '';
  String _combinedHash = '';

  @override
  void initState() {
    super.initState();
    _loadKeysAndDeviceInfo();
  }

  Future<void> _loadKeysAndDeviceInfo() async {
    final keys = await ECCKeyManager.getKeys();
    _publicKey = keys['publicKey'] ?? '';
    _deviceInfoString = await DeviceInfoService.getDeviceInfoString();
    print(_deviceInfoString);
    setState(() {});
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String> _computeHash() async {
    try {
      if (_selectedImage == null) return '';
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      List<int> combinedData = [...imageBytes, ..._deviceInfoString.codeUnits];
      var digest = sha256.convert(combinedData);
      return digest.toString();
    } catch (e) {
      print('Error computing hash: $e');
      return 'Error generating hash';
    }
  }

  Future<void> _submitImage() async {
    if (_selectedImage == null) return;

    String hash = await _computeHash();
    setState(() {
      _combinedHash = hash;
    });
    final keys = await ECCKeyManager.getKeys();
    _publicKey = keys['publicKey'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EncryptedImgUIDPage(
          deviceInfo: _deviceInfoString,
          image: _selectedImage!,
          publicKey: _publicKey,
        ),
      ),
    );
  }

  void _navigateToKeyInfoPage() {
    if (_selectedImage == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeyInfoPage(
          publicKey: _publicKey,
          deviceInfo: _deviceInfoString,
          image: _selectedImage!,
        ),
      ),
    );
  }

  void _showDeviceInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => DeviceInfoSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'VishwAadhar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.blue,
            ),
            onPressed: _showDeviceInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'Empowering Secure Identity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            child: Center(
              child: Text(
                'Right in Your Hands!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _selectedImage != null?
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ):Image(image: AssetImage('assets/images/logo_square.png'),height: 200,width: 200,),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.face,color: Colors.white,),
                    label: const Text('Take Selfie to Authenticate'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _submitImage,
                      icon: const Icon(Icons.info_outline,color: Colors.white,),
                      label: const Text('Verification Details',),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
