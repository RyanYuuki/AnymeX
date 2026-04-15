import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/screens/downloads/widgets/download_server_selector.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

String _episodeKey(Episode ep) {
  final sortPart = ep.sortMap.isNotEmpty
      ? '_${ep.sortMap.entries.map((e) => '${e.key}:${e.value}').join('|')}'
      : '';
  return '${ep.link ?? ep.number}$sortPart';
}

class DownloadEpisodeSelector extends StatefulWidget {
  final List<Episode> episodes;
  final Source source;
  final OfflineMedia media;

  const DownloadEpisodeSelector({
    super.key,
    required this.episodes,
    required this.source,
    required this.media,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Episode> episodes,
    required Source source,
    required OfflineMedia media,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DownloadEpisodeSelector(
        episodes: episodes,
        source: source,
        media: media,
      ),
    );
  }

  @override
  State<DownloadEpisodeSelector> createState() =>
      _DownloadEpisodeSelectorState();
}

class _DownloadEpisodeSelectorState extends State<DownloadEpisodeSelector> {
  final _selectedKeys = <String>{};

  List<Episode> get _sorted {
    final list = [...widget.episodes];
    list.sort((a, b) {
      final sa = int.tryParse(a.sortMap['season'] ?? '0') ?? 0;
      final sb = int.tryParse(b.sortMap['season'] ?? '0') ?? 0;
      if (sa != sb) return sa.compareTo(sb);
      return (double.tryParse(a.number) ?? 0)
          .compareTo(double.tryParse(b.number) ?? 0);
    });
    return list;
  }

  List<Episode> get _selectedEpisodes =>
      _sorted.where((ep) => _selectedKeys.contains(_episodeKey(ep))).toList();

  void _selectAll() {
    setState(() => _selectedKeys.addAll(_sorted.map(_episodeKey)));
  }

  void _deselectAll() {
    setState(() => _selectedKeys.clear());
  }

  void _selectFirstN(int n) {
    setState(() {
      _selectedKeys.clear();
      _selectedKeys.addAll(_sorted.take(n).map(_episodeKey));
    });
  }

  bool _isFirstNSelected(int n) {
    final expected = _sorted.take(n).map(_episodeKey).toSet();
    return expected.isNotEmpty && expected.every(_selectedKeys.contains);
  }

  Future<void> _proceed() async {
    if (_selectedEpisodes.isEmpty) return;
    Navigator.pop(context);
    await DownloadServerSelector.show(
      context,
      episodes: _selectedEpisodes,
      source: widget.source,
      media: widget.media,
    );
  }

  Map<String, List<Episode>> _groupBySeason() {
    final groups = <String, List<Episode>>{};
    for (final ep in _sorted) {
      final season =
          ep.sortMap['season'] ?? ep.sortMap.values.firstOrNull ?? '';
      final key = season.isEmpty ? '__default__' : season;
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(ep);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final groups = _groupBySeason();
    final hasMultipleGroups =
        groups.length > 1 || !groups.containsKey('__default__');

    return Container(
      height: MediaQuery.of(context).size.height * 0.87,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(theme),
          _buildHeader(theme),
          _buildQuickPicker(theme),
          _buildSelectionBar(theme),
          Expanded(child: _buildList(groups, hasMultipleGroups, theme)),
          _buildDownloadButton(theme),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme theme) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: theme.onSurface.opaque(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      );

  Widget _buildHeader(ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Icon(HugeIcons.strokeRoundedDownload04,
              size: 22, color: theme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymexText(
                    text: 'Select Episodes',
                    variant: TextVariant.bold,
                    size: 16),
                AnymexText(
                  text: widget.media.name ?? '',
                  size: 13,
                  color: theme.onSurface.opaque(0.6),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          AnymexOnTap(
            onTap: () => Navigator.pop(context),
            child:
                Icon(Icons.close_rounded, color: theme.onSurface.opaque(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPicker(ColorScheme theme) {
    final counts = [10, 15, 25, 50];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.opaque(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymexText(
              text: 'Quick Select',
              size: 12,
              variant: TextVariant.semiBold,
              color: theme.primary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickChip(
                label: 'All (${widget.episodes.length})',
                isSelected: _selectedKeys.length == widget.episodes.length,
                onTap: _selectedKeys.length == widget.episodes.length
                    ? _deselectAll
                    : _selectAll,
                theme: theme,
              ),
              ...counts.where((n) => n < widget.episodes.length).map(
                    (n) => _QuickChip(
                      label: 'First $n',
                      isSelected: _isFirstNSelected(n),
                      onTap: () => _selectFirstN(n),
                      theme: theme,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          AnymexText(
            text:
                '${_selectedKeys.length} / ${widget.episodes.length} selected',
            size: 13,
            color: theme.onSurface.opaque(0.6),
          ),
          const Spacer(),
          if (_selectedKeys.isNotEmpty)
            AnymexOnTap(
              onTap: _deselectAll,
              child: AnymexText(text: 'Clear', size: 13, color: theme.error),
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    Map<String, List<Episode>> groups,
    bool hasMultipleGroups,
    ColorScheme theme,
  ) {
    final items = <Widget>[];

    for (final entry in groups.entries) {
      final groupKey = entry.key;
      final eps = entry.value;

      if (hasMultipleGroups && groupKey != '__default__') {
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, size: 14, color: theme.primary),
              const SizedBox(width: 6),
              AnymexText(
                text: 'Season $groupKey',
                size: 13,
                variant: TextVariant.semiBold,
                color: theme.primary,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryContainer.opaque(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnymexText(
                    text: '${eps.length} eps', size: 11, color: theme.primary),
              ),
            ],
          ),
        ));
      }

      for (final ep in eps) {
        final key = _episodeKey(ep);
        final isSelected = _selectedKeys.contains(key);
        final linkType =
            ep.link != null ? detectLinkType(ep.link!) : VideoLinkType.unknown;

        items.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _EpisodeTile(
            episode: ep,
            isSelected: isSelected,
            linkType: linkType,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedKeys.remove(key);
                } else {
                  _selectedKeys.add(key);
                }
              });
            },
            theme: theme,
          ),
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  Widget _buildDownloadButton(ColorScheme theme) {
    final count = _selectedKeys.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: AnymexButton(
          onTap: count == 0 ? null : _proceed,
          color: count == 0 ? theme.surfaceContainer : theme.primary,
          radius: 16,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                HugeIcons.strokeRoundedDownload04,
                size: 20,
                color:
                    count == 0 ? theme.onSurface.opaque(0.4) : theme.onPrimary,
              ),
              const SizedBox(width: 8),
              AnymexText(
                text: count == 0
                    ? 'Select episodes to continue'
                    : 'Choose Quality for $count episode${count != 1 ? 's' : ''}',
                size: 15,
                variant: TextVariant.semiBold,
                color:
                    count == 0 ? theme.onSurface.opaque(0.4) : theme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool isSelected;
  final VideoLinkType linkType;
  final VoidCallback onTap;
  final ColorScheme theme;

  const _EpisodeTile({
    required this.episode,
    required this.isSelected,
    required this.linkType,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isHls = linkType == VideoLinkType.hls;
    final sortLabel = episode.sortMap.isNotEmpty
        ? episode.sortMap.entries
            .map((e) =>
                '${e.key[0].toUpperCase()}${e.key.substring(1)}: ${e.value}')
            .join(' · ')
        : null;

    return AnymexOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryContainer.opaque(0.35)
              : theme.surfaceContainer.opaque(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.primary.opaque(0.5)
                : theme.outline.opaque(0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (episode.thumbnail != null && episode.thumbnail!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnymeXImage(
                  imageUrl: episode.thumbnail!,
                  width: 72,
                  height: 45,
                  fit: BoxFit.cover,
                  radius: 8,
                ),
              )
            else
              Container(
                width: 72,
                height: 45,
                decoration: BoxDecoration(
                  color: theme.primaryContainer.opaque(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(HugeIcons.strokeRoundedPlay,
                    size: 20, color: theme.primary.opaque(0.5)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnymexText(
                          text: 'Episode ${episode.number}',
                          variant: TextVariant.semiBold,
                          size: 13,
                        ),
                      ),
                      if (isHls)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.4)),
                          ),
                          child: const Text('HLS',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  if (episode.title != null && episode.title!.isNotEmpty)
                    AnymexText(
                      text: episode.title!,
                      size: 11,
                      maxLines: 1,
                      color: theme.onSurface.opaque(0.5),
                    ),
                  if (sortLabel != null)
                    AnymexText(
                      text: sortLabel,
                      size: 10,
                      color: theme.primary.opaque(0.7),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? theme.primary : theme.outline.opaque(0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, size: 14, color: theme.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme theme;
  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AnymexOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.opaque(0.15)
              : theme.surfaceContainerHighest.opaque(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primary : theme.outline.opaque(0.2),
          ),
        ),
        child: AnymexText(
          text: label,
          size: 12,
          variant: TextVariant.semiBold,
          color: isSelected ? theme.primary : theme.onSurface.opaque(0.7),
        ),
      ),
    );
  }
}
