// lib/pages/page_helpers.dart
// Shared widget helpers used across all synth pages.

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
}) =>
    SizedBox(
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
