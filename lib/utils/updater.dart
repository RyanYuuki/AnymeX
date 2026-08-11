import 'dart:convert';
import 'dart:io';

import 'package:anymex/utils/abi_checker.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dio/dio.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:install_plugin/install_plugin.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateManager {
  static const String _stableRepoUrl =
      'https://api.github.com/repos/RyanYuuki/AnymeX/releases/latest';

  static const String _betaRepoUrl =
      'https://api.github.com/repos/Shebyyy/AnymeX-Preview/releases/latest';

  String getDownloadUrlByArch(List<dynamic> assets, String arch) {
    for (var asset in assets) {
      if (asset['name']?.contains(arch) == true) {
        return asset['browser_download_url'] ?? '';
      }
    }
    return '';
  }

  void showTestUpdateSheet(BuildContext context) {
    _showUpdateBottomSheet(
      context,
      '1.2.0',
      '1.3.0',
      '### What\'s New in v1.3.0\n'
          '- **Universal Video Casting**: Cast videos to Smart TVs, Chromecast, and PCs.\n',
      {
        'android_arm64': 'https://github.com/RyanYuuki/AnymeX/releases',
        'android_universal': 'https://github.com/RyanYuuki/AnymeX/releases',
      },
    );
  }

  Future<void> checkForUpdates(
    BuildContext context,
    RxBool canShowUpdate, {
    bool isBeta = false,
  }) async {
    if (canShowUpdate.value) {
      canShowUpdate.value = false;

      try {
        final currentVersion = await _getCurrentVersion();
        final latestRelease = await _fetchLatestRelease(isBeta: isBeta);

        if (latestRelease == null) {
          Logger.i("Failed to check for updates");
          return;
        }

        final assets = latestRelease['assets'] ?? [];

        Map<String, String> downloadUrls = {
          'android_arm64': getDownloadUrlByArch(assets, 'arm64'),
          'android_arm32': getDownloadUrlByArch(assets, 'v7a'),
          'android_universal': getDownloadUrlByArch(assets, 'universal'),
          'windows': getDownloadUrlByArch(assets, '.exe'),
          'macos': getDownloadUrlByArch(assets, '.dmg'),
          'linux': getDownloadUrlByArch(assets, '.AppImage'),
        };

        if (_shouldUpdate(currentVersion, latestRelease['tag_name'] ?? '',
            isBeta: isBeta)) {
          _showUpdateBottomSheet(
            context,
            currentVersion,
            latestRelease['tag_name'] ?? '',
            latestRelease['body'] ?? '',
            downloadUrls,
          );
        } else {
          debugPrint("You are already using the latest version!");
        }
      } catch (e) {
        debugPrint('Error checking for updates: $e');
      }
    }
  }

  final bool _currentVersionIncludesHotfix = true;

  bool _shouldUpdate(String currentVersion, String latestVersion,
      {bool isBeta = false}) {
    currentVersion = currentVersion.replaceFirst(RegExp(r'^v'), '');
    latestVersion = latestVersion.replaceFirst(RegExp(r'^v'), '');

    final currentSplit = currentVersion.split('-');
    final latestSplit = latestVersion.split('-');

    final currentNums =
        currentSplit[0].split('+')[0].split('.').map(int.parse).toList();
    final latestNums =
        latestSplit[0].split('+')[0].split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < currentNums.length ? currentNums[i] : 0;
      final l = i < latestNums.length ? latestNums[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }

    final currentHasTag = currentSplit.length == 2;
    final latestHasTag = latestSplit.length == 2;

    if (latestHasTag && latestSplit[1].toLowerCase() == 'hotfix') {
      if (_currentVersionIncludesHotfix) return false;
      if (currentHasTag && currentSplit[1].toLowerCase() == 'hotfix') {
        return false;
      }
      return true;
    }

    if (!currentHasTag && latestHasTag) {
      if (isBeta) {
        return true;
      }
      return false;
    }

    if (currentHasTag && !latestHasTag) return true;

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

  Future<Map<String, dynamic>?> _fetchLatestRelease({
    bool isBeta = false,
  }) async {
    try {
      if (isBeta) {
        const betaReleasesListUrl =
            'https://api.github.com/repos/Shebyyy/AnymeX-Preview/releases';
        final response = await http.get(
          Uri.parse(betaReleasesListUrl),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        );
        if (response.statusCode == 200) {
          final List<dynamic> list = json.decode(response.body);
          if (list.isNotEmpty) {
            return list.first as Map<String, dynamic>;
          }
        }
      }

      final url = isBeta ? _betaRepoUrl : _stableRepoUrl;
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
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
    AnymeXSheet.custom(
      UpdateBottomSheet(
        currentVersion: currentVersion,
        newVersion: newVersion,
        changelog: changelog,
        downloadUrls: downloadUrls,
      ),
      context,
      showDragHandle: true,
    );
  }
}

class UpdateBottomSheet extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final String changelog;
  final Map<String, String> downloadUrls;

  const UpdateBottomSheet({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.changelog,
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
      begin: 0.85,
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
      _showErrorDialog('Download failed: $e');
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
      snackBar("Install permission required");
    }

    final result = await InstallPlugin.installApk(
      savePath,
      appId: 'com.ryan.anymex',
    );

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
        icon: const Icon(Icons.error_outline, size: 32, color: Colors.red),
        title: const Text('Download Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
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
          color: context.colors.primary,
          size: 32,
        ),
        title: Text(
            Platform.isAndroid ? 'Installation Started' : 'Download Complete'),
        content: Text(
          Platform.isAndroid
              ? 'Please follow installation prompts.'
              : 'Installer saved to:\n${filePath ?? 'Downloads'}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.opaque(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.opaque(0.3)),
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 26,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnymeXText(
                    text: "New Version Available",
                    variant: TextVariant.bold,
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "v${widget.currentVersion}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, size: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.opaque(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: colorScheme.primary.opaque(0.3)),
                        ),
                        child: Text(
                          "v${widget.newVersion}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            const AnymeXText(
              text: "What's New",
              variant: TextVariant.bold,
              size: 15,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 240),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerHigh.opaque(0.5),
            border: Border.all(
              color: colorScheme.outline.opaque(0.15),
            ),
          ),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: widget.changelog,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                h3: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isDownloading) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.opaque(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.opaque(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: ExpressiveLoadingIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _downloadStatus,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: AnymeXContainerButton(
                onTap: _isDownloading ? null : () => Navigator.pop(context),
                height: 48,
                borderRadius: BorderRadius.circular(16),
                border: BorderSide(color: colorScheme.outline.opaque(0.2)),
                child: Center(
                  child: Text(
                    "Later",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AnymeXContainerButton(
                onTap: _isDownloading ? null : _downloadAndInstall,
                height: 48,
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isDownloading
                          ? "Downloading..."
                          : (Platform.isAndroid
                              ? "Download & Install"
                              : "Download"),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
