import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class AnymexTextSpan {
  final String text;
  final TextVariant variant;
  final Color? color;
  final double? size;

  const AnymexTextSpan({
    required this.text,
    this.variant = TextVariant.regular,
    this.color,
    this.size,
  });
}

class AnymexTextSpans extends StatelessWidget {
  final List<AnymexTextSpan>? spans;
  final String? text;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? fontSize;

  const AnymexTextSpans({
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
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size ?? 14.0,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Text(
      text ?? "",
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: _getTextStyle(TextVariant.regular, context),
    );
  }
}
