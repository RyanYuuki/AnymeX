library;

import 'dart:io';

import 'package:anymex/controllers/custom_logo/custom_logo_service.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/custom_logo_model.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_segmented_button.dart';
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
              confirmText: 'Choose File',
              isConfirmEnabled: !isDuplicate && !isEmpty,
              contentWidget: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnymeXText(
                    'Give your logo a name:',
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
                        borderSide:
                            const BorderSide(color: Colors.redAccent, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.redAccent, width: 1.5),
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
                        Row(
                          children: [
                            AnymeXSegmentedButton(
                              isSelected: sizeMode ==
                                  CustomLogoSizeMode.defaultSize,
                              title: 'Default',
                              icon: Icons.crop_square,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              onTap: () {
                                setDialogState(() {
                                  sizeMode = CustomLogoSizeMode.defaultSize;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            AnymeXSegmentedButton(
                              isSelected: sizeMode ==
                                  CustomLogoSizeMode.originalSize,
                              title: 'Original',
                              icon: Icons.aspect_ratio,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              onTap: () {
                                setDialogState(() {
                                  sizeMode = CustomLogoSizeMode.originalSize;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            AnymeXSegmentedButton(
                              isSelected: sizeMode ==
                                  CustomLogoSizeMode.customScale,
                              title: 'Custom',
                              icon: Icons.zoom_in,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              onTap: () {
                                setDialogState(() {
                                  sizeMode = CustomLogoSizeMode.customScale;
                                });
                              },
                            ),
                          ],
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
                  const SizedBox(height: 12),
                  AnymeXText(
                    'Supported: .gif, .webp, .png, .jpg (Max: 20 MB)',
                    style: TextStyle(
                      fontSize: 12,
                      color: dialogContext.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              onConfirm: () async {
                final currentName = nameController.text.trim();
                if (currentName.isEmpty ||
                    _customLogos.any((l) =>
                        l.name.trim().toLowerCase() ==
                        currentName.toLowerCase())) {
                  snackBar('A logo with this name already exists.');
                  return;
                }
                try {
                  final newLogo =
                      await CustomLogoService.pickAndSaveCustomLogo(
                    currentName,
                    sizeMode: sizeMode,
                    customScale: customScale,
                  );
                  if (newLogo != null && mounted) {
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth > screenHeight;

    return SizedBox(
      height: screenHeight * 0.5,
      child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
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

  Widget _buildCustomLogoControls(CustomLogo activeCustomLogo) {
    return AnymeXContainer(
      radius: 12,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(12),
      color: context.colors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AnymeXText(
                'Size Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (activeCustomLogo.sizeMode == CustomLogoSizeMode.customScale)
                AnymeXText(
                  '${(activeCustomLogo.customScale * 100).toInt()}% (${(activeCustomLogo.customScale * 200).toInt()}px)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AnymeXSegmentedButton(
                isSelected: activeCustomLogo.sizeMode ==
                    CustomLogoSizeMode.defaultSize,
                title: 'Default',
                icon: Icons.crop_square,
                padding: const EdgeInsets.symmetric(vertical: 8),
                onTap: () {
                  CustomLogoService.setSizeMode(
                      activeCustomLogo.id, CustomLogoSizeMode.defaultSize);
                  setState(() {
                    _customLogos = CustomLogoService.getCustomLogos();
                    _logoKey = UniqueKey();
                  });
                },
              ),
              const SizedBox(width: 8),
              AnymeXSegmentedButton(
                isSelected: activeCustomLogo.sizeMode ==
                    CustomLogoSizeMode.originalSize,
                title: 'Original',
                icon: Icons.aspect_ratio,
                padding: const EdgeInsets.symmetric(vertical: 8),
                onTap: () {
                  CustomLogoService.setSizeMode(
                      activeCustomLogo.id, CustomLogoSizeMode.originalSize);
                  setState(() {
                    _customLogos = CustomLogoService.getCustomLogos();
                    _logoKey = UniqueKey();
                  });
                },
              ),
              const SizedBox(width: 8),
              AnymeXSegmentedButton(
                isSelected: activeCustomLogo.sizeMode ==
                    CustomLogoSizeMode.customScale,
                title: 'Custom',
                icon: Icons.zoom_in,
                padding: const EdgeInsets.symmetric(vertical: 8),
                onTap: () {
                  CustomLogoService.setSizeMode(
                      activeCustomLogo.id, CustomLogoSizeMode.customScale);
                  setState(() {
                    _customLogos = CustomLogoService.getCustomLogos();
                    _logoKey = UniqueKey();
                  });
                },
              ),
            ],
          ),
          if (activeCustomLogo.sizeMode == CustomLogoSizeMode.customScale) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AnymeXSliderM3(
                    value: activeCustomLogo.customScale.clamp(0.5, 3.0),
                    min: 0.5,
                    max: 3.0,
                    divisions: 25,
                    onChanged: (val) {
                      setState(() {
                        CustomLogoService.setCustomScale(
                            activeCustomLogo.id, val);
                        _customLogos = CustomLogoService.getCustomLogos();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 20),
                  tooltip: 'Reset to 100% (200px)',
                  onPressed: () {
                    setState(() {
                      CustomLogoService.setCustomScale(
                          activeCustomLogo.id, 1.0);
                      _customLogos = CustomLogoService.getCustomLogos();
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    final activeCustomPath = _getActiveCustomLogoPath();
    final activeCustomLogo = _getActiveCustomLogo();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            AnymeXContainer(
              height: 180,
              radius: 16,
              clipBehavior: Clip.antiAlias,
              color: context.colors.surfaceContainer,
              child: Center(
                child: _buildPreviewLogo(120, activeCustomPath, activeCustomLogo),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.replay, size: 18),
              label: const AnymeXText('Replay'),
              onPressed: _replayAnimation,
            ),
            if (activeCustomLogo != null)
              _buildCustomLogoControls(activeCustomLogo),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: AnymeXText(
                'Select Animation Style',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        Expanded(
          child: _buildAnimationList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    final activeCustomPath = _getActiveCustomLogoPath();
    final activeCustomLogo = _getActiveCustomLogo();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnymeXContainer(
                    height: 200,
                    radius: 16,
                    clipBehavior: Clip.antiAlias,
                    color: context.colors.surfaceContainer,
                    child: Center(
                      child: _buildPreviewLogo(140, activeCustomPath, activeCustomLogo),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.replay, size: 18),
                    label: const AnymeXText('Replay'),
                    onPressed: _replayAnimation,
                  ),
                  if (activeCustomLogo != null)
                    _buildCustomLogoControls(activeCustomLogo),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnymeXText(
                  'Select Animation Style',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildAnimationList(),
                ),
              ],
            ),
          ),
        ],
      ),
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
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Colors.redAccent),
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
