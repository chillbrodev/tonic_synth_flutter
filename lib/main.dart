import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/orientation_config.dart';
import 'package:tonic_synth_flutter/pages/launcher_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
  ));
  tonic_set_sample_rate(44100);
  await SoLoud.instance.init();
  await OrientationConfig.apply();
  runApp(const TonicApp());
}

class TonicApp extends StatefulWidget {
  const TonicApp({super.key});

  @override
  State<TonicApp> createState() => _TonicAppState();
}

class _TonicAppState extends State<TonicApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OrientationConfig.apply();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tonic Synth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppStyles.background,
      ),
      home: const LauncherPage(),
    );
  }
}
