import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/pages/launcher_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tonic_set_sample_rate(44100);
  await SoLoud.instance.init();
  runApp(const TonicApp());
}

class TonicApp extends StatelessWidget {
  const TonicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tonic Synth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      ),
      home: const LauncherPage(),
    );
  }
}
