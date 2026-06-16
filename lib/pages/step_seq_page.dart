import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/step_seq_synth.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class StepSeqPage extends StatefulWidget {
  const StepSeqPage({super.key});

  @override
  State<StepSeqPage> createState() => _StepSeqPageState();
}

class _StepSeqPageState extends State<StepSeqPage> with SynthPageAudioMixin {
  late final StepSeqSynth synth;

  double tempo = 100;
  double transpose = 0;
  int selectedStep = 0;

  final List<double> pitches = [48, 52, 55, 48, 60, 55, 52, 43];
  final List<double> cutoffs = [500, 800, 300, 1200, 400, 900, 600, 200];

  @override
  void initState() {
    super.initState();
    synth = StepSeqSynth();
    initSynthPageAudio();
  }

  @override
  void dispose() {
    disposeSynthPageAudio();
    synth.destroy();
    super.dispose();
  }

  void onResult(TonicResult r) {}

  Color _cutoffColor(double hz) {
    final t = (hz - 30) / (1500 - 30);
    return Color.lerp(AppStyles.accentBlue, AppStyles.accentMint, t)!;
  }

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(isRecording: isRecording, child: Scaffold(
      backgroundColor: AppStyles.background,
      appBar: SynthAppBar(title: 'STEP SEQ'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tempo row
            Row(
              children: [
                const SectionLabel('TEMPO'),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppStyles.accentMint,
                      inactiveTrackColor: AppStyles.trackInactive,
                      thumbColor: AppStyles.textPrimary,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 1.5,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: tempo,
                      min: 50,
                      max: 300,
                      onChanged: (v) {
                        setState(() => tempo = v);
                        onResult(synth.setTempo(v));
                      },
                    ),
                  ),
                ),
                Text(
                  '${tempo.toStringAsFixed(0)} BPM',
                  style: AppStyles.monoValue(AppStyles.accentMint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Transpose row
            Row(
              children: [
                const SectionLabel('XPOSE'),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppStyles.accentOrange,
                      inactiveTrackColor: AppStyles.trackInactive,
                      thumbColor: AppStyles.textPrimary,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 1.5,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: transpose,
                      min: -6,
                      max: 6,
                      divisions: 12,
                      onChanged: (v) {
                        setState(() => transpose = v);
                        onResult(synth.setTranspose(v));
                      },
                    ),
                  ),
                ),
                Text(
                  '${transpose >= 0 ? '+' : ''}${transpose.toStringAsFixed(0)}',
                  style: AppStyles.monoValue(AppStyles.accentOrange),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('STEPS  ·  TAP TO SELECT  ·  DRAG TO EDIT'),
            const SizedBox(height: 12),
            // Step grid
            Expanded(
              flex: 3,
              child: Row(
                children: List.generate(StepSeqSynth.stepCount, (i) {
                  final pitchNorm = (pitches[i] - 10) / 70;
                  final cutoffColor = _cutoffColor(cutoffs[i]);
                  final isSelected = i == selectedStep;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedStep = i),
                      onVerticalDragUpdate: (d) {
                        if (selectedStep != i) setState(() => selectedStep = i);
                        setState(() {
                          pitches[i] = (pitches[i] - d.delta.dy * 0.5).clamp(
                            10,
                            80,
                          );
                        });
                        synth.setStepPitch(i, pitches[i]);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            // Step number
                            Text(
                              '${i + 1}',
                              style: AppStyles.stepNumber(selected: isSelected),
                            ),
                            const SizedBox(height: 4),
                            // Step cell
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cutoffColor.withValues(
                                    alpha: isSelected ? 0.15 : 0.06,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppStyles.accentMint
                                        : cutoffColor.withValues(alpha: 0.3),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // Pitch fill
                                    FractionallySizedBox(
                                      heightFactor: pitchNorm,
                                      child: Container(
                                        color: cutoffColor.withValues(
                                          alpha: isSelected ? 0.5 : 0.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Pitch value
                            Text(
                              pitches[i].toStringAsFixed(0),
                              style: AppStyles.stepPitch(selected: isSelected),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Selected step editor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppStyles.surface,
                border: Border.all(color: AppStyles.surfaceRaised),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP ${selectedStep + 1}',
                    style: AppStyles.stepEditorTitle,
                  ),
                  const SizedBox(height: 12),
                  LabeledSlider(
                    label: 'PITCH',
                    display: '${pitches[selectedStep].toStringAsFixed(0)} MIDI',
                    value: pitches[selectedStep],
                    min: 10,
                    max: 80,
                    color: AppStyles.accentMint,
                    labelWidth: 56,
                    displayWidth: 64,
                    displayFontSize: 10,
                    labelLetterSpacing: 1,
                    onChanged: (v) {
                      setState(() => pitches[selectedStep] = v);
                      synth.setStepPitch(selectedStep, v);
                    },
                  ),
                  const SizedBox(height: 8),
                  LabeledSlider(
                    label: 'CUTOFF',
                    display: '${cutoffs[selectedStep].toStringAsFixed(0)}Hz',
                    value: cutoffs[selectedStep],
                    min: 30,
                    max: 1500,
                    color: _cutoffColor(cutoffs[selectedStep]),
                    labelWidth: 56,
                    displayWidth: 64,
                    displayFontSize: 10,
                    labelLetterSpacing: 1,
                    onChanged: (v) {
                      setState(() => cutoffs[selectedStep] = v);
                      synth.setStepCutoff(selectedStep, v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SynthAudioControls.fromMixin(this, accent: AppStyles.accentMint),
          ],
        ),
      ),
    ));
  }
}
