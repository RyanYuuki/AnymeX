import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme_registry.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_bridge/ExtensionManager.dart';
import 'package:anymex_extension_bridge/Models/Source.dart';
import 'package:get/get.dart';

class Deeplink {
  static void handleDeepLink(Uri uri) {
    print("HANDLING DEEEPLIINK => ${uri.toString()}");
    final illegalSchemes = Get.find<ExtensionManager>()
        .managers
        .expand((e) => e.schemes.toList())
        .toList();

    if (_isThemeDeepLink(uri)) {
      _handleThemeDeepLink(uri);
      return;
    }

    if (!illegalSchemes.contains(uri.scheme)) {
      final mediaTarget = _parseMediaTarget(uri);
      if (mediaTarget == null) return;
      _openMediaTarget(mediaTarget);
      return;
    }

    bool isRepoAdded = false;
    snackBar("Adding repo... please wait.");
    final manager = Get.find<ExtensionManager>().managers;
    for (final handler in manager) {
      print('Matching ${uri.scheme} with ${handler.schemes.toString()}');
      if (handler.schemes.contains(uri.scheme.toLowerCase())) {
        handler.handleSchemes(uri);
        isRepoAdded = true;
        break;
      }
    }
    snackBar(
      isRepoAdded
          ? "Added Repo Links Successfully!"
          : "Missing or invalid parameters in the link.",
    );
  }

  static bool _isThemeDeepLink(Uri uri) {
    if (uri.host.toLowerCase() == 'theme') return true;
    final segments = _compactSegments(uri.pathSegments);
    return segments.isNotEmpty && segments.first.toLowerCase() == 'theme';
  }

  static Future<void> _handleThemeDeepLink(Uri uri) async {
    final type = (uri.queryParameters['type'] ?? '').trim().toLowerCase();
    if (type.isEmpty) {
      errorSnackBar('Missing "type" query parameter. Use type=player.');
      return;
    }
    if (type != 'player') {
      errorSnackBar('Unsupported theme type "$type". Supported: player.');
      return;
    }

    final rawUrl = uri.queryParameters['url']?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      errorSnackBar('Missing "url" query parameter for the theme JSON.');
      return;
    }

    snackBar('Importing player theme from link...');
    final result = await PlayerControlThemeRegistry.importFromUrl(rawUrl);

    if (result.hasErrors) {
      final extra = result.errors.length > 1
          ? ' (+${result.errors.length - 1} more issue(s))'
          : '';
      errorSnackBar('Theme is invalid: ${result.errors.first}$extra');
      return;
    }

    final imported = result.importedCount;
    final label = imported == 1 ? 'theme' : 'themes';
    if (result.hasWarnings) {
      final more = result.warnings.length > 1
          ? ' (+${result.warnings.length - 1} more warning(s))'
          : '';
      warningSnackBar(
          'Theme imported with warning: ${result.warnings.first}$more');
    } else {
      successSnackBar('Theme JSON is valid. Imported $imported $label.');
    }
  }

  static _MediaDeepLinkTarget? _parseMediaTarget(Uri uri) {
    final webTarget = _parseWebTarget(uri);
    if (webTarget != null) return webTarget;
    return _parseCustomTarget(uri);
  }

  static _MediaDeepLinkTarget? _parseWebTarget(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') return null;

    final host = uri.host.toLowerCase();
    final segments = _compactSegments(uri.pathSegments);

    if (_isHost(host, 'anilist.co')) {
      return _parseAnimeMangaTarget(
        uri: uri,
        segments: segments,
        serviceType: ServicesType.anilist,
      );
    }

    if (_isHost(host, 'myanimelist.net')) {
      return _parseAnimeMangaTarget(
        uri: uri,
        segments: segments,
        serviceType: ServicesType.mal,
      );
    }

    if (_isHost(host, 'simkl.com')) {
      return _parseSimklTarget(uri: uri, segments: segments);
    }

    return null;
  }

  static _MediaDeepLinkTarget? _parseCustomTarget(Uri uri) {
    if (uri.host.toLowerCase() == 'callback' ||
        uri.host.toLowerCase() == 'add-repo') {
      return null;
    }

    final segments = _compactSegments(uri.pathSegments);
    ServicesType? serviceType = _serviceFromToken(uri.host);
    int offset = 0;

    if (serviceType == null && segments.isNotEmpty) {
      serviceType = _serviceFromToken(segments.first);
      if (serviceType != null) {
        offset = 1;
      }
    }

    if (serviceType == null) return null;

    final mediaSegments = segments.skip(offset).toList();

    if (serviceType == ServicesType.simkl) {
      return _parseSimklTarget(uri: uri, segments: mediaSegments);
    }

    return _parseAnimeMangaTarget(
      uri: uri,
      segments: mediaSegments,
      serviceType: serviceType,
    );
  }

  static _MediaDeepLinkTarget? _parseAnimeMangaTarget({
    required Uri uri,
    required List<String> segments,
    required ServicesType serviceType,
  }) {
    if (segments.isEmpty) return null;

    final first = segments.first.toLowerCase();

    if ((first == 'anime.php' || first == 'manga.php') &&
        uri.queryParameters.containsKey('id')) {
      final isManga = first == 'manga.php';
      final id = _extractNumericId(uri.queryParameters['id']!);
      if (id == null) return null;

      return _MediaDeepLinkTarget(
        serviceType: serviceType,
        isManga: isManga,
        mediaId: id,
        initialTabIndex: _parseInitialTabIndex(uri.fragment),
      );
    }

    if (segments.length < 2) return null;

    final type = first;
    final isAnimePath = type == 'anime';
    final isMangaPath = type == 'manga';
    if (!isAnimePath && !isMangaPath) return null;

    final id = _extractNumericId(segments[1]);
    if (id == null) return null;

    return _MediaDeepLinkTarget(
      serviceType: serviceType,
      isManga: isMangaPath,
      mediaId: id,
      initialTabIndex: _parseInitialTabIndex(uri.fragment),
    );
  }

  static _MediaDeepLinkTarget? _parseSimklTarget({
    required Uri uri,
    required List<String> segments,
  }) {
    if (segments.length < 2) return null;

    final type = segments.first.toLowerCase();
    final isMovie = {'movie', 'movies', 'film', 'films'}.contains(type);
    final isSeries = {'anime', 'tv', 'series', 'show', 'shows'}.contains(type);

    if (!isMovie && !isSeries) return null;

    final id = _extractNumericId(segments[1]);
    if (id == null) return null;

    return _MediaDeepLinkTarget(
      serviceType: ServicesType.simkl,
      isManga: false,
      mediaId: '$id*${isMovie ? 'MOVIE' : 'SERIES'}',
      initialTabIndex: _parseInitialTabIndex(uri.fragment),
    );
  }

  static ServicesType? _serviceFromToken(String raw) {
    final token = raw.toLowerCase();
    if (token.contains('anilist')) return ServicesType.anilist;
    if (token.contains('myanimelist') || token == 'mal') {
      return ServicesType.mal;
    }
    if (token.contains('simkl')) return ServicesType.simkl;

    switch (token) {
      case 'anilist':
      case 'al':
        return ServicesType.anilist;
      case 'mal':
      case 'myanimelist':
        return ServicesType.mal;
      case 'simkl':
        return ServicesType.simkl;
      default:
        return null;
    }
  }

  static int _parseInitialTabIndex(String fragment) {
    var tab = fragment.trim().toLowerCase();
    tab = tab.replaceFirst(RegExp(r'^/+'), '');

    switch (tab) {
      case 'watch':
      case 'read':
        return 1;
      case 'comment':
      case 'comments':
        return 2;
      case 'details':
      default:
        return 0;
    }
  }

  static void _openMediaTarget(
    _MediaDeepLinkTarget target, {
    int attempts = 0,
  }) {
    if (!Get.isRegistered<ServiceHandler>() || Get.context == null) {
      if (attempts >= 300) return;
      Future.delayed(const Duration(milliseconds: 200), () {
        _openMediaTarget(target, attempts: attempts + 1);
      });
      return;
    }

    final handler = Get.find<ServiceHandler>();
    if (handler.serviceType.value != target.serviceType) {
      handler.changeService(target.serviceType);
    }

    _openHydratedMediaTarget(target);
  }

  static Future<void> _openHydratedMediaTarget(
      _MediaDeepLinkTarget target) async {
    Media media = Media(
      id: target.mediaId,
      serviceType: target.serviceType,
      mediaType: target.isManga ? ItemType.manga : ItemType.anime,
    );

    try {
      final fetchedMedia = await target.serviceType.service.fetchDetails(
        FetchDetailsParams(
          id: target.mediaId,
          isManga: target.isManga,
        ),
      );

      fetchedMedia.serviceType = target.serviceType;
      fetchedMedia.mediaType = target.isManga ? ItemType.manga : ItemType.anime;
      media = fetchedMedia;
    } catch (_) {
      // Fallback to minimal media payload if details request fails.
    }

    final tag = 'deep-link-${DateTime.now().millisecondsSinceEpoch}';

    if (target.isManga) {
      navigate(() => MangaDetailsPage(
            media: media,
            tag: tag,
            initialTabIndex: target.initialTabIndex,
          ));
      return;
    }

    navigate(() => AnimeDetailsPage(
          media: media,
          tag: tag,
          initialTabIndex: target.initialTabIndex,
        ));
  }

  static bool _isHost(String host, String domain) {
    return host == domain || host.endsWith('.$domain');
  }

  static List<String> _compactSegments(List<String> segments) {
    return segments.where((s) => s.trim().isNotEmpty).toList();
  }

  static String? _extractNumericId(String raw) {
    return RegExp(r'\d+').firstMatch(raw)?.group(0);
  }
}

class _MediaDeepLinkTarget {
  final ServicesType serviceType;
  final bool isManga;
  final String mediaId;
  final int initialTabIndex;

  const _MediaDeepLinkTarget({
    required this.serviceType,
    required this.isManga,
    required this.mediaId,
    required this.initialTabIndex,
  });
}
