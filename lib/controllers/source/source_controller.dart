// ignore_for_file: unnecessary_null_comparison

import 'dart:developer';
import 'dart:async';
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/core/Search/get_detail.dart';
import 'package:anymex/core/Search/get_popular.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/non_widgets/extensions_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:anymex/core/Extensions/extensions_provider.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anymex/core/Search/search.dart' as m;

final sourceController = Get.put(SourceController());

class SourceController extends GetxController implements BaseService {
  var installedExtensions = <Source>[].obs;
  var activeSource = Rxn<Source>();

  var installedMangaExtensions = <Source>[].obs;
  var activeMangaSource = Rxn<Source>();

  var installedNovelExtensions = <Source>[].obs;
  var activeNovelSource = Rxn<Source>();

  var lastUpdatedSource = "".obs;

  final _animeSections = <Widget>[].obs;
  final _homeSections = <Widget>[].obs;
  final _mangaSections = <Widget>[].obs;

  final isExtensionsServiceAllowed = false.obs;
  final RxString _activeAnimeRepo = ''.obs;
  final RxString _activeMangaRepo = ''.obs;
  final RxString _activeNovelRepo = ''.obs;

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

  void saveRepoSettings() {
    final box = Hive.box('themeData');
    box.put("activeAnimeRepo", _activeAnimeRepo.value);
    box.put("activeMangaRepo", _activeMangaRepo.value);
    box.put("activeNovelRepo", _activeNovelRepo.value);
    log("Anime Repo: $activeAnimeRepo, Manga Repo: $activeMangaRepo, Novel Repo: $activeNovelRepo");
  }

  @override
  void onInit() {
    super.onInit();
    initExtensions().then((e) {
      if (Get.find<ServiceHandler>().serviceType.value ==
          ServicesType.extensions) {
        return fetchHomePage();
      }
    });
  }

  Future<void> initExtensions({bool refresh = true}) async {
    try {
      final container = ProviderContainer();
      final extensions = await container
          .read(getExtensionsStreamProvider(MediaType.anime).future);
      final mangaExtensions = await container
          .read(getExtensionsStreamProvider(MediaType.manga).future);
      final novelExtensions = await container
          .read(getExtensionsStreamProvider(MediaType.novel).future);

      installedExtensions.value =
          extensions.where((e) => e.isAdded ?? false).toList();
      installedMangaExtensions.value =
          mangaExtensions.where((e) => e.isAdded ?? false).toList();
      installedNovelExtensions.value =
          novelExtensions.where((e) => e.isAdded ?? false).toList();

      final box = Hive.box('themeData');
      final savedActiveSourceId = box.get('activeSourceId') as int?;
      final savedActiveMangaSourceId = box.get('activeMangaSourceId') as int?;
      final savedActiveNovelSourceId = box.get('activeNovelSourceId') as int?;
      isExtensionsServiceAllowed.value =
          box.get('extensionsServiceAllowed', defaultValue: false);

      activeSource.value = installedExtensions
          .firstWhereOrNull((source) => source.id == savedActiveSourceId);
      activeMangaSource.value = installedMangaExtensions
          .firstWhereOrNull((source) => source.id == savedActiveMangaSourceId);
      activeNovelSource.value = installedNovelExtensions
          .firstWhereOrNull((source) => source.id == savedActiveNovelSourceId);

      if (activeSource.value == null && installedExtensions.isNotEmpty) {
        activeSource.value = installedExtensions[0];
      }
      if (activeMangaSource.value == null &&
          installedMangaExtensions.isNotEmpty) {
        activeMangaSource.value = installedMangaExtensions[0];
      }
      if (activeNovelSource.value == null &&
          installedNovelExtensions.isNotEmpty) {
        activeNovelSource.value = installedNovelExtensions[0];
      }

      _activeAnimeRepo.value = box.get("activeAnimeRepo", defaultValue: '');
      _activeMangaRepo.value = box.get("activeMangaRepo", defaultValue: '');
      _activeNovelRepo.value = box.get("activeNovelRepo", defaultValue: '');

      log('Extensions initialized.');
    } catch (e) {
      log('Error initializing extensions: $e');
      errorSnackBar('Failed to initialize extensions.');
    }
  }

  void setActiveSource(Source source) {
    if (source.itemType == MediaType.manga) {
      activeMangaSource.value = source;
      Hive.box('themeData').put('activeMangaSourceId', source.id);
      lastUpdatedSource.value = 'MANGA';
    } else if (source.itemType == MediaType.anime) {
      activeSource.value = source;
      Hive.box('themeData').put('activeSourceId', source.id);
      lastUpdatedSource.value = 'ANIME';
    } else {
      activeSource.value = source;
      Hive.box('themeData').put('activeNovelSourceId', source.id);
      lastUpdatedSource.value = 'NOVEL';
    }
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
            isManga: true);
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
            children: _mangaSections.value,
          );
        })
      ].obs;

  @override
  Future<void> fetchHomePage() async {
    try {
      _initializeEmptySections();

      for (final source in installedExtensions) {
        _fetchSourceData(source,
            targetSections: _animeSections, isManga: false);
      }

      for (final source in installedMangaExtensions) {
        _fetchSourceData(source, targetSections: _mangaSections, isManga: true);
      }

      log('Fetched home page data.');
    } catch (error) {
      log('Error in fetchHomePage: $error');
      errorSnackBar('Failed to fetch data from sources.');
    }
  }

  Future<void> _fetchSourceData(
    Source source, {
    required RxList<Widget> targetSections,
    required bool isManga,
  }) async {
    try {
      final data = await getPopular(source: source);

      if (data == null || data.isEmpty) {
        log('No data fetched from ${source.name}');
        return;
      }

      final newSection = buildSection(
        source.name ?? '??',
        data,
        isManga: isManga,
        variant: DataVariant.extension,
        source: source,
      );

      if (targetSections.first is Center) {
        targetSections.value = [];
        targetSections.add(CustomSearchBar(
          disableIcons: true,
          onSubmitted: (v) {
            extensionSheet(
                v, isManga ? installedMangaExtensions : installedExtensions);
          },
        ));
      }
      targetSections.add(newSection);

      log('Data fetched and updated for ${source.name}');
    } catch (e) {
      log('Error fetching data from ${source.name}: $e');
    }
  }

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    final id = params.id;

    final isAnime = lastUpdatedSource.value == "ANIME";
    final data = await getDetail(
        url: id,
        source: (isAnime ? activeSource.value : activeMangaSource.value)!);
    if (serviceHandler.serviceType.value != ServicesType.extensions) {
      cacheController.addCache(data!.toJson());
    }
    return Media.fromManga(data!, isAnime ? MediaType.anime : MediaType.manga);
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final data = await m.search(
        source:
            (params.isManga ? activeMangaSource.value : activeSource.value)!,
        query: params.query,
        page: 1,
        filterList: []);
    return data
            ?.map((e) => Media.fromManga(e ?? MManga(),
                params.isManga ? MediaType.manga : MediaType.anime))
            .toList() ??
        [];
  }
}
