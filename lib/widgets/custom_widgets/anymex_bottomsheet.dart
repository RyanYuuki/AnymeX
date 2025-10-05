import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnymexSheet extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? contentWidget;
  final Widget? customWidget;

  const AnymexSheet({
    super.key,
    this.title,
    this.message,
    this.contentWidget,
    this.customWidget,
  });

  static void custom(Widget widget, BuildContext context) => AnymexSheet(
        customWidget: widget,
      ).show(context);

  void show(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      // backgroundColor: settingsController.liquidMode
      //     ? Colors.transparent
      //     : context.theme.colorScheme.surface,
      backgroundColor: context.theme.colorScheme.surface,
      builder: (context) => AnymexSheet(
        title: title,
        message: message,
        contentWidget: contentWidget,
        customWidget: customWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final useBlur = settingsController.liquidMode;
    final useBlur = false;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Stack(
        children: [
          if (useBlur)
            Positioned.fill(
                child: Blur(
                    blur: 30,
                    colorOpacity: 0.05,
                    blurColor: context.theme.colorScheme.primary,
                    child: Container())),
          if (customWidget != null)
            customWidget!
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  AnymexText(text: title!, size: 18, variant: TextVariant.bold),
                  const SizedBox(height: 10),
                ],
                contentWidget ??
                    (message != null
                        ? AnymexText(
                            text: message!,
                            textAlign: TextAlign.center,
                            size: 14)
                        : const SizedBox.shrink()),
              ],
            ),
        ],
      ),
    );
  }
}
