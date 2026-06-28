import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/compressor_ducking_synth.dart';

class CompressorDuckingPage extends StatefulWidget {
  const CompressorDuckingPage({super.key});

  @override
  State<CompressorDuckingPage> createState() => _CompressorDuckingPageState();
}

class _CompressorDuckingPageState extends State<CompressorDuckingPage>
    with SynthPageAudioMixin {
  late final CompressorDuckingSynth synth;
  double compRelease = 0.025;
  bool _duckFlash = false;
  Timer? _duckTimer;

  @override
  void initState() {
    super.initState();
    synth = CompressorDuckingSynth();
    initSynthPageAudio();
  }

  @override
  void dispose() {
    _duckTimer?.cancel();
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Future<void> onSynthAudioStarting() async {
    // Pulse at 120 BPM = 500ms interval
    _duckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => _duckFlash = true);
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _duckFlash = false);
      });
    });
  }

  @override
  Future<void> onSynthAudioStopping() async {
    _duckTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(
      isRecording: isRecording,
      child: Scaffold(
        backgroundColor: AppStyles.background,
        appBar: SynthAppBar(title: 'DUCK'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('SIDECHAIN COMPRESSOR · 120 BPM'),
              const Spacer(),
              // DUCK flash indicator
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _duckFlash
                        ? AppStyles.accentRed.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: _duckFlash
                          ? AppStyles.accentRed
                          : AppStyles.trackInactive,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'DUCK',
                      style: AppStyles.duckLabel(active: _duckFlash),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const SectionLabel('COMP RELEASE'),
              const SizedBox(height: 24),
              // Arc dial
              Center(
                child: GestureDetector(
                  onPanUpdate: (d) {
                    final delta = -d.delta.dy / 150 * 0.49;
                    setState(() {
                      compRelease = (compRelease + delta).clamp(0.01, 0.5);
                    });
                    synth.setCompRelease(compRelease);
                  },
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _ArcDialPainter(
                        value: (compRelease - 0.01) / 0.49,
                        color: AppStyles.accentRed,
                        displayText:
                            '${(compRelease * 1000).toStringAsFixed(0)}ms',
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SynthAudioControls.fromMixin(this, accent: AppStyles.accentRed),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcDialPainter extends CustomPainter {
  const _ArcDialPainter({
    required this.value,
    required this.color,
    required this.displayText,
  });
  final double value;
  final Color color;
  final String displayText;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = AppStyles.trackInactive
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
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
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: displayText,
        style: AppStyles.monoValue(color, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ArcDialPainter old) =>
      old.value != value || old.displayText != displayText;
}
