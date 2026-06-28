import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/orientation_config.dart';
import 'package:tonic_synth_flutter/pages/settings_page.dart';
import 'fm_drone_page.dart';
import 'xy_speed_page.dart';
import 'delay_test_page.dart';
import 'arbitrary_table_page.dart';
import 'bandlimited_osc_page.dart';
import 'compressor_test_page.dart';
import 'compressor_ducking_page.dart';
import 'filtered_noise_page.dart';
import 'lf_noise_page.dart';
import 'reverb_test_page.dart';
import 'step_seq_page.dart';
import 'sine_sum_page.dart';
import 'stereo_delay_page.dart';
import 'snap_to_scale_page.dart';

class _SynthCard {
  const _SynthCard({
    required this.name,
    required this.description,
    required this.accent,
    required this.builder,
  });
  final String name;
  final String description;
  final Color accent;
  final Widget Function() builder;
}

class LauncherPage extends StatelessWidget {
  const LauncherPage({super.key});

  static final _synths = [
    _SynthCard(
      name: 'FM DRONE',
      description: 'Carrier · Modulation · LFO',
      accent: AppStyles.accentMint,
      builder: () => const FmDronePage(),
    ),
    _SynthCard(
      name: 'XY SPEED',
      description: 'Gesture-controlled filter',
      accent: AppStyles.accentMint,
      builder: () => const XySpeedPage(),
    ),
    _SynthCard(
      name: 'DELAY SEQ',
      description: 'Step sequencer · Delay',
      accent: AppStyles.accentMint,
      builder: () => const DelayTestPage(),
    ),
    _SynthCard(
      name: 'WAVETABLE',
      description: 'Arbitrary lookup oscillator',
      accent: AppStyles.accentOrange,
      builder: () => const ArbitraryTablePage(),
    ),
    _SynthCard(
      name: 'BANDLIMITED',
      description: 'Aliased vs bandlimited',
      accent: AppStyles.accentOrange,
      builder: () => const BandlimitedOscPage(),
    ),
    _SynthCard(
      name: 'COMPRESSOR',
      description: '808 snare · Knee curve',
      accent: AppStyles.accentRed,
      builder: () => const CompressorTestPage(),
    ),
    _SynthCard(
      name: 'DUCK',
      description: 'Sidechain compression',
      accent: AppStyles.accentRed,
      builder: () => const CompressorDuckingPage(),
    ),
    _SynthCard(
      name: 'NOISE FILTER',
      description: 'Pink noise · BPF bank',
      accent: AppStyles.accentPurple,
      builder: () => const FilteredNoisePage(),
    ),
    _SynthCard(
      name: 'LF NOISE',
      description: 'Noise-modulated sine',
      accent: AppStyles.accentPurple,
      builder: () => const LfNoisePage(),
    ),
    _SynthCard(
      name: 'REVERB',
      description: 'Room · Decay · Density',
      accent: AppStyles.accentBlue,
      builder: () => const ReverbTestPage(),
    ),
    _SynthCard(
      name: 'STEP SEQ',
      description: '8-step · Pitch · Filter',
      accent: AppStyles.accentMint,
      builder: () => const StepSeqPage(),
    ),
    _SynthCard(
      name: 'SINE SUM',
      description: '10 detuned sine waves',
      accent: AppStyles.accentOrange,
      builder: () => const SineSumPage(),
    ),
    _SynthCard(
      name: 'STEREO DLY',
      description: 'Panned stereo echo',
      accent: AppStyles.accentBlue,
      builder: () => const StereoDelayPage(),
    ),
    _SynthCard(
      name: 'SNAP SCALE',
      description: 'Melodic step sequencer',
      accent: AppStyles.accentPurple,
      builder: () => const SnapToScalePage(),
    ),
  ];

  static int _crossAxisCount(double width) {
    if (width >= 1000) return 4;
    if (width >= OrientationConfig.tabletBreakpoint) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _crossAxisCount(width);
    final isTablet = crossAxisCount > 2;

    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: AppStyles.background,
        elevation: 0,
        title: const Text('TONIC SYNTHS', style: AppStyles.launcherAppTitle),
        actions: const [SettingsNavAction()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppStyles.surfaceRaised, height: 1),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(isTablet ? 12 : 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isTablet ? 1.15 : 1.1,
        ),
        itemCount: _synths.length,
        itemBuilder: (context, i) =>
            _SynthCardWidget(card: _synths[i], compact: isTablet),
      ),
    );
  }
}

class _SynthCardWidget extends StatelessWidget {
  const _SynthCardWidget({required this.card, this.compact = false});
  final _SynthCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => card.builder()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppStyles.surface,
          border: Border.all(color: AppStyles.surfaceRaised),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: card.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppStyles.iconMuted, size: 14),
              ],
            ),
            const Spacer(),
            Text(card.name, style: AppStyles.launcherCardTitle),
            const SizedBox(height: 4),
            Text(card.description, style: AppStyles.launcherCardDescription),
          ],
        ),
      ),
    );
  }
}
