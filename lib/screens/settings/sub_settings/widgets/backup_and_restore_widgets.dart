import 'package:flutter/material.dart';
import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';

class PasswordInputDialog extends StatefulWidget {
  final TextEditingController controller;

  const PasswordInputDialog({super.key, required this.controller});

  @override
  State<PasswordInputDialog> createState() => PasswordInputDialogState();
}

class PasswordInputDialogState extends State<PasswordInputDialog> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnymeXDialog(
      title: "Password Required".tr,
      confirmText: "Unlock".tr,
      onConfirm: () {},
      confirmResultGetter: () =>
          widget.controller.text.isNotEmpty ? widget.controller.text : null,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          AnymeXText(
            "This backup is encrypted. Please enter the password to continue.".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.opaque(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.opaque(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    obscureText: _obscurePassword,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Linotte',
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: "Enter password".tr,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.opaque(0.45),
                        fontSize: 13.5,
                        fontFamily: 'Linotte',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  final RxString statusObs;
  final RxDouble progressObs;

  const LoadingDialog({
    super.key,
    required this.statusObs,
    required this.progressObs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer.opaque(0.4),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: theme.colorScheme.outlineVariant.opaque(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Obx(() => AnymeXText(
                    statusObs.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
              const SizedBox(height: 8),
              Obx(() => AnymeXText(
                    "${(progressObs.value * 100).toInt()}%",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryDashboard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const LibraryDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _buildStat(context, "Anime", stats['animeCount'],
            theme.colorScheme.primary, Icons.movie_filter),
        const SizedBox(width: 12),
        _buildStat(context, "Manga", stats['mangaCount'],
            theme.colorScheme.secondary, Icons.menu_book),
        const SizedBox(width: 12),
        _buildStat(context, "Novel", stats['novelCount'],
            theme.colorScheme.tertiary, Icons.auto_stories),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String label, dynamic count,
      Color color, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer.opaque(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.opaque(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              AnymeXText(count.toString(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              AnymeXText(label,
                  style: TextStyle(
                      color: context.colors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class RestorePreviewSheet extends StatefulWidget {
  final Map<String, dynamic> info;
  final bool isEncrypted;
  final Function(RestoreOptions options) onConfirm;

  const RestorePreviewSheet({
    super.key,
    required this.info,
    required this.isEncrypted,
    required this.onConfirm,
  });

  @override
  State<RestorePreviewSheet> createState() => _RestorePreviewSheetState();
}

class _RestorePreviewSheetState extends State<RestorePreviewSheet> {
  late final RestoreOptions _options;

  @override
  void initState() {
    super.initState();
    _options = RestoreOptions(
      anime: widget.info['hasAnime'] ?? false,
      manga: widget.info['hasManga'] ?? false,
      novel: widget.info['hasNovel'] ?? false,
      customLists: widget.info['hasCustomLists'] ?? false,
      stats: widget.info['hasStats'] ?? false,
      settings: SettingsOptions(
        appearance: widget.info['hasAppearance'] ?? false,
        player: widget.info['hasPlayer'] ?? false,
        reader: widget.info['hasReader'] ?? false,
        extensions: widget.info['hasExtSettings'] ?? false,
        downloads: widget.info['hasDownloadSettings'] ?? false,
        general: widget.info['hasGeneralSettings'] ?? false,
        authTokens: false,
      ),
      extensionsData: widget.info['hasExtensionsData'] ?? false,
      extensionFiles: widget.info['hasExtensionFiles'] ?? false,
      runtimeHost: widget.info['hasRuntimeHost'] ?? false,
    );
  }

  Widget _buildGlassContainer(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.opaque(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.opaque(0.5)),
      ),
      child: child,
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final username = widget.info['username'] ?? 'Unknown User';
    final avatar = widget.info['avatar'] as String?;
    final rawVersion = (widget.info['appVersion'] as String? ?? '').trim();
    final appVersion = rawVersion.startsWith('v') || rawVersion.startsWith('V')
        ? rawVersion
        : (rawVersion.isNotEmpty ? 'v$rawVersion' : 'Unknown');

    return _buildGlassContainer(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.opaque(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: avatar != null && avatar.isNotEmpty
                    ? AnymeXImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        radius: 0,
                      )
                    : Container(
                        color: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    "Backup Owner".tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnymeXText(
                    username,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      AnymeXText(
                        appVersion,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int itemCount,
    required int listCount,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.opaque(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnymeXText(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnymeXText(
                itemCount.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              AnymeXText(
                "$listCount lists",
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryStatsCard(BuildContext context) {
    final theme = Theme.of(context);
    final animeCount = widget.info['animeCount'] ?? 0;
    final mangaCount = widget.info['mangaCount'] ?? 0;
    final novelCount = widget.info['novelCount'] ?? 0;
    final animeCustomListsCount =
        widget.info['animeCustomListsCount'] ?? 0;
    final mangaCustomListsCount =
        widget.info['mangaCustomListsCount'] ?? 0;
    final novelCustomListsCount =
        widget.info['novelCustomListsCount'] ?? 0;

    final totalItems = animeCount + mangaCount + novelCount;
    final totalLists = animeCustomListsCount +
        mangaCustomListsCount +
        novelCustomListsCount;

    return _buildGlassContainer(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                AnymeXText(
                  "Library Statistics".tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.opaque(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      AnymeXText(
                        totalItems.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      AnymeXText(
                        "Total Items".tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.opaque(0.2),
                  ),
                  Column(
                    children: [
                      AnymeXText(
                        totalLists.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      AnymeXText(
                        "Custom Lists".tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryRow(
              context,
              icon: Icons.movie_filter,
              label: "Anime".tr,
              itemCount: animeCount,
              listCount: animeCustomListsCount,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildCategoryRow(
              context,
              icon: Icons.menu_book,
              label: "Manga".tr,
              itemCount: mangaCount,
              listCount: mangaCustomListsCount,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            _buildCategoryRow(
              context,
              icon: Icons.auto_stories,
              label: "Novel".tr,
              itemCount: novelCount,
              listCount: novelCustomListsCount,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.opaque(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.opaque(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnymeXText(
              "Restoring will overwrite your selected local library items and settings with the contents of this backup.".tr,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedOptions(BuildContext context) {
    final hasAnime = widget.info['hasAnime'] ?? false;
    final hasManga = widget.info['hasManga'] ?? false;
    final hasNovel = widget.info['hasNovel'] ?? false;
    final hasCustomLists = widget.info['hasCustomLists'] ?? false;
    final hasStats = widget.info['hasStats'] ?? false;
    final hasAppearance = widget.info['hasAppearance'] ?? false;
    final hasPlayer = widget.info['hasPlayer'] ?? false;
    final hasReader = widget.info['hasReader'] ?? false;
    final hasExtSettings = widget.info['hasExtSettings'] ?? false;
    final hasDownloadSettings = widget.info['hasDownloadSettings'] ?? false;
    final hasGeneralSettings = widget.info['hasGeneralSettings'] ?? false;
    final hasAuthTokens = widget.info['hasAuthTokens'] ?? false;
    final hasExtData = widget.info['hasExtensionsData'] ?? false;
    final hasExtFiles = widget.info['hasExtensionFiles'] ?? false;
    final hasRuntimeHost = widget.info['hasRuntimeHost'] ?? false;

    final hasAnyMedia =
        hasAnime || hasManga || hasNovel || hasCustomLists || hasStats;
    final hasAnySettings = hasAppearance ||
        hasPlayer ||
        hasReader ||
        hasExtSettings ||
        hasDownloadSettings ||
        hasGeneralSettings ||
        hasAuthTokens;
    final hasAnyExtensions = hasExtData || hasExtFiles;

    final runtimePlatform =
        widget.info['runtimeHostPlatform'] as String? ?? '';
    final runtimeSize = widget.info['runtimeHostSize'] as int? ?? 0;
    final runtimeSizeStr = runtimeSize > 0
        ? '${(runtimeSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';
    final runtimeTitle = runtimePlatform.toLowerCase() == 'android'
        ? 'Android Runtime Host (APK)'
        : 'Desktop Runtime (JAR)';

    return Column(
      children: [
        if (hasAnyMedia)
          AnymeXExpansionTile(
            title: "Media Library".tr,
            initialExpanded: true,
            icon: Icons.video_library_rounded,
            content: Column(
              children: [
                if (hasAnime)
                  AnymeXTile.checkbox(
                    icon: Icons.movie_filter_rounded,
                    title: "Anime Library".tr,
                    subtitle: "@p0 titles".trParams({'p0': (widget.info['animeCount'] ?? 0).toString()}),
                    value: _options.anime,
                    onChanged: (v) => setState(() => _options.anime = v),
                  ),
                if (hasManga)
                  AnymeXTile.checkbox(
                    icon: Icons.menu_book_rounded,
                    title: "Manga Library".tr,
                    subtitle: "@p0 titles".trParams({'p0': (widget.info['mangaCount'] ?? 0).toString()}),
                    value: _options.manga,
                    onChanged: (v) => setState(() => _options.manga = v),
                  ),
                if (hasNovel)
                  AnymeXTile.checkbox(
                    icon: Icons.auto_stories_rounded,
                    title: "Novel Library".tr,
                    subtitle: "@p0 titles".trParams({'p0': (widget.info['novelCount'] ?? 0).toString()}),
                    value: _options.novel,
                    onChanged: (v) => setState(() => _options.novel = v),
                  ),
                if (hasCustomLists)
                  AnymeXTile.checkbox(
                    icon: Icons.playlist_play_rounded,
                    title: "Custom Lists".tr,
                    subtitle:
                        "@p0 custom lists".trParams({'p0': ((widget.info['animeCustomListsCount'] ?? 0) + (widget.info['mangaCustomListsCount'] ?? 0) + (widget.info['novelCustomListsCount'] ?? 0)).toString()}),
                    value: _options.customLists,
                    onChanged: (v) =>
                        setState(() => _options.customLists = v),
                  ),
                if (hasStats)
                  AnymeXTile.checkbox(
                    icon: Icons.insights_rounded,
                    title: "History & Statistics".tr,
                    subtitle: "Daily activity and watch/read progress tracking".tr,
                    value: _options.stats,
                    onChanged: (v) => setState(() => _options.stats = v),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (hasAnySettings)
          AnymeXExpansionTile(
            title: "Settings & Account".tr,
            initialExpanded: false,
            icon: Icons.tune_rounded,
            content: Column(
              children: [
                if (hasAppearance)
                  AnymeXTile.checkbox(
                    icon: Icons.palette_rounded,
                    title: "Appearance & Theme".tr,
                    subtitle: "UI layout, colors, and themes".tr,
                    value: _options.settings.appearance,
                    onChanged: (v) =>
                        setState(() => _options.settings.appearance = v),
                  ),
                if (hasPlayer)
                  AnymeXTile.checkbox(
                    icon: Icons.play_circle_outline_rounded,
                    title: "Video Player".tr,
                    subtitle: "Controls, subtitles, and playback preferences".tr,
                    value: _options.settings.player,
                    onChanged: (v) =>
                        setState(() => _options.settings.player = v),
                  ),
                if (hasReader)
                  AnymeXTile.checkbox(
                    icon: Icons.chrome_reader_mode_rounded,
                    title: "Reader Preferences".tr,
                    subtitle: "Manga & novel reader settings, tap zones".tr,
                    value: _options.settings.reader,
                    onChanged: (v) =>
                        setState(() => _options.settings.reader = v),
                  ),
                if (hasExtSettings)
                  AnymeXTile.checkbox(
                    icon: Icons.extension_outlined,
                    title: "Extension Preferences".tr,
                    subtitle: "Source and plugin configurations".tr,
                    value: _options.settings.extensions,
                    onChanged: (v) =>
                        setState(() => _options.settings.extensions = v),
                  ),
                if (hasDownloadSettings)
                  AnymeXTile.checkbox(
                    icon: Icons.download_done_rounded,
                    title: "Downloads & Storage".tr,
                    subtitle: "Download paths and quality settings".tr,
                    value: _options.settings.downloads,
                    onChanged: (v) =>
                        setState(() => _options.settings.downloads = v),
                  ),
                if (hasGeneralSettings)
                  AnymeXTile.checkbox(
                    icon: Icons.settings_outlined,
                    title: "General & Sync".tr,
                    subtitle: "General app settings and sync services".tr,
                    value: _options.settings.general,
                    onChanged: (v) =>
                        setState(() => _options.settings.general = v),
                  ),
                if (hasAuthTokens)
                  AnymeXTile.checkbox(
                    icon: Icons.vpn_key_rounded,
                    title: "Login Sessions".tr,
                    subtitle:
                        "Sensitive login tokens for MAL, Simkl, and AniList".tr,
                    value: _options.settings.authTokens,
                    onChanged: (v) =>
                        setState(() => _options.settings.authTokens = v),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (hasAnyExtensions)
          AnymeXExpansionTile(
            title: "Extensions".tr,
            initialExpanded: false,
            icon: Icons.extension_rounded,
            content: Column(
              children: [
                if (hasExtData)
                  AnymeXTile.checkbox(
                    icon: Icons.settings_input_component_rounded,
                    title: "Extension Configurations".tr,
                    subtitle:
                        "@p0 repositories and source settings".trParams({'p0': (widget.info['extensionsDataCount'] ?? 0).toString()}),
                    value: _options.extensionsData,
                    onChanged: (v) =>
                        setState(() => _options.extensionsData = v),
                  ),
                if (hasExtFiles)
                  AnymeXTile.checkbox(
                    icon: Icons.folder_zip_rounded,
                    title: "Extension Packages".tr,
                    subtitle:
                        "@p0 installed files@p1".trParams({'p0': (widget.info['extensionFilesCount'] ?? 0).toString(), 'p1': (widget.info['extensionFilesSize'] != null && (widget.info['extensionFilesSize'] as int) > 0 ? ' • ${((widget.info['extensionFilesSize'] as int) / (1024 * 1024)).toStringAsFixed(1)} MB' : '').toString()}),
                    value: _options.extensionFiles,
                    onChanged: (v) =>
                        setState(() => _options.extensionFiles = v),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (hasRuntimeHost)
          AnymeXExpansionTile(
            title: "Runtime Host".tr,
            initialExpanded: false,
            icon: Icons.memory_rounded,
            content: Column(
              children: [
                AnymeXTile.checkbox(
                  icon: runtimePlatform.toLowerCase() == 'android'
                      ? Icons.android_rounded
                      : Icons.desktop_windows_rounded,
                  title: runtimeTitle,
                  subtitle: runtimeSizeStr.isNotEmpty
                      ? "$runtimeSizeStr • Bundled in backup"
                      : "Bundled runtime host",
                  value: _options.runtimeHost,
                  onChanged: (v) =>
                      setState(() => _options.runtimeHost = v),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = widget.info['date'] as String? ?? 'Unknown Date';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  AnymeXText(
                    "Restore Preview".tr,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.isEncrypted) ...[
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        AnymeXText(
                          "Encrypted • ".tr,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      AnymeXText(
                        date,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildUserInfoCard(context),
                  const SizedBox(height: 24),
                  _buildLibraryStatsCard(context),
                  const SizedBox(height: 16),
                  _buildWarningBanner(context),
                  const SizedBox(height: 24),
                  AnymeXText(
                    "DATA TO RESTORE".tr,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGroupedOptions(context),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      if (!_options.hasAnySelected) {
                        snackBar(
                            "Please select at least one item to restore.".tr);
                        return;
                      }
                      widget.onConfirm(_options);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: AnymeXText(
                      "CONFIRM & RESTORE".tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExportBackupSheet extends StatefulWidget {
  final BackupRestoreService controller;
  final Function(BackupOptions options, String? password) onExport;

  const ExportBackupSheet({
    super.key,
    required this.controller,
    required this.onExport,
  });

  @override
  State<ExportBackupSheet> createState() => _ExportBackupSheetState();
}

class _ExportBackupSheetState extends State<ExportBackupSheet> {
  final BackupOptions _options = BackupOptions();
  bool _usePassword = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;

  RuntimeHostInfo? _runtimeHostInfo;
  ExtensionFilesInfo? _extensionFilesInfo;
  int _extensionsDataCount = 0;
  bool _isLoadingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final hostInfo = await widget.controller.getRuntimeHostInfo();
    final filesInfo = await widget.controller.getExtensionFilesInfo();
    final dataCount = widget.controller.getExtensionsDataCount();
    if (mounted) {
      setState(() {
        _runtimeHostInfo = hostInfo;
        _extensionFilesInfo = filesInfo;
        _extensionsDataCount = dataCount;
        _isLoadingInfo = false;
        if (!hostInfo.isInstalled) {
          _options.runtimeHost = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _selectAll(bool select) {
    setState(() {
      _options.anime = select;
      _options.manga = select;
      _options.novel = select;
      _options.customLists = select;
      _options.stats = select;
      _options.settings.appearance = select;
      _options.settings.player = select;
      _options.settings.reader = select;
      _options.settings.extensions = select;
      _options.settings.downloads = select;
      _options.settings.general = select;
      _options.settings.authTokens = select;
      _options.extensionsData = select;
      _options.extensionFiles = select;
      if (_runtimeHostInfo?.isInstalled ?? false) {
        _options.runtimeHost = select;
      }
    });
  }

  void _handleExport() {
    if (!_options.hasAnySelected) {
      snackBar("Please select at least one item to back up.".tr);
      return;
    }

    String? password;
    if (_usePassword) {
      if (_passwordController.text.isEmpty) {
        snackBar("Please enter a password or disable password protection.".tr);
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        snackBar("Passwords don't match!".tr);
        return;
      }
      password = _passwordController.text;
    }

    widget.onExport(_options, password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hostInstalled = _runtimeHostInfo?.isInstalled ?? false;
    final hostSize = _runtimeHostInfo?.fileSize ?? 0;
    final hostSizeStr = hostSize > 0
        ? '${(hostSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';
    final isDesktop = _runtimeHostInfo?.isDesktop ?? true;
    final runtimeTitle =
        isDesktop ? "Desktop Runtime Host (JAR)" : "Android Runtime Host (APK)";
    final rawVersion = (_runtimeHostInfo?.version ?? '').trim();
    final hostVersion = rawVersion.startsWith('v') || rawVersion.startsWith('V')
        ? rawVersion
        : (rawVersion.isNotEmpty ? 'v$rawVersion' : '');

    final extCount = _extensionFilesInfo?.count ?? 0;
    final extSize = _extensionFilesInfo?.totalSize ?? 0;
    final extSizeStr = extSize > 0
        ? '${(extSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        "Export Backup".tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        "Select data to include in this backup".tr,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final all = _options.hasAnySelected;
                    _selectAll(!all);
                  },
                  icon: Icon(
                    _options.hasAnySelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: AnymeXText(
                    _options.hasAnySelected ? "Deselect" : "Select All",
                    variant: TextVariant.semiBold,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.opaque(0.2),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
              children: [
                AnymeXExpansionTile(
                  title: "Media Library".tr,
                  icon: Icons.video_library_rounded,
                  initialExpanded: true,
                  content: Column(
                    children: [
                      AnymeXTile.checkbox(
                        icon: Icons.movie_filter_rounded,
                        title: "Anime Library".tr,
                        subtitle: "Saved anime entries and progress".tr,
                        value: _options.anime,
                        onChanged: (v) => setState(() => _options.anime = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.menu_book_rounded,
                        title: "Manga Library".tr,
                        subtitle: "Saved manga entries and chapters".tr,
                        value: _options.manga,
                        onChanged: (v) => setState(() => _options.manga = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.auto_stories_rounded,
                        title: "Novel Library".tr,
                        subtitle: "Saved light novels and reading state".tr,
                        value: _options.novel,
                        onChanged: (v) => setState(() => _options.novel = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.playlist_play_rounded,
                        title: "Custom Lists".tr,
                        subtitle: "User-created custom media collections".tr,
                        value: _options.customLists,
                        onChanged: (v) =>
                            setState(() => _options.customLists = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.insights_rounded,
                        title: "History & Statistics".tr,
                        subtitle: "Daily activities, watch and read metrics".tr,
                        value: _options.stats,
                        onChanged: (v) => setState(() => _options.stats = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AnymeXExpansionTile(
                  title: "Settings & Authentication".tr,
                  icon: Icons.tune_rounded,
                  initialExpanded: true,
                  content: Column(
                    children: [
                      AnymeXTile.checkbox(
                        icon: Icons.palette_rounded,
                        title: "Appearance & Theme".tr,
                        subtitle: "Theme, layout, and colors".tr,
                        value: _options.settings.appearance,
                        onChanged: (v) => setState(
                            () => _options.settings.appearance = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.play_circle_outline_rounded,
                        title: "Video Player".tr,
                        subtitle:
                            "Controls, subtitles, and playback preferences".tr,
                        value: _options.settings.player,
                        onChanged: (v) => setState(
                            () => _options.settings.player = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.chrome_reader_mode_rounded,
                        title: "Reader Preferences".tr,
                        subtitle:
                            "Manga and novel reader styles and tap zones".tr,
                        value: _options.settings.reader,
                        onChanged: (v) => setState(
                            () => _options.settings.reader = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.extension_outlined,
                        title: "Extension Preferences".tr,
                        subtitle: "Source and plugin configurations".tr,
                        value: _options.settings.extensions,
                        onChanged: (v) => setState(
                            () => _options.settings.extensions = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.download_done_rounded,
                        title: "Downloads & Storage".tr,
                        subtitle: "Download paths and storage settings".tr,
                        value: _options.settings.downloads,
                        onChanged: (v) => setState(
                            () => _options.settings.downloads = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.settings_outlined,
                        title: "General & Sync".tr,
                        subtitle: "General app preferences and sync services".tr,
                        value: _options.settings.general,
                        onChanged: (v) => setState(
                            () => _options.settings.general = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.vpn_key_rounded,
                        title: "Login & Auth Tokens".tr,
                        subtitle:
                            "Sensitive session tokens for MAL, Simkl, and AniList".tr,
                        value: _options.settings.authTokens,
                        onChanged: (v) => setState(
                            () => _options.settings.authTokens = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AnymeXExpansionTile(
                  title: "Extensions".tr,
                  icon: Icons.extension_rounded,
                  initialExpanded: true,
                  content: Column(
                    children: [
                      AnymeXTile.checkbox(
                        icon: Icons.settings_input_component_rounded,
                        title: "Extension Configurations & Repos".tr,
                        subtitle:
                            "@v registered repositories and source settings".trParams({'v': (_extensionsDataCount).toString()}),
                        value: _options.extensionsData,
                        onChanged: (v) =>
                            setState(() => _options.extensionsData = v),
                      ),
                      AnymeXTile.checkbox(
                        icon: Icons.folder_zip_rounded,
                        title: "Extension Packages".tr,
                        subtitle: extCount > 0
                            ? "$extCount installed files ($extSizeStr)"
                            : "No downloaded extension packages found",
                        value: _options.extensionFiles,
                        onChanged: (v) =>
                            setState(() => _options.extensionFiles = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AnymeXExpansionTile(
                  title: "Runtime Host".tr,
                  icon: Icons.memory_rounded,
                  initialExpanded: true,
                  content: Column(
                    children: [
                      AnymeXTile.checkbox(
                        icon: isDesktop
                            ? Icons.desktop_windows_rounded
                            : Icons.android_rounded,
                        title: runtimeTitle,
                        subtitle: _isLoadingInfo
                            ? "Checking installed runtime..."
                            : hostInstalled
                                ? "${hostVersion.isNotEmpty ? '$hostVersion • ' : ''}$hostSizeStr"
                                : "Not installed on this device",
                        value: _options.runtimeHost,
                        onChanged: hostInstalled
                            ? (v) => setState(() => _options.runtimeHost = v)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AnymeXExpansionTile(
                  title: "Security & Encryption".tr,
                  icon: Icons.lock_outline_rounded,
                  initialExpanded: true,
                  content: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    child: Column(
                      children: [
                        AnymeXTile.checkbox(
                          icon: Icons.security_rounded,
                          title: "Password Protect Backup".tr,
                          subtitle:
                              "Encrypt with AES-256 (recommended for auth tokens)".tr,
                          value: _usePassword,
                          onChanged: (v) => setState(() => _usePassword = v),
                        ),
                        if (_usePassword) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .opaque(0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.opaque(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Linotte',
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      hintText: "Enter backup password".tr,
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .opaque(0.45),
                                        fontSize: 13.5,
                                        fontFamily: 'Linotte',
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword =
                                        !_obscurePassword);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .opaque(0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.opaque(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Linotte',
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      hintText: "Confirm backup password".tr,
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .opaque(0.45),
                                        fontSize: 13.5,
                                        fontFamily: 'Linotte',
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: ElevatedButton(
              onPressed: _handleExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vertical_align_bottom_rounded,
                      color: theme.colorScheme.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  AnymeXText(
                    "Export Backup".tr,
                    variant: TextVariant.bold,
                    color: theme.colorScheme.onPrimary,
                    size: 15,
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

