import 'package:anymex/controllers/source/source_controller.dart';
import 'package:dartotsu_extension_bridge/Models/DMedia.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension ExtensionCarousel on Future<List<DMedia>> {}

extension ItemTypeExts on ItemType {
  bool get isManga => this == ItemType.manga;
  bool get isAnime => this == ItemType.anime;
  bool get isNovel => this == ItemType.novel;

  List<Source> get extensions => switch (this) {
        ItemType.anime => sourceController.installedExtensions,
        ItemType.manga => sourceController.installedMangaExtensions,
        ItemType.novel => sourceController.installedNovelExtensions
      };
}

extension NavigatorExts on Widget {
  void go({BuildContext? context}) => Navigator.of(context ?? Get.context!)
      .push(MaterialPageRoute(builder: (context) => this));
}
