// ignore_for_file: invalid_use_of_protected_member

import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/Services/CloudStream/CloudStreamSourceMethods.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
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

  Future<void> _handleInstall() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      await widget.source.install();
      await sourceController.refreshSourceState(widget.source);
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
      final manager = getSourceManager(widget.source);
      await manager.updateSource(widget.source);
      await sourceController.refreshSourceState(widget.source);
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
      await widget.source.uninstall();
      await sourceController.refreshSourceState(widget.source);
      widget.onUpdate?.call();
    } catch (e) {
      Logger.i("Uninstall Failed => ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  Future<void> _handleOpenSettings() async {
    final source = widget.source;
    if (source is CloudStreamSource && source.hasSettings) {
      await CloudStreamSourceMethods(source).openNativeSettings();
    } else {
      Get.to(() => SourcePreferenceScreen(source: source));
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

    Widget buildMainIcon() {
      final iconUrl = widget.source.iconUrl ?? '';
      if (iconUrl.isEmpty) {
        return Container(
          height: 50,
          width: 50,
          alignment: Alignment.center,
          child: Icon(Icons.extension_rounded, color: theme.primary, size: 24),
        );
      }
      if (iconUrl.startsWith('http')) {
        return AnymeXImage(
          imageUrl: iconUrl,
          fit: BoxFit.cover,
          width: 50,
          height: 50,
          radius: 0,
        );
      }
      return Image.file(
        File(iconUrl),
        fit: BoxFit.cover,
        height: 50,
        width: 50,
      );
    }

    Widget buildManagerBadge() {
      final badgeUrl = widget.source.managerIcon;

      return Container(
        height: 19,
        width: 19,
        decoration: BoxDecoration(
          color: theme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: AnymeXImage(
            imageUrl: badgeUrl,
            height: 13,
            width: 13,
            radius: 0,
          ),
        ),
      );
    }

    final version =
        (widget.source.version ?? 'Unknown').toLowerCase().startsWith('v')
            ? (widget.source.version ?? 'Unknown')
            : 'v${widget.source.version ?? 'Unknown'}';

    return Obx(() {
      final isInstalled = _isInstalled;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: theme.surfaceContainerHighest.withOpacity(0.55),
                        child: buildMainIcon(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: buildManagerBadge(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.source.name!,
                    style: TextStyle(
                      color: theme.onSurface,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.secondary,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(5),
                              ),
                            ),
                            child: Text(
                              completeLanguageName(
                                      widget.source.lang?.toLowerCase() ?? '')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Poppins-SemiBold',
                                fontSize: 10.0,
                                color: theme.secondary.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.tertiary,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(5),
                                right: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              version.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Poppins-SemiBold',
                                fontSize: 10.0,
                                color: theme.tertiary.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.source.isNsfw == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '18+',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 10.0,
                              color: theme.error.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _isLoading
                ? const SizedBox(
                    height: 40,
                    width: 40,
                    child: Center(
                      child: AnymexProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                : _buildTrailing(isInstalled, updateAvailable, theme),
          ],
        ),
      );
    });
  }

  Widget _buildTrailing(
      bool isInstalled, bool updateAvailable, ColorScheme theme) {
    if (!isInstalled) {
      return _actionButton(
        icon: Icons.download_rounded,
        color: theme.primary,
        tooltip: "Download",
        onTap: _handleInstall,
        borderRadius: BorderRadius.circular(30),
      );
    }

    if (updateAvailable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(
            icon: Icons.refresh_rounded,
            color: theme.tertiary,
            tooltip: "Update",
            onTap: _handleUpdate,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
              right: Radius.circular(8),
            ),
          ),
          const SizedBox(width: 2),
          _actionButton(
            icon: Iconsax.trash,
            color: theme.error,
            tooltip: "Delete",
            iconSize: 17,
            onTap: () => _onActionTap(false),
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(width: 2),
          _actionButton(
            icon: Iconsax.setting,
            color: theme.secondary,
            tooltip: "Settings",
            iconSize: 17,
            onTap: _handleOpenSettings,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
              right: Radius.circular(20),
            ),
          ),
        ],
      );
    }

    final hasSettings =
        (widget.source is CloudStreamSource && Platform.isAndroid) || widget.source is CloudStreamSource == false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          icon: Iconsax.trash,
          color: theme.error,
          tooltip: "Delete",
          iconSize: 17,
          onTap: () => _onActionTap(false),
          borderRadius: BorderRadius.horizontal(
            left: const Radius.circular(16),
            right: Radius.circular(hasSettings ? 5 : 16),
          ),
        ),
        if (hasSettings) ...[
          const SizedBox(width: 2),
          _actionButton(
            icon: Iconsax.setting,
            color: theme.secondary,
            tooltip: "Settings",
            iconSize: 17,
            onTap: _handleOpenSettings,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(5),
              right: Radius.circular(16),
            ),
          ),
        ],
      ],
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

Widget _actionButton({
  required IconData icon,
  required Color color,
  required String tooltip,
  required VoidCallback onTap,
  double iconSize = 19,
  required BorderRadius borderRadius,
}) {
  return Tooltip(
    message: tooltip,
    child: Material(
      color: color.withValues(alpha: 0.7),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: SizedBox(
          height: 38,
          width: 38,
          child: Icon(icon, size: iconSize, color: Colors.black),
        ),
      ),
    ),
  );
}
