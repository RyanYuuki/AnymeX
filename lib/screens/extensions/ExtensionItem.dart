// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/logger.dart';
import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartotsu_extension_bridge/Mangayomi/get_source_preference.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
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

  Future<void> sortExtensions() async {
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

    Logger.d('Sorted Extensions for ${widget.mediaType}');
  }

  Future<void> _handleSourceAction() async {
    setState(() => _isLoading = true);
    try {
      await widget.source.extensionType
          ?.getManager()
          .installSource(widget.source);
      await sortExtensions();
    } catch (e) {
      Logger.i(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Source> get _installedExtensions {
    switch (widget.mediaType) {
      case ItemType.manga:
        return sourceController.installedMangaExtensions.value;
      case ItemType.anime:
        return sourceController.installedExtensions.value;
      case ItemType.novel:
        return sourceController.installedNovelExtensions.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final updateAvailable = widget.source.hasUpdate ?? false;
    final sourceNotEmpty =
        _installedExtensions.any((e) => e.id == widget.source.id);

    return AnymexCard(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: (widget.source.extensionType == ExtensionType.mangayomi
                    ? Colors.red
                    : Colors.indigoAccent)
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
                  child: _buildMainIcon(),
                ),
                // Floating badge
                Positioned(
                  top: 1,
                  right: 1,
                  child: NetworkSizedImage(
                    radius: 50,
                    imageUrl: widget.source.extensionType ==
                            ExtensionType.mangayomi
                        ? "https://raw.githubusercontent.com/kodjodevf/mangayomi/main/assets/app_icons/icon-red.png"
                        : 'https://aniyomi.org/img/logo-128px.png',
                    height: 13,
                    width: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          widget.source.name!,
          style: TextStyle(
            color: theme.onSurface,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    completeLanguageName(widget.source.lang!.toLowerCase()),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 10.0,
                      color: theme.primary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.source.version ?? 'Unknown',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 10.0,
                      color: theme.tertiary,
                    ),
                  ),
                ),
                if (widget.source.isNsfw!)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "18+",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            10.width(),
          ],
        ),
        trailing: _isLoading
            ? Container(
                height: 50,
                width: 50,
                padding: const EdgeInsets.all(2),
                child: const Center(
                    child: AnymexProgressIndicator(strokeWidth: 2.0)),
              )
            : _buildButtons(sourceNotEmpty, updateAvailable, theme),
      ),
    );
  }

  Widget _buildMainIcon() {
    return widget.source.iconUrl!.isEmpty
        ? Icon(Icons.extension_rounded,
            color: Theme.of(context).colorScheme.primary)
        : widget.source.iconUrl!.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: widget.source.iconUrl!,
                fit: BoxFit.cover,
                width: 42,
                height: 42,
                placeholder: (context, url) => Icon(
                  Icons.extension_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.extension_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Image.file(
                File(widget.source.iconUrl!),
                fit: BoxFit.cover,
                height: 42,
                width: 42,
              );
  }

  Widget _buildButtons(
      bool sourceNotEmpty, bool updateAvailable, ColorScheme theme) {
    void onTap() async {
      if (updateAvailable) {
        setState(() => _isLoading = true);
        await widget.source.extensionType!
            .getManager()
            .updateSource(widget.source);
        await sortExtensions();
        if (mounted) {
          setState(() => _isLoading = false);
          if (widget.onUpdate != null) widget.onUpdate!();
        }
      } else {
        AlertDialogBuilder(context)
          ..setTitle("Delete Extension")
          ..setMessage("Are you sure you want to delete this extension?")
          ..setPositiveButton("Yes", () async {
            setState(() => _isLoading = true);
            try {
              Logger.i("Uninstalling => ${widget.source.id}");
              await widget.source.extensionType!
                  .getManager()
                  .uninstallSource(widget.source);
              await sortExtensions();
            } catch (e) {
              Logger.i("Uninstall Failed => ${e.toString()}");
            }
            if (mounted) {
              setState(() => _isLoading = false);
            }
          })
          ..setNegativeButton("No", () => Get.back())
          ..show();
      }
    }

    return !sourceNotEmpty
        ? Container(
            decoration: BoxDecoration(
              color: theme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnymexOnTap(
              child: IconButton(
                onPressed: () => _handleSourceAction(),
                icon: Icon(
                  Icons.download,
                  color: theme.onPrimaryContainer,
                  size: 20,
                ),
                tooltip: "Download",
              ),
            ),
          )
        : Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: updateAvailable
                        ? theme.tertiaryContainer
                        : theme.errorContainer.withAlpha(122),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymexOnTap(
                    onTap: onTap,
                    child: IconButton(
                      onPressed: onTap,
                      icon: Icon(
                        size: 18,
                        updateAvailable ? Icons.update : Iconsax.trash,
                        color: updateAvailable
                            ? theme.onTertiaryContainer
                            : theme.onErrorContainer,
                      ),
                      tooltip: updateAvailable ? "Update" : "Delete",
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
                      onPressed: () async {
                        Get.to(() =>
                            SourcePreferenceScreen(source: widget.source));
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
}
