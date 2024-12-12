import 'package:device_dna/ecc_channel.dart';
import 'package:device_dna/key_infopage.dart';
import 'package:device_dna/encryptedimguid.dart'; // Ensure this import exists
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'widgets/device_info_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final keys = await ECCKeyManager.getKeys();
  print('Public Key: ${keys['publicKey']}');
  print('Private Key: ${keys['privateKey']}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeviceDNA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
    // Fetch the public key
    final keys = await ECCKeyManager.getKeys();
    _publicKey = keys['publicKey'] ?? '';

    // Fetch device info and convert to a concatenated string
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceInfo = {};
    if (Platform.isAndroid) {
      deviceInfo = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
    } else if (Platform.isIOS) {
      deviceInfo = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
    }
    setState(() {
      _deviceInfoString = deviceInfo.entries.map((e) => '${e.value}').join();
    });
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // Use the front camera
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
      // Read the image as bytes
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      // Combine image bytes with device info
      List<int> combinedData = [...imageBytes, ..._deviceInfoString.codeUnits];
      // Compute SHA-256 hash
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

    print('Navigating to EncryptedImgUIDPage...');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EncryptedImgUIDPage(
          deviceInfo: _deviceInfoString,
          image: _selectedImage!,
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

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return {
      'Security Patch': build.version.securityPatch,
      'SDK Version': build.version.sdkInt,
      'Release': build.version.release,
      'Preview SDK': build.version.previewSdkInt,
      'Incremental': build.version.incremental,
      'Board': build.board,
      'Bootloader': build.bootloader,
      'Brand': build.brand,
      'Device': build.device,
      'Display': build.display,
      'Fingerprint': build.fingerprint,
      'Hardware': build.hardware,
      'Host': build.host,
      'ID': build.id,
      'Manufacturer': build.manufacturer,
      'Model': build.model,
      'Product': build.product,
      'Type': build.type,
      'Is Physical Device': build.isPhysicalDevice,
      'Serial Number': build.serialNumber,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return {
      'Name': data.name,
      'System Name': data.systemName,
      'System Version': data.systemVersion,
      'Model': data.model,
      'Localized Model': data.localizedModel,
      'Identifier for Vendor': data.identifierForVendor,
      'Is Physical Device': data.isPhysicalDevice,
      'System': data.utsname.sysname,
      'Node Name': data.utsname.nodename,
      'Release': data.utsname.release,
      'Version': data.utsname.version,
      'Machine': data.utsname.machine,
    };
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
        title: const Row(
          children: [
            Text(
              'Device',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'DNA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.blue,
              ),
            ),
            Text(
              '🧬',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
            padding: const EdgeInsets.all(20),
            child: Text(
              'Secure Your Device Identity',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedImage != null)
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
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.face),
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
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Verification Details'),
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
                    ElevatedButton.icon(
                      onPressed: _navigateToKeyInfoPage,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Proceed to Key Info'),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
