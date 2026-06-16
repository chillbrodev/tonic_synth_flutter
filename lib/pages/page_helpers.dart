// lib/pages/page_helpers.dart
// Shared widgets used across all synth pages.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tonic_synth_flutter/audio/audio_limits.dart';

const int maxSessionSeconds = kMaxSessionSeconds;

class RecordingLimitNotice extends StatelessWidget {
  const RecordingLimitNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'RECORDINGS LIMITED TO ${kMaxSessionSeconds}s',
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 9,
        color: Color(0xFF555555),
        letterSpacing: 2,
      ),
    );
  }
}

/// Blocks back navigation while recording unless the user confirms discard.
class GuardRecordingExit extends StatelessWidget {
  const GuardRecordingExit({
    super.key,
    required this.isRecording,
    required this.child,
  });

  final bool isRecording;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
    );
  }
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

class SynthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SynthAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 9,
        color: Color(0xFF555555),
        letterSpacing: 3,
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.accent = const Color(0xFF00FF9C),
  });

  final bool isPlaying;
  final Future<void> Function() onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
  }
}

class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.display,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
    this.labelWidth = 72,
    this.displayWidth = 56,
    this.displayFontSize = 11,
    this.labelLetterSpacing = 1.5,
  });

  final String label;
  final String display;
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;
  final double labelWidth;
  final double displayWidth;
  final double displayFontSize;
  final double labelLetterSpacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 9,
              color: const Color(0xFF555555),
              letterSpacing: labelLetterSpacing,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xFF2A2A2A),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 1.5,
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
        SizedBox(
          width: displayWidth,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: displayFontSize,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class ArcDial extends StatelessWidget {
  const ArcDial({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
    this.color = const Color(0xFF00FF9C),
    this.dialSize = 100,
    this.strokeWidth = 6,
    this.displayFontSize = 13,
    this.labelSpacing = 8,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;
  final Color color;
  final double dialSize;
  final double strokeWidth;
  final double displayFontSize;
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onPanUpdate: (d) {
            final range = max - min;
            final delta = -d.delta.dy / 150 * range;
            onChanged((value + delta).clamp(min, max));
          },
          child: SizedBox(
            width: dialSize,
            height: dialSize,
            child: CustomPaint(
              painter: ArcDialPainter(
                value: (value - min) / (max - min),
                color: color,
                displayText: display,
                strokeWidth: strokeWidth,
                displayFontSize: displayFontSize,
              ),
            ),
          ),
        ),
        SizedBox(height: labelSpacing),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9,
            color: Color(0xFF555555),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class ArcDialPainter extends CustomPainter {
  const ArcDialPainter({
    required this.value,
    required this.color,
    required this.displayText,
    this.strokeWidth = 6,
    this.displayFontSize = 13,
  });

  final double value;
  final Color color;
  final String displayText;
  final double strokeWidth;
  final double displayFontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth - 4;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * value,
      false,
      activePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: displayFontSize,
          color: color,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(ArcDialPainter old) =>
      old.value != value ||
      old.displayText != displayText ||
      old.strokeWidth != strokeWidth ||
      old.displayFontSize != displayFontSize;
}

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
        const RecordingLimitNotice(),
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
