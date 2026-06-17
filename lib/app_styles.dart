import 'package:flutter/material.dart';

/// Central palette and typography for the Tonic Synth UI.
abstract class AppStyles {
  static const String fontFamily = 'RobotoMono';

  // ---------------------------------------------------------------------------
  // Colors — backgrounds & surfaces
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFF0D0D0D);
  static const Color backgroundDeep = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceRaised = Color(0xFF1A1A1A);
  static const Color gridLine = Color(0xFF222222);
  static const Color trackInactive = Color(0xFF2A2A2A);

  // ---------------------------------------------------------------------------
  // Colors — text
  // ---------------------------------------------------------------------------

  /// Muted chrome for borders, ticks, and inactive strokes (not body text).
  static const Color chromeMuted = Color(0xFF333333);

  static const Color iconMuted = Color(0xFF9A9A9A);
  static const Color textInactive = Color(0xFF999999);
  static const Color textDim = Color(0xFFB8B8B8);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textBody = Color(0xFFD4D4D4);
  static const Color textPrimary = Color(0xFFFFFFFF);

  static const FontWeight labelWeight = FontWeight.w600;

  // ---------------------------------------------------------------------------
  // Colors — accents
  // ---------------------------------------------------------------------------

  static const Color accentMint = Color(0xFF00FF9C);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentRed = Color(0xFFFF4444);
  static const Color accentPurple = Color(0xFF9B59B6);
  static const Color accentBlue = Color(0xFF3498DB);

  /// Default synth / app accent.
  static const Color accent = accentMint;

  static const Color thumb = Colors.white;

  static const List<Color> purpleBands = [
    accentPurple,
    Color(0xFF8E44AD),
    Color(0xFF7D3C98),
    Color(0xFF6C3483),
    Color(0xFF5B2C6F),
  ];

  // ---------------------------------------------------------------------------
  // Typography — labels & chrome
  // ---------------------------------------------------------------------------

  static const TextStyle recordingLimit = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 2,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 3,
  );

  static const TextStyle sliderLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 1.5,
  );

  static const TextStyle arcDialLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 2,
  );

  static const TextStyle faderLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 1.5,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    color: accentMint,
    fontSize: 12,
    letterSpacing: 4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle launcherAppTitle = TextStyle(
    fontFamily: fontFamily,
    color: accentMint,
    fontSize: 14,
    letterSpacing: 6,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle launcherCardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: textPrimary,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle launcherCardDescription = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 0.5,
  );

  static const TextStyle playButtonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: labelWeight,
    letterSpacing: 2,
  );

  static const TextStyle recordButtonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: labelWeight,
    letterSpacing: 2,
  );

  static const TextStyle exportButtonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: labelWeight,
    letterSpacing: 2,
  );

  static const TextStyle sessionTimeRemaining = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 1,
  );

  static const TextStyle dialogTitle = TextStyle(
    fontFamily: fontFamily,
    color: accentRed,
    fontSize: 14,
    letterSpacing: 1,
  );

  static const TextStyle dialogBody = TextStyle(
    fontFamily: fontFamily,
    color: textBody,
    fontSize: 12,
    fontWeight: labelWeight,
    height: 1.4,
  );

  static const TextStyle dialogActionStay = TextStyle(
    fontFamily: fontFamily,
    color: accentMint,
    letterSpacing: 1,
  );

  static const TextStyle dialogActionLeave = TextStyle(
    fontFamily: fontFamily,
    color: accentRed,
    letterSpacing: 1,
  );

  static const TextStyle bpmValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 72,
    color: accentMint,
    fontWeight: FontWeight.w300,
    height: 1,
  );

  static const TextStyle bpmUnit = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 2,
  );

  static const TextStyle largeAccent = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    color: accentOrange,
    letterSpacing: 2,
  );

  static const TextStyle stepEditorTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: accentMint,
    letterSpacing: 2,
  );

  static const TextStyle coordLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: accentMint,
  );

  static const TextStyle coordRowLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 1,
  );

  static const TextStyle settingsTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: accentMint,
    fontWeight: labelWeight,
    letterSpacing: 2,
    height: 1.4,
  );

  static const TextStyle settingsBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: textBody,
    fontWeight: labelWeight,
    height: 1.6,
  );

  static const TextStyle settingsLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    color: accentBlue,
    fontWeight: labelWeight,
    letterSpacing: 1,
  );

  static const TextStyle settingsCopyright = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 1,
  );

  // ---------------------------------------------------------------------------
  // Typography — helpers
  // ---------------------------------------------------------------------------

  static TextStyle monoValue(
    Color color, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  static TextStyle sessionElapsed(Color color) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 9,
      color: color,
      fontWeight: labelWeight,
      letterSpacing: 1,
    );
  }

  static TextStyle modeLabel({required bool active}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 10,
      color: active ? accentOrange : textInactive,
      fontWeight: active ? FontWeight.w500 : labelWeight,
      letterSpacing: 2,
    );
  }

  static TextStyle stepNumber({required bool selected}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 9,
      color: selected ? accentMint : textInactive,
      fontWeight: selected ? FontWeight.w500 : labelWeight,
    );
  }

  static TextStyle stepPitch({required bool selected}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 8,
      color: selected ? accentMint : textDim,
      fontWeight: selected ? FontWeight.w500 : labelWeight,
    );
  }

  static const TextStyle heroCaption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 9,
    color: textSecondary,
    fontWeight: labelWeight,
    letterSpacing: 4,
  );

  static TextStyle scaleNote({required bool isActive}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 8,
      color: isActive ? textPrimary : accentPurple.withValues(alpha: 0.75),
      fontWeight: isActive ? FontWeight.w500 : labelWeight,
    );
  }

  static TextStyle duckLabel({required bool active}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      color: active ? accentRed : textInactive,
      fontWeight: active ? FontWeight.w500 : labelWeight,
      letterSpacing: 4,
    );
  }

  static TextStyle painterLabel(
    Color color, {
    double fontSize = 9,
    double letterSpacing = 1,
    FontWeight fontWeight = labelWeight,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle heroValue(
    Color color, {
    double fontSize = 40,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w300,
      letterSpacing: letterSpacing,
    );
  }
}
