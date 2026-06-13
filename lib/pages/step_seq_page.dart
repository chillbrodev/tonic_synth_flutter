import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import '../../synths/step_seq_synth.dart';
import '../../synths/result/tonic_result.dart';

class StepSeqPage extends StatefulWidget {
  const StepSeqPage({super.key});

  @override
  State<StepSeqPage> createState() => _StepSeqPageState();
}

class _StepSeqPageState extends State<StepSeqPage> {
  late final StepSeqSynth synth;

  double tempo = 100;
  double transpose = 0;
  int selectedStep = 0;
  bool isPlaying = false;

  final List<double> pitches = [48, 52, 55, 48, 60, 55, 52, 43];
  final List<double> cutoffs = [500, 800, 300, 1200, 400, 900, 600, 200];

  @override
  void initState() {
    super.initState();
    synth = StepSeqSynth();
  }

  @override
  void dispose() {
    synth.destroy();
    super.dispose();
  }

  void onResult(TonicResult r) {}

  Future<void> toggleAudio() async {
    if (isPlaying) {
      await synth.stopAudio();
    } else {
      await synth.startAudio();
    }
    setState(() => isPlaying = !isPlaying);
  }

  Color _cutoffColor(double hz) {
    final t = (hz - 30) / (1500 - 30);
    return Color.lerp(const Color(0xFF3498DB), const Color(0xFF00FF9C), t)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: synthAppBar('STEP SEQ'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tempo row
            Row(
              children: [
                sectionLabel('TEMPO'),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00FF9C),
                      inactiveTrackColor: const Color(0xFF2A2A2A),
                      thumbColor: Colors.white,
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
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 11,
                    color: Color(0xFF00FF9C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Transpose row
            Row(
              children: [
                sectionLabel('XPOSE'),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFF9500),
                      inactiveTrackColor: const Color(0xFF2A2A2A),
                      thumbColor: Colors.white,
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
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 11,
                    color: Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            sectionLabel('STEPS  ·  TAP TO SELECT  ·  DRAG TO EDIT'),
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
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 9,
                                color: isSelected
                                    ? const Color(0xFF00FF9C)
                                    : const Color(0xFF333333),
                              ),
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
                                        ? const Color(0xFF00FF9C)
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
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 8,
                                color: isSelected
                                    ? const Color(0xFF00FF9C)
                                    : const Color(0xFF444444),
                              ),
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
                color: const Color(0xFF111111),
                border: Border.all(color: const Color(0xFF1A1A1A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP ${selectedStep + 1}',
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 9,
                      color: Color(0xFF00FF9C),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _stepSlider(
                    'PITCH',
                    '${pitches[selectedStep].toStringAsFixed(0)} MIDI',
                    pitches[selectedStep],
                    10,
                    80,
                    const Color(0xFF00FF9C),
                    (v) {
                      setState(() => pitches[selectedStep] = v);
                      synth.setStepPitch(selectedStep, v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _stepSlider(
                    'CUTOFF',
                    '${cutoffs[selectedStep].toStringAsFixed(0)}Hz',
                    cutoffs[selectedStep],
                    30,
                    1500,
                    _cutoffColor(cutoffs[selectedStep]),
                    (v) {
                      setState(() => cutoffs[selectedStep] = v);
                      synth.setStepCutoff(selectedStep, v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            playButton(
              isPlaying: isPlaying,
              onTap: toggleAudio,
              accent: const Color(0xFF00FF9C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepSlider(
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
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 9,
              color: Color(0xFF555555),
              letterSpacing: 1,
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
          width: 64,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 10,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
