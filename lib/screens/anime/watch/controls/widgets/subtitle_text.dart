import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:outlined_text/outlined_text.dart';

class SubtitleText extends StatelessWidget {
  final PlayerController controller;
  const SubtitleText({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final subtitleAnimation = controller.settings.transitionSubtitle;
    const animDuration = Duration(milliseconds: 200);
    const switchDuration = Duration(milliseconds: 250);

    return Obx(() {
      if (controller.subtitleText.isEmpty) return const SizedBox.shrink();

      final htmlRx = RegExp(r'<[^>]*>');
      final assRx = RegExp(r'\{[^}]*\}');
      final newlineRx = RegExp(r'\\[nN]');

      final bottomPosition = controller.showControls.value
          ? 100
          : (30 + controller.playerSettings.subtitleBottomMargin);

      final useTranslation = controller.playerSettings.autoTranslate &&
          controller.translatedSubtitle.value.isNotEmpty;

      final subtitle = useTranslation
          ? controller.translatedSubtitle.value
          : [
              for (final line in controller.subtitleText)
                if (line.trim().isNotEmpty) line.trim(),
            ].join('\n');

      final sanitizedSubtitle = subtitle
          .replaceAll(htmlRx, '')
          .replaceAll(assRx, '')
          .replaceAll(newlineRx, '\n')
          .trim();

      if (sanitizedSubtitle.isEmpty) return const SizedBox.shrink();

      final String outlineType = controller.playerSettings.subtitleOutlineType;
      final double outlineWidth =
          controller.settings.subtitleOutlineWidth.toDouble();
      final Color outlineColorVal =
          fontColorOptions[controller.settings.subtitleOutlineColor] ??
              Colors.black;

      List<OutlinedTextStroke> strokes = [];
      if (outlineType == "Outline") {
        strokes = [
          OutlinedTextStroke(color: outlineColorVal, width: outlineWidth)
        ];
      } else if (outlineType == "Drop Shadow") {
        strokes = [
          OutlinedTextStroke(color: outlineColorVal, width: outlineWidth)
        ];
      }

      Widget content = OutlinedText(
        key: ValueKey(controller.subtitleText.join()),
        text: Text(
          sanitizedSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fontColorOptions[controller.settings.subtitleColor],
            fontSize: controller.settings.subtitleSize.toDouble(),
            fontFamily: controller.playerSettings.subtitleFont == 'Default'
                ? 'Poppins'
                : controller.playerSettings.subtitleFont == 'Anime Ace 3'
                    ? 'AnimeAce'
                    : controller.playerSettings.subtitleFont,
            fontWeight: FontWeight.bold,
          ),
        ),
        strokes: strokes,
      );

      if (outlineType == "Drop Shadow") {
        final off = outlineWidth;
        content = Stack(alignment: Alignment.center, children: [
          Positioned(
            top: off,
            left: off,
            child: Text(
              sanitizedSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: outlineColorVal,
                fontSize: controller.settings.subtitleSize.toDouble(),
                fontFamily: controller.playerSettings.subtitleFont == 'Default'
                    ? 'Poppins'
                    : controller.playerSettings.subtitleFont == 'Anime Ace 3'
                        ? 'AnimeAce'
                        : controller.playerSettings.subtitleFont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            sanitizedSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fontColorOptions[controller.settings.subtitleColor],
              fontSize: controller.settings.subtitleSize.toDouble(),
              fontFamily: controller.playerSettings.subtitleFont == 'Default'
                  ? 'Poppins'
                  : controller.playerSettings.subtitleFont == 'Anime Ace 3'
                      ? 'AnimeAce'
                      : controller.playerSettings.subtitleFont,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]);
      } else if (outlineType == "Shine") {
        content = Stack(alignment: Alignment.center, children: [
          OutlinedText(
            text: Text(
              sanitizedSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fontColorOptions[controller.settings.subtitleColor],
                fontSize: controller.settings.subtitleSize.toDouble(),
                fontFamily: controller.playerSettings.subtitleFont == 'Default'
                    ? 'Poppins'
                    : controller.playerSettings.subtitleFont == 'Anime Ace 3'
                        ? 'AnimeAce'
                        : controller.playerSettings.subtitleFont,
                fontWeight: FontWeight.bold,
              ),
            ),
            strokes: [
              OutlinedTextStroke(
                  color: outlineColorVal.withOpacity(0.5),
                  width: outlineWidth + 2)
            ],
          ),
          Text(
            sanitizedSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fontColorOptions[controller.settings.subtitleColor],
              fontSize: controller.settings.subtitleSize.toDouble(),
              fontFamily: controller.playerSettings.subtitleFont == 'Default'
                  ? 'Poppins'
                  : controller.playerSettings.subtitleFont == 'Anime Ace 3'
                      ? 'AnimeAce'
                      : controller.playerSettings.subtitleFont,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]);
      }

      final subtitleBox = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: controller.subtitleText[0].isEmpty
              ? Colors.transparent
              : colorOptions[controller.settings.subtitleBackgroundColor],
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
        ),
        child: subtitleAnimation
            ? AnimatedSwitcher(
                duration: switchDuration,
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  final fade = FadeTransition(opacity: animation, child: child);
                  final slide = SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: fade,
                  );
                  return slide;
                },
                child: content,
              )
            : content,
      );

      final baseOpacity = controller.subtitleText[0].isEmpty ? 0.0 : 1.0;
      final finalOpacity =
          baseOpacity * controller.playerSettings.subtitleOpacity;

      final opacityWidget = subtitleAnimation
          ? AnimatedOpacity(
              opacity: finalOpacity,
              duration: animDuration,
              curve: Curves.easeInOut,
              child: subtitleBox,
            )
          : Opacity(
              opacity: finalOpacity,
              child: subtitleBox,
            );

      final positionWidget = subtitleAnimation
          ? AnimatedPositioned(
              right: 0,
              left: 0,
              duration: animDuration,
              curve: Curves.easeInOut,
              bottom: bottomPosition.toDouble(),
              child: IgnorePointer(
                ignoring: true,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: opacityWidget,
                ),
              ),
            )
          : Positioned(
              right: 0,
              left: 0,
              bottom: bottomPosition.toDouble(),
              child: IgnorePointer(
                ignoring: true,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: opacityWidget,
                ),
              ),
            );

      return positionWidget;
    });
  }
}
