// lib/pages/page_helpers.dart
// Shared widget helpers used across all synth pages.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/audio/audio_limits.dart';

const int maxSessionSeconds = kMaxSessionSeconds;

Widget recordingLimitNotice() => Text(
  'RECORDINGS LIMITED TO ${kMaxSessionSeconds}s',
  style: const TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 9,
    color: Color(0xFF555555),
    letterSpacing: 2,
  ),
);

/// Blocks back navigation while recording unless the user confirms discard.
Widget guardRecordingExit({required bool isRecording, required Widget child}) {
  return Builder(
    builder: (context) => PopScope(
      canPop: !isRecording,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!context.mounted) return;
        final leave = await confirmDiscardRecordingDialog(context);
        if (leave && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: child,
    ),
  );
}

Future<bool> confirmDiscardRecordingDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Discard recording?',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          color: Color(0xFFFF4444),
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
      content: const Text(
        'Leaving this page will stop playback and discard your '
        'in-progress recording.',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          color: Color(0xFFAAAAAA),
          fontSize: 12,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'STAY',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              color: Color(0xFF00FF9C),
              letterSpacing: 1,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'LEAVE',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              color: Color(0xFFFF4444),
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

class SessionTimerBar extends StatefulWidget {
  const SessionTimerBar({
    super.key,
    required this.isActive,
    required this.getProgress,
    required this.getSecondsElapsed,
    required this.getSecondsRemaining,
    this.accent = const Color(0xFF00FF9C),
  });

  final bool isActive;
  final double Function() getProgress;
  final double Function() getSecondsElapsed;
  final double Function() getSecondsRemaining;
  final Color accent;

  @override
  State<SessionTimerBar> createState() => _SessionTimerBarState();
}

class _SessionTimerBarState extends State<SessionTimerBar> {
  Timer? _refreshTimer;

  @override
  void didUpdateWidget(SessionTimerBar old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() {});
      });
    } else if (!widget.isActive && old.isActive) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final progress = widget.getProgress();
    final elapsed = widget.getSecondsElapsed();
    final remaining = widget.getSecondsRemaining();
    final nearLimit = progress > 0.8;

    return Column(
      children: [
        SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(
              nearLimit
                  ? const Color(0xFFFF4444)
                  : widget.accent.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatSessionTime(elapsed),
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 9,
                color: nearLimit ? const Color(0xFFFF4444) : widget.accent,
                letterSpacing: 1,
              ),
            ),
            Text(
              '-${formatSessionTime(remaining)}',
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 9,
                color: Color(0xFF555555),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String formatSessionTime(double seconds) {
  final s = seconds.clamp(0, kMaxSessionSeconds.toDouble()).toInt();
  final m = s ~/ 60;
  final rem = s % 60;
  return '${m.toString().padLeft(1, '0')}:${rem.toString().padLeft(2, '0')}';
}

Widget playbackFooter({
  required bool isPlaying,
  required Future<void> Function() onToggle,
  Color accent = const Color(0xFF00FF9C),
}) => playButton(isPlaying: isPlaying, onTap: onToggle, accent: accent);

AppBar synthAppBar(String title) => AppBar(
  backgroundColor: const Color(0xFF0D0D0D),
  elevation: 0,
  leading: const BackButton(color: Color(0xFF555555)),
  title: Text(
    title,
    style: const TextStyle(
      fontFamily: 'RobotoMono',
      color: Color(0xFF00FF9C),
      fontSize: 12,
      letterSpacing: 4,
      fontWeight: FontWeight.w500,
    ),
  ),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(color: const Color(0xFF1A1A1A), height: 1),
  ),
);

Widget sectionLabel(String text) => Text(
  text,
  style: const TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 9,
    color: Color(0xFF555555),
    letterSpacing: 3,
  ),
);

Widget playButton({
  required bool isPlaying,
  required Future<void> Function() onTap,
  Color accent = const Color(0xFF00FF9C),
}) => SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: BorderSide(
        color: isPlaying ? const Color(0xFFFF9500) : accent,
        width: 1,
      ),
      foregroundColor: isPlaying ? const Color(0xFFFF9500) : accent,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
    onPressed: onTap,
    child: Text(
      isPlaying ? 'STOP' : 'PLAY',
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 11,
        letterSpacing: 2,
      ),
    ),
  ),
);

// ---------------------------------------------------------------------------
// Recording controls widget
// ---------------------------------------------------------------------------

class RecordingControls extends StatefulWidget {
  const RecordingControls({
    super.key,
    required this.isPlaying,
    required this.isRecording,
    required this.getRecordingProgress,
    required this.getRecordingElapsed,
    required this.getRecordingRemaining,
    required this.onRecord,
    required this.onStopRecord,
    required this.onShare,
    this.savedRecordingPath,
  });
  final bool isPlaying;
  final bool isRecording;
  final double Function() getRecordingProgress;
  final double Function() getRecordingElapsed;
  final double Function() getRecordingRemaining;
  final VoidCallback onRecord;
  final Future<String?> Function() onStopRecord;
  final Future<void> Function(String) onShare;
  final String? savedRecordingPath;

  @override
  State<RecordingControls> createState() => _RecordingControlsState();
}

class _RecordingControlsState extends State<RecordingControls> {
  Timer? _refreshTimer;

  @override
  void didUpdateWidget(covariant RecordingControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startRefreshTimer();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isRecording) ...[
          SessionTimerBar(
            isActive: true,
            getProgress: widget.getRecordingProgress,
            getSecondsElapsed: widget.getRecordingElapsed,
            getSecondsRemaining: widget.getRecordingRemaining,
            accent: const Color(0xFFFF4444),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        recordingLimitNotice(),
        const SizedBox(height: 12),

        // Record / Stop button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.isRecording || widget.isPlaying
                    ? const Color(0xFFFF4444)
                    : const Color(0xFF333333),
                width: 1,
              ),
              foregroundColor: widget.isRecording || widget.isPlaying
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            onPressed: widget.isPlaying
                ? () async {
                    if (widget.isRecording) {
                      await widget.onStopRecord();
                    } else {
                      widget.onRecord();
                    }
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.fiber_manual_record,
                  size: 14,
                  color: widget.isRecording || widget.isPlaying
                      ? const Color(0xFFFF4444)
                      : const Color(0xFF333333),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isRecording ? 'STOP REC' : 'RECORD',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Share button — appears after a recording is saved
        if (widget.savedRecordingPath != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3498DB), width: 1),
                foregroundColor: const Color(0xFF3498DB),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: () => widget.onShare(widget.savedRecordingPath!),
              icon: const Icon(Icons.ios_share, size: 14),
              label: const Text(
                'EXPORT WAV',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
