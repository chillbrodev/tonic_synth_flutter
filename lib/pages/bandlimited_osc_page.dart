import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/bandlimited_osc_synth.dart';

class BandlimitedOscPage extends StatefulWidget {
  const BandlimitedOscPage({super.key});

  @override
  State<BandlimitedOscPage> createState() => _BandlimitedOscPageState();
}

class _BandlimitedOscPageState extends State<BandlimitedOscPage> with SynthPageAudioMixin {
  late final BandlimitedOscSynth synth;
  double blend = 0.5;

  @override
  void initState() {
    super.initState();
    synth = BandlimitedOscSynth();
    initSynthPageAudio();
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
      backgroundColor: AppStyles.background,
      appBar: SynthAppBar(title: 'BANDLIMITED'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('OSCILLATOR BLEND'),
            const Spacer(),
            // Waveform comparison labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ModeLabel(text: 'ALIASED', active: blend < 0.5),
                _ModeLabel(text: 'BANDLIMITED', active: blend >= 0.5),
              ],
            ),
            const SizedBox(height: 32),
            // Big crossfade slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppStyles.accentOrange,
                inactiveTrackColor: AppStyles.trackInactive,
                thumbColor: AppStyles.textPrimary,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: blend,
                min: 0,
                max: 1,
                onChanged: (v) {
                  setState(() => blend = v);
                  synth.setBlend(v);
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                blend < 0.1
                    ? 'FULL ALIAS'
                    : blend > 0.9
                    ? 'FULL BANDLIMIT'
                    : '${(blend * 100).toStringAsFixed(0)}% BLEND',
                style: AppStyles.largeAccent,
              ),
            ),
            // Alias indicator — jagged line when aliased, smooth when bandlimited
            const SizedBox(height: 32),
            _AliasIndicator(blend: blend),
            const Spacer(),
            SynthAudioControls.fromMixin(this, accent: AppStyles.accentOrange),
          ],
        ),
      ),
    ));
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppStyles.modeLabel(active: active));
  }
}

class _AliasIndicator extends StatelessWidget {
  const _AliasIndicator({required this.blend});

  final double blend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: _BlendWavePainter(blend: blend),
        size: Size.infinite,
      ),
    );
  }
}

class _BlendWavePainter extends CustomPainter {
  const _BlendWavePainter({required this.blend});
  final double blend;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppStyles.accentOrange
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final path = Path();
    const steps = 200;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;

      // Aliased: sharp square; bandlimited: smooth sine-ish
      final phase = t * 4 * 3.14159;
      final aliased = (phase % (2 * 3.14159)) < 3.14159 ? 1.0 : -1.0;
      final smooth =
          (importSin(phase) +
              importSin(phase * 3) / 3 +
              importSin(phase * 5) / 5) *
          1.2;
      final sample = aliased * (1 - blend) + smooth * blend;
      final y = midY - sample * midY * 0.7;

      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  double importSin(double x) => (x - x * x * x / 6 + x * x * x * x * x / 120);

  @override
  bool shouldRepaint(_BlendWavePainter old) => old.blend != blend;
}
