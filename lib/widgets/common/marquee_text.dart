import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  Alignment _alignmentForTextAlign(TextAlign? align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.justify:
      case TextAlign.left:
      case TextAlign.start:
      case null:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
        final effectiveMaxLines = maxLines ?? 1;
        final displayText = text.replaceAll('\n', ' ').trimRight();
        final hasBoundedWidth =
          constraints.hasBoundedWidth && constraints.maxWidth > 0;

        if (!hasBoundedWidth || effectiveMaxLines != 1 || displayText.isEmpty) {
          return Text(
            displayText,
            style: effectiveStyle,
            textAlign: textAlign,
            overflow: overflow ?? TextOverflow.ellipsis,
            maxLines: effectiveMaxLines,
          );
        }

        final textSpan = TextSpan(text: displayText, style: effectiveStyle);
        final textScaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);

        final intrinsicPainter = TextPainter(
          text: textSpan,
          maxLines: 1,
          textDirection: direction,
          textScaler: textScaler,
        )..layout(maxWidth: double.infinity);

        final availableWidth = constraints.maxWidth;
        final bool shouldScroll = intrinsicPainter.width >= availableWidth - 1.5;

        if (shouldScroll) {
          return SizedBox(
            height: intrinsicPainter.height,
            width: availableWidth,
            child: Marquee(
              text: displayText,
              style: effectiveStyle,
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 30.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 2),
              startPadding: 0.0,
              accelerationDuration: const Duration(milliseconds: 500),
              accelerationCurve: Curves.easeIn,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          );
        }

        return SizedBox(
          height: intrinsicPainter.height,
          width: availableWidth,
          child: Align(
            alignment: _alignmentForTextAlign(textAlign),
            child: Text(
              displayText,
              style: effectiveStyle,
              textAlign: textAlign,
              overflow: overflow ?? TextOverflow.ellipsis,
              maxLines: effectiveMaxLines,
            ),
          ),
        );
      },
    );
  }
}
