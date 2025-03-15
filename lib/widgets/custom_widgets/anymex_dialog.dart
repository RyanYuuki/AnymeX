import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnymexDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? contentWidget;
  final VoidCallback onConfirm;
  final bool enableV2;
  final EdgeInsets padding;

  const AnymexDialog({
    super.key,
    required this.title,
    this.message,
    this.contentWidget,
    required this.onConfirm,
    this.enableV2 = false,
    this.padding = const EdgeInsets.all(25),
  });

  void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AnymexDialog(
        title: title,
        message: message,
        contentWidget: contentWidget,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: getResponsiveValue(context,
            mobileValue: double.infinity, desktopValue: 500.0),
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            message != null
                ? AnymexText(
                    text: message!, textAlign: TextAlign.center, size: 14)
                : contentWidget ?? const SizedBox.shrink(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: AnymexText(
                        text: 'Cancel',
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                        variant: TextVariant.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      onConfirm.call();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryFixed,
                    ),
                    child: const AnymexText(
                        text: 'Confirm',
                        size: 14,
                        color: Colors.black,
                        variant: TextVariant.bold),
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
// class AnymexDialog extends StatelessWidget {
//   final String title;
//   final String? message;
//   final Widget? contentWidget;
//   final String confirmText;
//   final String cancelText;
//   final VoidCallback? onConfirm;
//   final VoidCallback? onCancel;
//   final bool enableV2;

//   const AnymexDialog({
//     super.key,
//     required this.title,
//     this.message,
//     this.contentWidget,
//     this.confirmText = "OK",
//     this.cancelText = "Cancel",
//     this.onConfirm,
//     this.onCancel,
//     this.enableV2 = false,
//   });

//   void show(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AnymexDialog(
//         title: title,
//         message: message,
//         contentWidget: contentWidget,
//         confirmText: confirmText,
//         cancelText: cancelText,
//         onConfirm: onConfirm,
//         onCancel: onCancel,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AnymexText(text: title, size: 18, variant: TextVariant.bold),
//             const SizedBox(height: 10),
//             contentWidget ??
//                 (message != null
//                     ? AnymexText(
//                         text: message!, textAlign: TextAlign.center, size: 14)
//                     : const SizedBox.shrink()),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: () {
//                     if (onCancel != null) onCancel!();
//                     Navigator.of(context).pop();
//                   },
//                   child: Text(cancelText),
//                 ),
//                 InkWell(
//                   onTap: () {
//                     if (onConfirm != null) onConfirm!();
//                     Navigator.of(context).pop();
//                   },
//                   child: AnymexText(
//                     text: confirmText,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
