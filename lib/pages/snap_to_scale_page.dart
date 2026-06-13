import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import '../../synths/snap_to_scale_synth.dart';
import '../../synths/result/tonic_result.dart';

class SnapToScalePage extends StatefulWidget {
  const SnapToScalePage({super.key});

  @override
  State<SnapToScalePage> createState() => _SnapToScalePageState();
}

class _SnapToScalePageState extends State<SnapToScalePage> {
  late final SnapToScaleSynth synth;

  double speed = 0.85;
  double stepperStart = 0.5;
  double stepperSpread = 0.5;
  bool isPlaying = false;

  // Scale degrees that light up: 0,2,3,7,10
  static const _scaleDegrees = [0, 2, 3, 7, 10];
  int _activeDegree = 0;
  Timer? _noteTimer;

  @override
  void initState() {
    super.initState();
    synth = SnapToScaleSynth();
  }

  @override
  void dispose() {
    _noteTimer?.cancel();
    synth.destroy();
    super.dispose();
  }

  void onResult(TonicResult r) {}

  Future<void> toggleAudio() async {
    if (isPlaying) {
      _noteTimer?.cancel();
      await synth.stopAudio();
    } else {
      await synth.startAudio();
      final bpm = 600 * speed;
      final interval = Duration(milliseconds: (60000 / bpm).toInt());
      _noteTimer = Timer.periodic(interval, (_) {
        setState(() {
          _activeDegree =
              _scaleDegrees[math.Random().nextInt(_scaleDegrees.length)];
        });
      });
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: synthAppBar('SNAP SCALE'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel('SCALE · Cm PENTATONIC'),
            const SizedBox(height: 16),
            // Scale grid
            Expanded(
              child: _ScaleGrid(
                activeDegree: _activeDegree,
                isPlaying: isPlaying,
                spread: stepperSpread,
              ),
            ),
            const SizedBox(height: 24),
            sectionLabel('CONTROLS'),
            const SizedBox(height: 16),
            _slider(
              'SPEED',
              speed.toStringAsFixed(2),
              speed,
              0,
              2,
              const Color(0xFF9B59B6),
              (v) {
                setState(() => speed = v);
                onResult(synth.setSpeed(v));
              },
            ),
            const SizedBox(height: 12),
            _slider(
              'START',
              stepperStart.toStringAsFixed(2),
              stepperStart,
              0,
              1,
              const Color(0xFF9B59B6),
              (v) {
                setState(() => stepperStart = v);
                onResult(synth.setStepperStart(v));
              },
            ),
            const SizedBox(height: 12),
            _slider(
              'SPREAD',
              stepperSpread.toStringAsFixed(2),
              stepperSpread,
              0,
              1,
              const Color(0xFF9B59B6),
              (v) {
                setState(() => stepperSpread = v);
                onResult(synth.setStepperSpread(v));
              },
            ),
            const SizedBox(height: 24),
            playButton(
              isPlaying: isPlaying,
              onTap: toggleAudio,
              accent: const Color(0xFF9B59B6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    String display,
    double value,
    double min,
    double max,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 64,
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
          width: 48,
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
}

class _ScaleGrid extends StatelessWidget {
  final int activeDegree;
  final bool isPlaying;
  final double spread;

  const _ScaleGrid({
    required this.activeDegree,
    required this.isPlaying,
    required this.spread,
  });

  static const _allDegrees = 12;
  static const _scaleDegrees = {0, 2, 3, 7, 10};
  static const _noteNames = [
    'C',
    'C#',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];
  static const _octaves = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        children: List.generate(_octaves, (oct) {
          return Expanded(
            child: Row(
              children: List.generate(_allDegrees, (degree) {
                final inScale = _scaleDegrees.contains(degree);
                final isActive = isPlaying && degree == activeDegree;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF9B59B6)
                          : inScale
                          ? const Color(0xFF9B59B6).withValues(alpha: 0.08)
                          : const Color(0xFF0D0D0D),
                      border: Border.all(
                        color: inScale
                            ? const Color(
                                0xFF9B59B6,
                              ).withValues(alpha: isActive ? 1 : 0.3)
                            : const Color(0xFF1A1A1A),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        inScale ? _noteNames[degree] : '',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 8,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF9B59B6).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
