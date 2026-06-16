import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/delay_test_synth.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class DelayTestPage extends StatefulWidget {
  const DelayTestPage({super.key});

  @override
  State<DelayTestPage> createState() => _DelayTestPageState();
}

class _DelayTestPageState extends State<DelayTestPage> with SynthPageAudioMixin {
  late final DelayTestSynth synth;

  double tempo = 120;
  double delayTime = 0.12;
  double feedback = 0.4;
  double delayMix = 0.3;
  double decayTime = 0.08;
  double volume = -6;

  @override
  void initState() {
    super.initState();
    synth = DelayTestSynth();
    initSynthPageAudio();
  }

  @override
  void dispose() {
    disposeSynthPageAudio();
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

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  Widget build(BuildContext context) {
    return SynthPageShell(isRecording: isRecording, child: Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: SynthAppBar(title: 'DELAY SEQ'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('TEMPO'),
            const SizedBox(height: 16),
            _BpmCounter(tempo: tempo, onAdjustTempo: adjustTempo),
            const SizedBox(height: 36),
            const SectionLabel('DELAY'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ArcDial(
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
                ArcDial(
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
            const SectionLabel('ENVELOPE & MIX'),
            const SizedBox(height: 20),
            LabeledSlider(
              label: 'DRY / WET',
              display: delayMix.toStringAsFixed(2),
              value: delayMix,
              min: 0,
              max: 1,
              displayWidth: 52,
              color: const Color(0xFF00FF9C),
              onChanged: (v) {
                setState(() => delayMix = v);
                onResult(synth.setDelayMix(v));
              },
            ),
            const SizedBox(height: 16),
            LabeledSlider(
              label: 'DECAY',
              display: '${(decayTime * 1000).toStringAsFixed(0)}ms',
              value: decayTime,
              min: 0.05,
              max: 0.25,
              displayWidth: 52,
              color: const Color(0xFF00FF9C),
              onChanged: (v) {
                setState(() => decayTime = v);
                onResult(synth.setDecayTime(v));
              },
            ),
            const SizedBox(height: 16),
            LabeledSlider(
              label: 'VOLUME',
              display: '${volume.toStringAsFixed(0)}dB',
              value: volume,
              min: -60,
              max: 0,
              displayWidth: 52,
              color: const Color(0xFFFF9500),
              onChanged: (v) {
                setState(() => volume = v);
                onResult(synth.setVolume(v));
              },
            ),
            const SizedBox(height: 32),
            SynthAudioControls.fromMixin(this),
          ],
        ),
      ),
    ));
  }
}

class _BpmCounter extends StatelessWidget {
  const _BpmCounter({required this.tempo, required this.onAdjustTempo});

  final double tempo;
  final ValueChanged<int> onAdjustTempo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TempoButton(icon: Icons.remove, delta: -1, onAdjustTempo: onAdjustTempo),
        const SizedBox(width: 8),
        _TempoButton(
          icon: Icons.remove,
          delta: -10,
          large: false,
          onAdjustTempo: onAdjustTempo,
        ),
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
        _TempoButton(
          icon: Icons.add,
          delta: 10,
          large: false,
          onAdjustTempo: onAdjustTempo,
        ),
        const SizedBox(width: 8),
        _TempoButton(icon: Icons.add, delta: 1, onAdjustTempo: onAdjustTempo),
      ],
    );
  }
}

class _TempoButton extends StatelessWidget {
  const _TempoButton({
    required this.icon,
    required this.delta,
    required this.onAdjustTempo,
    this.large = true,
  });

  final IconData icon;
  final int delta;
  final ValueChanged<int> onAdjustTempo;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onAdjustTempo(delta),
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
}
