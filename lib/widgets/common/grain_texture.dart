import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GrainTexture extends StatelessWidget {
  final Color color;
  final double opacity;

  const GrainTexture({
    super.key,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GrainTexturePainter(color, opacity),
        size: Size.infinite,
      ),
    );
  }
}

class _GrainTexturePainter extends CustomPainter {
  _GrainTexturePainter(this.color, this.opacity);

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final shader = _NoiseTileCache.shaderFor(color, opacity);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _GrainTexturePainter oldDelegate) {
    return color != oldDelegate.color || opacity != oldDelegate.opacity;
  }
}

class _NoiseTileCache {
  _NoiseTileCache._();

  static const int _tileSize = 128;
  static const int _randomSeed = 1337;
  static const double _speckIntensity = 0.6;

  static ui.ImageShader? _shader;
  static ui.Image? _image;
  static Color? _color;
  static double? _opacity;

  static ui.ImageShader shaderFor(Color color, double opacity) {
    if (_shader != null && _color == color && _opacity == opacity) {
      return _shader!;
    }

    _image?.dispose();
    _image = _buildNoiseImage(color, opacity);
    _shader = ui.ImageShader(
      _image!,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      Matrix4.identity().storage,
    );
    _color = color;
    _opacity = opacity;

    return _shader!;
  }

  static ui.Image _buildNoiseImage(Color color, double opacity) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _tileSize.toDouble(), _tileSize.toDouble()),
    );

    final random = math.Random(_randomSeed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < _tileSize; y++) {
      for (int x = 0; x < _tileSize; x++) {
        final factor = (random.nextDouble() - 0.5) * 2.0;
        final alpha =
            (factor.abs() * opacity * _speckIntensity).clamp(0.0, 1.0);

        paint.color =
            (factor > 0 ? Colors.white : color).withValues(alpha: alpha);

        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.0, 1.0),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = picture.toImageSync(_tileSize, _tileSize);
    picture.dispose();
    return image;
  }
}
