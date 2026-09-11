import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
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

Map<String, String> getPageImageHeaders(Map<String, String>? headers, [String? baseUrl]) {
  final effectiveBaseUrl = baseUrl ?? sourceController.activeMangaSource.value?.baseUrl ?? '';
  final referer = effectiveBaseUrl.isNotEmpty
      ? (effectiveBaseUrl.endsWith('/') ? effectiveBaseUrl : '$effectiveBaseUrl/')
      : '';
  final origin = effectiveBaseUrl.endsWith('/')
      ? effectiveBaseUrl.substring(0, effectiveBaseUrl.length - 1)
      : effectiveBaseUrl;

  return {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    if (referer.isNotEmpty) 'Referer': referer,
    if (origin.isNotEmpty) 'Origin': origin,
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    ...?headers,
  };
}