import 'dart:ui' as ui;

enum UpscalePass {
  clampHighlights,
  edgeSharpen,
  softSmooth,
  bilateralDenoise,
  bicubicX2,
  anymexSharpen,
}

class ShaderRegistry {
  static final Map<UpscalePass, ui.FragmentProgram> _programs = {};
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final entries = {
        UpscalePass.clampHighlights:
            'assets/shaders/upscale/clamp_highlights.frag',
        UpscalePass.edgeSharpen: 'assets/shaders/upscale/edge_sharpen.frag',
        UpscalePass.softSmooth: 'assets/shaders/upscale/soft_smooth.frag',
        UpscalePass.bilateralDenoise:
            'assets/shaders/upscale/bilateral_denoise.frag',
        UpscalePass.bicubicX2: 'assets/shaders/upscale/bicubic_x2.frag',
        UpscalePass.anymexSharpen: 'assets/shaders/upscale/anymex_sharpen.frag',
      };
      for (final e in entries.entries) {
        _programs[e.key] = await ui.FragmentProgram.fromAsset(e.value);
      }
      _loaded = true;
    } catch (_) {}
  }

  static ui.FragmentProgram? get(UpscalePass pass) => _programs[pass];
}
