import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';

class AnymexToast {
  static void show({
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final context = Get.context!;
    final colorScheme = context.colors;

    Get.showSnackbar(
      GetSnackBar(
        snackPosition:
            context.isPortrait ? SnackPosition.BOTTOM : SnackPosition.TOP,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: duration,
        messageText: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.opaque(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.opaque(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: AnymeXAnimatedLogo(
                        size: 28,
                        autoPlay: true,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  12.width(),
                  Flexible(
                    child: AnymexText(
                      text: message,
                      size: 13,
                      color: colorScheme.onSurface,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
