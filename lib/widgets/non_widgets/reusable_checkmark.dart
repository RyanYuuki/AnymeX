import 'package:anymex/widgets/common/checkmark_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSelectionDialog<T>({
  required String title,
  required List<T> items,
  required Rx<T> selectedItem,
  required String Function(T) getTitle,
  required Function(T) onItemSelected,
  IconData? leadingIcon,
}) {
  final context = Get.context!;
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: getResponsiveValue(
            context,
            mobileValue: null,
            desktopValue: 500.0,
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                child: Column(
                  children: items
                      .map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          child: ListTileWithCheckMark(
                            leading:
                                leadingIcon != null ? Icon(leadingIcon) : null,
                            color: Theme.of(context).colorScheme.primary,
                            active: item == selectedItem.value,
                            title: getTitle(item),
                            onTap: () {
                              onItemSelected(item);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}
