import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/lf_noise_synth.dart';

class LfNoisePage extends StatefulWidget {
  const LfNoisePage({super.key});

  @override
  State<LfNoisePage> createState() => _LfNoisePageState();
}

class _LfNoisePageState extends State<LfNoisePage> with SynthPageAudioMixin {
  late final LfNoiseSynth synth;
  double noiseFreq = 100;
  double _dialAngle = 0; // accumulated drag angle

  @override
  void initState() {
    super.initState();
    synth = LfNoiseSynth();
    initSynthPageAudio();
    _dialAngle = _freqToAngle(noiseFreq);
  }

  @override
  void dispose() {
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  double _freqToAngle(double freq) =>
      (freq - 1) / 499 * math.pi * 2.5 - math.pi * 1.25;

  double _angleToFreq(double angle) =>
      ((angle + math.pi * 1.25) / (math.pi * 2.5) * 499 + 1).clamp(1, 500);

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(isRecording: isRecording, child: Scaffold(
      backgroundColor: AppStyles.background,
      appBar: SynthAppBar(title: 'LF NOISE'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('NOISE FREQUENCY'),
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
                style: AppStyles.heroValue(
                  AppStyles.accentPurple,
                  fontSize: 32,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Spacer(),
            SynthAudioControls.fromMixin(this, accent: AppStyles.accentPurple),
          ],
        ),
      ),
    ));
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
    const color = AppStyles.accentPurple;

    // Outer ring
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = AppStyles.surfaceRaised
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
        ..color = AppStyles.trackInactive
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
      Paint()..color = AppStyles.surfaceRaised,
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
          ..color = AppStyles.chromeMuted
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_RotaryKnobPainter old) =>
      old.angle != angle || old.isPlaying != isPlaying;
}
