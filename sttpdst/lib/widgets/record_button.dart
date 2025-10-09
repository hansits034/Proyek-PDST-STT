import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isRecording ? onStop : onStart,
      icon: Icon(isRecording ? Icons.stop : Icons.mic),
      label: Text(isRecording ? 'Hentikan Rekaman' : 'Mulai Merekam'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isRecording ? Colors.redAccent : Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
