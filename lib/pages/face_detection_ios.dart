import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CameraScreenIOS extends StatefulWidget {
  @override
  _CameraScreenIOSState createState() => _CameraScreenIOSState();
}

class _CameraScreenIOSState extends State<CameraScreenIOS> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> cameras = [];
  String? errorMessage;

  final faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    getCameras();
  }

  Future<void> getCameras() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front),
          ResolutionPreset.high,
        );
        _initializeControllerFuture = _controller.initialize();
      }
    } catch (e) {
      errorMessage = 'Failed to access cameras: $e';
    } finally {
      setState(() {}); // Trigger UI rebuild after attempting to fetch cameras
    }
  }

  @override
  void dispose() {
    faceDetector.close();
    if (_controller.value.isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: errorMessage != null
          ? Center(
              child: Text(errorMessage!)) // Show error if camera access fails
          : cameras.isEmpty
              ? const Center(child: CircularProgressIndicator()) // Show loader
              : FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Stack(
                        children: [
                          // Camera preview
                          CameraPreview(_controller),

                          // Capture button at the bottom
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 32.0),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await captureImage(context);
                                },
                                icon: const Icon(
                                  Icons.face,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Take Selfie',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
    );
  }

  Future<void> captureImage(BuildContext context) async {
    if (!_controller.value.isInitialized) {
      showErrorDialog(context, 'Camera not initialized');
      return;
    }

    try {
      final image = await _controller.takePicture();
      final hasClearFace = await getImageAndDetectFaces(image);

      if (hasClearFace) {
        Navigator.pop(context, File(image.path));
      } else {
        showErrorDialog(context,
            'No clear face detected or face not properly positioned. Please try again.');
      }
    } catch (e) {
      print('Error: $e');
      showErrorDialog(context, 'An error occurred. Please try again.');
    }
  }

  Future<bool> getImageAndDetectFaces(XFile imageFile) async {
    try {
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      List<Face> faces = await processPickedFile(imageFile);

      if (faces.isEmpty) {
        return false;
      }

      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;
      final radius = screenWidth * 0.35;
      Rect rectOverlay = Rect.fromLTRB(
        screenWidth / 2 - radius,
        screenHeight / 3.5 - radius,
        screenWidth / 2 + radius,
        screenHeight / 2.5 + radius,
      );

      for (Face face in faces) {
        final Rect boundingBox = face.boundingBox;
        if (boundingBox.bottom < rectOverlay.top ||
            boundingBox.top > rectOverlay.bottom ||
            boundingBox.right < rectOverlay.left ||
            boundingBox.left > rectOverlay.right) {
          return false;
        }

        // Check face orientation
        if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
          if (face.headEulerAngleY!.abs() > 20 ||
              face.headEulerAngleZ!.abs() > 20) {
            // Face is misoriented
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('Error in getImageAndDetectFaces: $e');
      return false;
    }
  }

  Future<List<Face>> processPickedFile(XFile pickedFile) async {
    final path = pickedFile.path;

    InputImage inputImage;
    if (Platform.isIOS) {
      final File? iosImageProcessed = await bakeImageOrientation(pickedFile);
      if (iosImageProcessed == null) {
        return [];
      }
      inputImage = InputImage.fromFilePath(iosImageProcessed.path);
    } else {
      inputImage = InputImage.fromFilePath(path);
    }
    print('INPUT IMAGE PROCESSED: ${inputImage.filePath}');

    List<Face> faces = await faceDetector.processImage(inputImage);
    print('Found ${faces.length} faces for picked file');
    return faces;
  }

  Future<File?> bakeImageOrientation(XFile pickedFile) async {
    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final filename = DateTime.now().millisecondsSinceEpoch.toString();

      final imglib.Image? capturedImage =
          imglib.decodeImage(await File(pickedFile.path).readAsBytes());

      if (capturedImage == null) {
        return null;
      }

      final imglib.Image orientedImage = imglib.bakeOrientation(capturedImage);

      File imageToBeProcessed = await File('$path/$filename')
          .writeAsBytes(imglib.encodeJpg(orientedImage));

      return imageToBeProcessed;
    }
    return null;
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}