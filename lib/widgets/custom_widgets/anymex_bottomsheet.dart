import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class AnymexSheet extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? contentWidget;

  const AnymexSheet({
    super.key,
    required this.title,
    this.message,
    this.contentWidget,
  });

  void show(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AnymexSheet(
        title: title,
        message: message,
        contentWidget: contentWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        ],
      ),
    );
  }
}
