import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/stereo_delay_synth.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class StereoDelayPage extends StatefulWidget {
  const StereoDelayPage({super.key});

  @override
  State<StereoDelayPage> createState() => _StereoDelayPageState();
}

class _StereoDelayPageState extends State<StereoDelayPage> with SynthPageAudioMixin {
  late final StereoDelaySynth synth;

  double freq = 0;
  double freqRand = 0.5;
  double decay = 0.5;
  double _tapPhase = 0;

  @override
  void initState() {
    super.initState();
    synth = StereoDelaySynth();
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
    if (isPlaying) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _tapPhase += 0.15);
      });
    }

    return SynthPageShell(isRecording: isRecording, child: Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: SynthAppBar(title: 'STEREO DELAY'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('STEREO FIELD'),
            const SizedBox(height: 16),
            Expanded(
              child: CustomPaint(
                painter: _StereoFieldPainter(
                  phase: _tapPhase,
                  decay: decay,
                  isPlaying: isPlaying,
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ArcDial(
                  label: 'FREQ',
                  value: freq,
                  min: 0,
                  max: 500,
                  display: '${freq.toStringAsFixed(0)}Hz',
                  color: const Color(0xFF3498DB),
                  dialSize: 90,
                  strokeWidth: 5,
                  displayFontSize: 10,
                  labelSpacing: 6,
                  onChanged: (v) {
                    setState(() => freq = v);
                    onResult(synth.setFreq(v));
                  },
                ),
                ArcDial(
                  label: 'RANDOM',
                  value: freqRand,
                  min: 0,
                  max: 1,
                  display: freqRand.toStringAsFixed(2),
                  color: const Color(0xFF3498DB),
                  dialSize: 90,
                  strokeWidth: 5,
                  displayFontSize: 10,
                  labelSpacing: 6,
                  onChanged: (v) {
                    setState(() => freqRand = v);
                    onResult(synth.setFrequencyRandomAmount(v));
                  },
                ),
                ArcDial(
                  label: 'DECAY',
                  value: decay,
                  min: 0,
                  max: 2,
                  display: '${decay.toStringAsFixed(2)}s',
                  color: const Color(0xFF3498DB),
                  dialSize: 90,
                  strokeWidth: 5,
                  displayFontSize: 10,
                  labelSpacing: 6,
                  onChanged: (v) {
                    setState(() => decay = v);
                    onResult(synth.setDecay(v));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SynthAudioControls.fromMixin(this, accent: const Color(0xFF3498DB)),
          ],
        ),
      ),
    ));
  }
}

class _StereoFieldPainter extends CustomPainter {

  const _StereoFieldPainter({
    required this.phase,
    required this.decay,
    required this.isPlaying,
  });
  final double phase;
  final double decay;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFF3498DB);
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Center line
    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, size.height),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 1,
    );

    // L/R labels
    void drawLabel(String text, double x) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9,
            color: Color(0xFF333333),
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, 8));
    }

    drawLabel('L', cx * 0.4);
    drawLabel('R', cx * 1.6);

    if (!isPlaying) return;

    // Bouncing delay taps
    const tapCount = 5;
    for (int i = 0; i < tapCount; i++) {
      final t = (phase + i * 0.4) % (math.pi * 2);

      // Left tap — 0.5s delay cycle
      final lx = cx * 0.4 + math.sin(t * 0.37) * cx * 0.25;
      final ly = cy + math.sin(t * 0.5 + i) * cy * 0.6;
      final lOpacity = (1 - i / tapCount) * (math.sin(t * 0.5) * 0.5 + 0.5);

      // Right tap — 0.55s delay cycle (slightly offset)
      final rx = cx * 1.6 + math.sin(t * 0.37 + math.pi) * cx * 0.25;
      final ry = cy + math.sin(t * 0.55 + i + 1) * cy * 0.6;
      final rOpacity =
          (1 - i / tapCount) * (math.sin(t * 0.55 + 1) * 0.5 + 0.5);

      final r = (4 - i * 0.5) * (1 + decay * 0.5);

      canvas.drawCircle(
        Offset(lx, ly),
        r,
        Paint()..color = color.withValues(alpha: lOpacity.clamp(0.05, 0.8)),
      );
      canvas.drawCircle(
        Offset(rx, ry),
        r,
        Paint()..color = color.withValues(alpha: rOpacity.clamp(0.05, 0.8)),
      );

      // Trail lines
      if (i > 0) {
        final prevT = (phase + (i - 1) * 0.4) % (math.pi * 2);
        canvas.drawLine(
          Offset(lx, ly),
          Offset(
            cx * 0.4 + math.sin(prevT * 0.37) * cx * 0.25,
            cy + math.sin(prevT * 0.5 + i - 1) * cy * 0.6,
          ),
          Paint()
            ..color = color.withValues(alpha: lOpacity * 0.3)
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StereoFieldPainter old) =>
      old.phase != phase || old.isPlaying != isPlaying || old.decay != decay;
}
