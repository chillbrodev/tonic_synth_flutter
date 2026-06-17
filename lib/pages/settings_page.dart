import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl =
    'https://www.freeprivacypolicy.com/live/8b468a87-4abf-4f4a-8e9d-7bf321cfc238';
const _tonicEngineUrl = 'https://github.com/TonicAudio/Tonic';
const _uptechStudioUrl = 'https://www.uptechstudio.com';

void openSettings(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
}

class SettingsNavAction extends StatelessWidget {
  const SettingsNavAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(
        Icons.settings_outlined,
        color: AppStyles.textSecondary,
        size: 20,
      ),
      onPressed: () => openSettings(context),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _openUrl(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open ${uri.host}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: AppStyles.background,
        elevation: 0,
        leading: const BackButton(color: AppStyles.textSecondary),
        title: const Text('SETTINGS', style: AppStyles.appBarTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppStyles.surfaceRaised, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tonic Synths',
              style: AppStyles.settingsTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Live Synthesizers',
              style: AppStyles.settingsBody,
            ),
            const SizedBox(height: 24),
            const Text('ABOUT', style: AppStyles.sectionLabel),
            const SizedBox(height: 12),
            const Text(
              'Tonic Synths is a collection of 14 interactive synthesizers '
              'running live in Flutter on your device. Each synth explores a '
              'different sound-design technique — FM modulation, wavetable '
              'oscillators, step sequencers, reverb, sidechain compression, '
              'and more.',
              style: AppStyles.settingsBody,
            ),
            const SizedBox(height: 16),
            const Text(
              'Audio is rendered in real time by the Tonic C++ synthesis '
              'engine, bridged to Dart through FFI and Dart Build Hooks. PCM '
              'audio streams straight to your speaker — no servers, no cloud.',
              style: AppStyles.settingsBody,
            ),
            const SizedBox(height: 16),
            const Text(
              'Built as a companion demo for the FlutterCon 2026 talk '
              '"Hook, Line & Sinker: Dart Hooks", Tonic Synths shows how '
              'modern Dart tooling can integrate native C++ libraries without '
              'platform channels. It just happens to be a cool application.',
              style: AppStyles.settingsBody,
            ),
            const SizedBox(height: 32),
            const Text('PRIVACY', style: AppStyles.sectionLabel),
            const SizedBox(height: 12),
            const Text(
              'Tonic Synths does not collect any data about your usage. '
              'It is 100% offline without any diagnostics or telemetry '
              'data collection. The Tonic C++ engine is part of the public domain.',
              style: AppStyles.settingsBody,
            ),
            const SizedBox(height: 32),
            const Text('LINKS', style: AppStyles.sectionLabel),
            const SizedBox(height: 12),
            _SettingsLink(
              label: 'PRIVACY POLICY',
              onTap: () => _openUrl(context, Uri.parse(_privacyPolicyUrl)),
            ),
            const SizedBox(height: 8),
            _SettingsLink(
              label: 'TONIC C++ ENGINE',
              onTap: () => _openUrl(context, Uri.parse(_tonicEngineUrl)),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                const Text('© 2026 ', style: AppStyles.settingsCopyright),
                GestureDetector(
                  onTap: () => _openUrl(context, Uri.parse(_uptechStudioUrl)),
                  child: Text(
                    'Uptech Studio',
                    style: AppStyles.settingsCopyright.copyWith(
                      color: AppStyles.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppStyles.accentBlue, width: 1),
          foregroundColor: AppStyles.accentBlue,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onTap,
        child: Text(label, style: AppStyles.settingsLink),
      ),
    );
  }
}
