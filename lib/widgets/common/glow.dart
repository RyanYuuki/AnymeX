// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:math';

import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
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
        : context.colors;
    final isDesktop = Platform.isWindows;
    final isOled = Provider.of<ThemeProvider>(context).isOled;
    final ch = isDesktop
        ? Container(
            margin: const EdgeInsets.only(top: 40),
            child: child,
          )
        : child;

    if (disabled || (isOled && isDesktop)) {
      return Container(
          color: isOled ? Colors.black : Colors.transparent, child: ch);
    }

    return Obx(() {
      settings.liquidBackgroundPath;
      final liquidMode = settings.liquidMode;

      if (liquidMode) {
        return LiquidMode(
          isOled: isOled,
          theme: theme,
          gradientVariant: GradientVariant.subtle,
          child: ch,
        );
      } else {
        if (settings.disableGradient || isOled) {
          return Container(
              color: isOled ? Colors.black : theme.surface, child: ch);
        }
        return LightweightGlow(begin: begin, end: end, child: ch);
      }
    });
  }
}

class LiquidMode extends StatelessWidget {
  final GradientVariant gradientVariant;
  final ColorScheme theme;
  final bool isOled;
  final Widget child;

  const LiquidMode(
      {super.key,
      required this.child,
      this.gradientVariant = GradientVariant.subtle,
      required this.theme,
      this.isOled = false});

  @override
  Widget build(BuildContext context) {
    final imagePath = settingsController.liquidBackgroundPath.isEmpty
        ? 'assets/images/bg_glass.webp'
        : "file://${settingsController.liquidBackgroundPath}";

    return Stack(
      children: [
        Positioned.fill(
          child: Obx(() {
            return _CachedColorFilteredImage(
              color: settingsController.retainOriginalColor
                  ? null
                  : theme.primary.opaque(0.6),
              imagePath: imagePath,
            );
          }),
        ),
        Positioned.fill(
          child: isOled
              ? Container(color: Colors.black)
              : _OptimizedGradientOverlay(
                  gradientVariant: gradientVariant,
                  theme: theme,
                ),
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
            theme.surface.opaque(0.65),
            theme.surface.opaque(0.5),
            theme.primary.opaque(0.4),
            theme.surface.opaque(0.6),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        );

      case GradientVariant.softVignette:
        return RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            theme.surface.opaque(0.2),
            theme.surface.opaque(0.35),
            theme.surface.opaque(0.5),
            theme.surface.opaque(0.6),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        );

      case GradientVariant.centerFocus:
        return RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            theme.surface.opaque(0.15),
            theme.surface.opaque(0.3),
            theme.surface.opaque(0.45),
            theme.surface.opaque(0.55),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        );

      case GradientVariant.edgeFade:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.opaque(0.5),
            theme.surface.opaque(0.2),
            theme.surface.opaque(0.2),
            theme.surface.opaque(0.5),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        );

      case GradientVariant.warmTone:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surface.opaque(0.4),
            Color.lerp(theme.surface, theme.primaryContainer, 0.1)!.opaque(0.3),
            Color.lerp(theme.surface, theme.secondaryContainer, 0.1)!
                .opaque(0.25),
            theme.surface.opaque(0.45),
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        );

      case GradientVariant.coolTone:
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.surface.opaque(0.4),
            Color.lerp(theme.surface, theme.primaryContainer, 0.05)!
                .opaque(0.3),
            Color.lerp(theme.surface, theme.tertiaryContainer, 0.05)!
                .opaque(0.25),
            theme.surface.opaque(0.45),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case GradientVariant.dynamicFlow:
        return SweepGradient(
          center: Alignment.center,
          startAngle: 0,
          endAngle: 3.14159 * 2,
          colors: [
            theme.surface.opaque(0.4),
            theme.surface.opaque(0.25),
            theme.surface.opaque(0.35),
            theme.surface.opaque(0.3),
            theme.surface.opaque(0.4),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );

      case GradientVariant.minimalDark:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.opaque(0.3),
            theme.surface.opaque(0.25),
            theme.surface.opaque(0.25),
            theme.surface.opaque(0.3),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );
    }
  }
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
    final theme = context.colors;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 2.0,
            colors: [
              theme.primary.opaque(0.15),
              theme.primaryContainer.opaque(0.12),
              theme.secondary.opaque(0.08),
              theme.surface.opaque(0.05),
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
                theme.surface.opaque(0.85),
                theme.surface.opaque(0.7),
                theme.primary.opaque(0.4),
                theme.surface.opaque(0.6),
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
    final theme = context.colors;

    return RepaintBoundary(
      child: Container(
        color: theme.surface,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.surface.opaque(0.3), theme.primary.opaque(0.4)],
              begin: begin,
              end: end,
            ),
          ),
          child: child,
        ),
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
      color: context.colors.primary.opaque(0.4, iReallyMeanIt: true),
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
      color: context.colors.primary
          .opaque(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.6),
      blurRadius: 59.0.multiplyBlur(),
      spreadRadius: 1.0.multiplyGlow(),
      offset: const Offset(-1.0, 0),
    );
  }
}

Shimmer placeHolderWidget(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: context.colors.surfaceContainer,
    highlightColor: context.colors.primary,
    child: Container(
      width: 80,
      height: 80,
      color: context.colors.secondaryContainer,
    ),
  );
}
