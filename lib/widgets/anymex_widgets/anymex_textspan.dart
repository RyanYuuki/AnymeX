import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AnymeXTextSpan {
  final String text;
  final TextVariant variant;
  final Color? color;
  final double? size;

  const AnymeXTextSpan({
    required this.text,
    this.variant = TextVariant.regular,
    this.color,
    this.size,
  });
}

class AnymeXTextSpans extends StatelessWidget {
  final List<AnymeXTextSpan>? spans;
  final String? text;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? fontSize;

  const AnymeXTextSpans({
    super.key,
    this.spans,
    this.text,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 2,
    this.fontSize,
  }) : assert(spans != null || text != null,
            "Either 'spans' or 'text' must be provided.");

  TextStyle _getTextStyle(TextVariant variant, BuildContext context,
      {Color? color, double? size}) {
    final baseSize = size ?? fontSize ?? 14.0;
    final baseColor = color ?? Theme.of(context).textTheme.bodyMedium?.color;

    final customFamily = settingsController.appFontFamily;
    if (customFamily.isNotEmpty) {
      if (customFamily == 'System') {
        return TextStyle(
          fontSize: baseSize,
          color: baseColor,
        );
      }
      if (customFamily == 'Google Sans') {
        return TextStyle(
          fontFamily: 'Google Sans',
          fontSize: baseSize,
          color: baseColor,
        );
      }
      if (customFamily == 'SF Pro') {
        return TextStyle(
          fontFamily: 'SF Pro',
          fontSize: baseSize,
          color: baseColor,
        );
      }
      final weight = switch (variant) {
        TextVariant.bold => FontWeight.w700,
        TextVariant.semiBold => FontWeight.w600,
        _ => FontWeight.w400,
      };
      try {
        return GoogleFonts.getFont(
          customFamily,
          fontSize: baseSize,
          color: baseColor,
          fontWeight: weight,
        );
      } catch (_) {}
    }

    final fontFamily = switch (variant) {
      TextVariant.semiBold => 'Poppins-SemiBold',
      TextVariant.bold => 'Poppins-Bold',
      _ => 'Poppins',
    };

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: baseSize,
      color: baseColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (spans != null && spans!.isNotEmpty) {
        return RichText(
          textAlign: textAlign ?? TextAlign.start,
          maxLines: maxLines,
          overflow: overflow ?? TextOverflow.ellipsis,
          text: TextSpan(
            children: spans!.map((span) {
              return TextSpan(
                text: span.text,
                style: _getTextStyle(
                  span.variant,
                  context,
                  color: span.color,
                  size: fontSize,
                ),
              );
            }).toList(),
          ),
        );
      }

      return AnymeXText(
        text ?? "",
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        style: _getTextStyle(TextVariant.regular, context),
      );
    });
  }
}
