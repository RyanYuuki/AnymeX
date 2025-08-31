// ignore_for_file: unnecessary_null_comparison, invalid_use_of_protected_member

import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/storage_provider.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:hive/hive.dart';

final sourceController = Get.put(SourceController());

class SourceController extends GetxController implements BaseService {
  var availableExtensions = <Source>[].obs;
  var availableMangaExtensions = <Source>[].obs;
  var availableNovelExtensions = <Source>[].obs;

  var installedExtensions = <Source>[].obs;
  var activeSource = Rxn<Source>();

  var installedDownloaderExtensions = <Source>[].obs;

  var installedMangaExtensions = <Source>[].obs;
  var activeMangaSource = Rxn<Source>();

  var installedNovelExtensions = <Source>[].obs;
  var activeNovelSource = Rxn<Source>();

  var lastUpdatedSource = "".obs;

  final _animeSections = <Widget>[].obs;
  final _homeSections = <Widget>[].obs;
  final _mangaSections = <Widget>[].obs;
  final novelSections = <Widget>[].obs;

  final isExtensionsServiceAllowed = false.obs;
  final RxString _activeAnimeRepo = ''.obs;
  final RxString _activeMangaRepo = ''.obs;
  final RxString _activeNovelRepo = ''.obs;
  final RxString _activeAniyomiAnimeRepo = ''.obs;
  final RxString _activeAniyomiMangaRepo = ''.obs;

  final RxBool shouldShowExtensions = false.obs;

  String get activeAnimeRepo => _activeAnimeRepo.value;
  set activeAnimeRepo(String value) {
    _activeAnimeRepo.value = value;
    saveRepoSettings();
  }

  String get activeMangaRepo => _activeMangaRepo.value;
  set activeMangaRepo(String value) {
    _activeMangaRepo.value = value;
    saveRepoSettings();
  }

  String get activeNovelRepo => _activeNovelRepo.value;
  set activeNovelRepo(String value) {
    _activeNovelRepo.value = value;
    saveRepoSettings();
  }

  String get activeAniyomiAnimeRepo => _activeAniyomiAnimeRepo.value;
  set activeAniyomiAnimeRepo(String value) {
    _activeAniyomiAnimeRepo.value = value;
    saveRepoSettings();
  }

  String get activeAniyomiMangaRepo => _activeAniyomiMangaRepo.value;
  set activeAniyomiMangaRepo(String value) {
    _activeAniyomiMangaRepo.value = value;
    saveRepoSettings();
  }

  void setAnimeRepo(String val, ExtensionType type) {
    if (type == ExtensionType.aniyomi) {
      Logger.i('Settings Aniyomi repo: $val');
      activeAniyomiAnimeRepo = val;
    } else {
      Logger.i('Settings Mangayomi repo: $val');
      activeAnimeRepo = val;
    }
  }

  void setMangaRepo(String val, ExtensionType type) {
    if (type == ExtensionType.aniyomi) {
      activeAniyomiMangaRepo = val;
    } else {
      activeMangaRepo = val;
    }
  }

  String getAnimeRepo(ExtensionType type) {
    if (type == ExtensionType.aniyomi) {
      Logger.i('Getting Aniyomi repo');
      return activeAniyomiAnimeRepo;
    } else {
      Logger.i('Getting Mangayomi repo');
      return activeAnimeRepo;
    }
  }

  String getMangaRepo(ExtensionType type) {
    if (type == ExtensionType.aniyomi) {
      return activeAniyomiMangaRepo;
    } else {
      return activeMangaRepo;
    }
  }

  void saveRepoSettings() {
    final box = Hive.box('themeData');
    box.put("activeAnimeRepo", _activeAnimeRepo.value);
    box.put("activeMangaRepo", _activeMangaRepo.value);
    box.put("activeNovelRepo", _activeNovelRepo.value);
    box.put("activeAniyomiAnimeRepo", _activeAniyomiAnimeRepo.value);
    box.put("activeAniyomiMangaRepo", _activeAniyomiMangaRepo.value);
    shouldShowExtensions.value = [
      _activeAnimeRepo.value,
      _activeAniyomiAnimeRepo.value,
      _activeMangaRepo.value,
      _activeAniyomiMangaRepo.value,
      _activeNovelRepo.value,
      installedExtensions,
      installedMangaExtensions,
      installedNovelExtensions,
    ].any((e) => (e as dynamic).isNotEmpty);
  }

  @override
  void onInit() {
    super.onInit();

    _initialize();
  }

  void _initialize() async {
    isar = await StorageProvider().initDB(null);
    await DartotsuExtensionBridge().init(isar, 'AnymeX');

    await initExtensions();

    if (Get.find<ServiceHandler>().serviceType.value ==
        ServicesType.extensions) {
      fetchHomePage();
    }
  }

  Future<List<Source>> _getInstalledExtensions(
      Future<List<Source>> Function() fetchFn) async {
    return await fetchFn();
  }

  List<Source> _getAvailableExtensions(List<Source> Function() fetchFn) {
    return fetchFn();
  }

  Future<void> sortAnimeExtensions() async {
    final types = ExtensionType.values.where((e) {
      if (!Platform.isAndroid && e == ExtensionType.aniyomi) return false;
      return true;
    });

    final installed = <Source>[];
    final available = <Source>[];

    for (final type in types) {
      final manager = type.getManager();
      installed.addAll(await _getInstalledExtensions(
          () => manager.getInstalledAnimeExtensions()));
      available.addAll(_getAvailableExtensions(
          () => manager.availableAnimeExtensions.value));
    }

    installedExtensions.value = installed;
    availableExtensions.value = available;

    installedDownloaderExtensions.value = installed
        .where((e) => e.name?.contains('Downloader') ?? false)
        .toList();
  }

  Future<void> sortMangaExtensions() async {
    final types = ExtensionType.values.where((e) {
      if (!Platform.isAndroid && e == ExtensionType.aniyomi) return false;
      return true;
    });

    final installed = <Source>[];
    final available = <Source>[];

    for (final type in types) {
      final manager = type.getManager();
      installed.addAll(await _getInstalledExtensions(
          () => manager.getInstalledMangaExtensions()));
      available.addAll(_getAvailableExtensions(
          () => manager.availableMangaExtensions.value));
    }

    installedMangaExtensions.value = installed;
    availableMangaExtensions.value = available;
  }

  Future<void> sortNovelExtensions() async {
    final types = ExtensionType.values.where((e) {
      if (!Platform.isAndroid && e == ExtensionType.aniyomi) return false;
      return true;
    });

    final installed = <Source>[];
    final available = <Source>[];

    for (final type in types) {
      final manager = type.getManager();
      installed.addAll(await _getInstalledExtensions(
          () => manager.getInstalledNovelExtensions()));
      available.addAll(_getAvailableExtensions(
          () => manager.availableNovelExtensions.value));
    }

    installedNovelExtensions.value = installed;
    availableNovelExtensions.value = available;
  }

  Future<void> sortAllExtensions() async {
    await Future.wait([
      sortAnimeExtensions(),
      sortMangaExtensions(),
      sortNovelExtensions(),
    ]);
  }

  Future<void> initExtensions({bool refresh = true}) async {
    try {
      await sortAllExtensions();
      final box = Hive.box('themeData');
      final savedActiveSourceId =
          box.get('activeSourceId', defaultValue: '') as String?;
      final savedActiveMangaSourceId =
          box.get('activeMangaSourceId', defaultValue: '') as String;
      final savedActiveNovelSourceId =
          box.get('activeNovelSourceId', defaultValue: '') as String;
      isExtensionsServiceAllowed.value =
          box.get('extensionsServiceAllowed', defaultValue: false);

      activeSource.value = installedExtensions.firstWhereOrNull(
          (source) => source.id.toString() == savedActiveSourceId);
      activeMangaSource.value = installedMangaExtensions.firstWhereOrNull(
          (source) => source.id.toString() == savedActiveMangaSourceId);
      activeNovelSource.value = installedNovelExtensions.firstWhereOrNull(
          (source) => source.id.toString() == savedActiveNovelSourceId);

      activeSource.value ??= installedExtensions.firstOrNull;
      activeMangaSource.value ??= installedMangaExtensions.firstOrNull;
      activeNovelSource.value ??= installedNovelExtensions.firstOrNull;

      _activeAnimeRepo.value = box.get("activeAnimeRepo", defaultValue: '');
      _activeMangaRepo.value = box.get("activeMangaRepo", defaultValue: '');
      _activeNovelRepo.value = box.get("activeNovelRepo", defaultValue: '');
      _activeAniyomiAnimeRepo.value =
          box.get("activeAniyomiAnimeRepo", defaultValue: '');
      _activeAniyomiMangaRepo.value =
          box.get("activeAniyomiMangaRepo", defaultValue: '');

      shouldShowExtensions.value = [
        _activeAnimeRepo.value,
        _activeAniyomiAnimeRepo.value,
        _activeMangaRepo.value,
        _activeAniyomiMangaRepo.value,
        _activeNovelRepo.value,
        installedExtensions,
        installedMangaExtensions,
        installedNovelExtensions,
      ].any((e) => (e as dynamic).isNotEmpty);

      Logger.i('Extensions initialized.');
    } catch (e) {
      Logger.i('Error initializing extensions: $e');
    }
  }

  bool isEmpty(dynamic val) => val.isEmpty;

  void setActiveSource(Source source) {
    if (source.itemType == ItemType.manga) {
      activeMangaSource.value = source;
      Hive.box('themeData').put('activeMangaSourceId', source.id);
      lastUpdatedSource.value = 'MANGA';
    } else if (source.itemType == ItemType.anime) {
      activeSource.value = source;
      Hive.box('themeData').put('activeSourceId', source.id);
      lastUpdatedSource.value = 'ANIME';
    } else {
      activeNovelSource.value = source;
      Hive.box('themeData').put('activeNovelSourceId', source.id);
      lastUpdatedSource.value = 'NOVEL';
    }
  }

  List<Source> getInstalledExtensions(ItemType type) {
    switch (type) {
      case ItemType.anime:
        return installedExtensions;
      case ItemType.manga:
        return installedMangaExtensions;
      case ItemType.novel:
        return installedNovelExtensions;
    }
  }

  List<Source> getAvailableExtensions(ItemType type) {
    switch (type) {
      case ItemType.anime:
        return availableExtensions;
      case ItemType.manga:
        return availableMangaExtensions;
      case ItemType.novel:
        return availableNovelExtensions;
    }
  }

  Future<void> fetchRepos() async {
    final extenionTypes = ExtensionType.values.where((e) {
      if (!Platform.isAndroid) {
        if (e == ExtensionType.aniyomi) {
          return false;
        }
      }
      return true;
    }).toList();
    Logger.i(extenionTypes.length.toString());

    for (var type in extenionTypes) {
      await type
          .getManager()
          .fetchAvailableAnimeExtensions([getAnimeRepo(type)]);
      await type
          .getManager()
          .fetchAvailableMangaExtensions([getMangaRepo(type)]);
      await type.getManager().fetchAvailableNovelExtensions([
        activeNovelRepo,
      ]);
    }
    await initExtensions();
  }

  Source? getExtensionByName(String name) {
    final selectedSource = installedExtensions.firstWhereOrNull((source) =>
        '${source.name} (${source.lang?.toUpperCase()})' == name ||
        source.name == name);

    if (selectedSource != null) {
      activeSource.value = selectedSource;
      Hive.box('themeData').put('activeSourceId', selectedSource.id);
      return activeSource.value;
    }
    lastUpdatedSource.value = 'ANIME';
    return null;
  }

  Source? getMangaExtensionByName(String name) {
    final selectedMangaSource = installedMangaExtensions.firstWhereOrNull(
        (source) =>
            '${source.name} (${source.lang?.toUpperCase()})' == name ||
            source.name == name);

    if (selectedMangaSource != null) {
      activeMangaSource.value = selectedMangaSource;
      Hive.box('themeData').put('activeMangaSourceId', selectedMangaSource.id);
      return activeMangaSource.value;
    }
    lastUpdatedSource.value = 'MANGA';
    return null;
  }

  Source? getNovelExtensionByName(String name) {
    final selectedNovelSource = installedNovelExtensions.firstWhereOrNull(
        (source) =>
            '${source.name} (${source.lang?.toUpperCase()})' == name ||
            source.name == name);

    if (selectedNovelSource != null) {
      activeNovelSource.value = selectedNovelSource;
      Hive.box('themeData').put('activeNovelSourceId', selectedNovelSource.id);
      return activeNovelSource.value;
    }
    lastUpdatedSource.value = 'NOVEL';
    return null;
  }

  void _initializeEmptySections() {
    final offlineStorage = Get.find<OfflineStorageController>();
    _animeSections.value = [const Center(child: AnymexProgressIndicator())];
    _mangaSections.value = [const Center(child: AnymexProgressIndicator())];
    novelSections.value = [const Center(child: AnymexProgressIndicator())];
    _homeSections.value = [
      Obx(
        () => buildSection(
            "Continue Watching",
            offlineStorage.animeLibrary
                .where((e) => e.serviceIndex == ServicesType.extensions.index)
                .toList(),
            variant: DataVariant.offline),
      ),
      Obx(() {
        return buildSection(
            "Continue Reading",
            offlineStorage.mangaLibrary
                .where((e) => e.serviceIndex == ServicesType.extensions.index)
                .toList(),
            variant: DataVariant.offline,
            type: ItemType.manga);
      }),
      Obx(() {
        return buildSection(
            "Continue Reading",
            offlineStorage.mangaLibrary
                .where((e) => e.serviceIndex == ServicesType.extensions.index)
                .toList(),
            variant: DataVariant.offline,
            type: ItemType.manga);
      }),
    ];
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) => [
        Obx(() {
          return Column(
            children: _animeSections.value,
          );
        })
      ].obs;

  @override
  RxList<Widget> homeWidgets(BuildContext context) => [
        Obx(() {
          return Column(
            children: _homeSections.value,
          );
        })
      ].obs;

  @override
  RxList<Widget> mangaWidgets(BuildContext context) => [
        Obx(() {
          return Column(
            children: [..._mangaSections.value, ...novelSections.value],
          );
        })
      ].obs;

  Future<void> initNovelExtensions() async {
    if (novelSections.isNotEmpty) return;
    novelSections.value = [
      const SizedBox(),
    ];
    for (final source in installedNovelExtensions) {
      _fetchSourceData(source,
          targetSections: novelSections, type: ItemType.novel);
    }
  }

  @override
  Future<void> fetchHomePage() async {
    try {
      _initializeEmptySections();

      for (final source in installedExtensions) {
        _fetchSourceData(source,
            targetSections: _animeSections, type: ItemType.anime);
      }

      for (final source in installedMangaExtensions) {
        _fetchSourceData(source,
            targetSections: _mangaSections, type: ItemType.manga);
      }

      initNovelExtensions();

      Logger.i('Fetched home page data.');
    } catch (error) {
      Logger.i('Error in fetchHomePage: $error');
      errorSnackBar('Failed to fetch data from sources.');
    }
  }

  Future<void> _fetchSourceData(
    Source source, {
    required RxList<Widget> targetSections,
    required ItemType type,
  }) async {
    try {
      final future = source.methods.getPopular(1).then((result) => result.list);

      final newSection = buildFutureSection(
        source.name ?? '??',
        future,
        type: type,
        variant: DataVariant.extension,
        source: source,
      );

      if (targetSections.first is Center && type != ItemType.novel) {
        targetSections.value = [];
        targetSections.add(CustomSearchBar(
          disableIcons: true,
          onSubmitted: (v) {
            SourceSearchPage(initialTerm: v, type: type).go();
          },
        ));
      }
      targetSections.add(newSection);

      Logger.i('Data fetched and updated for ${source.name}');
    } catch (e) {
      Logger.i('Error fetching data from ${source.name}: $e');
    }
  }

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    final id = params.id;

    final isAnime = lastUpdatedSource.value == "ANIME";
    final data =
        await (!isAnime ? activeMangaSource.value! : activeSource.value!)
            .methods
            .getDetail(DMedia.withUrl(id));

    if (serviceHandler.serviceType.value != ServicesType.extensions) {
      cacheController.addCache(data.toJson());
    }
    return Media.froDMedia(data, isAnime ? ItemType.anime : ItemType.manga);
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final source =
        params.isManga ? activeMangaSource.value : activeSource.value;
    final data = (await source!.methods.search(params.query, 1, [])).list;
    return data
        .map((e) => Media.froDMedia(
            e, params.isManga ? ItemType.manga : ItemType.anime))
        .toList();
  }
}
