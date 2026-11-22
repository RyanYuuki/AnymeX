import 'dart:ui' as ui;
import 'package:anymex/controllers/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class DecoderQuickButton extends StatelessWidget {
  final bool isMobile;
  final bool _glass;
  final bool _netflix;
  final bool _ios26;

  const DecoderQuickButton({super.key, this.isMobile = false})
      : _glass = false,
        _netflix = false,
        _ios26 = false;

  const DecoderQuickButton.glass({super.key, this.isMobile = false})
      : _glass = true,
        _netflix = false,
        _ios26 = false;

  const DecoderQuickButton.netflix({super.key, this.isMobile = false})
      : _glass = false,
        _netflix = true,
        _ios26 = false;

  const DecoderQuickButton.ios26({super.key, this.isMobile = false})
      : _glass = false,
        _netflix = false,
        _ios26 = true;

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

      if (_ios26) {
        return Tooltip(
          message: '${_label(current)} → ${_label(_next(current))}',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              settings.hardwareDecoder = _next(current);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x66181818),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: AnymeXText(
                    _label(current),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

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
            child: AnymeXText(_label(current), style: style),
          ),
        ),
      );
    });
  }
}
