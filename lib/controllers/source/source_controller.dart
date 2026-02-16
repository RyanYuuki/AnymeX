import 'dart:async';
import 'dart:io';

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
import 'package:dartotsu_extension_bridge/Aniyomi/AniyomiExtensions.dart';
import 'package:dartotsu_extension_bridge/Mangayomi/MangayomiExtensions.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    hide isar;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

import '../../main.dart';

final sourceController = Get.put(SourceController());

class SourceController extends GetxController implements BaseService {
  static final _isAndroid = Platform.isAndroid;
  static final _extTypes = [
    ExtensionType.mangayomi,
    if (_isAndroid) ExtensionType.aniyomi,
  ];

  final availableExtensions = <Source>[].obs;
  final availableMangaExtensions = <Source>[].obs;
  final availableNovelExtensions = <Source>[].obs;

  final installedExtensions = <Source>[].obs;
  final installedMangaExtensions = <Source>[].obs;
  final installedNovelExtensions = <Source>[].obs;
  final installedDownloaderExtensions = <Source>[].obs;

  final activeSource = Rxn<Source>();
  final activeMangaSource = Rxn<Source>();
  final activeNovelSource = Rxn<Source>();
  final lastUpdatedSource = ''.obs;

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

  static const _kAnimeRepo = 'activeAnimeRepo';
  static const _kMangaRepo = 'activeMangaRepo';
  static const _kNovelRepo = 'activeNovelRepo';
  static const _kAniyomiAnimeRepo = 'activeAniyomiAnimeRepo';
  static const _kAniyomiMangaRepo = 'activeAniyomiMangaRepo';
  static const _allRepoKeys = [
    _kAnimeRepo,
    _kMangaRepo,
    _kNovelRepo,
    _kAniyomiAnimeRepo,
    _kAniyomiMangaRepo,
  ];

  final _repos = <String, String>{};

  final _pendingRebuilds = <ItemType>{};
  Timer? _rebuildTimer;
  bool _homeReady = false;

  String get activeAnimeRepo => _repos[_kAnimeRepo] ?? '';
  set activeAnimeRepo(String v) => _persistRepo(_kAnimeRepo, v);

  String get activeMangaRepo => _repos[_kMangaRepo] ?? '';
  set activeMangaRepo(String v) => _persistRepo(_kMangaRepo, v);

  String get activeNovelRepo => _repos[_kNovelRepo] ?? '';
  set activeNovelRepo(String v) => _persistRepo(_kNovelRepo, v);

  String get activeAniyomiAnimeRepo => _repos[_kAniyomiAnimeRepo] ?? '';
  set activeAniyomiAnimeRepo(String v) => _persistRepo(_kAniyomiAnimeRepo, v);

  String get activeAniyomiMangaRepo => _repos[_kAniyomiMangaRepo] ?? '';
  set activeAniyomiMangaRepo(String v) => _persistRepo(_kAniyomiMangaRepo, v);

  void _persistRepo(String key, String value) {
    if (_repos[key] == value) return;
    _repos[key] = value;
    _setStringKey(key, value);
    _refreshVisibility();
  }

  void _refreshVisibility() {
    shouldShowExtensions.value = _repos.values.any((v) => v.isNotEmpty) ||
        installedExtensions.isNotEmpty ||
        installedMangaExtensions.isNotEmpty ||
        installedNovelExtensions.isNotEmpty;
  }

  void saveRepoSettings() => _refreshVisibility();

  void setAnimeRepo(String val, ExtensionType type) =>
      type == ExtensionType.aniyomi
          ? activeAniyomiAnimeRepo = val
          : activeAnimeRepo = val;

  void setMangaRepo(String val, ExtensionType type) =>
      type == ExtensionType.aniyomi
          ? activeAniyomiMangaRepo = val
          : activeMangaRepo = val;

  String getAnimeRepo(ExtensionType type) =>
      type == ExtensionType.aniyomi ? activeAniyomiAnimeRepo : activeAnimeRepo;

  String getMangaRepo(ExtensionType type) =>
      type == ExtensionType.aniyomi ? activeAniyomiMangaRepo : activeMangaRepo;

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

  Future<void> sortAnimeExtensions() => _sortType(ItemType.anime);
  Future<void> sortMangaExtensions() => _sortType(ItemType.manga);
  Future<void> sortNovelExtensions() => _sortType(ItemType.novel);
  Future<void> sortAllExtensions() =>
      Future.wait(ItemType.values.map(_sortType));

  Future<void> _sortType(ItemType type) async {
    final installed = <Source>[];
    final available = <Source>[];

    for (final ext in _extTypes) {
      final mgr = ext.getManager();
      switch (type) {
        case ItemType.anime:
          installed.addAll(await mgr.getInstalledAnimeExtensions());
          available.addAll(mgr.availableAnimeExtensions.value);
        case ItemType.manga:
          installed.addAll(await mgr.getInstalledMangaExtensions());
          available.addAll(mgr.availableMangaExtensions.value);
        case ItemType.novel:
          installed.addAll(await mgr.getInstalledNovelExtensions());
          available.addAll(mgr.availableNovelExtensions.value);
      }
    }

    _applyDiff(_installedFor(type), installed);
    _applyDiff(_availableFor(type), available);

    if (type == ItemType.anime) {
      _applyDiff(
        installedDownloaderExtensions,
        installed
            .where((s) => s.name?.contains('Downloader') ?? false)
            .toList(),
      );
    }
  }

  void _applyDiff(RxList<Source> target, List<Source> next) {
    final oldIds = {for (final s in target) s.id};
    final newIds = {for (final s in next) s.id};
    if (oldIds.length == newIds.length && oldIds.containsAll(newIds)) return;
    target.value = next;
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
      await sortAllExtensions();
      _loadRepos();
      _restoreActiveSources();
      _refreshVisibility();
    } catch (e) {
      Logger.i('Error initializing extensions: $e');
    }
  }

  void _loadRepos() {
    for (final key in _allRepoKeys) {
      _repos[key] = _getStringKey(key);
    }
    isExtensionsServiceAllowed.value =
        SourceKeys.extensionsServiceAllowed.get<bool>(false);
  }

  void _restoreActiveSources() {
    activeSource.value = _restore(installedExtensions, 'activeSourceId');
    activeMangaSource.value =
        _restore(installedMangaExtensions, 'activeMangaSourceId');
    activeNovelSource.value =
        _restore(installedNovelExtensions, 'activeNovelSourceId');
  }

  Source? _restore(RxList<Source> list, String key) {
    final id = _getStringKey(key);
    return (id.isNotEmpty
            ? list.firstWhereOrNull((s) => s.id.toString() == id)
            : null) ??
        list.firstOrNull;
  }

  void setActiveSource(Source source) {
    final (rx, key, tag) = switch (source.itemType) {
      ItemType.anime => (activeSource, 'activeSourceId', 'ANIME'),
      ItemType.manga => (activeMangaSource, 'activeMangaSourceId', 'MANGA'),
      ItemType.novel => (activeNovelSource, 'activeNovelSourceId', 'NOVEL'),
      _ => (activeSource, 'activeSourceId', 'ANIME'),
    };
    rx.value = source;
    _setStringKey(key, source.id.toString());
    lastUpdatedSource.value = tag;
  }

  Source? getExtensionByName(String name) => _activateByName(
      installedExtensions, name, activeSource, 'activeSourceId', 'ANIME');

  Source? getMangaExtensionByName(String name) => _activateByName(
      installedMangaExtensions,
      name,
      activeMangaSource,
      'activeMangaSourceId',
      'MANGA');

  Source? getNovelExtensionByName(String name) => _activateByName(
      installedNovelExtensions,
      name,
      activeNovelSource,
      'activeNovelSourceId',
      'NOVEL');

  Source? _activateByName(
    List<Source> sources,
    String name,
    Rxn<Source> rx,
    String key,
    String tag,
  ) {
    final match = sources.firstWhereOrNull(
      (s) => '${s.name} (${s.lang?.toUpperCase()})' == name || s.name == name,
    );
    if (match != null) {
      rx.value = match;
      _setStringKey(key, match.id.toString());
      return match;
    }
    lastUpdatedSource.value = tag;
    return null;
  }

  String _getStringKey(String key) {
    return switch (key) {
      _kAnimeRepo => SourceKeys.activeAnimeRepo.get<String>(""),
      _kMangaRepo => SourceKeys.activeMangaRepo.get<String>(""),
      _kNovelRepo => SourceKeys.activeNovelRepo.get<String>(""),
      _kAniyomiAnimeRepo =>
        SourceKeys.activeAniyomiAnimeRepo.get<String>(""),
      _kAniyomiMangaRepo =>
        SourceKeys.activeAniyomiMangaRepo.get<String>(""),
      'activeSourceId' => SourceKeys.activeSourceId.get<String>(""),
      'activeMangaSourceId' =>
        SourceKeys.activeMangaSourceId.get<String>(""),
      'activeNovelSourceId' =>
        SourceKeys.activeNovelSourceId.get<String>(""),
      _ => '',
    };
  }

  void _setStringKey(String key, String value) {
    switch (key) {
      case _kAnimeRepo:
        SourceKeys.activeAnimeRepo.set(value);
        break;
      case _kMangaRepo:
        SourceKeys.activeMangaRepo.set(value);
        break;
      case _kNovelRepo:
        SourceKeys.activeNovelRepo.set(value);
        break;
      case _kAniyomiAnimeRepo:
        SourceKeys.activeAniyomiAnimeRepo.set(value);
        break;
      case _kAniyomiMangaRepo:
        SourceKeys.activeAniyomiMangaRepo.set(value);
        break;
      case 'activeSourceId':
        SourceKeys.activeSourceId.set(value);
        break;
      case 'activeMangaSourceId':
        SourceKeys.activeMangaSourceId.set(value);
        break;
      case 'activeNovelSourceId':
        SourceKeys.activeNovelSourceId.set(value);
        break;
    }
  }

  Future<void> fetchRepos() async {
    if (_isAndroid) Get.put(AniyomiExtensions(), tag: 'AniyomiExtensions');
    Get.put(MangayomiExtensions(), tag: 'MangayomiExtensions');

    await Future.wait([
      for (final type in _extTypes) ...[
        if (getAnimeRepo(type).isNotEmpty)
          type.getManager().fetchAvailableAnimeExtensions([getAnimeRepo(type)]),
        if (getMangaRepo(type).isNotEmpty)
          type.getManager().fetchAvailableMangaExtensions([getMangaRepo(type)]),
        if (activeNovelRepo.isNotEmpty)
          type.getManager().fetchAvailableNovelExtensions([activeNovelRepo]),
      ],
    ]);
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
      Obx(() => buildSection(
            'Continue Watching',
            animeLibrary,
            variant: DataVariant.offline,
          )),
      Obx(() => buildSection(
            'Continue Reading',
            mangaLibrary,
            variant: DataVariant.offline,
            type: ItemType.manga,
          )),
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
    return (await source!.methods.search(params.query, 1, []))
        .list
        .map((e) => Media.froDMedia(e, type))
        .toList();
  }
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      await fetchRepos();
      final updates = <Source>[];
      for (final source in installedExtensions) {
        final available =
            availableExtensions.firstWhereOrNull((s) => s.id == source.id);
        if (available != null &&
            (available.version ?? '') != (source.version ?? '')) {
          updates.add(available);
        }
      }

      for (final source in installedMangaExtensions) {
        final available =
            availableMangaExtensions.firstWhereOrNull((s) => s.id == source.id);
        if (available != null &&
            (available.version ?? '') != (source.version ?? '')) {
          updates.add(available);
        }
      }
      
      for (final source in installedNovelExtensions) {
        final available =
            availableNovelExtensions.firstWhereOrNull((s) => s.id == source.id);
        if (available != null &&
            (available.version ?? '') != (source.version ?? '')) {
          updates.add(available);
        }
      }

      if (updates.isNotEmpty) {
        snackString("Updates available for ${updates.length} extensions");
      }
    } catch (e) {
      Logger.e('Error checking for updates: $e');
    }
  }
}
