import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

typedef MeshRaster = ({int width, int height, Uint8List pixels});

class MeshBlurHelper {
  static const int meshGrid = 6;
  static const int meshTex = 48;
  static const double meshVibrance = 1.15;
  static const double meshFloor = 0.05;

  static double _smoothstep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
  }

  static int _lerpArgb(int from, int to, double t) {
    if (t <= 0.0) return from;
    if (t >= 1.0) return to;
    int channel(int shift) {
      final a = (from >> shift) & 0xFF;
      final b = (to >> shift) & 0xFF;
      return (a + ((b - a) * t)).round().clamp(0, 255);
    }

    return (0xFF << 24) |
        (channel(16) << 16) |
        (channel(8) << 8) |
        channel(0);
  }

  static void _rgbToHsl(int r, int g, int b, List<double> hsl) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;
    final max = math.max(rf, math.max(gf, bf));
    final min = math.min(rf, math.min(gf, bf));
    final delta = max - min;
    var h = 0.0;
    var s = 0.0;
    final l = (max + min) / 2.0;

    if (delta != 0.0) {
      s = l > 0.5 ? delta / (2.0 - max - min) : delta / (max + min);
      if (max == rf) {
        h = (gf - bf) / delta + (gf < bf ? 6.0 : 0.0);
      } else if (max == gf) {
        h = (bf - rf) / delta + 2.0;
      } else {
        h = (rf - gf) / delta + 4.0;
      }
      h /= 6.0;
    }
    hsl[0] = h;
    hsl[1] = s;
    hsl[2] = l;
  }

  static double _hue2rgb(double p, double q, double t) {
    var val = t;
    if (val < 0.0) val += 1.0;
    if (val > 1.0) val -= 1.0;
    if (val < 1.0 / 6.0) return p + (q - p) * 6.0 * val;
    if (val < 1.0 / 2.0) return q;
    if (val < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - val) * 6.0;
    return p;
  }

  static int _hslToRgb(double h, double s, double l) {
    var r = l;
    var g = l;
    var b = l;
    if (s != 0.0) {
      final q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
      final p = 2.0 * l - q;
      r = _hue2rgb(p, q, h + 1.0 / 3.0);
      g = _hue2rgb(p, q, h);
      b = _hue2rgb(p, q, h - 1.0 / 3.0);
    }
    return (0xFF << 24) |
        (((r * 255.0).round().clamp(0, 255)) << 16) |
        (((g * 255.0).round().clamp(0, 255)) << 8) |
        ((b * 255.0).round().clamp(0, 255));
  }

  static int _liftColor(int r, int g, int b) {
    final hsl = [0.0, 0.0, 0.0];
    _rgbToHsl(r, g, b, hsl);
    hsl[1] = (hsl[1] * meshVibrance).clamp(0.0, 1.0);
    hsl[2] = math.max(hsl[2], meshFloor);
    return _hslToRgb(hsl[0], hsl[1], hsl[2]);
  }

  static List<int> _buildRotatedGrid(
      img.Image source, int seed, int cols, int rows) {
    final cells = cols * rows;
    final red = List<int>.filled(cells, 0);
    final green = List<int>.filled(cells, 0);
    final blue = List<int>.filled(cells, 0);
    final count = List<int>.filled(cells, 0);

    final width = source.width;
    final height = source.height;
    final rowStep = math.max(1, height ~/ 120);
    final colStep = math.max(1, width ~/ 120);

    for (var y = 0; y < height; y += rowStep) {
      final rowBase = ((height - 1 - y) * rows ~/ height) * cols;
      for (var x = 0; x < width; x += colStep) {
        final cell = rowBase + (x * cols ~/ width);
        final pixel = source.getPixel(x, y);
        red[cell] += pixel.r.toInt();
        green[cell] += pixel.g.toInt();
        blue[cell] += pixel.b.toInt();
        count[cell]++;
      }
    }

    final grid = List<int>.generate(cells, (cell) {
      final n = math.max(1, count[cell]);
      return _liftColor(
        red[cell] ~/ n,
        green[cell] ~/ n,
        blue[cell] ~/ n,
      );
    });

    if (rows <= 1) return grid;

    final random = math.Random(seed);
    final mirror = random.nextBool();
    final shift = random.nextInt(cols);
    final rotated = List<int>.from(grid);

    for (var row = 1; row < rows; row++) {
      final base = row * cols;
      for (var x = 0; x < cols; x++) {
        final src = mirror ? (cols - 1 - x) : x;
        rotated[base + x] = grid[base + ((src + shift) % cols)];
      }
    }

    return rotated;
  }

  static img.Image generateMeshImageFromDecoded(img.Image decoded,
      {int seed = 42, int outputSize = meshTex}) {
    final grid = _buildRotatedGrid(decoded, seed, meshGrid, meshGrid);
    final outImage = img.Image(width: outputSize, height: outputSize);

    for (var ty = 0; ty < outputSize; ty++) {
      final fy = (ty + 0.5) / outputSize * meshGrid - 0.5;
      final y0 = fy.floor().clamp(0, meshGrid - 1);
      final y1 = (y0 + 1).clamp(0, meshGrid - 1);
      final wy = _smoothstep(fy - y0);

      for (var tx = 0; tx < outputSize; tx++) {
        final fx = (tx + 0.5) / outputSize * meshGrid - 0.5;
        final x0 = fx.floor().clamp(0, meshGrid - 1);
        final x1 = (x0 + 1).clamp(0, meshGrid - 1);
        final wx = _smoothstep(fx - x0);

        final top = _lerpArgb(
            grid[y0 * meshGrid + x0], grid[y0 * meshGrid + x1], wx);
        final bottom = _lerpArgb(
            grid[y1 * meshGrid + x0], grid[y1 * meshGrid + x1], wx);
        final color = _lerpArgb(top, bottom, wy);

        final r = (color >> 16) & 0xFF;
        final g = (color >> 8) & 0xFF;
        final b = color & 0xFF;

        outImage.setPixelRgba(tx, ty, r, g, b, 255);
      }
    }

    return outImage;
  }

  static MeshRaster processMeshBackdrop(
      (Uint8List, double, double, int) task) {
    final (sourceBytes, vibrancy, blurAmount, seed) = task;
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw StateError('Unable to decode image bytes for mesh');
    }

    var mesh = generateMeshImageFromDecoded(decoded, seed: seed);

    if (blurAmount > 0.5) {
      final radius = (blurAmount * 0.4).round().clamp(1, 15);
      mesh = img.gaussianBlur(mesh, radius: radius);
    }

    if (vibrancy != 1.0) {
      mesh = img.adjustColor(mesh, saturation: vibrancy);
    }

    final rgbaImage = mesh.convert(numChannels: 4, alpha: 255);
    return (
      width: rgbaImage.width,
      height: rgbaImage.height,
      pixels: rgbaImage.getBytes(order: img.ChannelOrder.rgba),
    );
  }

  static Future<ui.Image> inflateNativeImage(MeshRaster raster) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      raster.pixels,
      raster.width,
      raster.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}
