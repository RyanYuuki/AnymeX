import 'dart:io';
import 'package:flutter/material.dart';
import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/widgets/plugin_manager.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/common/source_selector.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

String _getCategoryDescription(String cat) {
  switch (cat) {
    case SettingsCategory.common:
      return 'General application settings & preferences';
    case SettingsCategory.ui:
      return 'Navigation dock order, layouts & scaling';
    case SettingsCategory.theme:
      return 'Theme mode, color palette & glow effects';
    case SettingsCategory.player:
      return 'Video engine, gestures, controls & player themes';
    case SettingsCategory.reader:
      return 'Reading mode, page transitions & reader layout';
    case SettingsCategory.accounts:
      return 'Tracker login tokens & sessions (Sensitive)';
    case SettingsCategory.discord:
      return 'Discord Rich Presence integration';
    case SettingsCategory.downloads:
      return 'Download directories & queue preferences';
    case SettingsCategory.extensions:
      return 'Extension repositories & source preferences';
    default:
      return 'Category preferences';
  }
}

IconData _getCategoryIcon(String cat) {
  switch (cat) {
    case SettingsCategory.common:
      return Icons.tune_rounded;
    case SettingsCategory.ui:
      return Icons.dashboard_customize_rounded;
    case SettingsCategory.theme:
      return Icons.palette_rounded;
    case SettingsCategory.player:
      return Icons.play_circle_outline_rounded;
    case SettingsCategory.reader:
      return Icons.menu_book_rounded;
    case SettingsCategory.accounts:
      return Icons.lock_outline_rounded;
    case SettingsCategory.discord:
      return Icons.discord;
    case SettingsCategory.downloads:
      return Icons.download_rounded;
    case SettingsCategory.extensions:
      return Icons.extension_rounded;
    default:
      return Icons.settings_rounded;
  }
}

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
      title: "Password Required",
      confirmText: "Unlock",
      onConfirm: () {},
      confirmResultGetter: () => widget.controller.text.isNotEmpty ? widget.controller.text : null,
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
            "This backup is encrypted. Please enter the password to continue.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: widget.controller,
            obscureText: _obscurePassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "Password",
              hintText: "Enter password",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.opaque(0.3),
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

  const LoadingDialog(
      {super.key, required this.statusObs, required this.progressObs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: GlassContainer(
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
                        fontWeight: FontWeight.w600),
                  )),
              const SizedBox(height: 8),
              Obx(() => AnymeXText(
                    "${(progressObs.value * 100).toInt()}%",
                    style: TextStyle(
                        color: theme.colorScheme.primary, fontSize: 12),
                  )),
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
  final Function(
    Set<String> selectedSettingsCategories,
    Set<String> selectedExtensionIds,
    bool restoreAnime,
    bool restoreManga,
    bool restoreNovel,
    bool restoreCustomLists,
  ) onConfirm;

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
  late bool _restoreAnime;
  late bool _restoreManga;
  late bool _restoreNovel;
  late bool _restoreCustomLists;
  late Set<String> _selectedSettingsCategories;
  late Set<String> _selectedExtensionIds;

  @override
  void initState() {
    super.initState();
    _restoreAnime = widget.info['hasAnime'] as bool? ??
        ((widget.info['animeCount'] as int? ?? 0) > 0);
    _restoreManga = widget.info['hasManga'] as bool? ??
        ((widget.info['mangaCount'] as int? ?? 0) > 0);
    _restoreNovel = widget.info['hasNovel'] as bool? ??
        ((widget.info['novelCount'] as int? ?? 0) > 0);
    _restoreCustomLists = widget.info['hasCustomLists'] as bool? ?? true;

    final categories = (widget.info['settingsCategories'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    _selectedSettingsCategories =
        categories.where((c) => c != SettingsCategory.accounts).toSet();

    final extensions = (widget.info['extensions'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    _selectedExtensionIds = extensions
        .map((e) => e['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _handleConfirmRestore(BuildContext context) async {
    final extensions = (widget.info['extensions'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final selectedExts = extensions
        .where((e) => _selectedExtensionIds.contains(e['id']))
        .toList();

    final hasSelectedPluginExt = selectedExts.any((e) {
      final m = (e['managerName'] as String? ?? '').toLowerCase();
      return m == 'aniyomi' || m == 'cloudstream' || m == 'kotatsu';
    });

    if (Platform.isIOS) {
      final cleanExtIds = selectedExts
          .where((e) {
            final m = (e['managerName'] as String? ?? '').toLowerCase();
            return m != 'aniyomi' && m != 'cloudstream' && m != 'kotatsu';
          })
          .map((e) => e['id'] as String)
          .toSet();

      widget.onConfirm(
        _selectedSettingsCategories,
        cleanExtIds,
        _restoreAnime,
        _restoreManga,
        _restoreNovel,
        _restoreCustomLists,
      );
      return;
    }

    if (hasSelectedPluginExt && !AnymeXRuntimeBridge.isPluginInstalled) {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AnymeXDialog(
          title: "Plugin Required",
          contentWidget: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Theme.of(ctx).colorScheme.error, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AnymeXText(
                      "Plugin Required for Extensions",
                      variant: TextVariant.bold,
                      size: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnymeXText(
                "Your backup contains extensions from Aniyomi, CloudStream, or Kotatsu which require the AnymeX Extension Runtime Plugin.\n\nWould you like to install the plugin now, or skip these extensions and continue restoring the rest?",
                size: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          confirmText: "Install Plugin",
          cancelText: "Skip Plugin Exts",
          onConfirm: () => Navigator.of(ctx).pop("install"),
          onCancel: () => Navigator.of(ctx).pop("skip"),
        ),
      );

      if (result == "install") {
        if (context.mounted) {
          await PluginManager().ensurePluginLoaded(context);
        }
        return;
      } else if (result == "skip") {
        final cleanExtIds = selectedExts
            .where((e) {
              final m = (e['managerName'] as String? ?? '').toLowerCase();
              return m != 'aniyomi' && m != 'cloudstream' && m != 'kotatsu';
            })
            .map((e) => e['id'] as String)
            .toSet();

        widget.onConfirm(
          _selectedSettingsCategories,
          cleanExtIds,
          _restoreAnime,
          _restoreManga,
          _restoreNovel,
          _restoreCustomLists,
        );
        return;
      } else {
        return;
      }
    }

    widget.onConfirm(
      _selectedSettingsCategories,
      _selectedExtensionIds,
      _restoreAnime,
      _restoreManga,
      _restoreNovel,
      _restoreCustomLists,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = widget.info['date'] as String? ?? 'Unknown Date';
    final categories = (widget.info['settingsCategories'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final extensions = (widget.info['extensions'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final hasLibraryData = (widget.info['hasAnime'] == true) ||
        (widget.info['hasManga'] == true) ||
        (widget.info['hasNovel'] == true) ||
        (widget.info['hasCustomLists'] == true);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => AnymeXContainer(
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
                    "Restore Preview",
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
                          "Encrypted • ",
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
                  UserInfoCard(
                    username: widget.info['username'] ?? 'Unknown User',
                    avatar: widget.info['avatar'],
                    appVersion: widget.info['appVersion'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 24),
                  LibraryStatsCard(
                    animeCount: widget.info['animeCount'] ?? 0,
                    mangaCount: widget.info['mangaCount'] ?? 0,
                    novelCount: widget.info['novelCount'] ?? 0,
                    animeCustomListsCount:
                        widget.info['animeCustomListsCount'] ?? 0,
                    mangaCustomListsCount:
                        widget.info['mangaCustomListsCount'] ?? 0,
                    novelCustomListsCount:
                        widget.info['novelCustomListsCount'] ?? 0,
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                            "This will restore selected items to your local storage. Existing matching data will be overwritten.",
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnymeXText(
                    "RESTORE CONTENT",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasLibraryData) ...[
                    AnymeXExpansionTile(
                      title: "Media Library",
                      leading: Icon(Icons.library_books_rounded,
                          color: theme.colorScheme.primary, size: 20),
                      initialExpanded: true,
                      content: Column(
                        children: [
                          if ((widget.info['animeCount'] ?? 0) > 0 ||
                              widget.info['hasAnime'] == true)
                            AnymeXTile.checkbox(
                              title: "Anime Library",
                              subtitle:
                                  "${widget.info['animeCount'] ?? 0} titles with watch progress",
                              value: _restoreAnime,
                              onChanged: (v) =>
                                  setState(() => _restoreAnime = v),
                            ),
                          if ((widget.info['mangaCount'] ?? 0) > 0 ||
                              widget.info['hasManga'] == true)
                            AnymeXTile.checkbox(
                              title: "Manga Library",
                              subtitle:
                                  "${widget.info['mangaCount'] ?? 0} titles with reading history",
                              value: _restoreManga,
                              onChanged: (v) =>
                                  setState(() => _restoreManga = v),
                            ),
                          if ((widget.info['novelCount'] ?? 0) > 0 ||
                              widget.info['hasNovel'] == true)
                            AnymeXTile.checkbox(
                              title: "Novel Library",
                              subtitle:
                                  "${widget.info['novelCount'] ?? 0} titles with bookmarks",
                              value: _restoreNovel,
                              onChanged: (v) =>
                                  setState(() => _restoreNovel = v),
                            ),
                          if ((widget.info['animeCustomListsCount'] ?? 0) > 0 ||
                              (widget.info['mangaCustomListsCount'] ?? 0) > 0 ||
                              (widget.info['novelCustomListsCount'] ?? 0) > 0 ||
                              widget.info['hasCustomLists'] == true)
                            AnymeXTile.checkbox(
                              title: "Custom Lists",
                              subtitle:
                                  "${(widget.info['animeCustomListsCount'] ?? 0) + (widget.info['mangaCustomListsCount'] ?? 0) + (widget.info['novelCustomListsCount'] ?? 0)} custom lists",
                              value: _restoreCustomLists,
                              onChanged: (v) =>
                                  setState(() => _restoreCustomLists = v),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (categories.isNotEmpty) ...[
                    AnymeXExpansionTile(
                      title:
                          "Settings (${_selectedSettingsCategories.length}/${categories.length})",
                      leading: Icon(Icons.settings_suggest_rounded,
                          color: theme.colorScheme.primary, size: 20),
                      initialExpanded: false,
                      content: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedSettingsCategories
                                        .addAll(categories);
                                  });
                                },
                                child:
                                    const AnymeXText("Select All", size: 12),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedSettingsCategories.clear();
                                  });
                                },
                                child:
                                    const AnymeXText("Deselect All", size: 12),
                              ),
                            ],
                          ),
                          ...categories.map((cat) {
                            final isSelected =
                                _selectedSettingsCategories.contains(cat);
                            return AnymeXTile.checkbox(
                              title: cat,
                              subtitle: _getCategoryDescription(cat),
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedSettingsCategories.add(cat);
                                  } else {
                                    _selectedSettingsCategories.remove(cat);
                                  }
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (extensions.isNotEmpty) ...[
                    AnymeXExpansionTile(
                      title:
                          "Extensions (${_selectedExtensionIds.length}/${extensions.length})",
                      leading: Icon(Icons.extension_rounded,
                          color: theme.colorScheme.primary, size: 20),
                      initialExpanded: false,
                      content: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedExtensionIds.addAll(extensions
                                        .map((e) => e['id'] as String? ?? '')
                                        .where((id) => id.isNotEmpty));
                                  });
                                },
                                child:
                                    const AnymeXText("Select All", size: 12),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedExtensionIds.clear();
                                  });
                                },
                                child:
                                    const AnymeXText("Deselect All", size: 12),
                              ),
                            ],
                          ),
                          ...extensions.map((ext) {
                            final extId = ext['id'] as String? ?? '';
                            final name = ext['name'] as String? ?? 'Unknown';
                            final lang =
                                (ext['lang'] as String? ?? '').toUpperCase();
                            final iconUrl = ext['iconUrl'] as String? ?? '';
                            final manager =
                                ext['managerName'] as String? ?? 'Extension';
                            final isPlugin = manager.toLowerCase() ==
                                    'aniyomi' ||
                                manager.toLowerCase() == 'cloudstream' ||
                                manager.toLowerCase() == 'kotatsu';
                            final isSelected =
                                _selectedExtensionIds.contains(extId);

                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedExtensionIds.add(extId);
                                  } else {
                                    _selectedExtensionIds.remove(extId);
                                  }
                                });
                              },
                              secondary: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: iconUrl.isNotEmpty
                                    ? AnymeXImage(
                                        imageUrl: iconUrl,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 36,
                                        height: 36,
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(Icons.extension,
                                            size: 20),
                                      ),
                              ),
                              title: AnymeXText(
                                name,
                                variant: TextVariant.semiBold,
                                size: 14,
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPlugin
                                          ? theme.colorScheme.errorContainer
                                              .opaque(0.6)
                                          : theme.colorScheme.primaryContainer
                                              .opaque(0.6),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: AnymeXText(
                                      manager,
                                      size: 10,
                                      variant: TextVariant.bold,
                                      color: isPlugin
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (lang.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    AnymeXText(
                                      lang,
                                      size: 11,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _handleConfirmRestore(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const AnymeXText(
                      "CONFIRM & RESTORE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final String username;
  final String? avatar;
  final String appVersion;

  const UserInfoCard({
    super.key,
    required this.username,
    this.avatar,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
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
                child: avatar != null && avatar!.isNotEmpty
                    ? AnymeXImage(
                        imageUrl: avatar!,
                        fit: BoxFit.cover,
                        radius: 0,
                      )
                    : const DefaultAvatar(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    "Backup Owner",
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
                        "v$appVersion",
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
}

class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        color: theme.colorScheme.primary,
        size: 32,
      ),
    );
  }
}

class LibraryStatsCard extends StatelessWidget {
  final int animeCount;
  final int mangaCount;
  final int novelCount;
  final int animeCustomListsCount;
  final int mangaCustomListsCount;
  final int novelCustomListsCount;

  const LibraryStatsCard({
    super.key,
    required this.animeCount,
    required this.mangaCount,
    required this.novelCount,
    required this.animeCustomListsCount,
    required this.mangaCustomListsCount,
    required this.novelCustomListsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = animeCount + mangaCount + novelCount;
    final totalLists =
        animeCustomListsCount + mangaCustomListsCount + novelCustomListsCount;

    return GlassContainer(
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
                  "Library Statistics",
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
                  TotalStat(
                    label: "Total Items",
                    value: totalItems.toString(),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.opaque(0.2),
                  ),
                  TotalStat(
                    label: "Custom Lists",
                    value: totalLists.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CategoryRow(
              icon: Icons.movie_filter,
              label: "Anime",
              itemCount: animeCount,
              listCount: animeCustomListsCount,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            CategoryRow(
              icon: Icons.menu_book,
              label: "Manga",
              itemCount: mangaCount,
              listCount: mangaCustomListsCount,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            CategoryRow(
              icon: Icons.auto_stories,
              label: "Novel",
              itemCount: novelCount,
              listCount: novelCustomListsCount,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class TotalStat extends StatelessWidget {
  final String label;
  final String value;

  const TotalStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AnymeXText(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        AnymeXText(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int itemCount;
  final int listCount;
  final Color color;

  const CategoryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.itemCount,
    required this.listCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
      child: GlassContainer(
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
                      color: context.colors.onSurfaceVariant,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class BackupPasswordDialog extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Function(
    bool usePassword,
    Set<String> selectedSettingsCategories,
    Set<String> selectedExtensionIds,
    bool backupAnime,
    bool backupManga,
    bool backupNovel,
    bool backupCustomLists,
  ) onConfirm;

  const BackupPasswordDialog({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onConfirm,
  });

  @override
  State<BackupPasswordDialog> createState() => BackupPasswordDialogState();
}

class BackupPasswordDialogState extends State<BackupPasswordDialog> {
  bool _usePassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _backupAnime = true;
  bool _backupManga = true;
  bool _backupNovel = true;
  bool _backupCustomLists = true;

  late Set<String> _selectedSettingsCategories;
  late Set<String> _selectedExtensionIds;
  List<Source> _allInstalledSources = [];

  @override
  void initState() {
    super.initState();
    _selectedSettingsCategories = SettingsCategory.all
        .where((c) => c != SettingsCategory.accounts)
        .toSet();

    final sourceCtrl = Get.isRegistered<SourceController>()
        ? Get.find<SourceController>()
        : null;
    if (sourceCtrl != null) {
      _allInstalledSources = [
        ...sourceCtrl.installedExtensions,
        ...sourceCtrl.installedMangaExtensions,
        ...sourceCtrl.installedNovelExtensions,
      ];
    }
    _selectedExtensionIds =
        _allInstalledSources.map((e) => e.id).whereType<String>().toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnymeXDialog(
      title: "Backup Options",
      confirmText: "Create Backup",
      onConfirm: () {
        widget.onConfirm(
          _usePassword,
          _selectedSettingsCategories,
          _selectedExtensionIds,
          _backupAnime,
          _backupManga,
          _backupNovel,
          _backupCustomLists,
        );
      },
      contentWidget: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.opaque(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.backup_rounded,
                        color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AnymeXText(
                          "Configure Backup",
                          variant: TextVariant.bold,
                          size: 16,
                        ),
                        const SizedBox(height: 2),
                        AnymeXText(
                          "Select items to include in your backup",
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnymeXExpansionTile(
                title: "Media Library",
                leading: Icon(Icons.library_books_rounded,
                    color: theme.colorScheme.primary, size: 20),
                initialExpanded: true,
                content: Column(
                  children: [
                    AnymeXTile.checkbox(
                      title: "Anime Library",
                      subtitle: "Watch history, progress & episodes",
                      value: _backupAnime,
                      onChanged: (v) => setState(() => _backupAnime = v),
                    ),
                    AnymeXTile.checkbox(
                      title: "Manga Library",
                      subtitle: "Reading progress & chapter history",
                      value: _backupManga,
                      onChanged: (v) => setState(() => _backupManga = v),
                    ),
                    AnymeXTile.checkbox(
                      title: "Novel Library",
                      subtitle: "Reading bookmarks & chapter history",
                      value: _backupNovel,
                      onChanged: (v) => setState(() => _backupNovel = v),
                    ),
                    AnymeXTile.checkbox(
                      title: "Custom Lists",
                      subtitle: "User-created custom media collections",
                      value: _backupCustomLists,
                      onChanged: (v) => setState(() => _backupCustomLists = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnymeXExpansionTile(
                title:
                    "Settings (${_selectedSettingsCategories.length}/${SettingsCategory.all.length})",
                leading: Icon(Icons.settings_suggest_rounded,
                    color: theme.colorScheme.primary, size: 20),
                initialExpanded: false,
                content: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedSettingsCategories
                                  .addAll(SettingsCategory.all);
                            });
                          },
                          child: const AnymeXText("Select All", size: 12),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedSettingsCategories.clear();
                            });
                          },
                          child: const AnymeXText("Deselect All", size: 12),
                        ),
                      ],
                    ),
                    ...SettingsCategory.all.map((cat) {
                      final isSelected =
                          _selectedSettingsCategories.contains(cat);
                      return AnymeXTile.checkbox(
                        icon: _getCategoryIcon(cat),
                        title: cat,
                        subtitle: _getCategoryDescription(cat),
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v) {
                              _selectedSettingsCategories.add(cat);
                            } else {
                              _selectedSettingsCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnymeXExpansionTile(
                title:
                    "Installed Extensions (${_selectedExtensionIds.length}/${_allInstalledSources.length})",
                leading: Icon(Icons.extension_rounded,
                    color: theme.colorScheme.primary, size: 20),
                initialExpanded: false,
                content: _allInstalledSources.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: AnymeXText("No extensions installed.",
                            variant: TextVariant.regular),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedExtensionIds.addAll(
                                        _allInstalledSources
                                            .map((e) => e.id)
                                            .whereType<String>());
                                  });
                                },
                                child:
                                    const AnymeXText("Select All", size: 12),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedExtensionIds.clear();
                                  });
                                },
                                child:
                                    const AnymeXText("Deselect All", size: 12),
                              ),
                            ],
                          ),
                          ..._allInstalledSources.map((source) {
                            final extId = source.id ?? '';
                            final name = source.name ?? 'Unknown';
                            final lang = (source.lang ?? '').toUpperCase();
                            final iconUrl = source.iconUrl ?? '';
                            final isSelected =
                                _selectedExtensionIds.contains(extId);
                            final manager = sourceTypeName(source);
                            final isPlugin = manager.toLowerCase() ==
                                    'aniyomi' ||
                                manager.toLowerCase() == 'cloudstream' ||
                                manager.toLowerCase() == 'kotatsu';
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    if (extId.isNotEmpty) {
                                      _selectedExtensionIds.add(extId);
                                    }
                                  } else {
                                    _selectedExtensionIds.remove(extId);
                                  }
                                });
                              },
                              secondary: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: iconUrl.isNotEmpty
                                    ? AnymeXImage(
                                        imageUrl: iconUrl,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 36,
                                        height: 36,
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(Icons.extension,
                                            size: 20),
                                      ),
                              ),
                              title: AnymeXText(
                                name,
                                variant: TextVariant.semiBold,
                                size: 14,
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPlugin
                                          ? theme.colorScheme.errorContainer
                                              .opaque(0.6)
                                          : theme.colorScheme.primaryContainer
                                              .opaque(0.6),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: AnymeXText(
                                      manager,
                                      size: 10,
                                      variant: TextVariant.bold,
                                      color: isPlugin
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (lang.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    AnymeXText(
                                      lang,
                                      size: 11,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              AnymeXText(
                "SECURITY",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              AnymeXTile.checkbox(
                title: "Password Protect",
                subtitle: "Add AES encryption to your backup",
                value: _usePassword,
                onChanged: (value) {
                  setState(() {
                    _usePassword = value;
                  });
                },
              ),
              if (_usePassword) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: widget.passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest.opaque(0.3),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    hintText: "Re-enter password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest.opaque(0.3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.opaque(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.opaque(0.5)),
      ),
      child: child,
    );
  }
}
