import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class AnymexDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? contentWidget;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const AnymexDialog({
    super.key,
    required this.title,
    this.message,
    this.contentWidget,
    this.confirmText = "OK",
    this.cancelText = "Cancel",
    this.onConfirm,
    this.onCancel,
  });

  static void show({
    required BuildContext context,
    required String title,
    String? message,
    Widget? contentWidget,
    String confirmText = "OK",
    String cancelText = "Cancel",
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => AnymexDialog(
        title: title,
        message: message,
        contentWidget: contentWidget,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnymexText(text: title, size: 18, variant: TextVariant.bold),
            const SizedBox(height: 10),
            contentWidget ??
                (message != null
                    ? AnymexText(
                        text: message!, textAlign: TextAlign.center, size: 14)
                    : const SizedBox.shrink()),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (onCancel != null) onCancel!();
                    Navigator.of(context).pop();
                  },
                  child: Text(cancelText),
                ),
                InkWell(
                  onTap: () {
                    if (onConfirm != null) onConfirm!();
                    Navigator.of(context).pop();
                  },
                  child: AnymexText(
                    text: confirmText,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
