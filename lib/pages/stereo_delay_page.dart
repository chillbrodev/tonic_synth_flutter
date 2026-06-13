import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import '../../synths/stereo_delay_synth.dart';
import '../../synths/result/tonic_result.dart';

class StereoDelayPage extends StatefulWidget {
  const StereoDelayPage({super.key});

  @override
  State<StereoDelayPage> createState() => _StereoDelayPageState();
}

class _StereoDelayPageState extends State<StereoDelayPage> {
  late final StereoDelaySynth synth;

  double freq = 0;
  double freqRand = 0.5;
  double decay = 0.5;
  bool isPlaying = false;
  double _tapPhase = 0;

  @override
  void initState() {
    super.initState();
    synth = StereoDelaySynth();
  }

  @override
  void dispose() {
    synth.destroy();
    super.dispose();
  }

  void onResult(TonicResult r) {}

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
    if (isPlaying) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _tapPhase += 0.15);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: synthAppBar('STEREO DELAY'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel('STEREO FIELD'),
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
                _arcDial(
                  label: 'FREQ',
                  value: freq,
                  min: 0,
                  max: 500,
                  display: '${freq.toStringAsFixed(0)}Hz',
                  color: const Color(0xFF3498DB),
                  onChanged: (v) {
                    setState(() => freq = v);
                    onResult(synth.setFreq(v));
                  },
                ),
                _arcDial(
                  label: 'RANDOM',
                  value: freqRand,
                  min: 0,
                  max: 1,
                  display: freqRand.toStringAsFixed(2),
                  color: const Color(0xFF3498DB),
                  onChanged: (v) {
                    setState(() => freqRand = v);
                    onResult(synth.setFrequencyRandomAmount(v));
                  },
                ),
                _arcDial(
                  label: 'DECAY',
                  value: decay,
                  min: 0,
                  max: 2,
                  display: '${decay.toStringAsFixed(2)}s',
                  color: const Color(0xFF3498DB),
                  onChanged: (v) {
                    setState(() => decay = v);
                    onResult(synth.setDecay(v));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            playButton(
              isPlaying: isPlaying,
              onTap: toggleAudio,
              accent: const Color(0xFF3498DB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arcDial({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        GestureDetector(
          onPanUpdate: (d) {
            final range = max - min;
            final delta = -d.delta.dy / 150 * range;
            onChanged((value + delta).clamp(min, max));
          },
          child: SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _ArcDialPainter(
                value: (value - min) / (max - min),
                color: color,
                displayText: display,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9,
            color: Color(0xFF555555),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _StereoFieldPainter extends CustomPainter {
  final double phase;
  final double decay;
  final bool isPlaying;

  const _StereoFieldPainter({
    required this.phase,
    required this.decay,
    required this.isPlaying,
  });

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

class _ArcDialPainter extends CustomPainter {
  final double value;
  final Color color;
  final String displayText;

  const _ArcDialPainter({
    required this.value,
    required this.color,
    required this.displayText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = const Color(0xFF2A2A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(fontFamily: 'RobotoMono', fontSize: 10, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ArcDialPainter old) =>
      old.value != value || old.displayText != displayText;
}
