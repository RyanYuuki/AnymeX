import 'dart:io';

import 'package:anymex/main.dart';
import 'package:anymex/utils/extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';

class Deeplink {
  static void handleDeepLink(Uri uri) {
    if (uri.host != 'add-repo') return;
    ExtensionType extType;
    String? repoUrl;
    String? mangaUrl;
    String? novelUrl;

    if (Platform.isAndroid) {
      switch (uri.scheme.toLowerCase()) {
        case 'aniyomi':
          extType = ExtensionType.aniyomi;
          repoUrl = uri.queryParameters["url"]?.trim();
          break;
        case 'tachiyomi':
          extType = ExtensionType.aniyomi;
          mangaUrl = uri.queryParameters["url"]?.trim();
          break;
        default:
          extType = ExtensionType.mangayomi;
          repoUrl =
              (uri.queryParameters["url"] ?? uri.queryParameters['anime_url'])
                  ?.trim();
          mangaUrl = uri.queryParameters["manga_url"]?.trim();
          novelUrl = uri.queryParameters["novel_url"]?.trim();
      }
    } else {
      extType = ExtensionType.mangayomi;
      repoUrl = (uri.queryParameters["url"] ?? uri.queryParameters['anime_url'])
          ?.trim();
      mangaUrl = uri.queryParameters["manga_url"]?.trim();
      novelUrl = uri.queryParameters["novel_url"]?.trim();
    }

    if (repoUrl != null) {
      Extensions().addRepo(ItemType.anime, repoUrl, extType);
    }

    if (mangaUrl != null) {
      Extensions().addRepo(ItemType.manga, mangaUrl, extType);
    }

    if (novelUrl != null) {
      Extensions().addRepo(ItemType.novel, novelUrl, extType);
    }

    if (repoUrl != null || mangaUrl != null || novelUrl != null) {
      snackBar("Added Repo Links Successfully!");
    } else {
      snackBar("Missing required parameters in the link.");
    }
  }
}
