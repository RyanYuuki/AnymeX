import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:get/get.dart';

class Extensions {
  final settings = Get.put(SourceController());

  Future<void> addRepo(MediaType type, String repo, ExtensionType ext) async {
    if (type == MediaType.manga) {
      settings.setMangaRepo(repo, ext);
    } else if (type == MediaType.anime) {
      settings.setAnimeRepo(repo, ext);
    } else {
      settings.activeNovelRepo = repo;
    }
    await settings.fetchRepos();
  }
}
