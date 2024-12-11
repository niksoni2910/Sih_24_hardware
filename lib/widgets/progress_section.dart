import 'package:flutter/material.dart';

class ProgressSection extends StatelessWidget {
  final String label;
  final double progress;

  const ProgressSection({
    required this.label,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 10,
        ),
        SizedBox(height: 5),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(color: Colors.blue[700]),
        ),
      ],
    );
  }
}
