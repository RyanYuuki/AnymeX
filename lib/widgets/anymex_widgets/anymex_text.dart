import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

enum TextVariant { regular, semiBold, bold }

class AnymeXText extends StatelessWidget {
  final String text;
  final TextVariant variant;
  final Color? color;
  final double? size;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final FontStyle fontStyle;
  final bool stripHtml;
  final bool autoResize;
  final double? minFontSize;
  final double? stepGranularity;
  final bool isMarquee;
  final TextStyle? style;
  final bool? softWrap;

  const AnymeXText(
    this.text, {
    super.key,
    this.variant = TextVariant.regular,
    this.color,
    this.size,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 2,
    this.fontStyle = FontStyle.normal,
    this.stripHtml = false,
    this.autoResize = false,
    this.minFontSize = 10,
    this.stepGranularity = 1,
    this.isMarquee = false,
    this.style,
    this.softWrap,
  });

  const AnymeXText.regular(
    String text, {
    Key? key,
    Color? color,
    double? size,
    TextAlign? textAlign,
    TextOverflow? overflow = TextOverflow.ellipsis,
    int? maxLines = 2,
    FontStyle fontStyle = FontStyle.normal,
    bool stripHtml = false,
    bool autoResize = false,
    double? minFontSize = 10,
    double? stepGranularity = 1,
    bool isMarquee = false,
    TextStyle? style,
    bool? softWrap,
  }) : this(
          text,
          key: key,
          variant: TextVariant.regular,
          color: color,
          size: size,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          fontStyle: fontStyle,
          stripHtml: stripHtml,
          autoResize: autoResize,
          minFontSize: minFontSize,
          stepGranularity: stepGranularity,
          isMarquee: isMarquee,
          style: style,
          softWrap: softWrap,
        );

  const AnymeXText.semiBold(
    String text, {
    Key? key,
    Color? color,
    double? size,
    TextAlign? textAlign,
    TextOverflow? overflow = TextOverflow.ellipsis,
    int? maxLines = 2,
    FontStyle fontStyle = FontStyle.normal,
    bool stripHtml = false,
    bool autoResize = false,
    double? minFontSize = 10,
    double? stepGranularity = 1,
    bool isMarquee = false,
    TextStyle? style,
    bool? softWrap,
  }) : this(
          text,
          key: key,
          variant: TextVariant.semiBold,
          color: color,
          size: size,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          fontStyle: fontStyle,
          stripHtml: stripHtml,
          autoResize: autoResize,
          minFontSize: minFontSize,
          stepGranularity: stepGranularity,
          isMarquee: isMarquee,
          style: style,
          softWrap: softWrap,
        );

  const AnymeXText.bold(
    String text, {
    Key? key,
    Color? color,
    double? size,
    TextAlign? textAlign,
    TextOverflow? overflow = TextOverflow.ellipsis,
    int? maxLines = 2,
    FontStyle fontStyle = FontStyle.normal,
    bool stripHtml = false,
    bool autoResize = false,
    double? minFontSize = 10,
    double? stepGranularity = 1,
    bool isMarquee = false,
    TextStyle? style,
    bool? softWrap,
  }) : this(
          text,
          key: key,
          variant: TextVariant.bold,
          color: color,
          size: size,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          fontStyle: fontStyle,
          stripHtml: stripHtml,
          autoResize: autoResize,
          minFontSize: minFontSize,
          stepGranularity: stepGranularity,
          isMarquee: isMarquee,
          style: style,
          softWrap: softWrap,
        );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final processedText = stripHtml ? _removeHtmlTags(text) : text;
      final textStyle = _resolveStyle();
      final effectiveMaxLines = isMarquee ? 1 : maxLines;

      if (isMarquee) {
        return MarqueeText(
          processedText,
          style: textStyle,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: effectiveMaxLines,
        );
      }

      if (!autoResize) {
        return Text(
          processedText,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: effectiveMaxLines,
          style: textStyle,
          softWrap: softWrap,
        );
      }

      return AutoSizeText(
        processedText,
        textAlign: textAlign,
        maxLines: effectiveMaxLines,
        minFontSize: minFontSize ?? 10,
        stepGranularity: stepGranularity ?? 1,
        overflow: overflow,
        style: textStyle,
        softWrap: softWrap,
      );
    });
  }

  TextStyle _resolveStyle() {
    final baseSize = size ?? style?.fontSize ?? 14.0;
    final baseColor = color ?? style?.color;
    final baseFontStyle = style?.fontStyle ?? fontStyle;

    final customFamily = settingsController.appFontFamily;
    if (customFamily.isNotEmpty) {
      if (customFamily == 'System') {
        final base = TextStyle(
          fontSize: baseSize,
          color: baseColor,
          fontStyle: baseFontStyle,
        );
        return style != null ? base.merge(style) : base;
      }
      if (customFamily == 'Google Sans') {
        final base = TextStyle(
          fontFamily: 'Google Sans',
          fontSize: baseSize,
          color: baseColor,
          fontStyle: baseFontStyle,
        );
        return style != null
            ? base.merge(style).copyWith(fontFamily: 'Google Sans')
            : base;
      }
      if (customFamily == 'SF Pro') {
        final base = TextStyle(
          fontFamily: 'SF Pro',
          fontSize: baseSize,
          color: baseColor,
          fontStyle: baseFontStyle,
        );
        return style != null
            ? base.merge(style).copyWith(fontFamily: 'SF Pro')
            : base;
      }
      final weight = style?.fontWeight ??
          switch (variant) {
            TextVariant.bold => FontWeight.w700,
            TextVariant.semiBold => FontWeight.w600,
            _ => FontWeight.w400,
          };
      try {
        final gFont = GoogleFonts.getFont(
          customFamily,
          fontSize: baseSize,
          color: baseColor,
          fontStyle: baseFontStyle,
          fontWeight: weight,
        );

        return style != null
            ? gFont.merge(style).copyWith(fontFamily: gFont.fontFamily)
            : gFont;
      } catch (_) {}
    }

    final builtInFamily = switch (variant) {
      TextVariant.semiBold => 'Poppins-SemiBold',
      TextVariant.bold => 'Poppins-Bold',
      _ => 'Poppins',
    };

    final base = TextStyle(
      fontFamily: builtInFamily,
      fontSize: baseSize,
      color: baseColor,
      fontStyle: baseFontStyle,
    );

    return style != null ? base.merge(style) : base;
  }

  String _removeHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
