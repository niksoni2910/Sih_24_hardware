import 'package:flutter/material.dart';
import '../widgets/progress_section.dart';

class ProgressPage extends StatefulWidget {
  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  double _uploadProgress = 0.0;
  double _encryptionProgress = 0.0;
  double _sendingProgress = 0.0;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() async {
    // Simulate upload progress
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 20));
      setState(() {
        _uploadProgress = i / 100;
      });
    }

    // Simulate encryption progress
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 20));
      setState(() {
        _encryptionProgress = i / 100;
      });
    }

    // Simulate sending progress
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 20));
      setState(() {
        _sendingProgress = i / 100;
      });
    }

    // Show authentication status
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Processing'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressSection(
              label: 'Uploading',
              progress: _uploadProgress,
            ),
            SizedBox(height: 30),
            ProgressSection(
              label: 'Encrypting',
              progress: _encryptionProgress,
            ),
            SizedBox(height: 30),
            ProgressSection(
              label: 'Sending',
              progress: _sendingProgress,
            ),
            SizedBox(height: 40),
            Center(
              child: _isAuthenticated
                  ? Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Authentication Successful',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
