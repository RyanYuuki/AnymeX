import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void snackBar(String message, {int duration = 700}) {
  Get.snackbar(
    "",
    "",
    titleText: const AnymexText(
      textAlign: TextAlign.center,
      text: 'AnymeX',
      variant: TextVariant.bold,
      size: 18,
    ),
    messageText: AnymexText(
      textAlign: TextAlign.center,
      text: message,
      size: 16,
    ),
    backgroundColor: Get.theme.colorScheme.surfaceContainer,
    duration: Duration(milliseconds: duration),
    snackPosition: SnackPosition.BOTTOM,
    maxWidth: 300,
  );
}
