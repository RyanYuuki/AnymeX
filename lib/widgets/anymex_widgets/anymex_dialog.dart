import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';

class AnymeXDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? contentWidget;
  final VoidCallback onConfirm;
  final bool enableV2;
  final EdgeInsets padding;
  final bool showCancelButton;
  final String confirmText;
  final bool translucent;
  final dynamic Function()? confirmResultGetter;
  final bool forceAction;
  final bool isConfirmEnabled;
  final VoidCallback? onCancel;
  final dynamic Function()? cancelResultGetter;
  final String cancelText;

  const AnymeXDialog({
    super.key,
    this.title,
    this.message,
    this.contentWidget,
    required this.onConfirm,
    this.enableV2 = false,
    this.padding = const EdgeInsets.all(24),
    this.showCancelButton = true,
    this.confirmText = 'Confirm',
    this.translucent = true,
    this.confirmResultGetter,
    this.forceAction = false,
    this.isConfirmEnabled = true,
    this.onCancel,
    this.cancelResultGetter,
    this.cancelText = 'Cancel',
  });

  void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !forceAction,
      builder: (context) => AnymeXDialog(
        title: title,
        message: message,
        contentWidget: contentWidget,
        onConfirm: onConfirm,
        translucent: translucent,
        showCancelButton: showCancelButton,
        confirmText: confirmText,
        forceAction: forceAction,
        isConfirmEnabled: isConfirmEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = 24.multiplyRadius();
    final buttonRadius = 16.multiplyRadius();

    return PopScope(
        canPop: !forceAction,
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (!forceAction) {
                    Navigator.of(context).pop();
                  }
                },
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: getResponsiveValue(
                        context,
                        mobileValue: Get.width * 0.8,
                        desktopValue: 400.0,
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                      ),
                      decoration: BoxDecoration(
                        color: translucent
                            ? context.colors.surfaceContainer.withOpacity(0.5)
                            : context.colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: context.colors.onSurface.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: translucent ? 20 : 0,
                            sigmaY: translucent ? 20 : 0,
                          ),
                          child: Padding(
                            padding: padding,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (title != null) ...[
                                  AnymeXText(
                                    text: title!,
                                    size: 20,
                                    variant: TextVariant.semiBold,
                                    color: context.colors.onSurface,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Flexible(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: message != null
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: AnymeXText(
                                              text: message!,
                                              size: 14,
                                              color:
                                                  context.colors.onSurfaceVariant,
                                              textAlign: TextAlign.center,
                                              maxLines: 100,
                                            ),
                                          )
                                        : (contentWidget ??
                                            const SizedBox.shrink()),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    if (showCancelButton) ...[
                                      Expanded(
                                        child: AnymexOnTap(
                                          onTap: () {
                                            final result = cancelResultGetter?.call();
                                            Get.back(result: result);
                                            onCancel?.call();
                                          },
                                          scale: 0.95,
                                          child: Container(
                                            height: 48,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: context
                                                  .colors.surfaceContainerHighest,
                                              borderRadius: BorderRadius.horizontal(
                                                right: const Radius.circular(2),
                                                left: Radius.circular(buttonRadius),
                                              ),
                                              border: Border.all(
                                                color: context.colors.onSurface
                                                    .withOpacity(0.04),
                                                width: 1,
                                              ),
                                            ),
                                            child: AnymeXText(
                                              text: cancelText,
                                              size: 14,
                                              color: context.colors.onSurface,
                                              variant: TextVariant.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: AnymexOnTap(
                                        onTap: isConfirmEnabled
                                            ? () {
                                                final result =
                                                    confirmResultGetter?.call();
                                                Get.back(result: result);
                                                onConfirm.call();
                                              }
                                            : () {},
                                        scale: 0.95,
                                        child: Container(
                                          height: 48,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isConfirmEnabled
                                                ? context.colors.primary
                                                : context.colors.surfaceContainerHighest.withOpacity(0.4),
                                            borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(showCancelButton
                                                  ? 2
                                                  : buttonRadius),
                                              right: Radius.circular(buttonRadius),
                                            ),
                                            boxShadow: isConfirmEnabled
                                                ? [
                                                    BoxShadow(
                                                      color: context.colors.primary
                                                          .withOpacity(0.15),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: AnymeXText(
                                            text: confirmText,
                                            size: 14,
                                            color: isConfirmEnabled
                                                ? context.colors.onPrimary
                                                : context.colors.onSurface.withOpacity(0.4),
                                            variant: TextVariant.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )));
  }
}
