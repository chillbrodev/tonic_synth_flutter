import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/app_styles.dart';
import 'package:tonic_synth_flutter/pages/page_helpers.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';

/// Shared playback + recording state for synth pages.
mixin SynthPageAudioMixin<T extends StatefulWidget> on State<T> {
  SynthAudioHost get synthAudio;

  bool isPlaying = false;
  bool isRecording = false;
  String? savedRecordingPath;

  @mustCallSuper
  void initSynthPageAudio() {
    synthAudio.onRecordingLimitReached = _handleRecordingLimit;
  }

  @mustCallSuper
  void disposeSynthPageAudio() {
    synthAudio.onRecordingLimitReached = null;
  }

  void _handleRecordingLimit(String? savedPath) {
    if (!mounted) return;
    setState(() {
      isRecording = false;
      if (savedPath != null) savedRecordingPath = savedPath;
    });
    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('60s recording limit reached — WAV saved'),
        ),
      );
    }
  }

  /// Override to run side effects when playback starts (e.g. animation timers).
  Future<void> onSynthAudioStarting() async {}

  /// Override to run side effects when playback stops (e.g. cancel timers).
  Future<void> onSynthAudioStopping() async {}

  Future<void> toggleSynthAudio() async {
    if (isPlaying) {
      await onSynthAudioStopping();
      final path = await synthAudio.stopAudio(saveActiveRecording: isRecording);
      setState(() {
        isPlaying = false;
        isRecording = false;
        if (path != null) savedRecordingPath = path;
      });
    } else {
      await synthAudio.startAudio();
      await onSynthAudioStarting();
      setState(() => isPlaying = true);
    }
  }

  void startSynthRecording() {
    setState(() {
      synthAudio.startRecording();
      isRecording = true;
    });
  }

  Future<String?> stopSynthRecording() async {
    final path = await synthAudio.stopRecording();
    setState(() {
      isRecording = false;
      if (path != null) savedRecordingPath = path;
    });
    return path;
  }
}

class SynthPageShell extends StatelessWidget {
  const SynthPageShell({
    super.key,
    required this.isRecording,
    required this.child,
  });

  final bool isRecording;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GuardRecordingExit(isRecording: isRecording, child: child);
  }
}

class SynthAudioControls extends StatelessWidget {
  const SynthAudioControls({
    super.key,
    required this.isPlaying,
    required this.isRecording,
    required this.savedRecordingPath,
    required this.getRecordingProgress,
    required this.getRecordingElapsed,
    required this.getRecordingRemaining,
    required this.onToggle,
    required this.onRecord,
    required this.onStopRecord,
    required this.onShare,
    this.accent = AppStyles.accentMint,
  });

  factory SynthAudioControls.fromMixin(
    SynthPageAudioMixin audioMixin, {
    Key? key,
    Color accent = AppStyles.accentMint,
  }) {
    return SynthAudioControls(
      key: key,
      isPlaying: audioMixin.isPlaying,
      isRecording: audioMixin.isRecording,
      savedRecordingPath: audioMixin.savedRecordingPath,
      getRecordingProgress: () => audioMixin.synthAudio.recordingProgress,
      getRecordingElapsed: () => audioMixin.synthAudio.recordingSecondsRecorded,
      getRecordingRemaining: () =>
          audioMixin.synthAudio.recordingSecondsRemaining,
      onToggle: audioMixin.toggleSynthAudio,
      onRecord: audioMixin.startSynthRecording,
      onStopRecord: audioMixin.stopSynthRecording,
      onShare: audioMixin.synthAudio.shareRecording,
      accent: accent,
    );
  }

  final bool isPlaying;
  final bool isRecording;
  final String? savedRecordingPath;
  final double Function() getRecordingProgress;
  final double Function() getRecordingElapsed;
  final double Function() getRecordingRemaining;
  final Future<void> Function() onToggle;
  final VoidCallback onRecord;
  final Future<String?> Function() onStopRecord;
  final Future<void> Function(String) onShare;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlayButton(isPlaying: isPlaying, onTap: onToggle, accent: accent),
        RecordingControls(
          isPlaying: isPlaying,
          isRecording: isRecording,
          savedRecordingPath: savedRecordingPath,
          getRecordingProgress: getRecordingProgress,
          getRecordingElapsed: getRecordingElapsed,
          getRecordingRemaining: getRecordingRemaining,
          onRecord: onRecord,
          onStopRecord: onStopRecord,
          onShare: onShare,
        ),
      ],
    );
  }
}
