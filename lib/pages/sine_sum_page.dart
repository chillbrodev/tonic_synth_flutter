import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/sine_sum_synth.dart';

class SineSumPage extends StatefulWidget {
  const SineSumPage({super.key});

  @override
  State<SineSumPage> createState() => _SineSumPageState();
}

class _SineSumPageState extends State<SineSumPage> with SynthPageAudioMixin {
  late final SineSumSynth synth;
  double pitch = 0.5;
  double _wheelAngle = 0;

  @override
  void initState() {
    super.initState();
    synth = SineSumSynth();
    initSynthPageAudio();
    _wheelAngle = pitch * math.pi * 2;
  }

  @override
  void dispose() {
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(isRecording: isRecording, child: Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: SynthAppBar(title: 'SINE SUM'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('CHORD STACK · 10 DETUNED SINES'),
            const Spacer(),
            Center(
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _wheelAngle += d.delta.dy * 0.008;
                    pitch = ((_wheelAngle / (math.pi * 2)) % 1 + 1) % 1;
                  });
                  synth.setPitch(pitch);
                },
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: _JogWheelPainter(
                      angle: _wheelAngle,
                      pitch: pitch,
                      isPlaying: isPlaying,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    pitch.toStringAsFixed(3),
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 40,
                      color: Color(0xFFFF9500),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Text(
                    'PITCH',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 9,
                      color: Color(0xFF555555),
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SynthAudioControls.fromMixin(this, accent: const Color(0xFFFF9500)),
          ],
        ),
      ),
    ));
  }
}

class _JogWheelPainter extends CustomPainter {

  const _JogWheelPainter({
    required this.angle,
    required this.pitch,
    required this.isPlaying,
  });
  final double angle;
  final double pitch;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 4;
    final innerR = outerR - 24;
    const color = Color(0xFFFF9500);

    // Outer ring — filled segment showing pitch position
    final segPaint = Paint()
      ..color = color.withValues(alpha: isPlaying ? 0.15 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerR, segPaint);

    // Outer border
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = const Color(0xFF2A2A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Grip lines (like a real jog wheel)
    const gripCount = 24;
    for (int i = 0; i < gripCount; i++) {
      final a = angle + i / gripCount * 2 * math.pi;
      final p1 = Offset(
        center.dx + (outerR - 2) * math.cos(a),
        center.dy + (outerR - 2) * math.sin(a),
      );
      final p2 = Offset(
        center.dx + (outerR - 14) * math.cos(a),
        center.dy + (outerR - 14) * math.sin(a),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = const Color(0xFF222222)
          ..strokeWidth = 2,
      );
    }

    // Inner disc
    canvas.drawCircle(center, innerR, Paint()..color = const Color(0xFF0D0D0D));
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = isPlaying ? color.withValues(alpha: 0.4) : const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Indicator dot on outer ring
    final dotAngle = angle - math.pi / 2;
    canvas.drawCircle(
      Offset(
        center.dx + (outerR - 8) * math.cos(dotAngle),
        center.dy + (outerR - 8) * math.sin(dotAngle),
      ),
      4,
      Paint()..color = color,
    );

    // Sine wave preview inside disc
    final wavePaint = Paint()
      ..color = color.withValues(alpha: isPlaying ? 0.6 : 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final wavePath = Path();
    const steps = 80;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final wx = center.dx - innerR * 0.8 + t * innerR * 1.6;
      final freq = 1 + pitch * 4;
      final wy =
          center.dy +
          math.sin(t * math.pi * 2 * freq + angle * 3) * innerR * 0.3;
      i == 0 ? wavePath.moveTo(wx, wy) : wavePath.lineTo(wx, wy);
    }
    // Clip to inner circle
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: innerR - 4)),
    );
    canvas.drawPath(wavePath, wavePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JogWheelPainter old) =>
      old.angle != angle || old.isPlaying != isPlaying;
}
