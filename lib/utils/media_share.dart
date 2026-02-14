import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class MediaShare {
  static Future<void> showOptions({
    required BuildContext context,
    required Media baseMedia,
    required Media? hydratedMedia,
    required bool isManga,
  }) async {
    final selectedService = serviceHandler.serviceType.value;
    final resolvedService = _resolveShareService(
      selectedService: selectedService,
      mediaService: baseMedia.serviceType,
    );

    AnymexSheet.custom(
      Builder(
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: Text(
                    resolvedService == null
                        ? 'Share tracking link'
                        : 'Share ${_serviceLabel(resolvedService)} link',
                  ),
                  subtitle:
                      const Text('Share with your selected tracking service'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final link = _buildTrackingShareLink(
                      service: resolvedService,
                      baseMedia: baseMedia,
                      hydratedMedia: hydratedMedia,
                      isManga: isManga,
                    );
                    await _shareLink(
                      link: link,
                      fallbackMessage:
                          'Tracking link unavailable for this media.',
                      title: hydratedMedia?.title ?? baseMedia.title,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded),
                  title: const Text('Share AnymeX link'),
                  subtitle: const Text('Opens directly in AnymeX'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final link = _buildAnymexShareLink(
                      service: resolvedService,
                      baseMedia: baseMedia,
                      hydratedMedia: hydratedMedia,
                      isManga: isManga,
                    );
                    await _shareLink(
                      link: link,
                      fallbackMessage:
                          'AnymeX link unavailable for this media.',
                      title: hydratedMedia?.title ?? baseMedia.title,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      context,
      showDragHandle: true,
    );
  }

  static Future<void> _shareLink({
    required String? link,
    required String fallbackMessage,
    required String title,
  }) async {
    if (link == null) {
      snackBar(fallbackMessage);
      return;
    }
    await Share.share(link, subject: title);
  }

  static ServicesType? _resolveShareService({
    required ServicesType selectedService,
    required ServicesType mediaService,
  }) {
    if (selectedService != ServicesType.extensions) {
      return selectedService;
    }
    if (mediaService != ServicesType.extensions) {
      return mediaService;
    }
    return null;
  }

  static String _serviceLabel(ServicesType service) {
    switch (service) {
      case ServicesType.anilist:
        return 'AniList';
      case ServicesType.mal:
        return 'MyAnimeList';
      case ServicesType.simkl:
        return 'Simkl';
      case ServicesType.extensions:
        return 'Tracking';
    }
  }

  static String? _buildTrackingShareLink({
    required ServicesType? service,
    required Media baseMedia,
    required Media? hydratedMedia,
    required bool isManga,
  }) {
    if (service == null) return null;

    switch (service) {
      case ServicesType.anilist:
        final id =
            _resolveAnilistId(baseMedia: baseMedia, hydrated: hydratedMedia);
        if (id == null) return null;
        final path = isManga ? 'manga' : 'anime';
        return 'https://anilist.co/$path/$id';
      case ServicesType.mal:
        final id = _resolveMalId(baseMedia: baseMedia, hydrated: hydratedMedia);
        if (id == null) return null;
        final path = isManga ? 'manga' : 'anime';
        return 'https://myanimelist.net/$path/$id';
      case ServicesType.simkl:
        if (isManga) return null;
        final id =
            _resolveSimklId(baseMedia: baseMedia, hydrated: hydratedMedia);
        if (id == null) return null;
        final path =
            _isSimklMovie(baseMedia: baseMedia, hydrated: hydratedMedia)
                ? 'movie'
                : 'anime';
        return 'https://simkl.com/$path/$id';
      case ServicesType.extensions:
        return null;
    }
  }

  static String? _buildAnymexShareLink({
    required ServicesType? service,
    required Media baseMedia,
    required Media? hydratedMedia,
    required bool isManga,
  }) {
    if (service == null) return null;

    switch (service) {
      case ServicesType.anilist:
        final id =
            _resolveAnilistId(baseMedia: baseMedia, hydrated: hydratedMedia);
        if (id == null) return null;
        final path = isManga ? 'manga' : 'anime';
        return 'anymex://anilist/$path/$id';
      case ServicesType.mal:
        final id = _resolveMalId(baseMedia: baseMedia, hydrated: hydratedMedia);
        if (id == null) return null;
        final path = isManga ? 'manga' : 'anime';
        return 'anymex://mal/$path/$id';
      case ServicesType.simkl:
        if (isManga) return null;
        final id =
            _resolveSimklId(baseMedia: baseMedia, hydrated: hydratedMedia);
        if (id == null) return null;
        final path =
            _isSimklMovie(baseMedia: baseMedia, hydrated: hydratedMedia)
                ? 'movie'
                : 'anime';
        return 'anymex://simkl/$path/$id';
      case ServicesType.extensions:
        return null;
    }
  }

  static String? _resolveAnilistId({
    required Media baseMedia,
    required Media? hydrated,
  }) {
    if (baseMedia.serviceType == ServicesType.anilist) {
      return _extractNumericId(baseMedia.id);
    }
    return _extractNumericId(hydrated?.id ?? baseMedia.id);
  }

  static String? _resolveMalId({
    required Media baseMedia,
    required Media? hydrated,
  }) {
    if (baseMedia.serviceType == ServicesType.mal) {
      return _extractNumericId(baseMedia.id);
    }

    final mappedMalId = _extractNumericId(hydrated?.idMal ?? '');
    if (mappedMalId != null) return mappedMalId;

    return _extractNumericId(baseMedia.idMal);
  }

  static String? _resolveSimklId({
    required Media baseMedia,
    required Media? hydrated,
  }) {
    if (baseMedia.serviceType == ServicesType.simkl) {
      return _extractNumericId(baseMedia.id.split('*').first);
    }

    final detailId = hydrated?.id;
    if (detailId == null) return null;
    return _extractNumericId(detailId.split('*').first);
  }

  static bool _isSimklMovie({
    required Media baseMedia,
    required Media? hydrated,
  }) {
    final mediaId = (hydrated?.id ?? baseMedia.id).toUpperCase();
    final mediaType = (hydrated?.type ?? baseMedia.type).toUpperCase();
    return mediaId.contains('*MOVIE') ||
        mediaType.contains('MOVIE') ||
        mediaType.contains('FILM');
  }

  static String? _extractNumericId(String rawId) {
    final trimmed = rawId.trim();
    if (trimmed.isEmpty || trimmed == '0') return null;
    final match = RegExp(r'\d+').firstMatch(trimmed);
    return match?.group(0);
  }
}
