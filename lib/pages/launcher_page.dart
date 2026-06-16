import 'package:flutter/material.dart';
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
      accent: const Color(0xFF00FF9C),
      builder: () => const FmDronePage(),
    ),
    _SynthCard(
      name: 'XY SPEED',
      description: 'Gesture-controlled filter',
      accent: const Color(0xFF00FF9C),
      builder: () => const XySpeedPage(),
    ),
    _SynthCard(
      name: 'DELAY SEQ',
      description: 'Step sequencer · Delay',
      accent: const Color(0xFF00FF9C),
      builder: () => const DelayTestPage(),
    ),
    _SynthCard(
      name: 'WAVETABLE',
      description: 'Arbitrary lookup oscillator',
      accent: const Color(0xFFFF9500),
      builder: () => const ArbitraryTablePage(),
    ),
    _SynthCard(
      name: 'BANDLIMITED',
      description: 'Aliased vs bandlimited',
      accent: const Color(0xFFFF9500),
      builder: () => const BandlimitedOscPage(),
    ),
    _SynthCard(
      name: 'COMPRESSOR',
      description: '808 snare · Knee curve',
      accent: const Color(0xFFFF4444),
      builder: () => const CompressorTestPage(),
    ),
    _SynthCard(
      name: 'DUCK',
      description: 'Sidechain compression',
      accent: const Color(0xFFFF4444),
      builder: () => const CompressorDuckingPage(),
    ),
    _SynthCard(
      name: 'NOISE FILTER',
      description: 'Pink noise · BPF bank',
      accent: const Color(0xFF9B59B6),
      builder: () => const FilteredNoisePage(),
    ),
    _SynthCard(
      name: 'LF NOISE',
      description: 'Noise-modulated sine',
      accent: const Color(0xFF9B59B6),
      builder: () => const LfNoisePage(),
    ),
    _SynthCard(
      name: 'REVERB',
      description: 'Room · Decay · Density',
      accent: const Color(0xFF3498DB),
      builder: () => const ReverbTestPage(),
    ),
    _SynthCard(
      name: 'STEP SEQ',
      description: '8-step · Pitch · Filter',
      accent: const Color(0xFF00FF9C),
      builder: () => const StepSeqPage(),
    ),
    _SynthCard(
      name: 'SINE SUM',
      description: '10 detuned sine waves',
      accent: const Color(0xFFFF9500),
      builder: () => const SineSumPage(),
    ),
    _SynthCard(
      name: 'STEREO DLY',
      description: 'Panned stereo echo',
      accent: const Color(0xFF3498DB),
      builder: () => const StereoDelayPage(),
    ),
    _SynthCard(
      name: 'SNAP SCALE',
      description: 'Melodic step sequencer',
      accent: const Color(0xFF9B59B6),
      builder: () => const SnapToScalePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text(
          'TONIC',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            color: Color(0xFF00FF9C),
            fontSize: 14,
            letterSpacing: 6,
            fontWeight: FontWeight.w500,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1A1A1A), height: 1),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _synths.length,
        itemBuilder: (context, i) => _SynthCardWidget(card: _synths[i]),
      ),
    );
  }
}

class _SynthCardWidget extends StatelessWidget {
  const _SynthCardWidget({required this.card});
  final _SynthCard card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => card.builder()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(16),
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
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF333333),
                  size: 14,
                ),
              ],
            ),
            const Spacer(),
            Text(
              card.name,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.description,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 9,
                color: Color(0xFF555555),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
