import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  final bool isRecording;
  final String? audioPath;

  const StatusText({super.key, required this.isRecording, required this.audioPath});

  @override
  Widget build(BuildContext context) {
    if (isRecording) {
      return const Text('Sedang Merekam...',
          style: TextStyle(fontSize: 20, color: Colors.redAccent));
    } else if (audioPath != null) {
      return const Text('Rekaman Selesai',
          style: TextStyle(fontSize: 20, color: Colors.greenAccent));
    } else {
      return const Text('Tekan tombol untuk mulai merekam',
          style: TextStyle(fontSize: 18));
    }
  }
}
