import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/snap_to_scale_synth.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class SnapToScalePage extends StatefulWidget {
  const SnapToScalePage({super.key});

  @override
  State<SnapToScalePage> createState() => _SnapToScalePageState();
}

class _SnapToScalePageState extends State<SnapToScalePage> with SynthPageAudioMixin {
  late final SnapToScaleSynth synth;

  double speed = 0.85;
  double stepperStart = 0.5;
  double stepperSpread = 0.5;

  // Scale degrees that light up: 0,2,3,7,10
  static const _scaleDegrees = [0, 2, 3, 7, 10];
  int _activeDegree = 0;
  Timer? _noteTimer;

  @override
  void initState() {
    super.initState();
    synth = SnapToScaleSynth();
    initSynthPageAudio();
  }

  @override
  void dispose() {
    _noteTimer?.cancel();
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  void onResult(TonicResult r) {}

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Future<void> onSynthAudioStarting() async {
    final bpm = 600 * speed;
    final interval = Duration(milliseconds: (60000 / bpm).toInt());
    _noteTimer = Timer.periodic(interval, (_) {
      setState(() {
        _activeDegree =
            _scaleDegrees[math.Random().nextInt(_scaleDegrees.length)];
      });
    });
  }

  @override
  Future<void> onSynthAudioStopping() async {
    _noteTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(isRecording: isRecording, child: Scaffold(
      backgroundColor: AppStyles.background,
      appBar: SynthAppBar(title: 'SNAP SCALE'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('SCALE · Cm PENTATONIC'),
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
            const SectionLabel('CONTROLS'),
            const SizedBox(height: 16),
            LabeledSlider(
              label: 'SPEED',
              display: speed.toStringAsFixed(2),
              value: speed,
              min: 0,
              max: 2,
              color: AppStyles.accentPurple,
              labelWidth: 64,
              displayWidth: 48,
              onChanged: (v) {
                setState(() => speed = v);
                onResult(synth.setSpeed(v));
              },
            ),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'START',
              display: stepperStart.toStringAsFixed(2),
              value: stepperStart,
              min: 0,
              max: 1,
              color: AppStyles.accentPurple,
              labelWidth: 64,
              displayWidth: 48,
              onChanged: (v) {
                setState(() => stepperStart = v);
                onResult(synth.setStepperStart(v));
              },
            ),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'SPREAD',
              display: stepperSpread.toStringAsFixed(2),
              value: stepperSpread,
              min: 0,
              max: 1,
              color: AppStyles.accentPurple,
              labelWidth: 64,
              displayWidth: 48,
              onChanged: (v) {
                setState(() => stepperSpread = v);
                onResult(synth.setStepperSpread(v));
              },
            ),
            const SizedBox(height: 24),
            SynthAudioControls.fromMixin(this, accent: AppStyles.accentPurple),
          ],
        ),
      ),
    ));
  }
}

class _ScaleGrid extends StatelessWidget {

  const _ScaleGrid({
    required this.activeDegree,
    required this.isPlaying,
    required this.spread,
  });
  final int activeDegree;
  final bool isPlaying;
  final double spread;

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
        color: AppStyles.backgroundDeep,
        border: Border.all(color: AppStyles.surfaceRaised),
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
                          ? AppStyles.accentPurple
                          : inScale
                          ? AppStyles.accentPurple.withValues(alpha: 0.08)
                          : AppStyles.background,
                      border: Border.all(
                        color: inScale
                            ? AppStyles.accentPurple.withValues(
                                alpha: isActive ? 1 : 0.3,
                              )
                            : AppStyles.surfaceRaised,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        inScale ? _noteNames[degree] : '',
                        style: AppStyles.scaleNote(isActive: isActive),
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
