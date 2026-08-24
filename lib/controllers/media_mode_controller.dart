import 'dart:async';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';

class MediaModeController extends GetxController {
  final rxMode = ItemType.anime.obs;
  ItemType get mode => rxMode.value;
  set mode(ItemType val) => rxMode.value = val;

  final animeHistory = <OfflineMedia>[].obs;
  final mangaHistory = <OfflineMedia>[].obs;
  final novelHistory = <OfflineMedia>[].obs;

  StreamSubscription? _animeSub;
  StreamSubscription? _mangaSub;
  StreamSubscription? _novelSub;

  @override
  void onInit() {
    super.onInit();
    final storage = Get.find<OfflineStorageController>();

    _animeSub = storage.watchAnimeLibrary().listen((items) {
      animeHistory.value = items.where((e) => e.currentEpisode?.currentTrack != null).toList()
        ..sort((a, b) => (b.currentEpisode?.lastWatchedTime ?? 0)
            .compareTo(a.currentEpisode?.lastWatchedTime ?? 0));
    });

    _mangaSub = storage.watchMangaLibrary().listen((items) {
      mangaHistory.value = items.where((e) => e.currentChapter?.link != null).toList()
        ..sort((a, b) => (b.currentChapter?.lastReadTime ?? 0)
            .compareTo(a.currentChapter?.lastReadTime ?? 0));
    });

    _novelSub = storage.watchNovelLibrary().listen((items) {
      novelHistory.value = items.where((e) => e.currentChapter?.link != null).toList()
        ..sort((a, b) => (b.currentChapter?.lastReadTime ?? 0)
            .compareTo(a.currentChapter?.lastReadTime ?? 0));
    });
  }

  @override
  void onClose() {
    _animeSub?.cancel();
    _mangaSub?.cancel();
    _novelSub?.cancel();
    super.onClose();
  }

  List<OfflineMedia> get currentHistory {
    switch (mode) {
      case ItemType.anime:
        return animeHistory;
      case ItemType.manga:
        return mangaHistory;
      case ItemType.novel:
        return novelHistory;
    }
  }
}
