import 'package:flutter/material.dart';

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      content: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}
