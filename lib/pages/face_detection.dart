import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription> cameras = [];
  String? errorMessage;

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
    // Dispose of the camera controller
    if (_controller.value.isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: errorMessage != null
          ? Center(child: Text(errorMessage!)) // Show error if camera access fails
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
                        color: Colors.white, // Red icon for capture
                      ),
                      label: const Text(
                        'Take Selfie',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Transparent background
                        shadowColor: Colors.transparent, // No shadow
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

  // Function to capture the image and perform face detection
  Future<void> captureImage(BuildContext context) async {
    if (!_controller.value.isInitialized) {
      showErrorDialog(context, 'Camera not initialized');
      return;
    }

    try {
      final image = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Perform face detection
      final hasClearFace = await detectFaces(inputImage);

      if (hasClearFace) {
        // Return the image file to the HomePage
        Navigator.pop(context, File(image.path));
      } else {
        showErrorDialog(context, 'No clear face detected. Please try again.');
      }
    } catch (e) {
      print('Error: $e');
      showErrorDialog(context, 'An error occurred. Please try again.');
    }
  }

  // Function to detect faces in the captured image
  Future<bool> detectFaces(InputImage image) async {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true, // Enable contour detection
        enableClassification: true, // Enable classification (e.g., smiling)
      ),
    );

    try {
      final List<Face> faces = await faceDetector.processImage(image);

      if (faces.isEmpty) {
        return false;
      }

      for (var face in faces) {
        if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
          if (face.headEulerAngleY!.abs() > 20 || face.headEulerAngleZ!.abs() > 20) {
            // Face is misoriented
            return false;
          }
        }
      }

      return true; // Clear face detected
    } catch (e) {
      print('Face detection error: $e');
      return false;
    } finally {
      faceDetector.close(); // Release resources
    }
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
