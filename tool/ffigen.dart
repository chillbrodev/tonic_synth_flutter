// tool/ffigen.dart
// Run: dart run tool/ffigen.dart

import 'dart:io';
import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  final header = packageRoot.resolve('third_party/tonic/tonic_wrapper.h');

  FfiGenerator(
    headers: Headers(
      entryPoints: [header],
      include: (uri) => uri == header,
      compilerOptions: ['-std=c11'],
    ),
    functions: Functions(
      include: (d) => RegExp(r'^tonic_.*').hasMatch(d.originalName),
    ),
    output: Output(
      dartFile: packageRoot.resolve('lib/ffi/gen/tonic_native.g.dart'),
      style: NativeExternalBindings(),
    ),
  ).generate();
}
