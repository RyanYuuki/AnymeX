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
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
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

  void _showAddCustomLogoDialog() {
    final nameController = TextEditingController(text: 'My Animated Logo');
    AnymeXDialog(
      title: 'Add Custom Logo',
      confirmText: 'Choose File',
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
            decoration: InputDecoration(
              hintText: 'e.g. My Anime Logo',
              filled: true,
              fillColor: context.colors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          AnymeXText(
            'Supported: .gif, .webp, .png, .jpg (Max: 20 MB)',
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onConfirm: () async {
        Navigator.pop(context);
        try {
          final newLogo = await CustomLogoService.pickAndSaveCustomLogo(
            nameController.text,
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
    ).show(context);
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

  Widget _buildPortraitLayout() {
    final activeCustomPath = _getActiveCustomLogoPath();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            AnymeXContainer(
              height: 180,
              radius: 16,
              color: context.colors.surfaceContainer,
              child: Center(
                child: AnymeXAnimatedLogo(
                  key: _logoKey,
                  size: 120,
                  autoPlay: true,
                  forceCustomLogoPath: activeCustomPath,
                  forceAnimationType:
                      activeCustomPath == null ? _selectedAnimation : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.replay, size: 18),
              label: const AnymeXText('Replay'),
              onPressed: _replayAnimation,
            ),
            const SizedBox(height: 16),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnymeXContainer(
                  height: 200,
                  radius: 16,
                  color: context.colors.surfaceContainer,
                  child: Center(
                    child: AnymeXAnimatedLogo(
                      key: _logoKey,
                      size: 140,
                      autoPlay: true,
                      forceCustomLogoPath: activeCustomPath,
                      forceAnimationType:
                          activeCustomPath == null ? _selectedAnimation : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.replay, size: 18),
                  label: const AnymeXText('Replay'),
                  onPressed: _replayAnimation,
                ),
              ],
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
                  subtitle: AnymeXText(
                    '${logo.formattedSize} • Tap to apply',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceVariant,
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
