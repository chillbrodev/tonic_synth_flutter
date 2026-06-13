// hook/build.dart
import 'dart:io';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS != OS.android) return;

    final abi = _abi(input.config.code.targetArchitecture);
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
        // Must match the implicit assetId of the @Native annotations
        // in lib/ffi/gen/tonic_native.g.dart:
        //   package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart
        name: 'ffi/gen/tonic_native.g.dart',
        linkMode: DynamicLoadingBundled(),
        file: so.uri,
      ),
    );

    // Note: libtonic_wrapper.so is built with ANDROID_STL=c++_static so the
    // C++ STL is compiled directly into the .so. No libc++_shared.so needed.
    //
    // We tried ANDROID_STL=c++_shared and package:android_libcpp_shared but
    // hit a confirmed bug in android_libcpp_shared 0.2.0 on NDK 28 + arm64:
    // the package looks for libc++_shared.so at the wrong path and with the
    // wrong filename. In NDK 28 arm64, libc++.so lives at:
    //   sysroot/usr/lib/aarch64-linux-android/24/libc++.so
    // Filed: https://github.com/dart-lang/native/issues
  });
}

String? _abi(Architecture arch) => switch (arch) {
  Architecture.arm64 => 'arm64-v8a',
  Architecture.arm => 'armeabi-v7a',
  Architecture.x64 => 'x86_64',
  _ => null,
};
