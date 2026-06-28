import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/filtered_noise_synth.dart';

class FilteredNoisePage extends StatefulWidget {
  const FilteredNoisePage({super.key});

  @override
  State<FilteredNoisePage> createState() => _FilteredNoisePageState();
}

class _FilteredNoisePageState extends State<FilteredNoisePage>
    with SynthPageAudioMixin {
  late final FilteredNoiseSynth synth;
  double cutoff = 0.5;
  double q = 5.0;

  @override
  void initState() {
    super.initState();
    synth = FilteredNoiseSynth();
    initSynthPageAudio();
  }

  @override
  void dispose() {
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  void onPanUpdate(DragUpdateDetails d, BoxConstraints c) {
    final x = (d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0);
    final y = 1.0 - (d.localPosition.dy / c.maxHeight).clamp(0.0, 1.0);
    setState(() {
      cutoff = x;
      q = y * 10;
    });
    synth.setCutoff(x);
    synth.setQ(y * 10);
  }

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(
      isRecording: isRecording,
      child: Scaffold(
        backgroundColor: AppStyles.background,
        appBar: SynthAppBar(title: 'NOISE FILTER'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('DRAG · X = CUTOFF · Y = RESONANCE'),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanUpdate: (d) => onPanUpdate(d, constraints),
                      onPanStart: (d) => onPanUpdate(
                        DragUpdateDetails(
                          globalPosition: d.globalPosition,
                          localPosition: d.localPosition,
                          delta: Offset.zero,
                        ),
                        constraints,
                      ),
                      child: CustomPaint(
                        painter: _NoiseFilterPainter(
                          cutoff: cutoff,
                          q: q / 10,
                          isPlaying: isPlaying,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CoordRow(label: 'CUTOFF', value: cutoff.toStringAsFixed(2)),
                  _CoordRow(label: 'Q', value: q.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 16),
              SynthAudioControls.fromMixin(
                this,
                accent: AppStyles.accentPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label  ', style: AppStyles.coordRowLabel),
        Text(
          value,
          style: AppStyles.monoValue(AppStyles.accentPurple, fontSize: 12),
        ),
      ],
    );
  }
}

class _NoiseFilterPainter extends CustomPainter {
  const _NoiseFilterPainter({
    required this.cutoff,
    required this.q,
    required this.isPlaying,
  });
  final double cutoff;
  final double q; // 0..1
  final bool isPlaying;

  static const _bandColors = AppStyles.purpleBands;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw frequency band columns
    for (int i = 0; i < 5; i++) {
      final bandCutoff = [0.0, 0.2, 0.4, 0.6, 0.8][i];
      final dist = (cutoff - bandCutoff).abs();
      final bandwidth = 0.4 * (1 - q * 0.8) + 0.05;
      final intensity = (1 - dist / bandwidth).clamp(0.0, 1.0);

      final x = bandCutoff * size.width;
      final w = size.width * 0.18;
      final h = intensity * size.height;

      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h, w, h),
        Paint()
          ..color = _bandColors[i].withValues(
            alpha: isPlaying ? 0.15 + intensity * 0.5 : 0.08,
          ),
      );
    }

    // Cursor
    final cx = cutoff * size.width;
    final cy = (1 - q) * size.height;

    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, size.height),
      Paint()
        ..color = AppStyles.accentPurple.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()
        ..color = AppStyles.accentPurple.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      8,
      Paint()..color = AppStyles.accentPurple,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      16,
      Paint()
        ..color = AppStyles.accentPurple.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NoiseFilterPainter old) =>
      old.cutoff != cutoff || old.q != q || old.isPlaying != isPlaying;
}
