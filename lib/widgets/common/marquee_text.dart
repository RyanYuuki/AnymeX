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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
        final textSpan = TextSpan(text: text, style: effectiveStyle);
        final textScaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final effectiveMaxLines = maxLines ?? 1;

        // not to overflow
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: effectiveMaxLines,
          textDirection: direction,
          textScaler: textScaler,
        )..layout(
            maxWidth: constraints.maxWidth > 0
                ? constraints.maxWidth
                : double.infinity,
          );

        final bool shouldScroll = textPainter.didExceedMaxLines ||
            (effectiveMaxLines == 1 &&
                constraints.maxWidth > 0 &&
                textPainter.width > constraints.maxWidth);

        if (shouldScroll) {
         
          final singleLinePainter = TextPainter(
            text: textSpan,
            maxLines: 1,
            textDirection: direction,
            textScaler: textScaler,
          )..layout();

          return SizedBox(
            height: singleLinePainter.height,
            width: constraints.maxWidth,
            child: Marquee(
              text: text,
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
          height: textPainter.height,
          width: constraints.maxWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
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
