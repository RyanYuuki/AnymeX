import 'dart:async';

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide isar;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

import '../../main.dart';

SourceController get sourceController => Get.find<SourceController>();

class SourceController extends GetxController implements BaseService {
  ExtensionManager get _bridge => Get.find<ExtensionManager>();

  RxList<Source> get availableExtensions => _bridge.availableAnimeExtensions;
  RxList<Source> get availableMangaExtensions =>
      _bridge.availableMangaExtensions;
  RxList<Source> get availableNovelExtensions =>
      _bridge.availableNovelExtensions;

  RxList<Source> get installedExtensions => _bridge.installedAnimeExtensions;
  RxList<Source> get installedMangaExtensions =>
      _bridge.installedMangaExtensions;
  RxList<Source> get installedNovelExtensions =>
      _bridge.installedNovelExtensions;

  final activeSource = Rxn<Source>();
  final activeMangaSource = Rxn<Source>();
  final activeNovelSource = Rxn<Source>();
  final lastUpdatedSource = ''.obs;

  final Map<String, String> _activeTokens = {};

  void cancelInProgress(String key) {
    if (_activeTokens.containsKey(key)) {
      final token = _activeTokens[key]!;
      final source = switch (key) {
        'search' || 'detail' => activeSource.value,
        'manga_search' || 'manga_detail' => activeMangaSource.value,
        _ => null,
      };
      source?.cancelRequest(token);
      _activeTokens.remove(key);
    }
  }

  void updateToken(String key, String token) {
    cancelInProgress(key);
    _activeTokens[key] = token;
  }

  final _animeSections = <Widget>[].obs;
  final _homeSections = <Widget>[].obs;
  final _mangaSections = <Widget>[].obs;
  final novelSections = <Widget>[].obs;

  final _widgetCache = <ItemType, Map<int, Widget>>{
    ItemType.anime: {},
    ItemType.manga: {},
    ItemType.novel: {},
  };

  final isExtensionsServiceAllowed = false.obs;
  final shouldShowExtensions = false.obs;

  final _pendingRebuilds = <ItemType>{};
  Timer? _rebuildTimer;
  Future<void>? _repoRefreshTask;
  bool _homeReady = false;

  final _extensionOrders = <ItemType, List<String>>{
    ItemType.anime: [],
    ItemType.manga: [],
    ItemType.novel: [],
  };

  void _refreshVisibility() {
    shouldShowExtensions.value = installedExtensions.isNotEmpty ||
        installedMangaExtensions.isNotEmpty ||
        installedNovelExtensions.isNotEmpty;
  }

  void saveRepoSettings() => _refreshVisibility();

  List<String> getExtensionOrder(ItemType type) =>
      List.unmodifiable(_extensionOrders[type] ?? []);

  void saveExtensionOrder(ItemType type, List<String> orderedIds) {
    _extensionOrders[type] = List.from(orderedIds);
    final key = _orderKeyFor(type);
    KvHelper.set(key.name, orderedIds);
    _applyOrderToInstalledList(type, orderedIds);
    _rebuildSectionsOrder(type, orderedIds);
  }

  void _applyOrderToInstalledList(ItemType type, List<String> orderedIds) {
    final list = _installedFor(type);
    final current = list.toList();
    if (current.isEmpty) return;

    final orderMap = <String, int>{};
    for (var i = 0; i < orderedIds.length; i++) {
      orderMap[orderedIds[i]] = i;
    }

    final sorted = List<Source>.from(current)
      ..sort((a, b) {
        final aIdx = orderMap[a.id?.toString() ?? ''] ?? orderedIds.length;
        final bIdx = orderMap[b.id?.toString() ?? ''] ?? orderedIds.length;
        return aIdx.compareTo(bIdx);
      });

    list.value = sorted;
  }

  void _rebuildSectionsOrder(ItemType type, List<String> orderedIds) {
    final cache = _widgetCache[type]!;
    if (cache.isEmpty) return;

    final sections = _sectionsFor(type);
    final orderMap = <String, int>{};
    for (var i = 0; i < orderedIds.length; i++) {
      orderMap[orderedIds[i]] = i;
    }

    final sortedEntries = cache.entries.toList()
      ..sort((a, b) {
        final aIdx = orderMap[a.key.toString()] ?? orderedIds.length;
        final bIdx = orderMap[b.key.toString()] ?? orderedIds.length;
        return aIdx.compareTo(bIdx);
      });

    sections.value = [
      if (cache.isNotEmpty && type != ItemType.novel)
        CustomSearchBar(
          disableIcons: true,
          onSubmitted: (v) => SourceSearchPage(initialTerm: v, type: type).go(),
        ),
      ...sortedEntries.map((e) => e.value),
    ];
  }

  SourceKeys _orderKeyFor(ItemType type) => switch (type) {
        ItemType.anime => SourceKeys.animeExtensionOrder,
        ItemType.manga => SourceKeys.mangaExtensionOrder,
        ItemType.novel => SourceKeys.novelExtensionOrder,
      };

  void _loadExtensionOrders() {
    for (final type in ItemType.values) {
      final key = _orderKeyFor(type);
      final stored = KvHelper.get<List<dynamic>>(key.name, defaultVal: []);
      _extensionOrders[type] = stored.map((e) => e.toString()).toList();
    }
  }

  List<Source> applyCustomOrder(ItemType type, List<Source> sources) {
    final order = _extensionOrders[type] ?? [];
    if (order.isEmpty) return sources;

    final orderMap = <String, int>{};
    for (var i = 0; i < order.length; i++) {
      orderMap[order[i]] = i;
    }

    final sorted = List<Source>.from(sources);
    sorted.sort((a, b) {
      final aIdx = orderMap[a.id?.toString() ?? ''] ?? order.length;
      final bIdx = orderMap[b.id?.toString() ?? ''] ?? order.length;
      return aIdx.compareTo(bIdx);
    });
    return sorted;
  }

  @override
  void onInit() {
    super.onInit();

    ever(installedExtensions, (_) => _scheduleRebuild(ItemType.anime));
    ever(installedMangaExtensions, (_) => _scheduleRebuild(ItemType.manga));
    ever(installedNovelExtensions, (_) => _scheduleRebuild(ItemType.novel));

    _initialize();
  }

  @override
  void onClose() {
    _rebuildTimer?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    await initExtensions();
    if (Get.find<ServiceHandler>().serviceType.value ==
        ServicesType.extensions) {
      fetchHomePage();
    }
    if (Get.context != null) {
      checkForUpdates(Get.context!);
    }
  }

  void _scheduleRebuild(ItemType type) {
    _refreshVisibility();
    if (!_homeReady) return;

    _pendingRebuilds.add(type);
    _rebuildTimer?.cancel();
    _rebuildTimer = Timer(const Duration(milliseconds: 150), () {
      for (final t in _pendingRebuilds) {
        _syncSections(t);
      }
      _pendingRebuilds.clear();
    });
  }

  RxList<Source> _installedFor(ItemType t) => switch (t) {
        ItemType.anime => installedExtensions,
        ItemType.manga => installedMangaExtensions,
        ItemType.novel => installedNovelExtensions,
      };

  RxList<Source> _availableFor(ItemType t) => switch (t) {
        ItemType.anime => availableExtensions,
        ItemType.manga => availableMangaExtensions,
        ItemType.novel => availableNovelExtensions,
      };

  RxList<Widget> _sectionsFor(ItemType t) => switch (t) {
        ItemType.anime => _animeSections,
        ItemType.manga => _mangaSections,
        ItemType.novel => novelSections,
      };

  List<Source> getInstalledExtensions(ItemType type) => _installedFor(type);
  List<Source> getAvailableExtensions(ItemType type) => _availableFor(type);

  Future<void> initExtensions({bool refresh = true}) async {
    try {
      _loadExtensionOrders();
      _restoreActiveSources();
      _refreshVisibility();
    } catch (e) {
      Logger.i('Error initializing extensions: $e');
    }
  }

  void _restoreActiveSources() {
    activeSource.value =
        _restore(installedExtensions, SourceKeys.activeSourceId);
    activeMangaSource.value =
        _restore(installedMangaExtensions, SourceKeys.activeMangaSourceId);
    activeNovelSource.value =
        _restore(installedNovelExtensions, SourceKeys.activeNovelSourceId);
  }

  Source? _restore(RxList<Source> list, SourceKeys key) {
    final id = KvHelper.get<String>(key.name, defaultVal: '');
    return (id.isNotEmpty
            ? list.firstWhereOrNull((s) => s.id.toString() == id)
            : null) ??
        list.firstOrNull;
  }

  void setActiveSource(Source source, {String? mediaId}) {
    final (rx, key, tag) = switch (source.itemType) {
      ItemType.anime => (activeSource, SourceKeys.activeSourceId, 'ANIME'),
      ItemType.manga => (
          activeMangaSource,
          SourceKeys.activeMangaSourceId,
          'MANGA'
        ),
      ItemType.novel => (
          activeNovelSource,
          SourceKeys.activeNovelSourceId,
          'NOVEL'
        ),
      _ => (activeSource, SourceKeys.activeSourceId, 'ANIME'),
    };

    if (rx.value?.id != source.id) {
      cancelInProgress(tag == 'ANIME' ? 'search' : 'manga_search');
      cancelInProgress(tag == 'ANIME' ? 'detail' : 'manga_detail');
    }

    rx.value = source;
    KvHelper.set(key.name, source.id.toString());
    if (mediaId != null) {
      DynamicKeys.stickySource.set(mediaId, source.id.toString());
    }
    lastUpdatedSource.value = tag;
  }

  Source? getSavedSource(String mediaId, ItemType type) {
    final savedId = DynamicKeys.stickySource.get<String?>(mediaId);
    if (savedId == null) return null;

    final list = _installedFor(type);
    return list.firstWhereOrNull((s) => s.id.toString() == savedId);
  }

  void savePreferredSource(String titleId, String sourceId) {
    DynamicKeys.stickySource.set(titleId, sourceId);
  }

  String? getPreferredSource(String titleId) {
    return DynamicKeys.stickySource.get<String?>(titleId);
  }

  Source? getExtensionByValue(String value, {String? mediaId}) =>
      _activateByName(installedExtensions, value, activeSource,
          SourceKeys.activeSourceId, 'ANIME',
          mediaId: mediaId);

  Source? getMangaExtensionByName(String name, {String? mediaId}) =>
      _activateByName(installedMangaExtensions, name, activeMangaSource,
          SourceKeys.activeMangaSourceId, 'MANGA',
          mediaId: mediaId);

  Source? getNovelExtensionByName(String name, {String? mediaId}) =>
      _activateByName(installedNovelExtensions, name, activeNovelSource,
          SourceKeys.activeNovelSourceId, 'NOVEL',
          mediaId: mediaId);

  Source? _activateByName(
    List<Source> sources,
    String name,
    Rxn<Source> rx,
    SourceKeys key,
    String tag, {
    String? mediaId,
  }) {
    print('Activating extension by name: $name');
    final match = sources.firstWhereOrNull(
      (s) =>
          s.id.toString() == name ||
          '${s.name}-${s.lang?.toUpperCase()}-${s.runtimeType}' == name ||
          s.name == name,
    );

    if (match != null) {
      if (rx.value?.id != match.id) {
        cancelInProgress(tag == 'ANIME' ? 'search' : 'manga_search');
        cancelInProgress(tag == 'ANIME' ? 'detail' : 'manga_detail');
      }
      rx.value = match;
      KvHelper.set(key.name, match.id.toString());
      if (mediaId != null) {
        DynamicKeys.stickySource.set(mediaId, match.id.toString());
      }
      lastUpdatedSource.value = tag;
      return match;
    }
    return null;
  }

  Future<void> fetchRepos() async {
    final activeTask = _repoRefreshTask;
    if (activeTask != null) {
      await activeTask;
      return;
    }

    final task = _refreshRepos();
    _repoRefreshTask = task;

    try {
      await task;
    } finally {
      if (identical(_repoRefreshTask, task)) {
        _repoRefreshTask = null;
      }
    }
  }

  Future<void> _refreshRepos() async {
    await _bridge.refreshExtensions(refreshAvailableSource: true);
    await initExtensions();
  }

  Future<void> refreshSourceState(Source source) async {
    final type = source.itemType;
    if (type == null) return;

    final managerId = getSourceManager(source).id;
    await _bridge.refreshManagerType(managerId, type);
    await initExtensions();
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) =>
      [Obx(() => Column(children: _animeSections.value))].obs;

  @override
  RxList<Widget> homeWidgets(BuildContext context) =>
      [Obx(() => Column(children: _homeSections.value))].obs;

  @override
  RxList<Widget> mangaWidgets(BuildContext context) => [
        Obx(() =>
            Column(children: [..._mangaSections.value, ...novelSections.value]))
      ].obs;

  @override
  Future<void> fetchHomePage() async {
    try {
      _buildOfflineSections();
      _homeReady = true;

      for (final type in ItemType.values) {
        _syncSections(type);
      }
    } catch (e) {
      Logger.i('Error in fetchHomePage: $e');
      errorSnackBar('Failed to fetch data from sources.');
    }
  }

  void _buildOfflineSections() {
    final idx = ServicesType.extensions.index;
    final animeLibrary = isar.offlineMedias
        .filter()
        .serviceIndexEqualTo(idx)
        .mediaTypeIndexEqualTo(1)
        .findAllSync();
    final mangaLibrary = isar.offlineMedias
        .filter()
        .serviceIndexEqualTo(idx)
        .mediaTypeIndexEqualTo(0)
        .findAllSync();

    _homeSections.value = [
      buildSection(
        'Continue Watching',
        animeLibrary,
        variant: DataVariant.offline,
      ),
      buildSection(
        'Continue Reading',
        mangaLibrary,
        variant: DataVariant.offline,
        type: ItemType.manga,
      ),
    ];
  }

  void _syncSections(ItemType type) {
    final sources = _installedFor(type);
    final cache = _widgetCache[type]!;
    final sections = _sectionsFor(type);

    final liveIds = {for (final s in sources) s.id};
    final cachedIds = cache.keys.toSet();

    final added = liveIds.difference(cachedIds);
    final removed = cachedIds.difference(liveIds);

    if (added.isEmpty && removed.isEmpty) return;

    for (final id in removed) {
      cache.remove(id);
    }

    for (final src in sources.where((s) => added.contains(s.id))) {
      cache[src.id?.toInt() ?? 0] = buildFutureSection(
        src.name ?? '??',
        src.methods.getPopular(1).then((r) => r.list),
        type: type,
        variant: DataVariant.extension,
        source: src,
      );
    }

    sections.value = [
      if (cache.isNotEmpty && type != ItemType.novel)
        CustomSearchBar(
          disableIcons: true,
          onSubmitted: (v) => SourceSearchPage(initialTerm: v, type: type).go(),
        ),
      ...cache.values,
    ];
  }

  Future<void> initNovelExtensions() async {
    if (_widgetCache[ItemType.novel]!.isNotEmpty) return;
    _syncSections(ItemType.novel);
  }

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    final isAnime = lastUpdatedSource.value == 'ANIME';
    final source = isAnime ? activeSource.value! : activeMangaSource.value!;
    final data = await source.methods.getDetail(DMedia.withUrl(params.id));

    if (serviceHandler.serviceType.value != ServicesType.extensions) {
      cacheController.addCache(data.toJson());
    }
    return Media.froDMedia(data, isAnime ? ItemType.anime : ItemType.manga);
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final source =
        params.isManga ? activeMangaSource.value : activeSource.value;
    final type = params.isManga ? ItemType.manga : ItemType.anime;
    return (await source!.methods.search(params.query, params.page, []))
        .list
        .map((e) => Media.froDMedia(e, type))
        .toList();
  }

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // await _bridge.checkForUpdates();
      final updatesCount = [
        ...availableExtensions,
        ...availableMangaExtensions,
        ...availableNovelExtensions
      ].where((s) => (s.hasUpdate ?? false)).length;

      if (updatesCount > 0) {
        snackString("Updates available for $updatesCount extensions");
      }
    } catch (e) {
      Logger.e('Error checking for updates: $e');
    }
  }
}
