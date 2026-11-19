import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'shader_registry.dart';
import 'mode_chains.dart';

class GpuUpscaleRunner {
  static Future<ui.Image?> run({
    required ui.Image input,
    required String mode,
    required Map<String, double> params,
    required int outW,
    required int outH,
  }) async {
    final basePasses = upscaleModeChains[mode] ??
        upscaleModeChains[defaultSuperResolutionMode]!;

    final List<UpscalePass> passes = [];
    if (params['denoise'] == 1.0 &&
        !basePasses.contains(UpscalePass.bilateralDenoise) &&
        !basePasses.contains(UpscalePass.clampHighlights)) {
      passes.add(UpscalePass.clampHighlights);
    }
    passes.addAll(basePasses);

    ui.Image current = input;
    bool hasScaled = false;
    bool ownsCurrent = false;

    for (final pass in passes) {
      if (pass == UpscalePass.bicubicX2) {
        hasScaled = true;
      }

      final passW = hasScaled ? outW : input.width;
      final passH = hasScaled ? outH : input.height;

      final next = await _renderPass(
        pass: pass,
        input: current,
        outW: passW,
        outH: passH,
        params: params,
      );

      if (next == null) continue;

      if (ownsCurrent) {
        current.dispose();
      }
      current = next;
      ownsCurrent = true;
    }

    return current;
  }

  static Future<ui.Image?> _renderPass({
    required UpscalePass pass,
    required ui.Image input,
    required int outW,
    required int outH,
    required Map<String, double> params,
  }) async {
    final program = ShaderRegistry.get(pass);
    if (program == null) return null;

    final shader = program.fragmentShader();

    switch (pass) {
      case UpscalePass.bicubicX2:
        shader.setFloat(0, input.width.toDouble());
        shader.setFloat(1, input.height.toDouble());
        shader.setFloat(2, outW.toDouble());
        shader.setFloat(3, outH.toDouble());
        shader.setImageSampler(0, input);
      case UpscalePass.edgeSharpen:
        shader.setFloat(0, outW.toDouble());
        shader.setFloat(1, outH.toDouble());
        shader.setFloat(2, params['edgeStrength'] ?? 0.6);
        shader.setImageSampler(0, input);
      case UpscalePass.softSmooth:
        shader.setFloat(0, outW.toDouble());
        shader.setFloat(1, outH.toDouble());
        shader.setFloat(2, params['sigmaColor'] ?? 0.1);
        shader.setImageSampler(0, input);
      case UpscalePass.bilateralDenoise:
        shader.setFloat(0, outW.toDouble());
        shader.setFloat(1, outH.toDouble());
        shader.setFloat(2, params['sigmaSpace'] ?? 2.0);
        shader.setFloat(3, params['sigmaColor'] ?? 0.1);
        shader.setImageSampler(0, input);
      case UpscalePass.clampHighlights:
        shader.setFloat(0, outW.toDouble());
        shader.setFloat(1, outH.toDouble());
        shader.setImageSampler(0, input);
      case UpscalePass.anymexSharpen:
        shader.setFloat(0, outW.toDouble());
        shader.setFloat(1, outH.toDouble());
        shader.setFloat(2, params['sharpness'] ?? 1.0);
        shader.setImageSampler(0, input);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
      Paint()..shader = shader,
    );

    final picture = recorder.endRecording();
    return await picture.toImage(outW, outH);
  }
}
