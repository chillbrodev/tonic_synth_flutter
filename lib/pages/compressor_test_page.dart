import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/compressor_test_synth.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class CompressorTestPage extends StatefulWidget {
  const CompressorTestPage({super.key});

  @override
  State<CompressorTestPage> createState() => _CompressorTestPageState();
}

class _CompressorTestPageState extends State<CompressorTestPage>
    with SynthPageAudioMixin {
  late final CompressorTestSynth synth;

  double threshold = -12;
  double ratio = 2;
  double attackTime = 0.001;
  double releaseTime = 0.05;
  bool bypass = false;

  @override
  void initState() {
    super.initState();
    synth = CompressorTestSynth();
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
    return SynthPageShell(
      isRecording: isRecording,
      child: Scaffold(
        backgroundColor: AppStyles.background,
        appBar: SynthAppBar(title: 'COMPRESSOR'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('TRANSFER CURVE'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: _CompressorCurvePainter(
                    threshold: threshold,
                    ratio: ratio,
                    bypass: bypass,
                  ),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 32),
              const SectionLabel('CONTROLS'),
              const SizedBox(height: 16),
              LabeledSlider(
                label: 'THRESHOLD',
                display: '${threshold.toStringAsFixed(0)}dB',
                value: threshold,
                min: -60,
                max: 0,
                color: AppStyles.accentRed,
                onChanged: (v) {
                  setState(() => threshold = v);
                  onResult(synth.setThreshold(v));
                },
              ),
              const SizedBox(height: 12),
              LabeledSlider(
                label: 'RATIO',
                display: '${ratio.toStringAsFixed(1)}:1',
                value: ratio,
                min: 1,
                max: 64,
                color: AppStyles.accentRed,
                onChanged: (v) {
                  setState(() => ratio = v);
                  onResult(synth.setRatio(v));
                },
              ),
              const SizedBox(height: 12),
              LabeledSlider(
                label: 'ATTACK',
                display: '${(attackTime * 1000).toStringAsFixed(1)}ms',
                value: attackTime,
                min: 0.001,
                max: 0.1,
                color: AppStyles.accentMint,
                onChanged: (v) {
                  setState(() => attackTime = v);
                  onResult(synth.setAttackTime(v));
                },
              ),
              const SizedBox(height: 12),
              LabeledSlider(
                label: 'RELEASE',
                display: '${(releaseTime * 1000).toStringAsFixed(0)}ms',
                value: releaseTime,
                min: 0.01,
                max: 0.08,
                color: AppStyles.accentMint,
                onChanged: (v) {
                  setState(() => releaseTime = v);
                  onResult(synth.setReleaseTime(v));
                },
              ),
              const SizedBox(height: 24),
              // Bypass toggle
              Row(
                children: [
                  const Text('BYPASS', style: AppStyles.arcDialLabel),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => bypass = !bypass);
                      synth.setBypass(bypass);
                    },
                    child: Container(
                      width: 48,
                      height: 24,
                      decoration: BoxDecoration(
                        color: bypass
                            ? AppStyles.accentRed
                            : AppStyles.trackInactive,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 150),
                        alignment: bypass
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppStyles.textPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SynthAudioControls.fromMixin(this, accent: AppStyles.accentRed),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompressorCurvePainter extends CustomPainter {
  const _CompressorCurvePainter({
    required this.threshold,
    required this.ratio,
    required this.bypass,
  });
  final double threshold; // -60..0 dBFS
  final double ratio;
  final bool bypass;

  @override
  void paint(Canvas canvas, Size size) {
    const dbRange = 60.0;

    // Grid
    final gridPaint = Paint()
      ..color = AppStyles.surfaceRaised
      ..strokeWidth = 1;
    for (int i = 0; i <= 6; i++) {
      final x = i / 6 * size.width;
      final y = i / 6 * size.height;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 1:1 reference line
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      Paint()
        ..color = AppStyles.trackInactive
        ..strokeWidth = 1,
    );

    // Threshold line
    final threshNorm = (threshold + dbRange) / dbRange;
    final threshX = threshNorm * size.width;
    canvas.drawLine(
      Offset(threshX, 0),
      Offset(threshX, size.height),
      Paint()
        ..color = AppStyles.accentRed.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..strokeStyle = StrokeStyle.dashed,
    );

    // Compression curve
    final curvePaint = Paint()
      ..color = bypass ? AppStyles.chromeMuted : AppStyles.accentRed
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i <= 200; i++) {
      final inputDb = -dbRange + i / 200 * dbRange;
      double outputDb;
      if (bypass || inputDb <= threshold) {
        outputDb = inputDb;
      } else {
        outputDb = threshold + (inputDb - threshold) / ratio;
      }
      final x = (inputDb + dbRange) / dbRange * size.width;
      final y = size.height - (outputDb + dbRange) / dbRange * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, curvePaint);

    // Labels
    final tp = TextPainter(
      text: TextSpan(
        text: bypass ? 'BYPASS' : 'THRESHOLD ${threshold.toStringAsFixed(0)}dB',
        style: AppStyles.painterLabel(AppStyles.textSecondary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(4, 4));
  }

  @override
  bool shouldRepaint(_CompressorCurvePainter old) =>
      old.threshold != threshold || old.ratio != ratio || old.bypass != bypass;
}

// Dashed stroke helper
extension on Paint {
  set strokeStyle(StrokeStyle _) {}
}

enum StrokeStyle { dashed }
