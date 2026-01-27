import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'extension_test_item.dart';

class ExtensionTestController extends GetxController {
  var extensionType = Rx<ItemType>(ItemType.anime);
  var testType = Rx<String>('basic');
  var searchQuery = RxString('Chainsaw Man');
  var selectedExtensions = RxList<String>();
  var testResults = RxList<ExtensionTestResultItem>();

  Future<void> startTests() async {
    testResults.clear();
    final sourceController = Get.find<SourceController>();
    final extensions = selectedExtensions.toList();
    final itemKeys = <GlobalKey<ExtensionTestResultItemState>>[];

    for (final extensionName in extensions) {
      Source? source;
      switch (extensionType.value) {
        case ItemType.anime:
          source = sourceController.installedExtensions
              .firstWhereOrNull((e) => e.name == extensionName);
          break;
        case ItemType.manga:
          source = sourceController.installedMangaExtensions
              .firstWhereOrNull((e) => e.name == extensionName);
          break;
        case ItemType.novel:
          source = sourceController.installedNovelExtensions
              .firstWhereOrNull((e) => e.name == extensionName);
          break;
      }
      if (source != null) {
        final key = GlobalKey<ExtensionTestResultItemState>();
        itemKeys.add(key);
        final testItem = ExtensionTestResultItem(
          key: key,
          source: source,
          itemType: extensionType.value,
          testType: testType.value,
          searchQuery: searchQuery.value,
          autostart: false,
        );
        testResults.add(testItem);
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));

    for (final key in itemKeys) {
      final state = key.currentState;
      if (state != null) {
        await state.startTest();
      }
    }
  }

  void toggleExtension(String extensionName, bool isSelected) {
    if (isSelected) {
      if (!selectedExtensions.contains(extensionName)) {
        selectedExtensions.add(extensionName);
      }
    } else {
      selectedExtensions.remove(extensionName);
    }
  }

  void clearTests() {
    testResults.clear();
  }

  @override
  void onClose() {
    clearTests();
    super.onClose();
  }
}