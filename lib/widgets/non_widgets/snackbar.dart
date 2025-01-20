import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void snackBar(
  String message, {
  int duration = 700,
  String? title,
  Color? backgroundColor,
  SnackPosition? snackPosition,
  double? maxWidth,
  int? maxLines,
}) {
  Get.snackbar(
    "",
    "",
    titleText: AnymexText(
      textAlign: TextAlign.center,
      text: title ?? 'AnymeX',
      variant: TextVariant.bold,
      size: 18,
      maxLines: maxLines,
    ),
    messageText: AnymexText(
      textAlign: TextAlign.center,
      text: message,
      size: 16,
      maxLines: maxLines,
    ),
    backgroundColor: backgroundColor ?? Get.theme.colorScheme.surfaceContainer,
    duration: Duration(milliseconds: duration),
    snackPosition: snackPosition ?? SnackPosition.BOTTOM,
    maxWidth: maxWidth ?? Get.width * 0.6,
  );
}
