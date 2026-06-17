import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Locks phones to portrait; tablets may rotate to landscape as well.
abstract final class OrientationConfig {
  static const _tabletBreakpoint = 600.0;

  static const _phoneOrientations = [DeviceOrientation.portraitUp];

  static const _tabletOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static Future<void> apply() async {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        break;
      default:
        return;
    }

    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final orientations = logicalSize.shortestSide >= _tabletBreakpoint
        ? _tabletOrientations
        : _phoneOrientations;

    await SystemChrome.setPreferredOrientations(orientations);
  }
}
