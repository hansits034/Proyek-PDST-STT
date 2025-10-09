import 'package:flutter/material.dart';

class PlaybackButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  const PlaybackButton({
    super.key,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isPlaying ? onStop : onPlay,
      icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
      label: Text(isPlaying ? 'Hentikan Audio' : 'Putar Rekaman'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPlaying ? Colors.orange : Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
