library;

import 'dart:io';

import 'package:anymex/controllers/custom_logo/custom_logo_service.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/custom_logo_model.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';

class LogoAnimationPreviewDialog extends StatefulWidget {
  final LogoAnimationType initialAnimation;
  final Function(LogoAnimationType) onConfirm;

  const LogoAnimationPreviewDialog({
    super.key,
    required this.initialAnimation,
    required this.onConfirm,
  });

  @override
  State<LogoAnimationPreviewDialog> createState() =>
      _LogoAnimationPreviewDialogState();
}

class _LogoAnimationPreviewDialogState
    extends State<LogoAnimationPreviewDialog> {
  late LogoAnimationType _selectedAnimation;
  String? _selectedCustomLogoId;
  List<CustomLogo> _customLogos = [];
  Key _logoKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _selectedAnimation = widget.initialAnimation;
    _selectedCustomLogoId = CustomLogoService.getSelectedCustomLogoId();
    _customLogos = CustomLogoService.getCustomLogos();
  }

  void _replayAnimation() {
    setState(() {
      _logoKey = UniqueKey();
    });
  }

  String? _getActiveCustomLogoPath() {
    if (_selectedCustomLogoId == null || _selectedCustomLogoId!.isEmpty) {
      return null;
    }
    try {
      final match = _customLogos.firstWhere(
        (l) => l.id == _selectedCustomLogoId,
      );
      if (File(match.filePath).existsSync()) {
        return match.filePath;
      }
    } catch (_) {}
    return null;
  }

  CustomLogo? _getActiveCustomLogo() {
    if (_selectedCustomLogoId == null || _selectedCustomLogoId!.isEmpty) {
      return null;
    }
    try {
      return _customLogos.firstWhere(
        (l) => l.id == _selectedCustomLogoId,
      );
    } catch (_) {}
    return null;
  }

  String _getNextDefaultLogoName() {
    final existingNames =
        _customLogos.map((l) => l.name.trim().toLowerCase()).toSet();
    if (!existingNames.contains('my animated logo')) {
      return 'My Animated Logo';
    }
    int index = 1;
    while (existingNames.contains('my animated logo $index')) {
      index++;
    }
    return 'My Animated Logo $index';
  }

  void _showAddCustomLogoDialog() {
    final defaultName = _getNextDefaultLogoName();
    final nameController = TextEditingController(text: defaultName);
    CustomLogoSizeMode sizeMode = CustomLogoSizeMode.defaultSize;
    double customScale = 1.0;
    PlatformFile? selectedFile;
    bool isPicking = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final trimmedName = nameController.text.trim();
            final isEmpty = trimmedName.isEmpty;
            final isDuplicate = _customLogos.any(
              (l) => l.name.trim().toLowerCase() == trimmedName.toLowerCase(),
            );
            final String? errorText = isDuplicate
                ? 'A logo with this name already exists'
                : (isEmpty ? 'Name cannot be empty' : null);

            return AnymeXDialog(
              title: 'Add Custom Logo',
              confirmText: 'Save Logo',
              isConfirmEnabled: selectedFile != null && !isDuplicate && !isEmpty,
              contentWidget: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedFile == null)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isPicking
                            ? null
                            : () async {
                                setDialogState(() => isPicking = true);
                                try {
                                  final file =
                                      await CustomLogoService.pickLogoFile();
                                  if (file != null) {
                                    setDialogState(() => selectedFile = file);
                                  }
                                } catch (e) {
                                  snackBar(e
                                      .toString()
                                      .replaceAll('Exception: ', ''));
                                } finally {
                                  setDialogState(() => isPicking = false);
                                }
                              },
                        child: AnymeXContainer(
                          radius: 12,
                          color: dialogContext.colors.surfaceContainer,
                          padding: const EdgeInsets.symmetric(
                              vertical: 22, horizontal: 16),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPicking
                                      ? Icons.hourglass_top_rounded
                                      : Icons.cloud_upload_outlined,
                                  size: 36,
                                  color: dialogContext.colors.primary,
                                ),
                                const SizedBox(height: 8),
                                AnymeXText(
                                  isPicking
                                      ? 'Opening file picker...'
                                      : 'Tap to Choose Logo File',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnymeXText(
                                  'PNG, JPG, WEBP, GIF (Max 20MB)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        dialogContext.colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      AnymeXContainer(
                        radius: 12,
                        color: dialogContext.colors.surfaceContainer,
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: dialogContext
                                    .colors.surfaceContainerHighest,
                                child: selectedFile!.path != null &&
                                        !selectedFile!.path!
                                            .toLowerCase()
                                            .endsWith('.gif')
                                    ? Image.file(
                                        File(selectedFile!.path!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.image_outlined,
                                          color: dialogContext.colors.primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.image_outlined,
                                        color: dialogContext.colors.primary,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnymeXText(
                                    selectedFile!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  AnymeXText(
                                    '${(selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: dialogContext
                                          .colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Change File',
                              icon: Icon(
                                Icons.sync_rounded,
                                size: 20,
                                color: dialogContext.colors.primary,
                              ),
                              onPressed: isPicking
                                  ? null
                                  : () async {
                                      setDialogState(() => isPicking = true);
                                      try {
                                        final file = await CustomLogoService
                                            .pickLogoFile();
                                        if (file != null) {
                                          setDialogState(
                                              () => selectedFile = file);
                                        }
                                      } catch (e) {
                                        snackBar(e
                                            .toString()
                                            .replaceAll('Exception: ', ''));
                                      } finally {
                                        setDialogState(
                                            () => isPicking = false);
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    const AnymeXText(
                      'Logo Name:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. My Anime Logo',
                        errorText: errorText,
                        filled: true,
                        fillColor: dialogContext.colors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnymeXContainer(
                      radius: 10,
                      color: dialogContext.colors.surfaceContainer,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AnymeXText(
                            'Size Mode:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildVerticalModeSelector(
                            context: dialogContext,
                            currentMode: sizeMode,
                            customScale: customScale,
                            onModeChanged: (newMode) {
                              setDialogState(() {
                                sizeMode = newMode;
                              });
                            },
                          ),
                          if (sizeMode == CustomLogoSizeMode.customScale) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const AnymeXText(
                                  'Scale Factor',
                                  style: TextStyle(fontSize: 12),
                                ),
                                AnymeXText(
                                  '${(customScale * 100).toInt()}% (${(customScale * 200).toInt()}px)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: dialogContext.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            AnymeXSliderM3(
                              value: customScale.clamp(0.5, 3.0),
                              min: 0.5,
                              max: 3.0,
                              divisions: 25,
                              onChanged: (val) {
                                setDialogState(() {
                                  customScale = val;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              onConfirm: () async {
                if (selectedFile == null) {
                  snackBar('Please choose a logo file.');
                  return;
                }
                final currentName = nameController.text.trim();
                if (currentName.isEmpty ||
                    _customLogos.any((l) =>
                        l.name.trim().toLowerCase() ==
                        currentName.toLowerCase())) {
                  snackBar('A logo with this name already exists.');
                  return;
                }
                try {
                  final newLogo = await CustomLogoService.savePickedLogoFile(
                    file: selectedFile!,
                    name: currentName,
                    sizeMode: sizeMode,
                    customScale: customScale,
                  );
                  if (mounted) {
                    setState(() {
                      _customLogos = CustomLogoService.getCustomLogos();
                      _selectedCustomLogoId = newLogo.id;
                      _logoKey = UniqueKey();
                    });
                    snackBar('Added "${newLogo.name}" successfully!');
                  }
                } catch (e) {
                  snackBar(e.toString().replaceAll('Exception: ', ''));
                }
              },
            );
          },
        );
      },
    );
  }

  void _showEditCustomLogoDialog(CustomLogo logo) {
    final nameController = TextEditingController(text: logo.name);
    CustomLogoSizeMode sizeMode = logo.sizeMode;
    double customScale = logo.customScale;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final trimmedName = nameController.text.trim();
            final isEmpty = trimmedName.isEmpty;
            final isDuplicate = _customLogos.any(
              (l) =>
                  l.id != logo.id &&
                  l.name.trim().toLowerCase() == trimmedName.toLowerCase(),
            );
            final String? errorText = isDuplicate
                ? 'A logo with this name already exists'
                : (isEmpty ? 'Name cannot be empty' : null);

            return AnymeXDialog(
              title: 'Edit Logo Settings',
              confirmText: 'Save Changes',
              isConfirmEnabled: !isDuplicate && !isEmpty,
              contentWidget: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXContainer(
                      radius: 12,
                      color: dialogContext.colors.surfaceContainer,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: dialogContext
                                  .colors.surfaceContainerHighest,
                              child: File(logo.filePath).existsSync() &&
                                      !logo.filePath
                                          .toLowerCase()
                                          .endsWith('.gif')
                                  ? Image.file(
                                      File(logo.filePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.image_outlined,
                                        color: dialogContext.colors.primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.image_outlined,
                                      color: dialogContext.colors.primary,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnymeXText(
                                  logo.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                AnymeXText(
                                  logo.formattedSize,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: dialogContext
                                        .colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AnymeXText(
                      'Logo Name:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. My Anime Logo',
                        errorText: errorText,
                        filled: true,
                        fillColor: dialogContext.colors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnymeXContainer(
                      radius: 10,
                      color: dialogContext.colors.surfaceContainer,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AnymeXText(
                            'Size Mode:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildVerticalModeSelector(
                            context: dialogContext,
                            currentMode: sizeMode,
                            customScale: customScale,
                            onModeChanged: (newMode) {
                              setDialogState(() {
                                sizeMode = newMode;
                              });
                            },
                          ),
                          if (sizeMode == CustomLogoSizeMode.customScale) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const AnymeXText(
                                  'Scale Factor',
                                  style: TextStyle(fontSize: 12),
                                ),
                                AnymeXText(
                                  '${(customScale * 100).toInt()}% (${(customScale * 200).toInt()}px)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: dialogContext.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            AnymeXSliderM3(
                              value: customScale.clamp(0.5, 3.0),
                              min: 0.5,
                              max: 3.0,
                              divisions: 25,
                              onChanged: (val) {
                                setDialogState(() {
                                  customScale = val;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              onConfirm: () async {
                final currentName = nameController.text.trim();
                if (currentName.isEmpty ||
                    _customLogos.any((l) =>
                        l.id != logo.id &&
                        l.name.trim().toLowerCase() ==
                            currentName.toLowerCase())) {
                  snackBar('A logo with this name already exists.');
                  return;
                }
                try {
                  final updated = await CustomLogoService.updateCustomLogo(
                    logo.id,
                    name: currentName,
                    sizeMode: sizeMode,
                    customScale: customScale,
                  );
                  if (updated != null && mounted) {
                    setState(() {
                      _customLogos = CustomLogoService.getCustomLogos();
                      _logoKey = UniqueKey();
                    });
                    snackBar('Updated "${updated.name}" successfully!');
                  }
                } catch (e) {
                  snackBar(e.toString().replaceAll('Exception: ', ''));
                }
              },
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCustomLogo(CustomLogo logo) {
    AnymeXDialog(
      title: 'Delete Custom Logo',
      message: 'Are you sure you want to delete "${logo.name}"?',
      confirmText: 'Delete',
      onConfirm: () async {
        await CustomLogoService.deleteCustomLogo(logo.id);
        if (mounted) {
          setState(() {
            _customLogos = CustomLogoService.getCustomLogos();
            if (_selectedCustomLogoId == logo.id) {
              _selectedCustomLogoId = '';
            }
            _logoKey = UniqueKey();
          });
          snackBar('Deleted "${logo.name}"');
        }
      },
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: (screenHeight * 0.65).clamp(440.0, 620.0),
      child: _buildLayout(),
    );
  }

  Widget _buildPreviewLogo(
      double size, String? activeCustomPath, CustomLogo? activeCustomLogo) {
    final isOriginal =
        activeCustomLogo?.sizeMode == CustomLogoSizeMode.originalSize;
    final isCustomScale =
        activeCustomLogo?.sizeMode == CustomLogoSizeMode.customScale;
    final customScale = activeCustomLogo?.customScale ?? 1.0;

    Widget logo = AnymeXAnimatedLogo(
      key: _logoKey,
      size: size,
      useOriginalSize: isOriginal ? true : null,
      autoPlay: true,
      forceCustomLogoPath: activeCustomPath,
      forceAnimationType:
          activeCustomPath == null ? _selectedAnimation : null,
    );

    if (isCustomScale) {
      logo = Transform.scale(
        scale: customScale,
        alignment: Alignment.center,
        child: logo,
      );
    }

    return logo;
  }

  Widget _buildVerticalModeSelector({
    required BuildContext context,
    required CustomLogoSizeMode currentMode,
    required double customScale,
    required ValueChanged<CustomLogoSizeMode> onModeChanged,
  }) {
    return Column(
      children: [
        _buildVerticalModeOption(
          context: context,
          title: 'Default Size',
          subtitle: 'Standard responsive fit (200px)',
          icon: Icons.crop_square_rounded,
          isSelected: currentMode == CustomLogoSizeMode.defaultSize,
          onTap: () => onModeChanged(CustomLogoSizeMode.defaultSize),
        ),
        const SizedBox(height: 6),
        _buildVerticalModeOption(
          context: context,
          title: 'Original Size',
          subtitle: 'Native unscaled dimensions',
          icon: Icons.aspect_ratio_rounded,
          isSelected: currentMode == CustomLogoSizeMode.originalSize,
          onTap: () => onModeChanged(CustomLogoSizeMode.originalSize),
        ),
        const SizedBox(height: 6),
        _buildVerticalModeOption(
          context: context,
          title: 'Custom Scale',
          subtitle: 'Manual scale (${(customScale * 100).toInt()}%)',
          icon: Icons.zoom_in_rounded,
          isSelected: currentMode == CustomLogoSizeMode.customScale,
          onTap: () => onModeChanged(CustomLogoSizeMode.customScale),
        ),
      ],
    );
  }

  Widget _buildVerticalModeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withOpacity(0.12)
              : colors.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? colors.primary : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  AnymeXText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colors.primary
                  : colors.onSurfaceVariant.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedModeBar({
    required BuildContext context,
    required CustomLogoSizeMode currentMode,
    required double customScale,
    required ValueChanged<CustomLogoSizeMode> onModeChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentItem(
              context: context,
              title: 'Default',
              isSelected: currentMode == CustomLogoSizeMode.defaultSize,
              onTap: () => onModeChanged(CustomLogoSizeMode.defaultSize),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentItem(
              context: context,
              title: 'Original',
              isSelected: currentMode == CustomLogoSizeMode.originalSize,
              onTap: () => onModeChanged(CustomLogoSizeMode.originalSize),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentItem(
              context: context,
              title: currentMode == CustomLogoSizeMode.customScale
                  ? 'Custom (${(customScale * 100).toInt()}%)'
                  : 'Custom',
              isSelected: currentMode == CustomLogoSizeMode.customScale,
              onTap: () => onModeChanged(CustomLogoSizeMode.customScale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: AnymeXText(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? context.colors.onPrimary
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout() {
    final activeCustomPath = _getActiveCustomLogoPath();
    final activeCustomLogo = _getActiveCustomLogo();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnymeXContainer(
          height: 160,
          radius: 16,
          clipBehavior: Clip.antiAlias,
          color: context.colors.surfaceContainer,
          child: Center(
            child: _buildPreviewLogo(120, activeCustomPath, activeCustomLogo),
          ),
        ),
        const SizedBox(height: 8),
        if (activeCustomLogo != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildSegmentedModeBar(
              context: context,
              currentMode: activeCustomLogo.sizeMode,
              customScale: activeCustomLogo.customScale,
              onModeChanged: (newMode) {
                CustomLogoService.setSizeMode(activeCustomLogo.id, newMode);
                setState(() {
                  _customLogos = CustomLogoService.getCustomLogos();
                  _logoKey = UniqueKey();
                });
              },
            ),
          ),
          const SizedBox(height: 6),
        ],
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.replay_rounded, size: 16),
            label: const AnymeXText('Replay',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            onPressed: _replayAnimation,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _buildAnimationList(),
        ),
      ],
    );
  }

  Widget _buildAnimationList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Custom Logo Button
          AnymeXContainer(
            radius: 12,
            color: context.colors.primary.withOpacity(0.12),
            border: Border.all(
              color: context.colors.primary.withOpacity(0.35),
              width: 1.5,
            ),
            child: InkWell(
              onTap: _showAddCustomLogoDialog,
              borderRadius: BorderRadius.circular(12.multiplyRadius()),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        color: context.colors.primary, size: 20),
                    const SizedBox(width: 8),
                    AnymeXText(
                      'Add Custom Logo (.gif, .webp)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_customLogos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const AnymeXText(
              'Custom Logos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...List.generate(_customLogos.length, (index) {
              final logo = _customLogos[index];
              final isSelected = _selectedCustomLogoId == logo.id;
              return AnymeXContainer(
                radius: 12,
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected
                    ? context.colors.primary.withOpacity(0.15)
                    : context.colors.surfaceContainer,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.file(
                        File(logo.filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                    ),
                  ),
                  title: AnymeXText(
                    logo.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        AnymeXText(
                          '${logo.formattedSize} • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: logo.sizeMode !=
                                    CustomLogoSizeMode.defaultSize
                                ? context.colors.primary.withOpacity(0.2)
                                : context.colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                logo.sizeMode ==
                                        CustomLogoSizeMode.originalSize
                                    ? Icons.aspect_ratio
                                    : (logo.sizeMode ==
                                            CustomLogoSizeMode.customScale
                                        ? Icons.zoom_in
                                        : Icons.crop_square),
                                size: 11,
                                color: logo.sizeMode !=
                                        CustomLogoSizeMode.defaultSize
                                    ? context.colors.primary
                                    : context.colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              AnymeXText(
                                logo.sizeMode ==
                                        CustomLogoSizeMode.originalSize
                                    ? 'Original'
                                    : (logo.sizeMode ==
                                            CustomLogoSizeMode.customScale
                                        ? 'Custom (${(logo.customScale * 100).toInt()}%)'
                                        : 'Default'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: logo.sizeMode !=
                                          CustomLogoSizeMode.defaultSize
                                      ? context.colors.primary
                                      : context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_circle_rounded,
                              color: context.colors.primary, size: 20),
                        ),
                      IconButton(
                        icon: Icon(Icons.tune_rounded,
                            size: 20, color: context.colors.primary),
                        tooltip: 'Edit Logo Settings',
                        onPressed: () => _showEditCustomLogoDialog(logo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Colors.redAccent),
                        tooltip: 'Delete Logo',
                        onPressed: () => _confirmDeleteCustomLogo(logo),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCustomLogoId = logo.id;
                      _logoKey = UniqueKey();
                    });
                    CustomLogoService.selectCustomLogo(logo.id);
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const AnymeXText(
              'Built-in Styles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
          AnymeXTileBuilder<LogoAnimationType>(
            items: LogoAnimationType.values,
            selectedItem: (_selectedCustomLogoId == null ||
                    _selectedCustomLogoId!.isEmpty)
                ? _selectedAnimation
                : null,
            getTitle: (type) => type.displayName,
            getSubtitle: (type) => type.description,
            onItemPressed: (type) {
              setState(() {
                _selectedAnimation = type;
                _selectedCustomLogoId = '';
                _logoKey = UniqueKey();
              });
              CustomLogoService.clearCustomLogoSelection();
              widget.onConfirm(type);
            },
          ),
        ],
      ),
    );
  }
}
