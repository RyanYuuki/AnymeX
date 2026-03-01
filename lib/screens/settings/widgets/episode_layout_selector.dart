import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

enum EpisodeListLayoutStyle {
  detailed,
  compact,
  blocks,
}

String episodeLayoutName(int index) {
  if (index < 0 || index >= EpisodeListLayoutStyle.values.length) {
    return 'Detailed';
  }
  return switch (EpisodeListLayoutStyle.values[index]) {
    EpisodeListLayoutStyle.detailed => 'Detailed',
    EpisodeListLayoutStyle.compact => 'Compact',
    EpisodeListLayoutStyle.blocks => 'Blocks',
  };
}

void showEpisodeLayoutSelector(BuildContext context) {
  final selectedIndex = settingsController.episodeListLayout.obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(
        () => AnymexDialog(
          title: 'Episode List Layout',
          padding: const EdgeInsets.all(16),
          onConfirm: () {
            settingsController.episodeListLayout = selectedIndex.value;
          },
          contentWidget: EpisodeLayoutSelector(
            initialIndex: selectedIndex.value,
            onLayoutChanged: (index) {
              selectedIndex.value = index;
            },
          ),
        ),
      );
    },
  );
}

class EpisodeLayoutSelector extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int> onLayoutChanged;

  const EpisodeLayoutSelector({
    super.key,
    required this.initialIndex,
    required this.onLayoutChanged,
  });

  @override
  State<EpisodeLayoutSelector> createState() => _EpisodeLayoutSelectorState();
}

class _EpisodeLayoutSelectorState extends State<EpisodeLayoutSelector> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: SuperListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                EpisodeListLayoutStyle.values.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildStyleChip(index),
                ),
              ),
            ),
          ),
          12.height(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildLayoutPreview(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(int index) {
    final isSelected = _selectedIndex == index;

    return AnymexChip(
      isSelected: isSelected,
      label: episodeLayoutName(index),
      onSelected: (selected) {
        if (!selected) return;
        setState(() {
          _selectedIndex = index;
        });
        widget.onLayoutChanged(index);
      },
    );
  }

  Widget _buildLayoutPreview(int index) {
    final mode = EpisodeListLayoutStyle.values[index];
    return switch (mode) {
      EpisodeListLayoutStyle.detailed => _buildDetailedPreview(),
      EpisodeListLayoutStyle.compact => _buildCompactPreview(),
      EpisodeListLayoutStyle.blocks => _buildBlocksPreview(),
    };
  }

  Widget _buildDetailedPreview() {
    return _buildPreviewShell(
      key: const ValueKey('detailed-preview'),
      title: 'Detailed Preview',
      subtitle: 'Thumbnail, title and synopsis',
      child: Column(
        children: [
          _buildEpisodeCardPreview(showSynopsis: true, highlighted: true),
        ],
      ),
    );
  }

  Widget _buildCompactPreview() {
    return _buildPreviewShell(
      key: const ValueKey('compact-preview'),
      title: 'Compact Preview',
      subtitle: 'Thumbnail and title only',
      child: Column(
        children: [
          _buildEpisodeCardPreview(showSynopsis: false, highlighted: true),
          const SizedBox(height: 10),
          _buildEpisodeCardPreview(showSynopsis: false),
        ],
      ),
    );
  }

  Widget _buildBlocksPreview() {
    return _buildPreviewShell(
      key: const ValueKey('blocks-preview'),
      title: 'Blocks Preview',
      subtitle: '50 compact episode blocks per page',
      child: SizedBox(
        height: 130,
        child: SingleChildScrollView(
          child: _buildBlocksGridPreview(),
        ),
      ),
    );
  }

  Widget _buildPreviewShell({
    required Key key,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.surfaceContainer.opaque(0.75),
            context.colors.surfaceContainerHigh.opaque(0.45),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurface.opaque(0.7),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildEpisodeCardPreview({
    required bool showSynopsis,
    bool highlighted = false,
  }) {
    return Container(
      height: showSynopsis ? 88 : 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.colors.surfaceContainerHighest.opaque(0.45),
        border: Border.all(
          color: highlighted
              ? context.colors.primary.opaque(0.55)
              : context.colors.outline.opaque(0.25),
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  context.colors.primary.opaque(0.35),
                  context.colors.secondary.opaque(0.35),
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.black.opaque(0.25),
                ),
                child: const Text(
                  'EP 12',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 170,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.colors.onSurface.opaque(0.16),
                  ),
                ),
                if (showSynopsis) ...[
                  const SizedBox(height: 9),
                  Container(
                    width: double.infinity,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: context.colors.onSurface.opaque(0.10),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 145,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: context.colors.onSurface.opaque(0.10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlocksGridPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 5;
        const spacing = 6.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            50,
            (index) {
              final isFocused = index == 6;
              return Container(
                width: itemWidth,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.colors.primary.opaque(isFocused ? 0.45 : 0.18),
                  border: Border.all(
                    color:
                        context.colors.primary.opaque(isFocused ? 0.8 : 0.35),
                    width: isFocused ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: context.colors.onSurface,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
