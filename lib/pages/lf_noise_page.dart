import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import '../../synths/lf_noise_synth.dart';

class LfNoisePage extends StatefulWidget {
  const LfNoisePage({super.key});

  @override
  State<LfNoisePage> createState() => _LfNoisePageState();
}

class _LfNoisePageState extends State<LfNoisePage> {
  late final LfNoiseSynth synth;
  double noiseFreq = 100;
  bool isPlaying = false;
  double _dialAngle = 0; // accumulated drag angle

  @override
  void initState() {
    super.initState();
    synth = LfNoiseSynth();
    _dialAngle = _freqToAngle(noiseFreq);
  }

  @override
  void dispose() {
    synth.destroy();
    super.dispose();
  }

  double _freqToAngle(double freq) =>
      (freq - 1) / 499 * math.pi * 2.5 - math.pi * 1.25;

  double _angleToFreq(double angle) =>
      ((angle + math.pi * 1.25) / (math.pi * 2.5) * 499 + 1).clamp(1, 500);

  Future<void> toggleAudio() async {
    if (isPlaying) {
      await synth.stopAudio();
    } else {
      await synth.startAudio();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: synthAppBar('LF NOISE'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel('NOISE FREQUENCY'),
            const Spacer(),
            Center(
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _dialAngle = (_dialAngle - d.delta.dy * 0.01).clamp(
                      -math.pi * 1.25,
                      math.pi * 1.25,
                    );
                    noiseFreq = _angleToFreq(_dialAngle);
                  });
                  synth.setNoiseFreq(noiseFreq);
                },
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _RotaryKnobPainter(
                      angle: _dialAngle,
                      freq: noiseFreq,
                      isPlaying: isPlaying,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '${noiseFreq.toStringAsFixed(0)} Hz',
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 32,
                  color: Color(0xFF9B59B6),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Spacer(),
            playButton(
              isPlaying: isPlaying,
              onTap: toggleAudio,
              accent: const Color(0xFF9B59B6),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotaryKnobPainter extends CustomPainter {

  const _RotaryKnobPainter({
    required this.angle,
    required this.freq,
    required this.isPlaying,
  });
  final double angle;
  final double freq;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const color = Color(0xFF9B59B6);

    // Outer ring
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Track arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      Paint()
        ..color = const Color(0xFF2A2A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Active arc
    final normalised = (angle + math.pi * 1.25) / (math.pi * 2.5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * normalised,
      false,
      Paint()
        ..color = isPlaying ? color : color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Knob body
    canvas.drawCircle(
      center,
      radius - 12,
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Indicator line
    final indicatorEnd = Offset(
      center.dx + (radius - 18) * math.cos(angle - math.pi / 2),
      center.dy + (radius - 18) * math.sin(angle - math.pi / 2),
    );
    canvas.drawLine(
      center,
      indicatorEnd,
      Paint()
        ..color = isPlaying ? color : color.withValues(alpha: 0.4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Tick marks
    for (int i = 0; i <= 10; i++) {
      final tickAngle = math.pi * 0.75 + i / 10 * math.pi * 1.5 - math.pi / 2;
      final inner = Offset(
        center.dx + (radius + 6) * math.cos(tickAngle),
        center.dy + (radius + 6) * math.sin(tickAngle),
      );
      final outer = Offset(
        center.dx + (radius + 12) * math.cos(tickAngle),
        center.dy + (radius + 12) * math.sin(tickAngle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = const Color(0xFF333333)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_RotaryKnobPainter old) =>
      old.angle != angle || old.isPlaying != isPlaying;
}
