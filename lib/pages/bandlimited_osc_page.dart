import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/synths/bandlimited_osc_synth.dart';

class BandlimitedOscPage extends StatefulWidget {
  const BandlimitedOscPage({super.key});

  @override
  State<BandlimitedOscPage> createState() => _BandlimitedOscPageState();
}

class _BandlimitedOscPageState extends State<BandlimitedOscPage> {
  late final BandlimitedOscSynth synth;
  double blend = 0.5;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    synth = BandlimitedOscSynth();
  }

  @override
  void dispose() {
    synth.destroy();
    super.dispose();
  }

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
      appBar: synthAppBar('BANDLIMITED'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel('OSCILLATOR BLEND'),
            const Spacer(),
            // Waveform comparison labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _modeLabel('ALIASED', blend < 0.5),
                _modeLabel('BANDLIMITED', blend >= 0.5),
              ],
            ),
            const SizedBox(height: 32),
            // Big crossfade slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF9500),
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: Colors.white,
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
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 20,
                  color: Color(0xFFFF9500),
                  letterSpacing: 2,
                ),
              ),
            ),
            // Alias indicator — jagged line when aliased, smooth when bandlimited
            const SizedBox(height: 32),
            _aliasIndicator(blend),
            const Spacer(),
            playButton(
              isPlaying: isPlaying,
              onTap: toggleAudio,
              accent: const Color(0xFFFF9500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeLabel(String text, bool active) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 10,
        color: active ? const Color(0xFFFF9500) : const Color(0xFF333333),
        letterSpacing: 2,
      ),
    );
  }

  Widget _aliasIndicator(double blend) {
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
  final double blend;
  const _BlendWavePainter({required this.blend});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF9500)
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
          (import_sin(phase) +
              import_sin(phase * 3) / 3 +
              import_sin(phase * 5) / 5) *
          1.2;
      final sample = aliased * (1 - blend) + smooth * blend;
      final y = midY - sample * midY * 0.7;

      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  double import_sin(double x) => (x - x * x * x / 6 + x * x * x * x * x / 120);

  @override
  bool shouldRepaint(_BlendWavePainter old) => old.blend != blend;
}
