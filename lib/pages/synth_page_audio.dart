import 'package:flutter/material.dart';
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

  Widget buildSynthPage({required Widget child}) {
    return guardRecordingExit(isRecording: isRecording, child: child);
  }

  Widget buildSynthAudioControls({Color accent = const Color(0xFF00FF9C)}) {
    return Column(
      children: [
        playbackFooter(
          isPlaying: isPlaying,
          onToggle: toggleSynthAudio,
          accent: accent,
        ),
        RecordingControls(
          isPlaying: isPlaying,
          isRecording: isRecording,
          savedRecordingPath: savedRecordingPath,
          getRecordingProgress: () => synthAudio.recordingProgress,
          getRecordingElapsed: () => synthAudio.recordingSecondsRecorded,
          getRecordingRemaining: () => synthAudio.recordingSecondsRemaining,
          onRecord: () {
            setState(() {
              synthAudio.startRecording();
              isRecording = true;
            });
          },
          onStopRecord: () async {
            final path = await synthAudio.stopRecording();
            setState(() {
              isRecording = false;
              if (path != null) savedRecordingPath = path;
            });
            return path;
          },
          onShare: synthAudio.shareRecording,
        ),
      ],
    );
  }
}
