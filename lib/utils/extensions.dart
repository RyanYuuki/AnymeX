import 'package:anymex/controllers/source/source_controller.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:get/get.dart';

class Extensions {
  final settings = Get.put(SourceController());

  Future<void> addRepo(ItemType type, String repo, ExtensionType ext) async {
    if (type == ItemType.manga) {
      settings.setMangaRepo(repo, ext);
    } else if (type == ItemType.anime) {
      settings.setAnimeRepo(repo, ext);
    } else {
      settings.activeNovelRepo = repo;
    }
    await settings.fetchRepos();
  }
}
