import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/xy_speed_synth.dart';

class XySpeedPage extends StatefulWidget {
  const XySpeedPage({super.key});

  @override
  State<XySpeedPage> createState() => _XySpeedPageState();
}

class _XySpeedPageState extends State<XySpeedPage> with SynthPageAudioMixin {
  late final XySpeedSynth synth;

  @override
  SynthAudioHost get synthAudio => synth;

  Offset position = const Offset(0.5, 0.5);
  final List<Offset> trail = [];
  static const int maxTrail = 30;

  @override
  void initState() {
    super.initState();
    synth = XySpeedSynth();
    initSynthPageAudio();
  }

  @override
  void dispose() {
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  void onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final x = (details.localPosition.dx / w).clamp(0.0, 1.0);
    final y = (details.localPosition.dy / h).clamp(0.0, 1.0);

    setState(() {
      position = Offset(x, y);
      trail.add(position);
      if (trail.length > maxTrail) trail.removeAt(0);
    });

    synth.setPosition(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return buildSynthPage(child: Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: synthAppBar('XY SPEED'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel('DRAG TO MODULATE'),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        border: Border.all(
                          color: isPlaying
                              ? const Color(0xFF00FF9C).withValues(alpha: 0.4)
                              : const Color(0xFF2A2A2A),
                          width: 1,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _XyPadPainter(
                          position: position,
                          trail: trail,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _coordLabel('X', position.dx),
                _coordLabel('Y', position.dy),
              ],
            ),
            const SizedBox(height: 16),
            buildSynthAudioControls(),
          ],
        ),
      ),
    ));
  }

  Widget _coordLabel(String axis, double value) => Text(
    '$axis  ${value.toStringAsFixed(3)}',
    style: const TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 12,
      color: Color(0xFF00FF9C),
    ),
  );
}

class _XyPadPainter extends CustomPainter {

  const _XyPadPainter({required this.position, required this.trail});
  final Offset position;
  final List<Offset> trail;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1;

    final x = position.dx * size.width;
    final y = position.dy * size.height;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    for (int i = 0; i < trail.length; i++) {
      final opacity = i / trail.length;
      final trailPaint = Paint()
        ..color = Color.fromRGBO(0, 255, 156, opacity * 0.4)
        ..style = PaintingStyle.fill;
      final radius = 3.0 + (i / trail.length) * 4;
      canvas.drawCircle(
        Offset(trail[i].dx * size.width, trail[i].dy * size.height),
        radius,
        trailPaint,
      );
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF00FF9C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 8, dotPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF00FF9C).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(x, y), 16, ringPaint);
  }

  @override
  bool shouldRepaint(_XyPadPainter old) =>
      old.position != position || old.trail != trail;
}
