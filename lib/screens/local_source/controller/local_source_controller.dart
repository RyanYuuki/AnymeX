// controllers/watch_offline_controller.dart
import 'package:anymex/utils/logger.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:dartotsu_extension_bridge/Models/DEpisode.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart' as d;
import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/screens/local_source/controller/tmdb_api.dart';
import 'package:anymex/screens/local_source/model/detail_result.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

enum ViewMode { local, download, search }

class LocalSourceController extends GetxController
    with GetTickerProviderStateMixin {
  // Observable variables for local mode
  final RxList<FileSystemEntity> currentItems = <FileSystemEntity>[].obs;
  final RxString currentPath = ''.obs;
  final RxList<String> pathHistory = <String>[].obs;

  // Observable variables for download mode
  final RxList<FileSystemEntity> downloadItems = <FileSystemEntity>[].obs;
  final RxString downloadPath = ''.obs;
  final RxList<String> downloadPathHistory = <String>[].obs;

  // Common variables
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMedia = false.obs;
  final RxBool isLoadingServers = false.obs;
  final RxBool hasPermission = false.obs;
  final RxBool hasSelectedDirectory = false.obs;
  final RxMap<String, Uint8List?> thumbnailCache = <String, Uint8List?>{}.obs;
  final Rx<ViewMode> viewMode = ViewMode.local.obs;
  final Rxn<d.Source> selectedSource = Rxn();

  final supportsDownloads = false.obs;

  final Rxn<DetailResult?> selectedMedia = Rxn();
  final Rxn<DetailSeasons?> selectedSeason = Rxn();
  final Rxn<DetailEpisode?> selectedEpisode = Rxn();
  final RxList<Video> selectedVideos = RxList();

  final Set<String> watchableExtensions = {
    '.mp4',
    '.mkv',
    '.m3u8',
    '.avi',
    '.mov',
    '.wmv',
    '.flv'
  };

  @override
  void onInit() {
    super.onInit();
    // Initialize local path
    currentPath.value = settingsController.preferences
        .get('watch_offline_path', defaultValue: '');

    List<String>? savedHistory = settingsController.preferences
        .get('watch_offline_path_history', defaultValue: <String>[]);
    if (savedHistory != null) {
      pathHistory.value = savedHistory;
    }

    // Initialize download path
    downloadPath.value = settingsController.preferences
        .get('watch_offline_download_path', defaultValue: '');

    List<String>? savedDownloadHistory = settingsController.preferences
        .get('watch_offline_download_path_history', defaultValue: <String>[]);
    if (savedDownloadHistory != null) {
      downloadPathHistory.value = savedDownloadHistory;
    }

    ever(currentPath, (_) => _saveCurrentPath());
    ever(pathHistory, (_) => _savePathHistory());
    ever(downloadPath, (_) => _saveDownloadPath());
    ever(downloadPathHistory, (_) => _saveDownloadPathHistory());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedSource.value =
          sourceController.installedDownloaderExtensions.isNotEmpty
              ? sourceController.installedDownloaderExtensions.first
              : null;

      // supportsDownloads.value =
      //     sourceController.installedDownloaderExtensions.isNotEmpty;
      if (!supportsDownloads.value) {
        viewMode.value = ViewMode.local;
      }
      checkPermissionAndShowPicker();
      _initializeDownloadPath();
    });
  }

  @override
  void onClose() {
    super.onClose();
    _saveCurrentPath();
    _savePathHistory();
    _saveDownloadPath();
    _saveDownloadPathHistory();
  }

  void _saveCurrentPath() {
    if (currentPath.isNotEmpty) {
      settingsController.preferences
          .put('watch_offline_path', currentPath.value);
    }
  }

  void _savePathHistory() {
    settingsController.preferences
        .put('watch_offline_path_history', pathHistory.toList());
  }

  void _saveDownloadPath() {
    if (downloadPath.isNotEmpty) {
      settingsController.preferences
          .put('watch_offline_download_path', downloadPath.value);
    }
  }

  void _saveDownloadPathHistory() {
    settingsController.preferences.put(
        'watch_offline_download_path_history', downloadPathHistory.toList());
  }

  Future<void> _initializeDownloadPath() async {
    if (downloadPath.isEmpty) {
      // final defaultDownloadPath = await getDownloadPath();
      // downloadPath.value = defaultDownloadPath;
      await loadDownloadDirectory();
    }
  }

  Future<bool> onWillPop() async {
    return handleBackButton();
  }

  bool handleBackButton() {
    if (viewMode.value == ViewMode.local && canNavigateBack) {
      navigateBack();
      return false;
    } else if (viewMode.value == ViewMode.download && canNavigateBackDownload) {
      navigateBackDownload();
      return false;
    } else if (selectedVideos.isNotEmpty) {
      selectedVideos.clear();
      return false;
    } else if (selectedSeason.value != null) {
      selectedSeason.value = null;
      return false;
    } else if (selectedMedia.value != null) {
      selectedMedia.value = null;
      return false;
    }
    return true;
  }

  Future<void> checkPermissionAndShowPicker() async {
    isLoading.value = true;

    bool permission = await _requestPermission();
    hasPermission.value = permission;
    isLoading.value = false;

    if (permission) {
      if (currentPath.isNotEmpty) {
        await loadCurrentDirectory();
        hasSelectedDirectory.value = true;
        return;
      }
      await _setDefaultDirectory();
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isIOS) {
      return true;
    }

    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        Logger.i('Android SDK version: $sdkInt');

        if (sdkInt >= 33) {
          final permissions = [
            Permission.photos,
            Permission.videos,
          ];

          Map<Permission, PermissionStatus> statuses =
              await permissions.request();

          if (await Permission.manageExternalStorage.isDenied) {
            final manageStorageStatus =
                await Permission.manageExternalStorage.request();
            if (manageStorageStatus.isPermanentlyDenied) {
              await openAppSettings();
              return false;
            }
          }

          return statuses.values.every((status) =>
              status == PermissionStatus.granted ||
              status == PermissionStatus.limited);
        } else if (sdkInt >= 30) {
          final status = await Permission.manageExternalStorage.request();

          if (status.isPermanentlyDenied) {
            await openAppSettings();
            return false;
          }

          return status.isGranted;
        } else if (sdkInt >= 23) {
          final permissions = [
            Permission.storage,
          ];

          Map<Permission, PermissionStatus> statuses =
              await permissions.request();

          bool allGranted = statuses.values.every((status) => status.isGranted);

          if (!allGranted) {
            bool permanentlyDenied =
                statuses.values.any((status) => status.isPermanentlyDenied);
            if (permanentlyDenied) {
              await openAppSettings();
              return false;
            }
          }

          return allGranted;
        } else {
          return true;
        }
      } catch (e) {
        Logger.i('Error requesting storage permissions: $e');
        return false;
      }
    }

    return true;
  }

  Future<void> showDirectoryPicker() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        pathHistory.clear();
        currentPath.value = selectedDirectory;
        hasSelectedDirectory.value = true;
        await loadCurrentDirectory();
      }
    } catch (e) {
      Logger.i('Error selecting directory: $e');
      errorSnackBar(e.toString());
      await _setDefaultDirectory();
    }
  }

  Future<void> _setDefaultDirectory() async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        directory ??= Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();

        final downloadsDir = Directory('${directory.path}/Downloads');
        if (!await downloadsDir.exists()) {
          try {
            await downloadsDir.create(recursive: true);
            directory = downloadsDir;
          } catch (e) {
            Logger.i(
                'Could not create Downloads directory, using Documents: $e');
          }
        } else {
          directory = downloadsDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      pathHistory.clear();
      currentPath.value = directory?.path ?? '';
      hasSelectedDirectory.value = true;

      await loadCurrentDirectory();
    } catch (e) {
      Logger.i('Error setting default directory: $e');
    }
  }

  Future<List<String>> getIOSDefaultPaths() async {
    if (!Platform.isIOS) return [];

    final List<String> paths = [];

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      paths.add(documentsDir.path);

      final downloadsDir = Directory('${documentsDir.path}/Downloads');
      if (await downloadsDir.exists() ||
          await downloadsDir
              .create(recursive: true)
              .then((_) => true)
              .catchError((_) => false)) {
        paths.add(downloadsDir.path);
      }

      final moviesDir = Directory('${documentsDir.path}/Movies');
      if (await moviesDir.exists() ||
          await moviesDir
              .create(recursive: true)
              .then((_) => true)
              .catchError((_) => false)) {
        paths.add(moviesDir.path);
      }

      final videosDir = Directory('${documentsDir.path}/Videos');
      if (await videosDir.exists() ||
          await videosDir
              .create(recursive: true)
              .then((_) => true)
              .catchError((_) => false)) {
        paths.add(videosDir.path);
      }
    } catch (e) {
      Logger.i('Error getting iOS default paths: $e');
    }

    return paths;
  }

  Future<void> loadCurrentDirectory() async {
    isLoading.value = true;

    try {
      Directory directory = Directory(currentPath.value);
      if (await directory.exists()) {
        List<FileSystemEntity> items = await directory.list().toList();
        currentItems.value = items.where((item) {
          if (item is Directory) return true;
          if (item is File) {
            String extension = path.extension(item.path).toLowerCase();
            return watchableExtensions.contains(extension);
          }
          return false;
        }).toList();

        currentItems.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return path
              .basename(a.path)
              .toLowerCase()
              .compareTo(path.basename(b.path).toLowerCase());
        });
      }
    } catch (e) {
      Logger.i('Error loading directory: $e');
      currentItems.clear();
    }

    isLoading.value = false;
  }

  Future<void> loadDownloadDirectory() async {
    isLoading.value = true;

    try {
      Directory directory = Directory(downloadPath.value);
      if (await directory.exists()) {
        List<FileSystemEntity> items = await directory.list().toList();
        downloadItems.value = items.where((item) {
          if (item is Directory) return true;
          if (item is File) {
            String extension = path.extension(item.path).toLowerCase();
            return watchableExtensions.contains(extension);
          }
          return false;
        }).toList();

        downloadItems.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return path
              .basename(a.path)
              .toLowerCase()
              .compareTo(path.basename(b.path).toLowerCase());
        });
      }
    } catch (e) {
      Logger.i('Error loading download directory: $e');
      downloadItems.clear();
    }

    isLoading.value = false;
  }

  void navigateBack() {
    if (pathHistory.isNotEmpty) {
      currentPath.value = pathHistory.removeLast();
      loadCurrentDirectory();
    }
  }

  void navigateBackDownload() {
    if (downloadPathHistory.isNotEmpty) {
      downloadPath.value = downloadPathHistory.removeLast();
      loadDownloadDirectory();
    }
  }

  void handleNavigation(BuildContext context) {
    if (!handleBackButton()) {
      return; // Back button was handled, don't navigate
    }
    Navigator.pop(context);
  }

  void navigateToFolder(String folderPath) {
    if (viewMode.value == ViewMode.local) {
      // Add current path to history before navigating
      if (currentPath.isNotEmpty && currentPath.value != folderPath) {
        pathHistory.add(currentPath.value);
      }
      currentPath.value = folderPath;
      loadCurrentDirectory();
    } else if (viewMode.value == ViewMode.download) {
      // Add current download path to history before navigating
      if (downloadPath.isNotEmpty && downloadPath.value != folderPath) {
        downloadPathHistory.add(downloadPath.value);
      }
      downloadPath.value = folderPath;
      loadDownloadDirectory();
    }
  }

  String getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return 'Unknown';
    }
  }

  void toggleViewMode(ViewMode mode) {
    viewMode.value = mode;
    // Load appropriate directory when switching modes
    if (mode == ViewMode.download) {
      loadDownloadDirectory();
    } else if (mode == ViewMode.local) {
      loadCurrentDirectory();
    }
  }

  void handleTabSwitch(ViewMode targetMode) {
    final isDownloads = targetMode == ViewMode.download;

    if (isDownloads || targetMode == ViewMode.search) {
      toggleViewMode(targetMode);
    } else {
      if (viewMode.value == ViewMode.local) {
        if (Platform.isIOS) {
          _setDefaultDirectory();
        } else {
          showDirectoryPicker();
        }
      } else {
        toggleViewMode(ViewMode.local);
      }
    }
  }

  bool get canNavigateBack =>
      pathHistory.isNotEmpty && viewMode.value == ViewMode.local;

  bool get canNavigateBackDownload =>
      downloadPathHistory.isNotEmpty && viewMode.value == ViewMode.download;

  String get currentDirectoryName {
    if (viewMode.value == ViewMode.local) {
      return currentPath.isNotEmpty
          ? path.basename(currentPath.value)
          : 'No directory selected';
    } else if (viewMode.value == ViewMode.download) {
      return downloadPath.isNotEmpty
          ? path.basename(downloadPath.value)
          : 'Downloads';
    }
    return 'No directory selected';
  }

  int get itemCount {
    if (viewMode.value == ViewMode.local) {
      return currentItems.length;
    } else if (viewMode.value == ViewMode.download) {
      return downloadItems.length;
    }
    return 0;
  }

  List<FileSystemEntity> get currentModeItems {
    if (viewMode.value == ViewMode.local) {
      return currentItems;
    } else if (viewMode.value == ViewMode.download) {
      return downloadItems;
    }
    return [];
  }

  RxBool isSearching = false.obs;
  RxList<d.DMedia?> searchResults = <d.DMedia?>[].obs;

  Future<void> search(String query) async {
    selectedVideos.value = [];
    selectedMedia.value = null;
    selectedSeason.value = null;
    isSearching.value = true;
    final results =
        (await selectedSource.value!.methods.search(query, 1, [])).list;
    if (results.isNotEmpty) {
      searchResults.value = results;
    } else {
      searchResults.value = [];
      errorSnackBar('No results found for "$query"');
    }
    isSearching.value = false;
  }

  Future<void> onSearchResultTap(d.DMedia? searchResult) async {
    isLoadingMedia.value = true;
    final supportsTmdb = searchResult!.url!.contains('tmdb');
    if (supportsTmdb) {
      final data = await TmdbApi.getDetails(searchResult.url!);
      if (data != null) {
        if (data.seasons[0].title == 'Movie') {
          selectedSeason.value = data.seasons[0];
        } else {
          selectedMedia.value = data;
        }
      } else {
        errorSnackBar('Failed to fetch details');
      }
    } else {
      final data = await selectedSource.value!.methods.getDetail(searchResult);
      selectedMedia.value = DetailResult.froDMedia(data);
    }

    isLoadingMedia.value = false;
  }

  void onSeasonTap(DetailSeasons season) => selectedSeason.value = season;

  Future<void> onEpisodeTap(DetailEpisode episode) async {
    selectedEpisode.value = episode;
    isLoadingServers.value = true;

    try {
      final data = await selectedSource.value!.methods.getVideoList(
          DEpisode(episodeNumber: episode.title, url: episode.id));

      Logger.i(data.length.toString());
      if (data.isNotEmpty) {
        selectedVideos.value = data.map((e) => Video.fromVideo(e)).toList();
      }
    } catch (e) {
      Logger.i(e.toString());
    } finally {
      isLoadingServers.value = false;
    }
  }

  // Future<String> getDownloadPath() async =>
  // DownloadManagerController.instance.downloadPath;

  Future<void> downloadVideo(Video video) async {
    // DownloadManagerController.instance.addDownload(
    //     url: video.url,
    //     headers: video.headers,
    //     displayName: '${selectedEpisode.value?.title} - ${video.quality}',
    //     metaData: {
    //       'poster': selectedSeason.value!.poster,
    //       'season': selectedSeason.value!.title
    //     },
    //     filename:
    //         '${selectedMedia.value!.title}/${selectedSeason.value!.title}/${selectedEpisode.value?.title} - ${video.quality}');
    snackBar('Added to downloads');
  }
}
