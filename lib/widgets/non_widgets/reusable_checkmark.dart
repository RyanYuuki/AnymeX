import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
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
  var didSelectItem = false;

  showDialog(
    context: context,
    builder: (context) {
      return Obx(() {
        final currentSelected = selectedItem.value;
        return AnymeXDialog(
          title: title,
          showCancelButton: false,
          confirmText: 'Close',
          onConfirm: () {},
          contentWidget: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: AnymeXTileBuilder<T>(
              items: items,
              selectedItem: currentSelected,
              getTitle: getTitle,
              lazy: true,
              onItemPressed: (item) {
                if (didSelectItem) return;
                didSelectItem = true;
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onItemSelected(item);
                });
              },
            ),
          ),
        );
      });
    },
  );
}
