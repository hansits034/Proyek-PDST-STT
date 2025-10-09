import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../widgets/record_button.dart';
import '../widgets/playback_button.dart';
import '../widgets/status_text.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  late final AudioRecorder _recorder;
  late final AudioPlayer _player;

  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _player = AudioPlayer();

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        _isRecording = true;
        _audioPath = null;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
    if (path != null) await ApiService.uploadFile(path);
  }

  Future<void> _playAudio() async {
    if (_audioPath != null) {
      await _player.setFilePath(_audioPath!);
      _player.play();
      setState(() {});
    }
  }

  Future<void> _stopAudio() async {
    await _player.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _player.playing;
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Recorder & Player")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusText(isRecording: _isRecording, audioPath: _audioPath),
              const SizedBox(height: 30),
              RecordButton(
                isRecording: _isRecording,
                onStart: _startRecording,
                onStop: _stopRecording,
              ),
              const SizedBox(height: 20),
              if (!_isRecording && _audioPath != null)
                PlaybackButton(
                  isPlaying: isPlaying,
                  onPlay: _playAudio,
                  onStop: _stopAudio,
                ),
              const SizedBox(height: 20),
              if (_audioPath != null)
                Text('Path:\n$_audioPath', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
