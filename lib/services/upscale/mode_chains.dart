import 'shader_registry.dart';

const String defaultSuperResolutionMode = 'Manga: Crisp Lines';

class SuperResolutionPreset {
  final String id;
  final String title;
  final String description;

  const SuperResolutionPreset({
    required this.id,
    required this.title,
    required this.description,
  });
}

const List<SuperResolutionPreset> superResolutionPresets = [
  SuperResolutionPreset(
    id: 'Manga: Crisp Lines',
    title: 'Manga (Crisp Lines)',
    description:
        'Contrast-adaptive ink & text sharpening that preserves screentones without moire',
  ),
  SuperResolutionPreset(
    id: 'Webtoon: Clean & Vibrant',
    title: 'Webtoon (Clean & Vibrant)',
    description:
        'Cleans JPEG compression ringing & enhances colors for digital manhwa',
  ),
  SuperResolutionPreset(
    id: 'Ultra: Adaptive Sharpness',
    title: 'Ultra Sharp (CAS)',
    description:
        'High-fidelity adaptive edge sharpening for soft or low-res scanlations',
  ),
];

const Map<String, List<UpscalePass>> upscaleModeChains = {
  'Manga: Crisp Lines': [
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Webtoon: Clean & Vibrant': [
    UpscalePass.clampHighlights,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Ultra: Adaptive Sharpness': [
    UpscalePass.edgeSharpen,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode A (Fast)': [
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode B (Fast)': [
    UpscalePass.clampHighlights,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode C (Fast)': [
    UpscalePass.clampHighlights,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode A+A (Fast)': [
    UpscalePass.edgeSharpen,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode B+B (Fast)': [
    UpscalePass.clampHighlights,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode C+A (Fast)': [
    UpscalePass.edgeSharpen,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode A (HQ)': [
    UpscalePass.edgeSharpen,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode B (HQ)': [
    UpscalePass.clampHighlights,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode C (HQ)': [
    UpscalePass.edgeSharpen,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode A+A (HQ)': [
    UpscalePass.edgeSharpen,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode B+B (HQ)': [
    UpscalePass.clampHighlights,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
  'Anime4K: Mode C+A (HQ)': [
    UpscalePass.edgeSharpen,
    UpscalePass.bicubicX2,
    UpscalePass.anymexSharpen,
  ],
};

Map<String, double> getShaderParams({
  required String profile,
  required double sharpness,
  required bool denoise,
}) {
  return {
    'edgeStrength': 0.75,
    'sharpness': sharpness,
    'denoise': denoise ? 1.0 : 0.0,
  };
}
