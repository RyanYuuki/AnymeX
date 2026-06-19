import 'dart:convert';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/track/track_binding.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

/// Owns the local (media × tracker) binding table and orchestrates
/// multi-tracker sync for downloaded media.
///
/// IMPORTANT — no new HTTP/GraphQL calls live here. Every remote action
/// goes through the EXISTING service singletons:
///   • search      → `<service>.search(SearchParams(...))`   (already implemented per service)
///   • push status → `<service>.updateListEntry(UpdateListEntryParams(...))` (already implemented per service)
///   • login state → `<service>.isLoggedIn` (RxBool, already wired under Settings → Accounts)
///
/// Bindings are persisted as a JSON string under
/// `DynamicKeys.trackBindings[mediaId]` in the existing KV store, so no
/// Isar schema migration / codegen is needed.
class TrackBindingController extends GetxController {
  final Map<String, List<TrackBinding>> _cache = {};

  /// Bumped on every bind/unbind so Obx listeners (card badges, Track
  /// button count) rebuild live.
  final RxInt bindingsVersion = 0.obs;

  // ---------- Bindings CRUD (local only) ----------

  /// All bindings for a given downloaded media item (keyed by its `folderName`).
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
          list.add(TrackBinding.fromJson(
              Map<String, dynamic>.from(entry)));
        }
      }
    } catch (e) {
      Logger.e('TrackBinding decode failed for $mediaId: $e');
    }
    _cache[mediaId] = list;
    return List.unmodifiable(list);
  }

  bool hasAnyBinding(String mediaId) => getBindingsFor(mediaId).isNotEmpty;

  int bindingCount(String mediaId) => getBindingsFor(mediaId).length;

  /// Bind (or replace) a tracker for a media item. Local-only — does NOT
  /// call the tracker API. Use [pushProgress] afterwards to sync remotely.
  Future<void> bind(String mediaId, TrackBinding binding) async {
    final list = getBindingsFor(mediaId)
        .where((b) => b.trackerId != binding.trackerId)
        .toList();
    list.add(binding);
    _cache[mediaId] = list;
    _persist(mediaId, list);
    bindingsVersion.value++;
  }

  Future<void> unbind(String mediaId, int trackerId) async {
    final list =
        getBindingsFor(mediaId).where((b) => b.trackerId != trackerId).toList();
    _cache[mediaId] = list;
    _persist(mediaId, list);
    bindingsVersion.value++;
  }

  void _persist(String mediaId, List<TrackBinding> list) {
    DynamicKeys.trackBindings.set<String>(
      mediaId,
      jsonEncode(list.map((b) => b.toJson()).toList()),
    );
  }

  // ---------- Tracker login state (reuses existing singletons) ----------

  /// The [OnlineService] for a tracker — used for `isLoggedIn` and
  /// `updateListEntry`. Reuses the existing Get singletons.
  OnlineService _online(Tracker t) {
    switch (t) {
      case Tracker.anilist:
        return Get.find<AnilistData>();
      case Tracker.mal:
        return Get.find<MalService>();
      case Tracker.simkl:
        return Get.find<SimklService>();
    }
  }

  bool isLoggedIn(Tracker t) => _online(t).isLoggedIn.value;

  /// Trackers the user has logged into (via Settings → Accounts).
  /// Only these are shown in the Track sheet.
  List<Tracker> loggedInTrackers() =>
      Tracker.values.where(isLoggedIn).toList();

  // ---------- Search (reuses existing per-service search) ----------

  /// Search a specific tracker for a title. Reuses the existing
  /// `<service>.search(SearchParams(...))` — no new endpoint.
  ///
  /// IMPORTANT: `args` (= isAdult) MUST be a non-null bool — AniList
  /// uses it as `isAdult: params.args` and MAL as `sfw: !params.args`.
  /// Leaving it null throws "Null is not a subtype of bool" inside the
  /// service. We pass `false` (= not adult, sfw=true) by default.
  Future<List<Media>> searchOn(Tracker t, SearchParams params) {
    // Defensive: ensure args is a bool for AniList/MAL which expect one.
    if (params.args is! bool) {
      // ignore: invalid_update_of_params_copy
      params = SearchParams(
        query: params.query,
        isManga: params.isManga,
        filters: params.filters,
        args: false,
        page: params.page,
      );
    }
    switch (t) {
      case Tracker.anilist:
        return Get.find<AnilistData>().search(params);
      case Tracker.mal:
        return Get.find<MalService>().search(params);
      case Tracker.simkl:
        return Get.find<SimklService>().search(params);
    }
  }

  // ---------- Remote sync (reuses existing updateListEntry) ----------

  /// Push the latest watched episode / read chapter count to EVERY
  /// bound + logged-in tracker, in parallel. Mirrors aniyomi's
  /// `TrackEpisode` fan-out.
  ///
  /// Uses each service's existing `updateListEntry` — no new API calls.
  Future<void> pushProgress(
    String mediaId,
    int progress, {
    required bool isAnime,
    String? status,
  }) async {
    final bindings = getBindingsFor(mediaId);
    if (bindings.isEmpty) return;

    await Future.wait(bindings.map((b) async {
      final tracker = b.tracker;
      final service = _online(tracker);
      if (!service.isLoggedIn.value) return;
      try {
        await service.updateListEntry(UpdateListEntryParams(
          listId: b.remoteId,
          progress: progress,
          status: status ?? b.status,
          isAnime: isAnime,
        ));
        b.progress = progress;
        if (status != null) b.status = status;
      } catch (e) {
        Logger.e('Track sync failed for ${tracker.label} ($mediaId): $e');
      }
    }));

    _persist(mediaId, bindings);
  }

  /// Convenience: build a [TrackBinding] from a search result picked by
  /// the user in the Track sheet.
  TrackBinding bindingFromSearchResult(
    Tracker tracker,
    Media result, {
    required bool isAnime,
  }) {
    return TrackBinding(
      trackerId: tracker.index,
      remoteId: result.id,
      title: result.title,
      poster: result.poster,
      totalEpisodes: result.totalEpisodes,
      isAnime: isAnime,
      progress: 0,
      status: 'CURRENT',
    );
  }
}
