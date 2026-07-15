import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class AnymexSheet extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? contentWidget;
  final Widget? customWidget;
  final bool showDragHandle;

  const AnymexSheet({
    super.key,
    this.title,
    this.message,
    this.contentWidget,
    this.customWidget,
    this.showDragHandle = false,
  });

  static Future<T?> custom<T>(
    Widget widget,
    BuildContext context, {
    bool showDragHandle = false,
  }) =>
      AnymexSheet(
        customWidget: widget,
        showDragHandle: showDragHandle,
      ).show<T>(context);

  Future<T?> show<T>(
    BuildContext context,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AnymexSheet(
        title: title,
        message: message,
        contentWidget: contentWidget,
        customWidget: customWidget,
        showDragHandle: showDragHandle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle)
                Container(
                  width: 36,
                  height: 3.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              if (customWidget != null)
                customWidget!
              else ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
