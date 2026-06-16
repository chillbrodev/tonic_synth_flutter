import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/reverb_test_synth.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class ReverbTestPage extends StatefulWidget {
  const ReverbTestPage({super.key});

  @override
  State<ReverbTestPage> createState() => _ReverbTestPageState();
}

class _ReverbTestPageState extends State<ReverbTestPage> with SynthPageAudioMixin {
  late final ReverbTestSynth synth;

  double dry = -6;
  double wet = -20;
  double decayTime = 1.0;
  double size = 0.5;
  double shape = 0.5;
  double density = 0.5;
  double stereo = 0.5;

  @override
  void initState() {
    super.initState();
    synth = ReverbTestSynth();
    initSynthPageAudio();
  }

  @override
  void dispose() {
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  void onResult(TonicResult r) {}

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(isRecording: isRecording, child: Scaffold(
      backgroundColor: AppStyles.background,
      appBar: SynthAppBar(title: 'REVERB'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('ROOM'),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 200,
                height: 160,
                child: CustomPaint(
                  painter: _RoomPainter(
                    size: size,
                    shape: shape,
                    density: density,
                    decayTime: decayTime,
                    isPlaying: isPlaying,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SectionLabel('SPACE'),
            const SizedBox(height: 16),
            LabeledSlider(
              label: 'DECAY',
              display: '${decayTime.toStringAsFixed(1)}s',
              value: decayTime,
              min: 0.1,
              max: 10,
              color: AppStyles.accentBlue,
              displayWidth: 52,
              onChanged: (v) {
                setState(() => decayTime = v);
                onResult(synth.setDecayTime(v));
              },
            ),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'SIZE',
              display: size.toStringAsFixed(2),
              value: size,
              min: 0,
              max: 1,
              color: AppStyles.accentBlue,
              displayWidth: 52,
              onChanged: (v) {
                setState(() => size = v);
                onResult(synth.setSize(v));
              },
            ),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'SHAPE',
              display: shape.toStringAsFixed(2),
              value: shape,
              min: 0,
              max: 1,
              color: AppStyles.accentBlue,
              displayWidth: 52,
              onChanged: (v) {
                setState(() => shape = v);
                onResult(synth.setShape(v));
              },
            ),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'DENSITY',
              display: density.toStringAsFixed(2),
              value: density,
              min: 0,
              max: 1,
              color: AppStyles.accentBlue,
              displayWidth: 52,
              onChanged: (v) {
                setState(() => density = v);
                onResult(synth.setDensity(v));
              },
            ),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'STEREO',
              display: stereo.toStringAsFixed(2),
              value: stereo,
              min: 0,
              max: 1,
              color: AppStyles.accentBlue,
              displayWidth: 52,
              onChanged: (v) {
                setState(() => stereo = v);
                onResult(synth.setStereo(v));
              },
            ),
            const SizedBox(height: 24),
            const SectionLabel('LEVELS'),
            const SizedBox(height: 16),
            LabeledSlider(
              label: 'DRY',
              display: '${dry.toStringAsFixed(0)}dB',
              value: dry,
              min: -60,
              max: 0,
              color: AppStyles.accentMint,
              displayWidth: 52,
              onChanged: (v) {
                setState(() => dry = v);
                onResult(synth.setDry(v));
              },
            ),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'WET',
              display: '${wet.toStringAsFixed(0)}dB',
              value: wet,
              min: -60,
              max: 0,
              color: AppStyles.accentOrange,
              displayWidth: 52,
              onChanged: (v) {
                setState(() => wet = v);
                onResult(synth.setWet(v));
              },
            ),
            const SizedBox(height: 32),
            SynthAudioControls.fromMixin(this, accent: AppStyles.accentBlue),
          ],
        ),
      ),
    ));
  }
}

class _RoomPainter extends CustomPainter {

  const _RoomPainter({
    required this.size,
    required this.shape,
    required this.density,
    required this.decayTime,
    required this.isPlaying,
  });
  final double size;
  final double shape;
  final double density;
  final double decayTime;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;
    final maxR = canvasSize.width / 2 - 8;
    final r = maxR * (0.3 + size * 0.7);

    // Interpolate between circle (shape=1) and rectangle (shape=0)
    const color = AppStyles.accentBlue;

    final path = Path();
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = t * 2 * math.pi;
      final circleX = cx + r * math.cos(angle);
      final circleY = cy + r * math.sin(angle);

      // Rectangle approximation
      final rectR = r / math.max(math.cos(angle).abs(), math.sin(angle).abs());
      final rectX = cx + rectR * math.cos(angle);
      final rectY = cy + rectR * math.sin(angle);

      final x = circleX * shape + rectX * (1 - shape);
      final y = circleY * shape + rectY * (1 - shape);

      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: isPlaying ? 0.08 : 0.04)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: isPlaying ? 0.6 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Density dots
    final rng = math.Random(42);
    final dotCount = (density * 20).toInt();
    for (int i = 0; i < dotCount; i++) {
      final a = rng.nextDouble() * 2 * math.pi;
      final d = rng.nextDouble() * r * 0.7;
      canvas.drawCircle(
        Offset(cx + d * math.cos(a), cy + d * math.sin(a)),
        1,
        Paint()..color = color.withValues(alpha: 0.3),
      );
    }

    // Decay time label
    final tp = TextPainter(
      text: TextSpan(
        text: '${decayTime.toStringAsFixed(1)}s',
        style: AppStyles.monoValue(color.withValues(alpha: 0.6), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.size != size ||
      old.shape != shape ||
      old.density != density ||
      old.decayTime != decayTime ||
      old.isPlaying != isPlaying;
}
