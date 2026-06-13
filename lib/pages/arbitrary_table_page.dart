import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import '../../synths/arbitrary_table_synth.dart';

class ArbitraryTablePage extends StatefulWidget {
  const ArbitraryTablePage({super.key});

  @override
  State<ArbitraryTablePage> createState() => _ArbitraryTablePageState();
}

class _ArbitraryTablePageState extends State<ArbitraryTablePage>
    with SingleTickerProviderStateMixin {
  late final ArbitraryTableSynth synth;
  late final AnimationController _animController;
  List<double> _waveform = List.filled(64, 0);
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    synth = ArbitraryTableSynth();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(_updateWaveform);
  }

  void _updateWaveform() {
    if (!isPlaying) return;
    final buf = synth.fillBuffer(512, 1);
    final step = buf.length ~/ 64;
    setState(() {
      _waveform = List.generate(64, (i) => buf[i * step].toDouble());
    });
  }

  Future<void> toggleAudio() async {
    if (isPlaying) {
      _animController.stop();
      await synth.stopAudio();
    } else {
      await synth.startAudio();
      _animController.repeat();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  void dispose() {
    _animController.dispose();
    synth.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: synthAppBar('WAVETABLE'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel('WAVEFORM OUTPUT'),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  border: Border.all(color: const Color(0xFF1A1A1A)),
                ),
                child: CustomPaint(
                  painter: _WaveformPainter(
                    samples: _waveform,
                    color: const Color(0xFFFF9500),
                    isPlaying: isPlaying,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 24),
            playButton(
              isPlaying: isPlaying,
              onTap: toggleAudio,
              accent: const Color(0xFFFF9500),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final bool isPlaying;

  const _WaveformPainter({
    required this.samples,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final midY = size.height / 2;
    final paint = Paint()
      ..color = isPlaying ? color : color.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < samples.length; i++) {
      final x = i / (samples.length - 1) * size.width;
      final y = midY - samples[i] * midY * 0.85;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Zero line
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 1,
    );

    // Glow when playing
    if (isPlaying) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.samples != samples || old.isPlaying != isPlaying;
}
