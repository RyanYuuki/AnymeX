// ignore_for_file: invalid_use_of_protected_member

import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ExtensionListTileWidget extends StatefulWidget {
  final Source source;
  final ItemType mediaType;
  final VoidCallback? onUpdate;

  const ExtensionListTileWidget({
    super.key,
    required this.source,
    required this.mediaType,
    this.onUpdate,
  });

  @override
  State<ExtensionListTileWidget> createState() =>
      _ExtensionListTileWidgetState();
}

class _ExtensionListTileWidgetState extends State<ExtensionListTileWidget> {
  bool _isLoading = false;

  Future<void> _sortExtensions() async {
    switch (widget.mediaType) {
      case ItemType.manga:
        await sourceController.sortMangaExtensions();
        break;
      case ItemType.anime:
        await sourceController.sortAnimeExtensions();
        break;
      case ItemType.novel:
        await sourceController.sortNovelExtensions();
        break;
    }
  }

  Future<void> _handleInstall() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      await widget.source.extensionType
          ?.getManager()
          .installSource(widget.source);
      await _sortExtensions();
      widget.onUpdate?.call();
    } catch (e) {
      Logger.i(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleUpdate() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      await widget.source.extensionType!
          .getManager()
          .updateSource(widget.source);
      await _sortExtensions();
      widget.onUpdate?.call();
    } catch (e) {
      Logger.i(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleUninstall() async {
    _setLoading(true);
    try {
      Logger.i("Uninstalling => ${widget.source.id}");
      await widget.source.extensionType!
          .getManager()
          .uninstallSource(widget.source);
      await _sortExtensions();
      widget.onUpdate?.call();
    } catch (e) {
      Logger.i("Uninstall Failed => ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  bool get _isInstalled {
    final list = switch (widget.mediaType) {
      ItemType.manga => sourceController.installedMangaExtensions,
      ItemType.anime => sourceController.installedExtensions,
      ItemType.novel => sourceController.installedNovelExtensions,
    };
    return list.any((e) => e.id == widget.source.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final updateAvailable = widget.source.hasUpdate ?? false;

    // Use Obx only for the installed check that depends on reactive lists
    return Obx(() {
      final isInstalled = _isInstalled;

      return AnymexCard(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _ExtensionIcon(source: widget.source, theme: theme),
          title: Text(
            widget.source.name!,
            style: TextStyle(
              color: theme.onSurface,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          subtitle: _ExtensionSubtitle(source: widget.source, theme: theme),
          trailing: _isLoading
              ? const SizedBox(
                  height: 50,
                  width: 50,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: AnymexProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                )
              : _buildTrailing(isInstalled, updateAvailable, theme),
        ),
      );
    });
  }

  Widget _buildTrailing(
      bool isInstalled, bool updateAvailable, ColorScheme theme) {
    if (!isInstalled) {
      return Container(
        decoration: BoxDecoration(
          color: theme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnymexOnTap(
          child: IconButton(
            onPressed: _handleInstall,
            icon: Icon(
              Icons.download,
              color: theme.onPrimaryContainer,
              size: 20,
            ),
            tooltip: "Download",
          ),
        ),
      );
    }

    return SizedBox(
      width: updateAvailable ? 150 : 100, // Adjusted width to accommodate extra button
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (updateAvailable) ...[
            Container(
              decoration: BoxDecoration(
                color: theme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnymexOnTap(
                onTap: _handleUpdate,
                child: IconButton(
                  onPressed: _handleUpdate,
                  icon: Icon(
                    Icons.update,
                    size: 18,
                    color: theme.onTertiaryContainer,
                  ),
                  tooltip: "Update",
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: theme.errorContainer.withAlpha(122),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnymexOnTap(
              onTap: () => _onActionTap(false), // Pass false to trigger delete logic
              child: IconButton(
                onPressed: () => _onActionTap(false),
                icon: Icon(
                  Iconsax.trash,
                  size: 18,
                  color: theme.onErrorContainer,
                ),
                tooltip: "Delete",
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnymexOnTap(
              child: IconButton(
                onPressed: () {
                  Get.to(() => SourcePreferenceScreen(source: widget.source));
                },
                icon: Icon(
                  Iconsax.setting,
                  size: 18,
                  color: theme.onSecondaryContainer,
                ),
                tooltip: "Settings",
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onActionTap(bool updateAvailable) {
    if (_isLoading) return;

    if (updateAvailable) {
      _handleUpdate();
    } else {
      AlertDialogBuilder(context)
        ..setTitle("Delete Extension")
        ..setMessage("Are you sure you want to delete this extension?")
        ..setPositiveButton("Yes", _handleUninstall)
        ..setNegativeButton("No", () {})
        ..show();
    }
  }
}

/// Extracted stateless icon widget to avoid rebuilds
class _ExtensionIcon extends StatelessWidget {
  final Source source;
  final ColorScheme theme;

  const _ExtensionIcon({required this.source, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isMangayomi = source.extensionType == ExtensionType.mangayomi;

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: (isMangayomi ? Colors.red : Colors.indigoAccent)
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildMainIcon(context),
            ),
            Positioned(
              top: 1,
              right: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  isMangayomi
                      ? "https://raw.githubusercontent.com/kodjodevf/mangayomi/main/assets/app_icons/icon-red.png"
                      : 'https://aniyomi.org/img/logo-128px.png',
                  height: 13,
                  width: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainIcon(BuildContext context) {
    final iconUrl = source.iconUrl ?? '';
    if (iconUrl.isEmpty) {
      return Icon(Icons.extension_rounded, color: context.colors.primary);
    }
    if (iconUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: iconUrl,
        fit: BoxFit.cover,
        width: 42,
        height: 42,
        placeholder: (context, url) =>
            Icon(Icons.extension_rounded, color: context.colors.primary),
        errorWidget: (context, url, error) =>
            Icon(Icons.extension_rounded, color: context.colors.primary),
      );
    }
    return Image.file(
      File(iconUrl),
      fit: BoxFit.cover,
      height: 42,
      width: 42,
    );
  }
}

/// Extracted stateless subtitle widget
class _ExtensionSubtitle extends StatelessWidget {
  final Source source;
  final ColorScheme theme;

  const _ExtensionSubtitle({required this.source, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: [
            _buildChip(
              completeLanguageName(source.lang?.toLowerCase() ?? ''),
              theme.primary,
            ),
            _buildChip(
              source.version ?? 'Unknown',
              theme.tertiary,
            ),
            if (source.isNsfw == true) _buildChip("18+", Colors.red),
          ],
        ),
        10.width(),
      ],
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.opaque(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 10.0,
          color: color,
        ),
      ),
    );
  }
}
