import 'package:flutter/material.dart';
import 'package:record/record.dart'; // Untuk merekam audio
import 'package:just_audio/just_audio.dart'; // Untuk memutar audio
import 'package:path_provider/path_provider.dart'; // Untuk manajemen path file
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AudioRecorderScreen(),
    );
  }
}

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    // Listener untuk deteksi audio selesai diputar
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Mulai rekaman
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _audioPath = null;
        });
      }
    } catch (e) {
      debugPrint('Gagal memulai rekaman: $e');
    }
  }

  /// Hentikan rekaman
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      // langsung upload setelah stop
      if (path != null) {
        await uploadFile(path);
      }
    } catch (e) {
      debugPrint('Gagal menghentikan rekaman: $e');
    }
  }

  /// Upload file ke backend FastAPI
  Future<void> uploadFile(String filePath) async {
    try {
      var uri = Uri.parse("http://10.0.2.2:8000/upload"); 
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();

      if (response.statusCode == 200) {
        print("✅ Upload sukses");
      } else {
        print("❌ Upload gagal: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error upload: $e');
    }
  }

  /// Putar audio
  Future<void> _playAudio() async {
    if (_audioPath != null) {
      try {
        await _audioPlayer.setFilePath(_audioPath!);
        _audioPlayer.play();
      } catch (e) {
        debugPrint('Gagal memutar audio: $e');
      }
    }
  }

  /// Hentikan audio
  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Gagal menghentikan audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _audioPlayer.playing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder & Player'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isRecording)
                const Text('Sedang Merekam...',
                    style: TextStyle(fontSize: 20, color: Colors.redAccent))
              else if (_audioPath != null)
                const Text('Rekaman Selesai',
                    style: TextStyle(fontSize: 20, color: Colors.greenAccent))
              else
                const Text('Tekan tombol untuk mulai merekam',
                    style: TextStyle(fontSize: 18)),

              const SizedBox(height: 40),

              _isRecording
                  ? _buildStopRecordButton()
                  : _buildStartRecordButton(),

              const SizedBox(height: 20),

              if (!_isRecording && _audioPath != null)
                isPlaying ? _buildStopAudioButton() : _buildPlayAudioButton(),

              const SizedBox(height: 20),

              if (_audioPath != null)
                Text(
                  'File disimpan di:\n$_audioPath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol UI
  Widget _buildStartRecordButton() {
    return ElevatedButton.icon(
      onPressed: _startRecording,
      icon: const Icon(Icons.mic),
      label: const Text('Mulai Merekam'),
    );
  }

  Widget _buildStopRecordButton() {
    return ElevatedButton.icon(
      onPressed: _stopRecording,
      icon: const Icon(Icons.stop),
      label: const Text('Hentikan Rekaman'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
    );
  }

  Widget _buildPlayAudioButton() {
    return ElevatedButton.icon(
      onPressed: _playAudio,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Putar Rekaman'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    );
  }

  Widget _buildStopAudioButton() {
    return ElevatedButton.icon(
      onPressed: _stopAudio,
      icon: const Icon(Icons.stop),
      label: const Text('Hentikan Audio'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
    );
  }
}
