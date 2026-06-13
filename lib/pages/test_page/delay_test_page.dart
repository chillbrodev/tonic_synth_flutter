import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../synths/delay_test_synth.dart';
import '../../synths/result/tonic_result.dart';

class DelayTestPage extends StatefulWidget {
  const DelayTestPage({super.key});

  @override
  State<DelayTestPage> createState() => _DelayTestPageState();
}

class _DelayTestPageState extends State<DelayTestPage> {
  late final DelayTestSynth synth;

  double tempo = 120;
  double delayTime = 0.12;
  double feedback = 0.4;
  double delayMix = 0.3;
  double decayTime = 0.08;
  double volume = -6;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    synth = DelayTestSynth();
  }

  @override
  void dispose() {
    synth.destroy();
    super.dispose();
  }

  void onResult(TonicResult result) {
    if (result case TonicParameterError(:final parameter)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unknown parameter: $parameter')));
    }
  }

  void adjustTempo(int delta) {
    setState(() => tempo = (tempo + delta).clamp(60, 300));
    onResult(synth.setTempo(tempo));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TEMPO'),
          const SizedBox(height: 16),
          _bpmCounter(),
          const SizedBox(height: 36),
          _sectionLabel('DELAY'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _arcDial(
                label: 'TIME',
                value: delayTime,
                min: 0.001,
                max: 1.0,
                display: '${(delayTime * 1000).toStringAsFixed(0)}ms',
                color: const Color(0xFF00FF9C),
                onChanged: (v) {
                  setState(() => delayTime = v);
                  onResult(synth.setDelayTime(v));
                },
              ),
              _arcDial(
                label: 'FEEDBACK',
                value: feedback,
                min: 0,
                max: 0.95,
                display: feedback.toStringAsFixed(2),
                color: const Color(0xFF00FF9C),
                onChanged: (v) {
                  setState(() => feedback = v);
                  onResult(synth.setFeedback(v));
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _sectionLabel('ENVELOPE & MIX'),
          const SizedBox(height: 20),
          _horizontalSlider(
            label: 'DRY / WET',
            value: delayMix,
            min: 0,
            max: 1,
            display: delayMix.toStringAsFixed(2),
            onChanged: (v) {
              setState(() => delayMix = v);
              onResult(synth.setDelayMix(v));
            },
          ),
          const SizedBox(height: 16),
          _horizontalSlider(
            label: 'DECAY',
            value: decayTime,
            min: 0.05,
            max: 0.25,
            display: '${(decayTime * 1000).toStringAsFixed(0)}ms',
            onChanged: (v) {
              setState(() => decayTime = v);
              onResult(synth.setDecayTime(v));
            },
          ),
          const SizedBox(height: 16),
          _horizontalSlider(
            label: 'VOLUME',
            value: volume,
            min: -60,
            max: 0,
            display: '${volume.toStringAsFixed(0)}dB',
            color: const Color(0xFFFF9500),
            onChanged: (v) {
              setState(() => volume = v);
              onResult(synth.setVolume(v));
            },
          ),
          const SizedBox(height: 32),
          _playButton(),
        ],
      ),
    );
  }

  Widget _bpmCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _tempoButton(Icons.remove, -1),
        const SizedBox(width: 8),
        _tempoButton(Icons.remove, -10, large: false),
        const SizedBox(width: 12),
        Text(
          tempo.toStringAsFixed(0),
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 72,
            color: Color(0xFF00FF9C),
            fontWeight: FontWeight.w300,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'BPM',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 11,
            color: Color(0xFF555555),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        _tempoButton(Icons.add, 10, large: false),
        const SizedBox(width: 8),
        _tempoButton(Icons.add, 1),
      ],
    );
  }

  Widget _tempoButton(IconData icon, int delta, {bool large = true}) {
    return GestureDetector(
      onTap: () => adjustTempo(delta),
      child: Container(
        width: large ? 44 : 32,
        height: large ? 44 : 32,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2A2A2A)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF00FF9C),
          size: large ? 18 : 14,
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
    required ValueChanged<double> onChanged,
    Color color = const Color(0xFF00FF9C),
  }) {
    return Column(
      children: [
        GestureDetector(
          onPanUpdate: (d) {
            final range = max - min;
            final delta = -d.delta.dy / 150 * range;
            final newVal = (value + delta).clamp(min, max);
            onChanged(newVal);
          },
          child: SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _ArcDialPainter(
                value: (value - min) / (max - min),
                color: color,
                displayText: display,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _horizontalSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
    Color color = const Color(0xFF00FF9C),
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 9,
              color: Color(0xFF555555),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF2A2A2A),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 1.5,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 11,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _playButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isPlaying
                ? const Color(0xFFFF9500)
                : const Color(0xFF00FF9C),
            width: 1,
          ),
          foregroundColor: isPlaying
              ? const Color(0xFFFF9500)
              : const Color(0xFF00FF9C),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        onPressed: toggleAudio,
        child: Text(
          isPlaying ? 'STOP' : 'PLAY',
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 9,
      color: Color(0xFF555555),
      letterSpacing: 3,
    ),
  );
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
    final radius = size.width / 2 - 10;

    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * value,
      false,
      activePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ArcDialPainter old) =>
      old.value != value || old.displayText != displayText;
}
