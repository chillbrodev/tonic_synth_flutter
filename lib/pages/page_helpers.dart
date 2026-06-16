// lib/pages/page_helpers.dart
// Shared widget helpers used across all synth pages.

import 'dart:async';

import 'package:flutter/material.dart';

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
    required this.getProgress,
    required this.getSecondsRecorded,
    required this.getSecondsRemaining,
    required this.onRecord,
    required this.onStopRecord,
    required this.onShare,
  });
  final bool isPlaying;
  final bool isRecording;
  final double Function() getProgress; // 0..1
  final double Function() getSecondsRecorded;
  final double Function() getSecondsRemaining;
  final VoidCallback onRecord;
  final Future<String?> Function() onStopRecord;
  final Future<void> Function(String) onShare;

  @override
  State<RecordingControls> createState() => _RecordingControlsState();
}

class _RecordingControlsState extends State<RecordingControls> {
  String? _lastRecordingPath;
  Timer? _refreshTimer;

  @override
  void didUpdateWidget(RecordingControls old) {
    super.didUpdateWidget(old);
    if (widget.isRecording && !old.isRecording) {
      // Start a 250ms refresh timer to animate the progress bar.
      _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() {});
      });
    } else if (!widget.isRecording && old.isRecording) {
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
    final progress = widget.getProgress();
    final secondsRecorded = widget.getSecondsRecorded();
    final secondsRemaining = widget.getSecondsRemaining();

    return Column(
      children: [
        const SizedBox(height: 12),

        // Progress bar — visible while recording
        if (widget.isRecording) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8
                    ? const Color(0xFFFF4444)
                    : const Color(0xFFFF4444).withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(secondsRecorded),
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  color: Color(0xFFFF4444),
                  letterSpacing: 1,
                ),
              ),
              Text(
                '-${_formatTime(secondsRemaining)}',
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  color: Color(0xFF555555),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Record / Stop button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.isRecording
                    ? const Color(0xFFFF4444)
                    : widget.isPlaying
                    ? const Color(0xFF555555)
                    : const Color(0xFF333333),
                width: 1,
              ),
              foregroundColor: widget.isRecording
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF555555),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            onPressed: widget.isPlaying
                ? () async {
                    if (widget.isRecording) {
                      final path = await widget.onStopRecord();
                      if (path != null) {
                        setState(() => _lastRecordingPath = path);
                      }
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
                  color: widget.isRecording
                      ? const Color(0xFFFF4444)
                      : const Color(0xFF555555),
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
        if (_lastRecordingPath != null) ...[
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
              onPressed: () => widget.onShare(_lastRecordingPath!),
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

  String _formatTime(double seconds) {
    final s = seconds.toInt();
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(1, '0')}:${rem.toString().padLeft(2, '0')}';
  }
}
