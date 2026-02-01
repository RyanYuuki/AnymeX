import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';

extension ThemeModeExts on BuildContext {
  ColorScheme get colors => ColorScheme(
        primary: Theme.of(this).colorScheme.primary,
        onPrimary: Theme.of(this).colorScheme.onPrimary,
        primaryContainer: Theme.of(this).colorScheme.primaryContainer,
        onPrimaryContainer: Theme.of(this).colorScheme.onPrimaryContainer,
        primaryFixed: Theme.of(this).colorScheme.primaryFixed,
        primaryFixedDim: Theme.of(this).colorScheme.primaryFixedDim,
        onPrimaryFixed: Theme.of(this).colorScheme.onPrimaryFixed,
        onPrimaryFixedVariant: Theme.of(this).colorScheme.onPrimaryFixedVariant,
        secondary: Theme.of(this).colorScheme.secondary,
        onSecondary: Theme.of(this).colorScheme.onSecondary,
        secondaryContainer: Theme.of(this).colorScheme.secondaryContainer,
        onSecondaryContainer: Theme.of(this).colorScheme.onSecondaryContainer,
        secondaryFixed: Theme.of(this).colorScheme.secondaryFixed,
        secondaryFixedDim: Theme.of(this).colorScheme.secondaryFixedDim,
        onSecondaryFixed: Theme.of(this).colorScheme.onSecondaryFixed,
        onSecondaryFixedVariant:
            Theme.of(this).colorScheme.onSecondaryFixedVariant,
        tertiary: Theme.of(this).colorScheme.tertiary,
        onTertiary: Theme.of(this).colorScheme.onTertiary,
        tertiaryContainer: Theme.of(this).colorScheme.tertiaryContainer,
        onTertiaryContainer: Theme.of(this).colorScheme.onTertiaryContainer,
        tertiaryFixed: Theme.of(this).colorScheme.tertiaryFixed,
        tertiaryFixedDim: Theme.of(this).colorScheme.tertiaryFixedDim,
        onTertiaryFixed: Theme.of(this).colorScheme.onTertiaryFixed,
        onTertiaryFixedVariant:
            Theme.of(this).colorScheme.onTertiaryFixedVariant,
        error: Theme.of(this).colorScheme.error,
        onError: Theme.of(this).colorScheme.onError,
        errorContainer: Theme.of(this).colorScheme.errorContainer,
        onErrorContainer: Theme.of(this).colorScheme.onErrorContainer,
        surface: Theme.of(this).colorScheme.surface,
        onSurface: Theme.of(this).colorScheme.onSurface,
        surfaceDim: Theme.of(this).colorScheme.surfaceDim,
        surfaceBright: Theme.of(this).colorScheme.surfaceBright,
        surfaceContainerLowest:
            Theme.of(this).colorScheme.surfaceContainerLowest,
        surfaceContainerLow: Theme.of(this).colorScheme.surfaceContainerLow,
        surfaceContainer: Theme.of(this).colorScheme.surfaceContainer,
        surfaceContainerHigh: Theme.of(this).colorScheme.surfaceContainerHigh,
        surfaceContainerHighest:
            Theme.of(this).colorScheme.surfaceContainerHighest,
        onSurfaceVariant: Theme.of(this).colorScheme.onSurfaceVariant,
        outline: Theme.of(this).colorScheme.outline,
        outlineVariant: Theme.of(this).colorScheme.outlineVariant,
        shadow: Theme.of(this).colorScheme.shadow,
        scrim: Theme.of(this).colorScheme.scrim,
        inverseSurface: Theme.of(this).colorScheme.inverseSurface,
        onInverseSurface: Theme.of(this).colorScheme.onInverseSurface,
        inversePrimary: Theme.of(this).colorScheme.inversePrimary,
        background: Theme.of(this).colorScheme.background,
        onBackground: Theme.of(this).colorScheme.onBackground,
        surfaceVariant: Theme.of(this).colorScheme.surfaceVariant,
        brightness: Theme.of(this).colorScheme.brightness,
      );
}

extension ThemeExtensions on Color {
  Color opaque(double val, {bool iReallyMeanIt = false}) => withValues(alpha: iReallyMeanIt ? val : Get.isDarkMode ? val : 1);
}