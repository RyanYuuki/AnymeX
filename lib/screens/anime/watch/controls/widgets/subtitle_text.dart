import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:outlined_text/outlined_text.dart';

class SubtitleText extends StatelessWidget {
  final PlayerController controller;
  const SubtitleText({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.subtitleText.isEmpty
        ? const SizedBox.shrink()
        : AnimatedPositioned(
            right: 0,
            left: 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: controller.showControls.value
                ? 100
                : (30 + controller.settings.bottomMargin),
            child: IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: controller.subtitleText[0].isEmpty ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: controller.subtitleText[0].isEmpty
                          ? Colors.transparent
                          : colorOptions[
                              controller.settings.subtitleBackgroundColor],
                      borderRadius: BorderRadius.circular(12.multiplyRadius()),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        final fade =
                            FadeTransition(opacity: animation, child: child);
                        final slide = SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: fade,
                        );
                        return slide;
                      },
                      child: OutlinedText(
                        key: ValueKey(controller.subtitleText.join()),
                        text: Text(
                          [
                            for (final line in controller.subtitleText)
                              if (line.trim().isNotEmpty) line.trim(),
                          ].join('\n'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: fontColorOptions[
                                controller.settings.subtitleColor],
                            fontSize:
                                controller.settings.subtitleSize.toDouble(),
                            fontFamily: "Poppins-Bold",
                          ),
                        ),
                        strokes: [
                          OutlinedTextStroke(
                            color: fontColorOptions[
                                controller.settings.subtitleOutlineColor]!,
                            width: controller.settings.subtitleOutlineWidth
                                .toDouble(),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ));
  }
}
