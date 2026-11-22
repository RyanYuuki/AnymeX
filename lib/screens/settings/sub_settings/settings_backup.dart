import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';
import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/controllers/sync/progress_sync_section.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extension_manager.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/backup_and_restore_widgets.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late final controller = Get.put(BackupRestoreService());

  String _conflictMode = 'Merge';
  String? _selectedFilePath;
  String? _selectedFileName;
  String? _backupPassword;
  Map<String, dynamic>? _loadedBackupInfo;
  bool _isLoadingFile = false;

  RestoreOptions _restoreOptions = RestoreOptions();

  @override
  void dispose() {
    Get.delete<BackupRestoreService>();
    super.dispose();
  }

  void _openExportSheet() {
    AnymeXSheet.custom(
      ExportBackupSheet(
        controller: controller,
        onExport: (options, password) async {
          Navigator.of(context).pop();
          await _executeExport(options, password);
        },
      ),
      context,
      showDragHandle: true,
    );
  }

  Future<void> _executeExport(BackupOptions options, String? password) async {
    setState(() {
      controller.isBackingUp.value = true;
    });

    try {
      final path = await controller.exportBackupToExternal(
        password: password,
        options: options,
      );
      if (path != null && mounted) {
        snackBar(context.l10n.backupSavedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        snackBar("Backup failed: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          controller.isBackingUp.value = false;
        });
      }
    }
  }

  Future<void> _pickAndLoadFile() async {
    try {
      final path = await controller.pickBackupFile();
      if (path == null) return;
      await _loadBackupFile(path);
    } catch (e) {
      snackBar("Error selecting file: ${e.toString()}");
    }
  }

  Future<void> _loadBackupFile(String path) async {
    setState(() {
      _isLoadingFile = true;
    });

    try {
      final isEncrypted = await controller.isBackupEncrypted(path);
      String? password;

      if (isEncrypted) {
        if (!mounted) return;
        password = await _showPasswordDialog(context);
        if (password == null) {
          setState(() {
            _isLoadingFile = false;
          });
          return;
        }
      }

      final info = await controller.getBackupInfo(path, password: password);
      if (info == null) {
        snackBar(Get.context!.l10n.invalidBackupFileOrIncorrectPassword);
        setState(() {
          _isLoadingFile = false;
        });
        return;
      }

      final fileName = path.split(Platform.pathSeparator).last;
      if (mounted) {
        setState(() {
          _selectedFilePath = path;
          _selectedFileName = fileName;
          _backupPassword = password;
          _loadedBackupInfo = info;
          _restoreOptions = RestoreOptions(
            anime: info['hasAnime'] ?? false,
            manga: info['hasManga'] ?? false,
            novel: info['hasNovel'] ?? false,
            customLists: info['hasCustomLists'] ?? false,
            stats: info['hasStats'] ?? false,
            settings: SettingsOptions(
              appearance: info['hasAppearance'] ?? false,
              player: info['hasPlayer'] ?? false,
              reader: info['hasReader'] ?? false,
              extensions: info['hasExtSettings'] ?? false,
              downloads: info['hasDownloadSettings'] ?? false,
              general: info['hasGeneralSettings'] ?? false,
              authTokens: false,
            ),
            extensionsData: info['hasExtensionsData'] ?? false,
            extensionFiles: info['hasExtensionFiles'] ?? false,
            runtimeHost: info['hasRuntimeHost'] ?? false,
          );
          _isLoadingFile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFile = false;
        });
        snackBar("Failed to load backup: ${e.toString()}");
      }
    }
  }

  Future<void> _executeRestore() async {
    if (_selectedFilePath == null || _loadedBackupInfo == null) {
      snackBar(context.l10n.pleaseSelectABackupFileFirst);
      return;
    }

    if (!_restoreOptions.hasAnySelected) {
      snackBar(context.l10n.pleaseSelectAtLeastOneItemTo);
      return;
    }

    setState(() {
      controller.isRestoring.value = true;
    });

    try {
      final needsHostPrompt = await controller.restoreBackup(
        _selectedFilePath!,
        password: _backupPassword,
        merge: _conflictMode == 'Merge',
        options: _restoreOptions,
      );
      if (mounted) {
        snackBar(context.l10n.backupRestoredSuccessfully);
        if (needsHostPrompt) {
          _showMissingRuntimeDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        snackBar("Restore failed: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          controller.isRestoring.value = false;
        });
      }
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => PasswordInputDialog(
        controller: passwordController,
      ),
    );
  }

  void _showConflictHandlingMenu(BuildContext context) {
    AnymeXSheet.custom(
      Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymeXText(
                context.l10n.conflictHandling,
                variant: TextVariant.bold,
                size: 18,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: AnymeXText(context.l10n.merge,
                    variant: TextVariant.bold, size: 15),
                subtitle: AnymeXText(
                    context.l10n.combineBackupDataWithExistingData,
                    size: 12),
                trailing: _conflictMode == 'Merge'
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _conflictMode = 'Merge');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: AnymeXText(context.l10n.overwrite,
                    variant: TextVariant.bold, size: 15),
                subtitle: AnymeXText(
                    context.l10n.replaceExistingDataOnThisDevice,
                    size: 12),
                trailing: _conflictMode == 'Overwrite'
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _conflictMode = 'Overwrite');
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
      context,
      showDragHandle: true,
    );
  }

  void _showMissingRuntimeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AnymeXDialog(
        title: context.l10n.runtimeHostRequired,
        confirmText: context.l10n.goToRuntimeManager,
        cancelText: context.l10n.later,
        onConfirm: () {
          Get.to(() => const SettingsExtensionManager());
        },
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(ctx).colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnymeXText(
                    context.l10n.missingRuntimeHost,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnymeXText(
              "Extensions have been restored to your app, but no runtime host is installed or active on this device.\n\nTo run your extensions properly, please install the runtime host in the Runtime Manager.",
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: AnymeXText(
            context.l10n.exportLabel,
            size: 12,
            variant: TextVariant.bold,
            color: theme.colorScheme.onSurfaceVariant.opaque(0.7),
          ),
        ),
        AnymeXContainer(
          color: theme.colorScheme.surfaceContainer
              .opaque(0.45, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXTile(
                backgroundColor: Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18.0)),
                icon: Icons.archive_outlined,
                title: context.l10n.exportDeviceBackup,
                subtitle:
                    context.l10n.createAFullAnymexArchiveOf,
                showChevron: false,
                onTap: controller.isBackingUp.value ? null : _openExportSheet,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.isBackingUp.value ? null : _openExportSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isBackingUp.value)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary),
                            ),
                          )
                        else ...[
                          Icon(Icons.file_upload_outlined,
                              color: theme.colorScheme.onPrimary, size: 20),
                          const SizedBox(width: 8),
                          AnymeXText(
                            "Configure & Export",
                            variant: TextVariant.bold,
                            color: theme.colorScheme.onPrimary,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportSection(BuildContext context) {
    final theme = Theme.of(context);
    final info = _loadedBackupInfo;

    final animeCount = info?['animeCount'] as int? ?? 0;
    final mangaCount = info?['mangaCount'] as int? ?? 0;
    final novelCount = info?['novelCount'] as int? ?? 0;
    final totalTitles = animeCount + mangaCount + novelCount;

    final animeLists = info?['animeCustomListsCount'] as int? ?? 0;
    final mangaLists = info?['mangaCustomListsCount'] as int? ?? 0;
    final novelLists = info?['novelCustomListsCount'] as int? ?? 0;
    final totalLists = animeLists + mangaLists + novelLists;

    final extDataCount = info?['extensionsDataCount'] as int? ?? 0;
    final extFilesCount = info?['extensionFilesCount'] as int? ?? 0;

    final hasRuntime = info?['hasRuntimeHost'] as bool? ?? false;
    final runtimePlatform = info?['runtimeHostPlatform'] as String? ?? '';
    final runtimeSize = info?['runtimeHostSize'] as int? ?? 0;
    final runtimeSizeStr = runtimeSize > 0
        ? '${(runtimeSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';

    final hasAppearance = info?['hasAppearance'] as bool? ?? false;
    final hasPlayer = info?['hasPlayer'] as bool? ?? false;
    final hasReader = info?['hasReader'] as bool? ?? false;
    final hasExtSettings = info?['hasExtSettings'] as bool? ?? false;
    final hasDownloadSettings = info?['hasDownloadSettings'] as bool? ?? false;
    final hasGeneralSettings = info?['hasGeneralSettings'] as bool? ?? false;
    final hasAuthTokens = info?['hasAuthTokens'] as bool? ?? false;

    final hasAnySettings = hasAppearance ||
        hasPlayer ||
        hasReader ||
        hasExtSettings ||
        hasDownloadSettings ||
        hasGeneralSettings ||
        hasAuthTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: AnymeXText(
            context.l10n.importLabel,
            size: 12,
            variant: TextVariant.bold,
            color: theme.colorScheme.onSurfaceVariant.opaque(0.7),
          ),
        ),
        if (info == null)
          AnymeXContainer(
            color: theme.colorScheme.surfaceContainer
                .opaque(0.45, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXTile(
                  backgroundColor: Colors.transparent,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18.0)),
                  icon: Icons.folder_open_rounded,
                  title: context.l10n.backupArchive,
                  subtitle:
                      "Select an .anymex, .tachibk, .proto.gz, or .zip backup file",
                  showChevron: false,
                  onTap: _isLoadingFile ? null : _pickAndLoadFile,
                ),
                if (_isLoadingFile)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _pickAndLoadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_open_outlined,
                                color: theme.colorScheme.onPrimary, size: 20),
                            const SizedBox(width: 8),
                            AnymeXText(
                              "Choose a backup file (.anymex)",
                              variant: TextVariant.bold,
                              color: theme.colorScheme.onPrimary,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          AnymeXTileBuilder<dynamic>(
            items: const [],
            getTitle: (_) => '',
            onItemPressed: (_) {},
            children: [
              AnymeXTile(
                icon: Icons.folder_open_rounded,
                title: "Backup Archive",
                subtitle: _selectedFileName ??
                    "Select an .anymex, .tachibk, .proto.gz, or .zip backup file",
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.opaque(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymeXText(
                    (info['format'] as String?)?.toUpperCase() ?? "LOADED",
                    size: 10,
                    variant: TextVariant.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                onTap: _pickAndLoadFile,
              ),
              if (_isLoadingFile)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
              AnymeXTile(
                icon: Icons.tune_rounded,
                title: context.l10n.conflictHandling,
                subtitle: _conflictMode == 'Merge'
                    ? "Merge with existing device data"
                    : "Overwrite existing device data",
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest.opaque(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.opaque(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnymeXText(
                        _conflictMode == 'Merge'
                            ? context.l10n.merge
                            : context.l10n.overwrite,
                        size: 13,
                        variant: TextVariant.semiBold,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
                onTap: () => _showConflictHandlingMenu(context),
              ),
              AnymeXExpansionTile(
                title: context.l10n.mediaLibrary,
                subtitle:
                    "$totalTitles titles • $animeCount anime · $mangaCount manga · $novelCount novel",
                icon: Icons.video_library_rounded,
                initialExpanded: true,
                useCard: false,
                content: Column(
                  children: [
                    if (info['hasAnime'] ?? false)
                      AnymeXTile.checkbox(
                        icon: Icons.movie_filter_rounded,
                        title: context.l10n.animeLibrary,
                        subtitle: "$animeCount titles and history",
                        value: _restoreOptions.anime,
                        onChanged: (v) =>
                            setState(() => _restoreOptions.anime = v),
                      ),
                    if (info['hasManga'] ?? false)
                      AnymeXTile.checkbox(
                        icon: Icons.menu_book_rounded,
                        title: context.l10n.mangaLibrary,
                        subtitle: "$mangaCount titles and chapters",
                        value: _restoreOptions.manga,
                        onChanged: (v) =>
                            setState(() => _restoreOptions.manga = v),
                      ),
                    if (info['hasNovel'] ?? false)
                      AnymeXTile.checkbox(
                        icon: Icons.auto_stories_rounded,
                        title: context.l10n.novelLibrary,
                        subtitle: "$novelCount titles and reading state",
                        value: _restoreOptions.novel,
                        onChanged: (v) =>
                            setState(() => _restoreOptions.novel = v),
                      ),
                  ],
                ),
              ),
              AnymeXTile.checkbox(
                icon: Icons.insights_rounded,
                title: context.l10n.progressHistory,
                subtitle: (info['hasStats'] ?? false)
                    ? "Episode progress, reading logs, and activity stats"
                    : "No progress or activity data in backup",
                enabled: info['hasStats'] ?? false,
                value: _restoreOptions.stats,
                onChanged: (v) => setState(() => _restoreOptions.stats = v),
              ),
              AnymeXTile.checkbox(
                icon: Icons.playlist_play_rounded,
                title: context.l10n.customLists,
                subtitle: "$totalLists custom lists across media",
                enabled: totalLists > 0,
                value: _restoreOptions.customLists,
                onChanged: (v) =>
                    setState(() => _restoreOptions.customLists = v),
              ),
              AnymeXExpansionTile(
                title: context.l10n.extensionsSources,
                subtitle:
                    "$extDataCount configurations • $extFilesCount packages",
                icon: Icons.extension_rounded,
                initialExpanded: true,
                useCard: false,
                content: Column(
                  children: [
                    if (info['hasExtensionsData'] ?? false)
                      AnymeXTile.checkbox(
                        icon: Icons.source_rounded,
                        title: context.l10n.configurationsRepos,
                        subtitle: "$extDataCount registered extension entries",
                        value: _restoreOptions.extensionsData,
                        onChanged: (v) =>
                            setState(() => _restoreOptions.extensionsData = v),
                      ),
                    if (info['hasExtensionFiles'] ?? false)
                      AnymeXTile.checkbox(
                        icon: Icons.folder_zip_rounded,
                        title: context.l10n.installedPackages,
                        subtitle: "$extFilesCount extension zip bundles",
                        value: _restoreOptions.extensionFiles,
                        onChanged: (v) =>
                            setState(() => _restoreOptions.extensionFiles = v),
                      ),
                  ],
                ),
              ),
              if (hasAnySettings)
                AnymeXExpansionTile(
                  title: context.l10n.appSettingsSessions,
                  subtitle:
                      "Themes, playback, reader${hasAuthTokens ? ' • Auth tokens' : ''}",
                  icon: Icons.settings_rounded,
                  initialExpanded: true,
                  useCard: false,
                  content: Column(
                    children: [
                      if (hasAppearance)
                        AnymeXTile.checkbox(
                          icon: Icons.palette_outlined,
                          title: context.l10n.appearanceTheme,
                          subtitle: context.l10n.uiLayoutColorsAndVisualStyles,
                          value: _restoreOptions.settings.appearance,
                          onChanged: (v) => setState(
                              () => _restoreOptions.settings.appearance = v),
                        ),
                      if (hasPlayer)
                        AnymeXTile.checkbox(
                          icon: Icons.play_circle_outline_rounded,
                          title: context.l10n.videoPlayer,
                          subtitle:
                              context.l10n.playerControlsSubtitlesAndPlaybackPreferences,
                          value: _restoreOptions.settings.player,
                          onChanged: (v) => setState(
                              () => _restoreOptions.settings.player = v),
                        ),
                      if (hasReader)
                        AnymeXTile.checkbox(
                          icon: Icons.chrome_reader_mode_outlined,
                          title: context.l10n.readerPreferences,
                          subtitle:
                              context.l10n.mangaNovelViewerSettingsTapZones,
                          value: _restoreOptions.settings.reader,
                          onChanged: (v) => setState(
                              () => _restoreOptions.settings.reader = v),
                        ),
                      if (hasExtSettings)
                        AnymeXTile.checkbox(
                          icon: Icons.extension_outlined,
                          title: context.l10n.extensionPreferences,
                          subtitle:
                              context.l10n.extensionSettingsAndSourceConfigurations,
                          value: _restoreOptions.settings.extensions,
                          onChanged: (v) => setState(
                              () => _restoreOptions.settings.extensions = v),
                        ),
                      if (hasDownloadSettings)
                        AnymeXTile.checkbox(
                          icon: Icons.download_done_rounded,
                          title: context.l10n.downloadsStorage,
                          subtitle: context.l10n.downloadQualityStoragePaths,
                          value: _restoreOptions.settings.downloads,
                          onChanged: (v) => setState(
                              () => _restoreOptions.settings.downloads = v),
                        ),
                      if (hasGeneralSettings)
                        AnymeXTile.checkbox(
                          icon: Icons.tune_rounded,
                          title: context.l10n.generalPreferences,
                          subtitle:
                              context.l10n.generalAppSettingsAndSyncServices,
                          value: _restoreOptions.settings.general,
                          onChanged: (v) => setState(
                              () => _restoreOptions.settings.general = v),
                        ),
                      if (hasAuthTokens)
                        AnymeXTile.checkbox(
                          icon: Icons.vpn_key_outlined,
                          title: context.l10n.loginSessions,
                          subtitle: context.l10n.accountTokensAnilistMalSimkl,
                          value: _restoreOptions.settings.authTokens,
                          onChanged: (v) => setState(
                              () => _restoreOptions.settings.authTokens = v),
                        ),
                    ],
                  ),
                ),
              if (hasRuntime)
                AnymeXTile.checkbox(
                  icon: Icons.memory_rounded,
                  title: context.l10n.runtimeHost,
                  subtitle:
                      "$runtimePlatform runtime${runtimeSizeStr.isNotEmpty ? ' • $runtimeSizeStr' : ''}",
                  value: _restoreOptions.runtimeHost,
                  onChanged: (v) =>
                      setState(() => _restoreOptions.runtimeHost = v),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.isRestoring.value ? null : _executeRestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isRestoring.value)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary),
                            ),
                          )
                        else ...[
                          Icon(Icons.file_download_outlined,
                              color: theme.colorScheme.onPrimary, size: 20),
                          const SizedBox(width: 8),
                          AnymeXText(
                            context.l10n.importBackup,
                            variant: TextVariant.bold,
                            color: theme.colorScheme.onPrimary,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: AnymeXText(
            context.l10n.externalBackupsRestoreMetadataAndConfigurations,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant.opaque(0.6),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.backup,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16.0, AnymeXHeaderScope.of(ctx), 16.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: controller.getLibraryStats(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: LibraryDashboard(stats: snapshot.data!),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              _buildExportSection(context),
              const SizedBox(height: 24),
              _buildImportSection(context),
              const SizedBox(height: 24),
              const ProgressSyncSection(),
            ],
          ),
        ),
      ),
    );
  }
}
