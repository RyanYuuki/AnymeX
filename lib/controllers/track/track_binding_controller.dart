
import 'dart:convert';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/track/track_binding.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

class TrackBindingController extends GetxController {
  final Map<String, List<TrackBinding>> _cache = {};

  final RxInt bindingsVersion = 0.obs;

  List<TrackBinding> getBindingsFor(String mediaId) {
    if (_cache.containsKey(mediaId)) {
      return List.unmodifiable(_cache[mediaId]!);
    }

    final raw = DynamicKeys.trackBindings.get<String>(mediaId, '[]');
    final list = <TrackBinding>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      for (final entry in decoded) {
        if (entry is Map) {
          list.add(
            TrackBinding.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          );
        }
      }
    } catch (e) {
      Logger.e('TrackBinding decode failed for $mediaId: $e');
    }

    _cache[mediaId] = list;
    return List.unmodifiable(list);
  }

  bool hasAnyBinding(String mediaId) =>
      getBindingsFor(mediaId).isNotEmpty;

  int bindingCount(String mediaId) =>
      getBindingsFor(mediaId).length;

  Future<void> bind(
    String mediaId,
    TrackBinding binding,
  ) async {
    final list = getBindingsFor(mediaId)
        .where((b) => b.trackerId != binding.trackerId)
        .toList();

    list.add(binding);
    _cache[mediaId] = list;

    _persist(mediaId, list);
    bindingsVersion.value++;
  }

  Future<void> unbind(
    String mediaId,
    int trackerId,
  ) async {
    final list = getBindingsFor(mediaId)
        .where((b) => b.trackerId != trackerId)
        .toList();

    _cache[mediaId] = list;

    _persist(mediaId, list);
    bindingsVersion.value++;
  }

  void _persist(
    String mediaId,
    List<TrackBinding> list,
  ) {
    DynamicKeys.trackBindings.set<String>(
      mediaId,
      jsonEncode(list.map((b) => b.toJson()).toList()),
    );
  }

  OnlineService _online(Tracker tracker) {
    switch (tracker) {
      case Tracker.anilist:
        return Get.find<AnilistData>();
      case Tracker.mal:
        return Get.find<MalService>();
      case Tracker.simkl:
        return Get.find<SimklService>();
    }
  }

  bool isLoggedIn(Tracker tracker) =>
      _online(tracker).isLoggedIn.value;

  List<Tracker> loggedInTrackers() =>
      Tracker.values.where(isLoggedIn).toList();

  Future<List<Media>> searchOn(
    Tracker tracker,
    SearchParams params,
  ) {
    if (params.args is! bool) {
      params = SearchParams(
        query: params.query,
        isManga: params.isManga,
        filters: params.filters,
        args: false,
        page: params.page,
      );
    }

    switch (tracker) {
      case Tracker.anilist:
        return Get.find<AnilistData>().search(params);
      case Tracker.mal:
        return Get.find<MalService>().search(params);
      case Tracker.simkl:
        return Get.find<SimklService>().search(params);
    }
  }

  /// Searches all registered tracking services concurrently.
  ///
  /// Results remain separated by tracker because IDs from
  /// different services are not necessarily interchangeable.
  ///
  /// When one service fails, successful results from the
  /// other services are still returned.
  Future<Map<Tracker, List<Media>>> searchAll(
    SearchParams params, {
    bool loggedInOnly = false,
  }) async {
    final trackers = loggedInOnly
        ? loggedInTrackers()
        : Tracker.values.toList();

    final entries = await Future.wait<
        MapEntry<Tracker, List<Media>>>(
      trackers.map((tracker) async {
        try {
          final results = await searchOn(tracker, params);

          return MapEntry<Tracker, List<Media>>(
            tracker,
            results,
          );
        } catch (error) {
          Logger.e(
            'Unified search failed for '
            '${tracker.label}: $error',
          );

          return MapEntry<Tracker, List<Media>>(
            tracker,
            <Media>[],
          );
        }
      }),
    );

    return Map<Tracker, List<Media>>.fromEntries(entries);
  }

  Future<List<Media>> searchOnSimkl(
    String query, {
    SimklSearchCategory category =
        SimklSearchCategory.anime,
    int page = 1,
  }) {
    return Get.find<SimklService>().searchByCategory(
      query,
      category,
      page: page,
    );
  }

  Future<void> pushProgress(
    String mediaId,
    int progress, {
    required bool isAnime,
    String? status,
    int? season,
  }) async {
    final bindings = getBindingsFor(mediaId);

    if (bindings.isEmpty) return;

    await Future.wait(
      bindings.map((binding) async {
        final tracker = binding.tracker;
        final service = _online(tracker);

        if (!service.isLoggedIn.value) return;

        try {
          final targetStatus =
              binding.status == 'REPEATING'
                  ? 'REPEATING'
                  : (status ?? binding.status);

          await service.updateListEntry(
            UpdateListEntryParams(
              listId: binding.remoteId,
              progress: progress,
              status: targetStatus,
              isAnime: isAnime,
              season: season,
            ),
          );

          binding.progress = progress;
          binding.status = targetStatus;
        } catch (error) {
          Logger.e(
            'Track sync failed for '
            '${tracker.label} ($mediaId): $error',
          );
        }
      }),
    );

    _persist(mediaId, bindings);
  }

  TrackBinding bindingFromSearchResult(
    Tracker tracker,
    Media result, {
    required bool isAnime,
  }) {
    final service = _online(tracker);
    final list = isAnime
        ? service.animeList
        : service.mangaList;

    TrackedMedia? existing;

    try {
      existing = list.firstWhere(
        (item) =>
            item.id == result.id ||
            item.mediaListId == result.id ||
            (result.idMal.isNotEmpty &&
                result.idMal != '0' &&
                item.idMal == result.idMal),
      );
    } catch (_) {
      existing = null;
    }

    return TrackBinding(
      trackerId: tracker.index,
      remoteId: result.id,
      title: result.title,
      poster: result.poster,
      totalEpisodes: result.totalEpisodes,
      isAnime: isAnime,
      progress: int.tryParse(
            existing?.episodeCount ?? '',
          ) ??
          0,
      status:
          (existing?.watchingStatus?.isNotEmpty ?? false)
              ? existing!.watchingStatus!
              : 'CURRENT',
      score: double.tryParse(existing?.score ?? ''),
      private: existing?.isPrivate ?? false,
    );
  }

  Future<void> updateBindingFields(
    String mediaId,
    TrackBinding binding, {
    int? progress,
    String? status,
    double? score,
    bool? isPrivate,
  }) async {
    final newProgress = progress ?? binding.progress;
    final newStatus = status ?? binding.status;
    final newScore = score ?? binding.score;
    final newPrivate = isPrivate ?? binding.private;

    final service = _online(binding.tracker);

    if (service.isLoggedIn.value) {
      try {
        await service.updateListEntry(
          UpdateListEntryParams(
            listId: binding.remoteId,
            progress: newProgress,
            status: newStatus,
            score: newScore,
            isAnime: binding.isAnime,
            isPrivate: newPrivate,
          ),
        );
      } catch (error) {
        Logger.e(
          'Track remote update failed for '
          '${binding.tracker.label} ($mediaId): $error '
          '— keeping local update only',
        );
      }
    }

    binding.progress = newProgress;
    binding.status = newStatus;
    binding.score = newScore;
    binding.private = newPrivate;

    final list = getBindingsFor(mediaId)
        .where(
          (item) => item.trackerId != binding.trackerId,
        )
        .toList();

    list.add(binding);
    _cache[mediaId] = list;

    _persist(mediaId, list);
    bindingsVersion.value++;
  }
}
