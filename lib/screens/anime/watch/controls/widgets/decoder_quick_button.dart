import 'package:anymex/controllers/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DecoderQuickButton extends StatelessWidget {
  final bool isMobile;
  final bool _glass;
  final bool _netflix;

  const DecoderQuickButton({super.key, this.isMobile = false})
      : _glass = false,
        _netflix = false;

  const DecoderQuickButton.glass({super.key, this.isMobile = false})
      : _glass = true,
        _netflix = false;

  const DecoderQuickButton.netflix({super.key, this.isMobile = false})
      : _glass = false,
        _netflix = true;

  String _next(String current) {
    return switch (current) {
      'hw' => 'hw+',
      'hw+' => 'sw',
      _ => 'hw',
    };
  }

  String _label(String v) => switch (v) {
        'hw+' => 'HW+',
        'hw' => 'HW',
        'sw' => 'SW',
        _ => v.toUpperCase(),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = Get.find<Settings>();

    return Obx(() {
      final current = settings.hardwareDecoder;

      final Color bg;
      final Border? border;
      final double radius;
      final EdgeInsets pad;
      final TextStyle? style;

      if (_glass) {
        bg = const Color(0x24FFFFFF);
        border = Border.all(color: const Color(0x40FFFFFF));
        radius = 12;
        pad = const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
        style = const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);
      } else if (_netflix) {
        bg = const Color(0x99000000);
        border = Border.all(color: const Color(0x66FFFFFF));
        radius = 8;
        pad = const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
        style = const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2);
      } else {
        bg = isDark
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.15)
            : theme.colorScheme.secondaryContainer;
        border = null;
        radius = isMobile ? 8.0 : 12.0;
        pad = EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12, vertical: isMobile ? 2 : 4);
        final color = isDark
            ? theme.colorScheme.secondary
            : theme.colorScheme.onSecondaryContainer;
        style =
            (isMobile ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : null);
      }

      return Tooltip(
        message: '${_label(current)} → ${_label(_next(current))}',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            settings.hardwareDecoder = _next(current);
          },
          child: Container(
            padding: pad,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: border,
            ),
            child: Text(_label(current), style: style),
          ),
        ),
      );
    });
  }
}
