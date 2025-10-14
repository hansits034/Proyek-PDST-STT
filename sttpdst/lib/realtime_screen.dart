import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart'; // <-- GANTI DARI mic_stream
import 'package:permission_handler/permission_handler.dart'; // <-- TAMBAHKAN INI
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

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

  // Waveform state
  final List<double> _waveform = <double>[]; // recent RMS values 0..1
  static const int _waveformCapacity = 120;  // ~ couple seconds depending on chunk rate
  double _rms = 0.0; // 0..1
  bool _voiceDetected = false;

  // Spectrum + transcript feedback
  static const int _spectrumBarCount = 24;
  final List<double> _spectrumLevels = List<double>.filled(_spectrumBarCount, 0.0);
  Timer? _ellipsisTimer;
  String _ellipsis = '';
  bool _awaitingServer = false;
  bool _hasTranscribedText = false;

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
    _ellipsisTimer?.cancel();
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
      _waveform.clear();
      _spectrumLevels.fillRange(0, _spectrumLevels.length, 0.0);
      _ellipsis = '';
      _awaitingServer = true;
      _hasTranscribedText = false;
    });
    _startEllipsisTimer();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      setState(() {
        _status = "Terhubung. Mulai berbicara...";
        _isRecording = true;
        _awaitingServer = true;
      });

      _listenToMic();

      _channel!.stream.listen(
        (message) {
          _stopEllipsisTimer();
          final text = (message ?? '').toString().trim();
          if (!mounted) return;
          setState(() {
            if (text.isNotEmpty) {
              _transcribedText = _transcribedText.isEmpty
                  ? text
                  : "$_transcribedText $text";
              _hasTranscribedText = true;
            }
            _status = "Transkrip diperbarui.";
            _awaitingServer = false;
            _ellipsis = '';
          });
        },
        onDone: () {
          _stopEllipsisTimer();
          setState(() {
            _status = "Koneksi ditutup oleh server.";
            _isRecording = false;
            _awaitingServer = false;
            _ellipsis = '';
          });
        },
        onError: (error) {
          _stopEllipsisTimer();
          setState(() {
            _status = "Error koneksi: $error";
            _isRecording = false;
            _awaitingServer = false;
            _ellipsis = '';
          });
        },
      );
    } catch (e) {
      _stopEllipsisTimer();
      setState(() {
        _status = "Gagal terhubung ke server: $e";
        _isRecording = false;
        _awaitingServer = false;
        _ellipsis = '';
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

    // Request server to transcribe any remaining buffer
    try {
      _channel?.sink.add('STOP');
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 50));
    _channel?.sink.close();
    _channel = null;

    setState(() {
      _status = "Koneksi dihentikan.";
      _isRecording = false;
      _voiceDetected = false;
      _awaitingServer = false;
      _ellipsis = '';
    });
    _stopEllipsisTimer();
    _waveform.clear();
    _spectrumLevels.fillRange(0, _spectrumLevels.length, 0.0);
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
          // Forward PCM16 bytes to backend
          if (_channel != null) {
            _channel!.sink.add(data);
          }
          // Update waveform/amplitude for UI
          _pushPcmForWaveform(data, channels: 1);
          setState(() {});
        },
        onError: (error) {
          _stopListening();
          setState(() => _status = "Error streaming: $error");
        },
      );
    }
  }

  void _pushPcmForWaveform(List<int> bytes, {int channels = 1}) {
    if (bytes.isEmpty) return;
    final u8 = Uint8List.fromList(bytes);
    final bd = ByteData.view(u8.buffer, u8.offsetInBytes, u8.lengthInBytes);
    final sampleCount = bd.lengthInBytes ~/ 2; // int16
    if (sampleCount == 0) return;

    final monoSamples = <double>[];
    double sumSq = 0.0;
    for (int i = 0; i < sampleCount; i += channels) {
      double acc = 0.0;
      for (int c = 0; c < channels; c++) {
        final idx = i + c;
        if (idx >= sampleCount) break;
        final v = bd.getInt16(idx * 2, Endian.little);
        acc += v / 32768.0;
      }
      final averaged = (acc / channels).clamp(-1.0, 1.0);
      monoSamples.add(averaged);
      sumSq += averaged * averaged;
    }
    if (monoSamples.isEmpty) return;

    final rms = math.sqrt(sumSq / monoSamples.length).clamp(0.0, 1.0);
    _rms = rms;
    _voiceDetected = rms > 0.02; // simple VAD threshold
    _waveform.add(rms);
    if (_waveform.length > _waveformCapacity) {
      _waveform.removeRange(0, _waveform.length - _waveformCapacity);
    }

    _updateSpectrum(monoSamples);

    if (_isRecording && _voiceDetected && !_awaitingServer) {
      _awaitingServer = true;
      _startEllipsisTimer();
    }
  }

  void _updateSpectrum(List<double> samples) {
    if (samples.isEmpty) return;
    final int limit = math.min(samples.length, 512);
    if (limit < 8) return;

    const double smoothing = 0.75;
    for (int bin = 0; bin < _spectrumBarCount; bin++) {
      double real = 0.0;
      double imag = 0.0;
      final double freq = 2 * math.pi * (bin + 1) / limit;
      for (int n = 0; n < limit; n++) {
        final double sample = samples[n];
        final double angle = freq * n;
        real += sample * math.cos(angle);
        imag -= sample * math.sin(angle);
      }
      double magnitude = math.sqrt(real * real + imag * imag) / limit;
      magnitude = (magnitude * 4).clamp(0.0, 1.0);
      _spectrumLevels[bin] = _spectrumLevels[bin] * smoothing + magnitude * (1 - smoothing);
    }
  }

  void _startEllipsisTimer() {
    _stopEllipsisTimer();
    const frames = ['', '.', '..', '...'];
    int index = 0;
    _ellipsisTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!mounted) {
        _ellipsisTimer?.cancel();
        _ellipsisTimer = null;
        return;
      }
      setState(() {
        _ellipsis = frames[index];
        index = (index + 1) % frames.length;
      });
    });
  }

  void _stopEllipsisTimer() {
    _ellipsisTimer?.cancel();
    _ellipsisTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = "Hasil transkrip akan muncul di sini" + (_awaitingServer ? _ellipsis : "...");
    final transcriptDisplay = _transcribedText.isEmpty
        ? placeholder
        : _transcribedText.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transkripsi Real-time'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _StatusRow(
              status: _status,
              connected: _isRecording,
              voice: _voiceDetected,
              rms: _rms,
              awaiting: _awaitingServer,
            ),
            const SizedBox(height: 16),
            _SpectrumCard(levels: _spectrumLevels, active: _isRecording || _voiceDetected),
            const SizedBox(height: 12),
            _WaveformCard(values: _waveform, active: _isRecording),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasTranscribedText ? Icons.text_snippet : Icons.hourglass_bottom,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hasTranscribedText ? 'Transkrip terkini' : 'Menunggu transkrip',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: _awaitingServer ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            ),
                          ),
                        ],
                      ),
                      if (_awaitingServer) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          minHeight: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            transcriptDisplay,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isRecording ? _stopListening : _startListening,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(_isRecording ? 'Hentikan' : 'Mulai Merekam', style: const TextStyle(fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRecording ? Colors.redAccent : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SpectrumCard extends StatelessWidget {
  final List<double> levels;
  final bool active;
  const _SpectrumCard({required this.levels, required this.active});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: CustomPaint(
          painter: _SpectrumPainter(levels, active),
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<double> levels;
  final bool active;
  _SpectrumPainter(this.levels, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint background = Paint()
      ..color = active ? const Color(0xFFE3F2FD) : const Color(0xFFF1F8E9);
    final Rect rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), background);

    if (levels.isEmpty) return;

    final int barCount = levels.length;
    final double gap = size.width / (barCount * 3);
    final double barWidth = math.max(2.0, (size.width - gap * (barCount + 1)) / barCount);

    double x = gap;
    final shader = LinearGradient(
      colors: active
          ? [Colors.blueAccent, Colors.cyanAccent]
          : [Colors.deepPurpleAccent.withOpacity(0.6), Colors.deepPurpleAccent.withOpacity(0.3)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(rect);

    final Paint barPaint = Paint()
      ..shader = shader
      ..isAntiAlias = true;

    for (int i = 0; i < barCount; i++) {
      final double level = levels[i].clamp(0.0, 1.0);
      final double barHeight = level * size.height;
      final Rect barRect = Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(4)), barPaint);
      x += barWidth + gap;
      if (x > size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return true;
  }
}

class _WaveformCard extends StatelessWidget {
  final List<double> values;
  final bool active;
  const _WaveformCard({required this.values, required this.active});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: CustomPaint(
          painter: _WaveformPainter(values, active),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> values;
  final bool active;
  _WaveformPainter(this.values, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = active ? const Color(0xFFE8F5E9) : const Color(0xFFF3E5F5);
    final radius = 10.0;
    final rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), bg);

    if (values.isEmpty) return;

    final stroke = Paint()
      ..color = active ? Colors.greenAccent.shade700 : Colors.deepPurpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final n = values.length;
    final dx = n > 1 ? size.width / (n - 1) : size.width;

    // Upper path
    final pathUp = Path();
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final y = size.height * 0.5 - v * (size.height * 0.5 - 4);
      final x = i * dx;
      if (i == 0) {
        pathUp.moveTo(x, y);
      } else {
        pathUp.lineTo(x, y);
      }
    }
    canvas.drawPath(pathUp, stroke);

    // Lower mirror
    final pathDown = Path();
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final y = size.height * 0.5 + v * (size.height * 0.5 - 4);
      final x = i * dx;
      if (i == 0) {
        pathDown.moveTo(x, y);
      } else {
        pathDown.lineTo(x, y);
      }
    }
    canvas.drawPath(pathDown, stroke);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return true;
  }
}

class _StatusRow extends StatelessWidget {
  final String status; 
  final bool connected; 
  final bool voice; 
  final double rms;
  final bool awaiting;
  const _StatusRow({
    required this.status,
    required this.connected,
    required this.voice,
    required this.rms,
    required this.awaiting,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final color = connected ? scheme.primary : Colors.grey;
    final vdColor = voice ? Colors.orange : Colors.grey;
    final serverColor = awaiting ? Colors.blueAccent : Colors.green;
    final db = rms > 0 ? (20 * math.log(rms) / math.ln10) : -80.0; // dBFS approx
    final dbStr = db.isFinite ? db.toStringAsFixed(1) : '-inf';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Dot(color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(status, style: Theme.of(context).textTheme.titleMedium)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(icon: Icons.mic, label: connected ? 'Streaming' : 'Idle', color: color),
            _StatusChip(icon: Icons.graphic_eq, label: voice ? 'Suara terdeteksi' : 'Sunyi', color: vdColor),
            _StatusChip(icon: Icons.cloud_sync, label: awaiting ? 'Menunggu server' : 'Server responsif', color: serverColor),
            _StatusChip(icon: Icons.volume_up, label: 'Level $dbStr dB', color: scheme.secondary),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}