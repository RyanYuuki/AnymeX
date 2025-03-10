import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCustomDialog({
  required BuildContext context,
  required String title,
  required List<String> buttonTitles,
  required List<VoidCallback> onTapActions,
}) {
  assert(buttonTitles.length == onTapActions.length,
      "Each button must have a corresponding onTap action");

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnymexText(
              text: title,
              variant: TextVariant.bold,
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(buttonTitles.length, (index) {
                return _buildButton(
                  context,
                  buttonTitles[index],
                  onTapActions[index],
                );
              }),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildButton(BuildContext context, String title, VoidCallback onTap) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    onPressed: () {
      Get.back();
      onTap();
    },
    child: Text(title),
  );
}
