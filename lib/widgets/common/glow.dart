// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:math';

import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

enum GradientVariant {
  subtle,
  softVignette,
  centerFocus,
  edgeFade,
  warmTone,
  coolTone,
  dynamicFlow,
  minimalDark,
}

class Glow extends StatelessWidget {
  final Widget child;
  final Alignment begin;
  final Alignment end;
  final String color;
  final bool disabled;

  const Glow({
    super.key,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.color = '',
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final theme = color.isNotEmpty && settings.usePosterColor
        ? ColorScheme.fromSeed(
            brightness: Theme.of(context).brightness,
            seedColor: Color(
              int.parse(color.replaceAll('#', '0xFF')),
            ),
          )
        : Theme.of(context).colorScheme;
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final ch = isDesktop
        ? Padding(
            padding: const EdgeInsets.only(top: 40),
            child: child,
          )
        : child;

    if (disabled) return child;

    return Obx(() {
      settings.liquidBackgroundPath;
      final liquidMode = settings.liquidMode;

      if (liquidMode) {
        return LiquidMode(
          theme: theme,
          gradientVariant: GradientVariant.subtle,
          child: ch,
        );
      } else {
        if (settings.disableGradient) {
          return Container(color: theme.surface, child: ch);
        }
        return LightweightGlow(begin: begin, end: end, child: ch);
      }
    });
  }
}

class LiquidMode extends StatelessWidget {
  final Widget child;
  final GradientVariant gradientVariant;
  final bool useTexture;
  final ColorScheme theme;

  const LiquidMode(
      {super.key,
      required this.child,
      this.gradientVariant = GradientVariant.subtle,
      this.useTexture = false,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    final imagePath = settingsController.liquidBackgroundPath.isEmpty
        ? 'assets/images/bg_glass.jpg'
        : "file://${settingsController.liquidBackgroundPath}";

    return Stack(
      children: [
        Positioned.fill(
          child: Obx(() {
            return _CachedColorFilteredImage(
              color: settingsController.retainOriginalColor
                  ? null
                  : theme.primary.withOpacity(0.6),
              imagePath: imagePath,
            );
          }),
        ),
        Positioned.fill(
          child: _OptimizedGradientOverlay(
            gradientVariant: gradientVariant,
            theme: theme,
          ),
        ),
        if (useTexture)
          Positioned.fill(
            child: _TextureOverlay(theme: theme),
          ),
        child,
      ],
    );
  }
}

class _OptimizedGradientOverlay extends StatelessWidget {
  final GradientVariant gradientVariant;
  final ColorScheme theme;

  const _OptimizedGradientOverlay({
    required this.gradientVariant,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: _getGradient(),
        ),
      ),
    );
  }

  Gradient _getGradient() {
    switch (gradientVariant) {
      case GradientVariant.subtle:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surface.withOpacity(0.65),
            theme.surface.withOpacity(0.5),
            theme.primary.withOpacity(0.4),
            theme.surface.withOpacity(0.6),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        );

      case GradientVariant.softVignette:
        return RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            theme.surface.withOpacity(0.2),
            theme.surface.withOpacity(0.35),
            theme.surface.withOpacity(0.5),
            theme.surface.withOpacity(0.6),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        );

      case GradientVariant.centerFocus:
        return RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            theme.surface.withOpacity(0.15),
            theme.surface.withOpacity(0.3),
            theme.surface.withOpacity(0.45),
            theme.surface.withOpacity(0.55),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        );

      case GradientVariant.edgeFade:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.withOpacity(0.5),
            theme.surface.withOpacity(0.2),
            theme.surface.withOpacity(0.2),
            theme.surface.withOpacity(0.5),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        );

      case GradientVariant.warmTone:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surface.withOpacity(0.4),
            Color.lerp(theme.surface, theme.primaryContainer, 0.1)!
                .withOpacity(0.3),
            Color.lerp(theme.surface, theme.secondaryContainer, 0.1)!
                .withOpacity(0.25),
            theme.surface.withOpacity(0.45),
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        );

      case GradientVariant.coolTone:
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.surface.withOpacity(0.4),
            Color.lerp(theme.surface, theme.primaryContainer, 0.05)!
                .withOpacity(0.3),
            Color.lerp(theme.surface, theme.tertiaryContainer, 0.05)!
                .withOpacity(0.25),
            theme.surface.withOpacity(0.45),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case GradientVariant.dynamicFlow:
        return SweepGradient(
          center: Alignment.center,
          startAngle: 0,
          endAngle: 3.14159 * 2,
          colors: [
            theme.surface.withOpacity(0.4),
            theme.surface.withOpacity(0.25),
            theme.surface.withOpacity(0.35),
            theme.surface.withOpacity(0.3),
            theme.surface.withOpacity(0.4),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );

      case GradientVariant.minimalDark:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.withOpacity(0.3),
            theme.surface.withOpacity(0.25),
            theme.surface.withOpacity(0.25),
            theme.surface.withOpacity(0.3),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );
    }
  }
}

class _TextureOverlay extends StatelessWidget {
  final ColorScheme theme;

  const _TextureOverlay({required this.theme});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _TexturePainter(theme: theme),
        size: Size.infinite,
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  final ColorScheme theme;

  _TexturePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.onSurface.withOpacity(0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final random = Random(42);
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 0.5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = theme.onSurface.withOpacity(random.nextDouble() * 0.03),
      );
    }

    paint.color = theme.onSurface.withOpacity(0.2);
    paint.strokeWidth = 0.4;

    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CachedColorFilteredImage extends StatelessWidget {
  final Color? color;
  final String imagePath;

  const _CachedColorFilteredImage({
    this.color,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final isFile = imagePath.startsWith('file://');
    final image = isFile
        ? Image.file(
            File(imagePath.replaceFirst('file://', '')),
            fit: getResponsiveValue(context,
                mobileValue: BoxFit.fitHeight, desktopValue: BoxFit.cover),
            filterQuality: FilterQuality.low,
          )
        : Image.asset(
            imagePath,
            fit: getResponsiveValue(context,
                mobileValue: BoxFit.fitHeight, desktopValue: BoxFit.cover),
            filterQuality: FilterQuality.low,
          );

    return color != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(color!, BlendMode.color),
            child: image,
          )
        : image;
  }
}

class PureGradientGlow extends StatelessWidget {
  final Widget child;
  final Alignment begin;
  final Alignment end;

  const PureGradientGlow({
    super.key,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 2.0,
            colors: [
              theme.primary.withOpacity(0.15),
              theme.primaryContainer.withOpacity(0.12),
              theme.secondary.withOpacity(0.08),
              theme.surface.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [
                theme.surface.withOpacity(0.85),
                theme.surface.withOpacity(0.7),
                theme.primary.withOpacity(0.4),
                theme.surface.withOpacity(0.6),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class LightweightGlow extends StatelessWidget {
  final Widget child;
  final Alignment begin;
  final Alignment end;

  const LightweightGlow({
    super.key,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      color: theme.surface,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.surface.withOpacity(0.3),
              theme.primary.withOpacity(0.4)
            ],
            begin: begin,
            end: end,
          ),
        ),
        child: child,
      ),
    );
  }
}

BoxShadow glowingShadow(BuildContext context) {
  final controller = Get.find<Settings>();
  if (controller.glowMultiplier == 0.0) {
    return const BoxShadow(color: Colors.transparent);
  } else {
    return BoxShadow(
      color: Theme.of(context).colorScheme.primary.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.6),
      blurRadius: 50.0.multiplyBlur(),
      spreadRadius: 1.0.multiplyGlow(),
      offset: const Offset(-2.0, 0),
    );
  }
}

BoxShadow lightGlowingShadow(BuildContext context) {
  final controller = Get.find<Settings>();
  if (controller.glowMultiplier == 0.0) {
    return const BoxShadow(color: Colors.transparent);
  } else {
    return BoxShadow(
      color: Theme.of(context).colorScheme.primary.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.6),
      blurRadius: 59.0.multiplyBlur(),
      spreadRadius: 1.0.multiplyGlow(),
      offset: const Offset(-1.0, 0),
    );
  }
}

Shimmer placeHolderWidget(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: Theme.of(context).colorScheme.surfaceContainer,
    highlightColor: Theme.of(context).colorScheme.primary,
    child: Container(
      width: 80,
      height: 80,
      color: Theme.of(context).colorScheme.secondaryContainer,
    ),
  );
}
