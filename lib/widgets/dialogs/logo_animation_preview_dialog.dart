library;

import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
  Key _logoKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _selectedAnimation = widget.initialAnimation;
  }

  void _replayAnimation() {
    setState(() {
      _logoKey = UniqueKey();
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AnymeXAnimatedLogo(
                  key: _logoKey,
                  size: 120,
                  autoPlay: true,
                  forceAnimationType: _selectedAnimation,
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
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AnymeXAnimatedLogo(
                      key: _logoKey,
                      size: 140,
                      autoPlay: true,
                      forceAnimationType: _selectedAnimation,
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
      child: AnymeXTileBuilder<LogoAnimationType>(
        items: LogoAnimationType.values,
        selectedItem: _selectedAnimation,
        getTitle: (type) => type.displayName,
        getSubtitle: (type) => type.description,
        onItemPressed: (type) {
          setState(() {
            _selectedAnimation = type;
            _logoKey = UniqueKey();
          });
        },
      ),
    );
  }
}
