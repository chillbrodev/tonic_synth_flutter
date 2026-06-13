// hook/build.dart
import 'dart:io';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final os = input.config.code.targetOS;
    final arch = input.config.code.targetArchitecture;

    switch (os) {
      case OS.android:
        await _bundleAndroid(input, output, arch);
      case OS.iOS:
        await _bundleIOS(input, output);
      default:
        return;
    }
  });
}

// ---------------------------------------------------------------------------
// Android
// ---------------------------------------------------------------------------

Future<void> _bundleAndroid(
  BuildInput input,
  BuildOutputBuilder output,
  Architecture arch,
) async {
  final abi = _androidAbi(arch);
  if (abi == null) return;

  final so = File.fromUri(
    input.packageRoot.resolve('native/libs/android/$abi/libtonic_wrapper.so'),
  );

  if (!so.existsSync()) {
    throw StateError(
      'libtonic_wrapper.so not found for $abi.\n'
      'Run scripts/build_native.sh first.',
    );
  }

  output.assets.code.add(
    CodeAsset(
      package: input.packageName,
      name: 'ffi/gen/tonic_native.g.dart',
      linkMode: DynamicLoadingBundled(),
      file: so.uri,
    ),
  );
}

// ---------------------------------------------------------------------------
// iOS — reach inside the XCFramework for the right slice
// ---------------------------------------------------------------------------

Future<void> _bundleIOS(BuildInput input, BuildOutputBuilder output) async {
  // Determine device vs simulator from IOSCodeConfig.targetSdk
  final isSimulator = input.config.code.iOS.targetSdk == IOSSdk.iPhoneSimulator;

  final slice = isSimulator ? 'arm64-sim' : 'arm64';

  final dylib = File.fromUri(
    input.packageRoot.resolve(
      'native/libs/ios/libtonic_wrapper.xcframework/'
      '${_xcframeworkSliceDir(isSimulator)}/'
      'libtonic_wrapper.dylib',
    ),
  );

  if (!dylib.existsSync()) {
    throw StateError(
      'libtonic_wrapper.dylib not found for iOS $slice.\n'
      'Run scripts/build_native.sh first.',
    );
  }

  output.assets.code.add(
    CodeAsset(
      package: input.packageName,
      name: 'ffi/gen/tonic_native.g.dart',
      linkMode: DynamicLoadingBundled(),
      file: dylib.uri,
    ),
  );
}

/// Maps to the directory name xcodebuild uses inside the XCFramework.
/// Device:    ios-arm64
/// Simulator: ios-arm64-simulator
String _xcframeworkSliceDir(bool isSimulator) =>
    isSimulator ? 'ios-arm64-simulator' : 'ios-arm64';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String? _androidAbi(Architecture arch) => switch (arch) {
  Architecture.arm64 => 'arm64-v8a',
  Architecture.arm => 'armeabi-v7a',
  Architecture.x64 => 'x86_64',
  _ => null,
};
