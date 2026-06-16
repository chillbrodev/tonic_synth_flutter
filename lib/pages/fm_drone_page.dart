import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/pages/synth_page_audio.dart';
import 'package:tonic_synth_flutter/synths/fm_drone_synth.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';

class FmDronePage extends StatefulWidget {
  const FmDronePage({super.key});

  @override
  State<FmDronePage> createState() => _FmDronePageState();
}

class _FmDronePageState extends State<FmDronePage> with SynthPageAudioMixin {
  late final FmDroneSynth synth;

  double volume = -12.0;
  double carrierPitch = 28.0;
  double modIndex = 0.25;
  double lfoAmount = 0.5;

  @override
  SynthAudioHost get synthAudio => synth;

  @override
  void initState() {
    super.initState();
    synth = FmDroneSynth();
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

  @override
  Widget build(BuildContext context) {
    return buildSynthPage(
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: synthAppBar('FM DRONE'),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionLabel('SIGNAL GRAPH'),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _verticalFader(
                      label: 'CARRIER',
                      unit: 'MIDI',
                      value: carrierPitch,
                      min: 20,
                      max: 32,
                      color: const Color(0xFF00FF9C),
                      onChanged: (v) {
                        setState(() => carrierPitch = v);
                        onResult(synth.setCarrierPitch(v));
                      },
                    ),
                    _verticalFader(
                      label: 'MOD IDX',
                      unit: '',
                      value: modIndex,
                      min: 0,
                      max: 1,
                      color: const Color(0xFF00FF9C),
                      onChanged: (v) {
                        setState(() => modIndex = v);
                        onResult(synth.setModIndex(v));
                      },
                    ),
                    _verticalFader(
                      label: 'LFO AMT',
                      unit: '',
                      value: lfoAmount,
                      min: 0,
                      max: 1,
                      color: const Color(0xFFFF9500),
                      onChanged: (v) {
                        setState(() => lfoAmount = v);
                        onResult(synth.setLfoAmount(v));
                      },
                    ),
                    _verticalFader(
                      label: 'VOLUME',
                      unit: 'dB',
                      value: volume,
                      min: -60,
                      max: 0,
                      color: const Color(0xFFFF9500),
                      onChanged: (v) {
                        setState(() => volume = v);
                        onResult(synth.setVolume(v));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 12),
              buildSynthAudioControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verticalFader({
    required String label,
    required String unit,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(
          unit.isEmpty
              ? value.toStringAsFixed(2)
              : '${value.toStringAsFixed(unit == 'dB' ? 0 : 1)}$unit',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 11,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
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
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9,
            color: Color(0xFF555555),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
