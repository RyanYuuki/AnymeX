import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

enum TextVariant { regular, semiBold, bold }

class AnymexText extends StatelessWidget {
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

  const AnymexText({
    super.key,
    required this.text,
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
  });

  const AnymexText.regular({
    Key? key,
    required String text,
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
  }) : this(
          key: key,
          text: text,
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
        );

  const AnymexText.semiBold({
    Key? key,
    required String text,
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
  }) : this(
          key: key,
          text: text,
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
        );

  const AnymexText.bold({
    Key? key,
    required String text,
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
  }) : this(
          key: key,
          text: text,
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
        );

  @override
  Widget build(BuildContext context) {
    final fontFamily = switch (variant) {
      TextVariant.semiBold => "Poppins-SemiBold",
      TextVariant.bold => "Poppins-Bold",
      _ => "Poppins",
    };

    final processedText = stripHtml ? _removeHtmlTags(text) : text;

    final textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: size ?? 14.0,
      color: color,
      fontStyle: fontStyle,
    );

    if (!autoResize) {
      return Text(
        processedText,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        style: textStyle,
      );
    }

    return AutoSizeText(
      processedText,
      textAlign: textAlign,
      maxLines: maxLines,
      minFontSize: minFontSize ?? 10,
      stepGranularity: stepGranularity ?? 1,
      overflow: overflow,
      style: textStyle,
    );
  }

  String _removeHtmlTags(String input) {
    return input.replaceAll(RegExp(r"<[^>]*>"), "").trim();
  }
}
