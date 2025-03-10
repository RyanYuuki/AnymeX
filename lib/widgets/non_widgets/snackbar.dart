import 'dart:io';

import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void snackBar(
  String message, {
  int duration = 2000,
  String? title,
  Color? backgroundColor,
  SnackPosition? snackPosition,
  double? maxWidth,
  int? maxLines = 3,
}) {
  final isMobile = Platform.isAndroid || Platform.isIOS;
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
    maxWidth: maxWidth ?? Get.width * (isMobile ? 0.9 : 0.6),
  );
}
