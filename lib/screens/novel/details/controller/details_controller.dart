import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/novel/reader/novel_reader.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:get/get.dart';

class NovelDetailsController extends GetxController {
  Media initialMedia;
  Source source;

  NovelDetailsController({
    required this.source,
    required this.initialMedia,
  });

  Rx<Media> media = Rx(Media(serviceType: ServicesType.extensions));
  Rx<OfflineMedia?> offlineMedia = Rx(OfflineMedia());
  RxList<Chapter> chapters = RxList<Chapter>([]);
  Rx<bool> isLoading = Rx(true);

  final offlineStorage = Get.find<OfflineStorageController>();

  @override
  void onInit() {
    super.onInit();
    getOfflineMedia();
    _fetchDetails();
  }

  void getOfflineMedia() async {
    offlineMedia.value = offlineStorage.getNovelById(initialMedia.id);
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await source.methods.getDetail(DMedia(url: initialMedia.id));
      media.value = Media.fromDManga(data, ItemType.novel);
      media.value.title = initialMedia.title;
      media.value.poster = initialMedia.poster;
      media.value.season = source.name ?? '';
      chapters.value = media.value.altMediaContent ?? [];
      isLoading.value = false;
    } catch (e) {
      errorSnackBar('Failed to fetch details');
    }
  }

  void goToReader(
    Chapter chapter, {
    List<Chapter>? filteredChapters,
  }) {
    final chaps = filteredChapters ?? chapters;
    navigate(() => NovelReader(
          chapter: chapter,
          media: media.value..title = initialMedia.title,
          chapters: chaps,
          source: source,
        ));
  }
}
