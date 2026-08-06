import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/novel/reader/novel_reader.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';

class NovelDetailsController extends GetxController {
  final Source? initialSource;
  final Media initialMedia;

  NovelDetailsController({
    required this.initialSource,
    required this.initialMedia,
  });

  late final SourceController sourceController;

  Rx<Media> media = Rx(Media(serviceType: ServicesType.extensions));
  Rx<OfflineMedia?> offlineMedia = Rx(OfflineMedia());
  RxList<Chapter> chapters = RxList<Chapter>([]);
  Rx<bool> isLoading = Rx(true);
  RxBool isChaptersLoading = false.obs;
  Rxn<Source> activeSource = Rxn<Source>();
  RxBool isSyncing = false.obs;
  RxString searchedTitle = ''.obs;

  // Cached source media from last fetch — reused by syncDetails so it never re-fetches.
  Media? _cachedSourceMedia;

  bool get hasInitialSource => initialSource != null;

  final offlineStorage = Get.find<OfflineStorageController>();

  @override
  void onInit() {
    super.onInit();
    sourceController = Get.find<SourceController>();
    activeSource.value = initialSource ??
        sourceController.activeNovelSource.value ??
        (sourceController.installedNovelExtensions.isNotEmpty
            ? sourceController.installedNovelExtensions.first
            : null);
    getOfflineMedia();
    _fetchChaptersOnly(url: initialMedia.id);
  }

  void getOfflineMedia() async {
    offlineMedia.value = offlineStorage.getNovelById(initialMedia.id);
  }

  Future<void> _fetchChaptersOnly({required String url}) async {
    final source = activeSource.value;
    if (source == null) {
      isLoading.value = false;
      isChaptersLoading.value = false;
      return;
    }
    try {
      final data = await source.methods.getDetail(DMedia(url: url));
      final fetched = Media.fromDManga(data, ItemType.novel);
      chapters.value = fetched.altMediaContent ?? [];

      // Build cache — keep initialMedia title/poster so UI stays consistent
      fetched.title = initialMedia.title;
      fetched.poster = initialMedia.poster;
      fetched.season = source.name ?? '';
      _cachedSourceMedia = fetched;

      // On first load populate the media display
      if ((media.value.title ?? '').isEmpty) {
        media.value = fetched;
        CommentPreloader.to.preloadComments(media.value);
      }
    } catch (e) {
      errorSnackBar('Failed to fetch chapters');
    } finally {
      isLoading.value = false;
      isChaptersLoading.value = false;
    }
  }

  Future<DMedia?> _searchBestMatch(Source source, String query) async {
    try {
      final results = (await source.methods.search(query, 1, [])).list;
      if (results == null || results.isEmpty) return null;
      final valid = results.whereType<DMedia>().toList();
      if (valid.isEmpty) return null;
      final lQuery = query.toLowerCase().trim();
      final exact = valid.firstWhereOrNull(
          (m) => (m.title ?? '').toLowerCase().trim() == lQuery);
      if (exact != null) return exact;
      final contains = valid.firstWhereOrNull((m) {
        final t = (m.title ?? '').toLowerCase().trim();
        return t.contains(lQuery) || lQuery.contains(t);
      });
      return contains ?? valid.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> switchSource(Source newSource) async {
    activeSource.value = newSource;
    sourceController.activeNovelSource.value = newSource;
    chapters.clear();
    _cachedSourceMedia = null;
    searchedTitle.value = '';
    isChaptersLoading.value = true;

    final match = await _searchBestMatch(newSource, initialMedia.title);
    if (match != null) {
      searchedTitle.value = 'Found: ${match.title}';
      await _fetchChaptersOnly(url: match.url ?? initialMedia.id);
    } else {
      await _fetchChaptersOnly(url: initialMedia.id);
    }
  }

  Future<void> getDetailsFromSource(Media selectedMedia) async {
    isChaptersLoading.value = true;
    final source = activeSource.value;
    if (source == null) {
      isChaptersLoading.value = false;
      return;
    }
    try {
      final data =
          await source.methods.getDetail(DMedia(url: selectedMedia.id));
      final fetched = Media.fromDManga(data, ItemType.novel);
      chapters.value = fetched.altMediaContent ?? [];
      searchedTitle.value = 'Found: ${selectedMedia.title}';
      fetched.title = initialMedia.title;
      fetched.poster = initialMedia.poster;
      fetched.season = source.name ?? '';
      _cachedSourceMedia = fetched;
    } catch (e) {
      errorSnackBar('Failed to fetch chapters');
    } finally {
      isChaptersLoading.value = false;
    }
  }

  // Replaces media metadata with source data.
  // Reuses cache — never re-fetches if chapters are already loaded.
  Future<void> syncDetails() async {
    if (!hasInitialSource) return;
    if (_cachedSourceMedia != null && chapters.isNotEmpty) {
      media.value = _cachedSourceMedia!;
      CommentPreloader.to.preloadComments(media.value);
      return;
    }
    isSyncing.value = true;
    try {
      await _fetchChaptersOnly(url: initialMedia.id);
      if (_cachedSourceMedia != null) {
        media.value = _cachedSourceMedia!;
        CommentPreloader.to.preloadComments(media.value);
      }
    } catch (e) {
      errorSnackBar('Sync failed');
    } finally {
      isSyncing.value = false;
    }
  }

  void goToReader(
    Chapter chapter, {
    List<Chapter>? filteredChapters,
  }) {
    final source = activeSource.value;
    if (source == null) {
      errorSnackBar('No source selected');
      return;
    }
    final chaps = filteredChapters ?? chapters;
    navigate(() => NovelReader(
          chapter: chapter,
          media: media.value..title = initialMedia.title,
          chapters: chaps,
          source: source,
        ));
  }
}
