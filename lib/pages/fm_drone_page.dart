import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
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
    return SynthPageShell(isRecording: isRecording, 
      child: Scaffold(
        backgroundColor: AppStyles.background,
        appBar: SynthAppBar(title: 'FM DRONE'),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('SIGNAL GRAPH'),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _VerticalFader(
                      label: 'CARRIER',
                      unit: 'MIDI',
                      value: carrierPitch,
                      min: 20,
                      max: 32,
                      color: AppStyles.accentMint,
                      onChanged: (v) {
                        setState(() => carrierPitch = v);
                        onResult(synth.setCarrierPitch(v));
                      },
                    ),
                    _VerticalFader(
                      label: 'MOD IDX',
                      unit: '',
                      value: modIndex,
                      min: 0,
                      max: 1,
                      color: AppStyles.accentMint,
                      onChanged: (v) {
                        setState(() => modIndex = v);
                        onResult(synth.setModIndex(v));
                      },
                    ),
                    _VerticalFader(
                      label: 'LFO AMT',
                      unit: '',
                      value: lfoAmount,
                      min: 0,
                      max: 1,
                      color: AppStyles.accentOrange,
                      onChanged: (v) {
                        setState(() => lfoAmount = v);
                        onResult(synth.setLfoAmount(v));
                      },
                    ),
                    _VerticalFader(
                      label: 'VOLUME',
                      unit: 'dB',
                      value: volume,
                      min: -60,
                      max: 0,
                      color: AppStyles.accentOrange,
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
              SynthAudioControls.fromMixin(this),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalFader extends StatelessWidget {
  const _VerticalFader({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          unit.isEmpty
              ? value.toStringAsFixed(2)
              : '${value.toStringAsFixed(unit == 'dB' ? 0 : 1)}$unit',
          style: AppStyles.monoValue(color),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: AppStyles.trackInactive,
                thumbColor: AppStyles.textPrimary,
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
        Text(label, style: AppStyles.faderLabel),
      ],
    );
  }
}
