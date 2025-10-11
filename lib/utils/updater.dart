import 'package:anymex/utils/logger.dart';
import 'dart:io';
import 'package:anymex/utils/abi_checker.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dio/dio.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:install_plugin/install_plugin.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UpdateManager {
  static const String _repoUrl =
      'https://api.github.com/repos/RyanYuuki/AnymeX/releases/latest';

  String getDownloadUrlByArch(List<dynamic> assets, String arch) {
    for (var asset in assets) {
      if (asset['name']?.contains(arch) == true) {
        return asset['browser_download_url'] ?? '';
      }
    }
    return '';
  }

  Future<void> checkForUpdates(
      BuildContext context, RxBool canShowUpdate) async {
    if (canShowUpdate.value) {
      canShowUpdate.value = false;

      try {
        final currentVersion = await _getCurrentVersion();
        final latestRelease = await _fetchLatestRelease();

        if (latestRelease == null) {
          snackBar("Failed to check for updates");
          return;
        }

        final assets = latestRelease['assets'];

        Map<String, String> downloadUrls = {
          'android_arm64': getDownloadUrlByArch(assets, 'arm64'),
          'android_arm32': getDownloadUrlByArch(assets, 'v7a'),
          'android_universal': getDownloadUrlByArch(assets, 'universal'),
          'windows': getDownloadUrlByArch(assets, '.exe'),
          'macos': getDownloadUrlByArch(assets, '.dmg'),
          'linux': getDownloadUrlByArch(assets, '.AppImage'),
        };

        if (_shouldUpdate(currentVersion, latestRelease['tag_name'])) {
          _showUpdateBottomSheet(context, currentVersion,
              latestRelease['tag_name'], latestRelease['body'], downloadUrls);
        } else {
          print("You're already using the latest version");
        }
      } catch (e) {
        debugPrint('Error checking for updates: $e');
        snackBar("Error checking for updates: ${e.toString()}");
      }
    } else {
      snackBar("Skipping Update Popup");
    }
  }

  final bool _currentVersionIncludesHotfix = true;

  bool _shouldUpdate(String currentVersion, String latestVersion) {
    currentVersion = currentVersion.replaceFirst(RegExp(r'^v'), '');
    latestVersion = latestVersion.replaceFirst(RegExp(r'^v'), '');

    final currentSplit = currentVersion.split('-');
    final latestSplit = latestVersion.split('-');

    final currentNums = currentSplit[0].split('.').map(int.parse).toList();
    final latestNums = latestSplit[0].split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final c = (i < currentNums.length) ? currentNums[i] : 0;
      final l = (i < latestNums.length) ? latestNums[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }

    final currentHasTag = currentSplit.length == 2;
    final latestHasTag = latestSplit.length == 2;

    if (latestHasTag && latestSplit[1].toLowerCase() == 'hotfix') {
      if (_currentVersionIncludesHotfix) {
        return false;
      }

      if (currentHasTag && currentSplit[1].toLowerCase() == 'hotfix') {
        return false;
      }

      return true;
    }

    if (!currentHasTag && latestHasTag) {
      return false;
    }

    if (currentHasTag && !latestHasTag) {
      return true;
    }

    if (currentHasTag && latestHasTag) {
      final priority = ['alpha', 'beta', 'rc'];
      final currentTag = currentSplit[1].toLowerCase();
      final latestTag = latestSplit[1].toLowerCase();

      final currentIndex = priority.indexOf(currentTag);
      final latestIndex = priority.indexOf(latestTag);

      if (currentIndex != -1 && latestIndex != -1) {
        return latestIndex > currentIndex;
      }
    }

    Logger.i('Current version ($currentVersion) is up to date.');
    return false;
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_repoUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        Logger.i('Failed to fetch latest release: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching latest release: $e');
    }
    return null;
  }

  void _showUpdateBottomSheet(
    BuildContext context,
    String currentVersion,
    String newVersion,
    String changelog,
    Map<String, String> downloadUrls,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => UpdateBottomSheet(
          currentVersion: currentVersion,
          newVersion: newVersion,
          changelog: changelog,
          scrollController: scrollController,
          downloadUrls: downloadUrls,
        ),
      ),
    );
  }
}

class UpdateBottomSheet extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final String changelog;
  final ScrollController scrollController;
  final Map<String, String> downloadUrls;

  const UpdateBottomSheet({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.changelog,
    required this.scrollController,
    required this.downloadUrls,
  });

  @override
  State<UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<UpdateBottomSheet>
    with TickerProviderStateMixin {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<String> _getPlatformSpecificUrl() async {
    if (Platform.isAndroid) {
      final currentAbi = await AppAbiDetector.getCurrentAppAbi();

      switch (currentAbi) {
        case 'arm64':
          return widget.downloadUrls['android_arm64']!;
        case 'arm32':
          return widget.downloadUrls['android_arm32']!;
        case 'x86_64':
          return widget.downloadUrls['android_x86_64'] ??
              widget.downloadUrls['android_universal']!;
        case 'x86':
          return widget.downloadUrls['android_x86'] ??
              widget.downloadUrls['android_universal']!;
        default:
          return widget.downloadUrls['android_universal']!;
      }
    } else if (Platform.isWindows) {
      return widget.downloadUrls['windows']!;
    } else if (Platform.isMacOS) {
      return widget.downloadUrls['macos']!;
    } else if (Platform.isLinux) {
      return widget.downloadUrls['linux']!;
    }

    throw UnsupportedError('Platform not supported');
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Preparing download...';
    });

    try {
      final downloadUrl = await _getPlatformSpecificUrl();

      if (Platform.isAndroid) {
        await _downloadAndInstallAndroid(downloadUrl);
      } else if (Platform.isWindows) {
        await _downloadWindows(downloadUrl);
      } else {
        final Uri url = Uri.parse(downloadUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      _showErrorDialog('Download failed: ${e.toString()}');
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
        _downloadStatus = '';
      });
    }
  }

  Future<void> _downloadAndInstallAndroid(String downloadUrl) async {
    setState(() {
      _downloadStatus = 'Downloading APK...';
    });

    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/app_update.apk';

    await dio.download(
      downloadUrl,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress = received / total;
            _downloadStatus =
                'Downloaded ${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        }
      },
    );

    setState(() {
      _downloadStatus = 'Installing...';
    });

    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) {
      snackBar("Install permission is required to update the app");
    }

    final result =
        await InstallPlugin.installApk(savePath, appId: 'com.ryan.anymex');
    if (result['isSuccess']) {
      _showSuccessDialog();
    } else {
      throw Exception('Installation failed: ${result['errorMessage']}');
    }
  }

  Future<void> _downloadWindows(String downloadUrl) async {
    setState(() {
      _downloadStatus = 'Downloading installer...';
    });

    final dio = Dio();
    final downloadsDir = await getDownloadsDirectory();
    final savePath =
        '${downloadsDir?.path ?? ''}/app_update_${widget.newVersion}.exe';

    await dio.download(
      downloadUrl,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress = received / total;
            _downloadStatus =
                'Downloaded ${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        }
      },
    );

    _showSuccessDialog(filePath: savePath);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 32),
        title: const Text('Download Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({String? filePath}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        title: Text(
            Platform.isAndroid ? 'Installation Started' : 'Download Complete'),
        content: Text(
          Platform.isAndroid
              ? 'Please follow the installation prompts to update the app.'
              : 'The installer has been saved to:\n${filePath ?? 'Downloads folder'}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.system_update,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Update Available',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'v${widget.currentVersion} → ${widget.newVersion}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.new_releases,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What\'s New',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Changelog container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Markdown(
                        controller: widget.scrollController,
                        data: widget.changelog,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                          h1: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Download progress
                  if (_isDownloading) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: ExpressiveLoadingIndicator(
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _downloadStatus,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _downloadProgress,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isDownloading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: colorScheme.outline),
                          ),
                          child: Text(
                            'Later',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed:
                              _isDownloading ? null : _downloadAndInstall,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isDownloading) ...[
                                Icon(
                                  Platform.isAndroid
                                      ? Icons.download_for_offline
                                      : Icons.download,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _isDownloading
                                    ? 'Downloading...'
                                    : Platform.isAndroid
                                        ? 'Download & Install'
                                        : 'Download',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
