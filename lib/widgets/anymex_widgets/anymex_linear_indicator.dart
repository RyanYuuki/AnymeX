import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class AnymeXLinearIndicator extends StatelessWidget {
  final double? value;
  final double? minHeight;
  final Color? backgroundColor;
  final Color? color;
  final double? waveAmplitude;
  final double? wavelength;
  final double? waveSpeed;

  const AnymeXLinearIndicator({
    super.key,
    this.value,
    this.minHeight,
    this.backgroundColor,
    this.color,
    this.waveAmplitude,
    this.wavelength,
    this.waveSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final stroke =
        minHeight != null ? (minHeight! > 5.0 ? 4.0 : minHeight!) : 4.0;
    final activeColor = color ?? Theme.of(context).colorScheme.primary;
    final track = backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final progress = value?.clamp(0.0, 1.0);
    final resolvedAmplitude = waveAmplitude ?? 1.0;
    final resolvedWavelength = wavelength ?? 25.0;
    final resolvedSpeed = waveSpeed ?? 20.0;

    final themeData = M3ETheme.of(context).copyWith(
      progressIndicatorTheme: M3EProgressIndicatorTheme(
        linear: M3ELinearProgressTheme(
          waveAmplitude: resolvedAmplitude,
          determinateWavelength: resolvedWavelength,
          indeterminateWavelength: resolvedWavelength,
          wavyContainerHeight: 18.0,
        ),
      ),
    );

    if (progress == null) {
      return M3ETheme(
        data: themeData,
        child: M3EProgressIndicator.linearWavy(
          value: null,
          color: activeColor,
          trackColor: track,
          strokeWidth: stroke,
          trackStrokeWidth: stroke,
          amplitude: 1.0,
          wavelength: resolvedWavelength,
          waveSpeed: resolvedSpeed,
        ),
      );
    }

    return M3ETheme(
      data: themeData,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          M3EProgressIndicator.linearWavy(
            value: 1.0,
            color: track,
            strokeWidth: stroke,
            trackStrokeWidth: stroke,
            stopSize: 0,
            amplitude: 1.0,
            amplitudeForProgress: (_) => 1.0,
            wavelength: resolvedWavelength,
            waveSpeed: resolvedSpeed,
          ),
          if (progress > 0)
            M3EProgressIndicator.linearWavy(
              value: progress,
              color: activeColor,
              showTrack: false,
              strokeWidth: stroke,
              trackStrokeWidth: stroke,
              stopSize: 0,
              amplitude: 1.0,
              amplitudeForProgress: (_) => 1.0,
              wavelength: resolvedWavelength,
              waveSpeed: resolvedSpeed,
            ),
        ],
      ),
    );
  }
}
