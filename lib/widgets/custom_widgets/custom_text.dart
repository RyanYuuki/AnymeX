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
  });

  @override
  Widget build(BuildContext context) {
    String fontFamily;

    switch (variant) {
      case TextVariant.semiBold:
        fontFamily = "Poppins-SemiBold";
        break;
      case TextVariant.bold:
        fontFamily = "Poppins-Bold";
        break;
      case TextVariant.regular:
      default:
        fontFamily = "Poppins";
    }

    String processedText = stripHtml ? _removeHtmlTags(text) : text;

    return Text(
      processedText,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: size ?? 14.0,
        color: color,
        fontStyle: fontStyle,
      ),
    );
  }

  String _removeHtmlTags(String input) {
    return input.replaceAll(RegExp(r"<[^>]*>"), "").trim();
  }
}
