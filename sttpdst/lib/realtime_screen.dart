import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart'; // <-- GANTI DARI mic_stream
import 'package:permission_handler/permission_handler.dart'; // <-- TAMBAHKAN INI
import 'dart:async';

class RealtimeScreen extends StatefulWidget {
  const RealtimeScreen({super.key});

  @override
  State<RealtimeScreen> createState() => _RealtimeScreenState();
}

class _RealtimeScreenState extends State<RealtimeScreen> {
  late final AudioRecorder _audioRecorder;
  StreamSubscription<List<int>>? _micSubscription;

  WebSocketChannel? _channel;
  String _transcribedText = "";
  String _status = "Belum Terhubung";
  bool _isRecording = false;

  final String _serverUrl = 'ws://10.0.2.2:8000/ws';

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _stopListening();
    _audioRecorder.dispose(); 
    super.dispose();
  }

  void _startListening() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _status = "Izin mikrofon ditolak.";
      });
      return;
    }

    setState(() {
      _status = "Menghubungkan ke server...";
      _transcribedText = "";
    });

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      setState(() {
        _status = "Terhubung. Mulai berbicara...";
        _isRecording = true;
      });

      _listenToMic();

      _channel!.stream.listen(
        (message) {
          setState(() {
            _transcribedText += "$message ";
          });
        },
        onDone: () {
          setState(() {
            _status = "Koneksi ditutup oleh server.";
            _isRecording = false;
          });
        },
        onError: (error) {
          setState(() {
            _status = "Error koneksi: $error";
            _isRecording = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = "Gagal terhubung ke server: $e";
        _isRecording = false;
      });
    }
  }

  void _stopListening() async {
    if (!_isRecording) return;

    await _micSubscription?.cancel();
    _micSubscription = null;

    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    _channel?.sink.close();
    _channel = null;

    setState(() {
      _status = "Koneksi dihentikan.";
      _isRecording = false;
    });
  }

  Future<void> _listenToMic() async {
    if (await _audioRecorder.hasPermission()) {
      const recorderConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits, 
        sampleRate: 16000,              
        numChannels: 1,               
      );

      final stream = await _audioRecorder.startStream(recorderConfig);

      _micSubscription = stream.listen(
        (data) {
          if (_channel != null && _channel!.sink != null) {
            _channel!.sink.add(data);
          }
        },
        onError: (error) {
          _stopListening();
          setState(() => _status = "Error streaming: $error");
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transkripsi Real-time'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _transcribedText.isEmpty
                          ? "Hasil transkrip akan muncul di sini..."
                          : _transcribedText,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildRecordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return ElevatedButton.icon(
      onPressed: _isRecording ? _stopListening : _startListening,
      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
      label: Text(_isRecording ? 'Hentikan' : 'Mulai Merekam'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRecording ? Colors.redAccent : Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}