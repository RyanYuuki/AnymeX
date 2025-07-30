import 'dart:io';

import 'package:anymex/main.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';

class Deeplink {
  static void initDeepLinkListener() async {
    if (Platform.isLinux) return;

    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) handleDeepLink(initialUri);
    } catch (err) {
      errorSnackBar('Error getting initial deep link: $err');
    }

    appLinks.uriLinkStream.listen(
      (uri) => handleDeepLink(uri),
      onError: (err) => errorSnackBar('Error Opening link: $err'),
    );
  }

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
      Extensions().addRepo(MediaType.anime, repoUrl, extType);
    }

    if (mangaUrl != null) {
      Extensions().addRepo(MediaType.manga, mangaUrl, extType);
    }

    if (novelUrl != null) {
      Extensions().addRepo(MediaType.novel, novelUrl, extType);
    }

    if (repoUrl != null || mangaUrl != null || novelUrl != null) {
      snackBar("Added Repo Links Successfully!");
    } else {
      snackBar("Missing required parameters in the link.");
    }
  }
}
