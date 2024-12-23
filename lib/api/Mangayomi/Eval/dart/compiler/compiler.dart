import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';

import '../plugin.dart';

Uint8List compilerEval(String code) {
  late Compiler compiler = Compiler();
  final plugin = MEvalPlugin();
  compiler.addPlugin(plugin);
  final program = compiler.compile({
    'anymex': {'main.dart': code}
  });

  final bytecode = program.write();
  return bytecode;
}
