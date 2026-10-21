import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/database/isar_models/track.dart' as model;
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/utils/online_subtitles.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_search_bar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

enum _SubtitleTab { source, embedded, online }

class TracksPopup extends StatelessWidget {
  final PlayerController controller;

  const TracksPopup({super.key, required this.controller});

  void _closePane() {
    controller.isTracksPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: controller.isTracksPaneOpened.value,
          onOverlayTap: _closePane,
          child: _TracksPopupContent(
            controller: controller,
            onClose: _closePane,
          ),
        ));
  }
}

class _TracksPopupContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;

  const _TracksPopupContent({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_TracksPopupContent> createState() => _TracksPopupContentState();
}

class _TracksPopupContentState extends State<_TracksPopupContent> {
  _SubtitleTab _currentTab = _SubtitleTab.source;
  final RxBool _showAllStreams = false.obs;

  late final TextEditingController _onlineSearchController;
  final RxString _selectedLanguageCode = 'eng'.obs;
  final RxList<OnlineSubtitle> _onlineResults = <OnlineSubtitle>[].obs;
  final RxBool _isSearchingOnline = false.obs;
  final RxString _downloadingSubtitleId = ''.obs;
  final RxnString _activeOnlineSubtitleId = RxnString();

  @override
  void initState() {
    super.initState();
    final animeName = widget.controller.itemName ??
        widget.controller.anilistData.title;
    final ep = widget.controller.currentEpisode.value.number;
    _onlineSearchController = TextEditingController(
      text: '$animeName $ep'.trim(),
    );
  }

  @override
  void dispose() {
    _onlineSearchController.dispose();
    super.dispose();
  }

  Future<void> _performOnlineSearch() async {
    final term = _onlineSearchController.text.trim();
    if (term.isEmpty) return;
    _isSearchingOnline.value = true;
    try {
      final epNum = int.tryParse(widget.controller.currentEpisode.value.number);
      final list = await searchOnlineSubtitles(
        query: term,
        language: _selectedLanguageCode.value,
        episode: epNum,
        imdbTitle: widget.controller.itemName ??
            widget.controller.anilistData.title,
      );
      _onlineResults.value = list;
    } catch (e) {
      debugPrint('Online subtitle search error: $e');
      _onlineResults.clear();
    } finally {
      _isSearchingOnline.value = false;
    }
  }

  Future<void> _selectOnlineSubtitle(OnlineSubtitle sub) async {
    _downloadingSubtitleId.value = sub.id;
    try {
      final filePath = await downloadOnlineSubtitle(sub);
      widget.controller.setSubtitleTrack(
        SubtitleTrack.uri(filePath, title: sub.name),
      );
      _activeOnlineSubtitleId.value = sub.id;
      snackBar('Loaded subtitle: ${sub.name}');
    } catch (e) {
      errorSnackBar('Failed to download subtitle: $e');
    } finally {
      _downloadingSubtitleId.value = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return WatchSettingsPane(
      title: 'Subtitle Settings',
      onClose: widget.onClose,
      tabBar: _buildTabBar(cs, theme),
      child: switch (_currentTab) {
        _SubtitleTab.source => _buildSourceSubtitles(cs, theme),
        _SubtitleTab.embedded => _buildEmbeddedSubtitles(cs, theme),
        _SubtitleTab.online => _buildOnlineSubtitles(cs, theme),
      },
    );
  }

  Widget _buildTabBar(ColorScheme cs, ThemeData theme) {
    final tabs = ['Source', 'Embedded', 'Online'];
    final icons = [
      Icons.cloud_rounded,
      Icons.closed_caption_rounded,
      Icons.language_rounded,
    ];

    final activeIndex = switch (_currentTab) {
      _SubtitleTab.source => 0,
      _SubtitleTab.embedded => 1,
      _SubtitleTab.online => 2,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnymeXTabBar(
        selectTabs: tabs,
        selectedIndex: activeIndex,
        icons: icons,
        onTabSelected: (index) {
          setState(() {
            _currentTab = switch (index) {
              0 => _SubtitleTab.source,
              1 => _SubtitleTab.embedded,
              _ => _SubtitleTab.online,
            };
          });
        },
      ),
    );
  }

  Widget _buildSourceSubtitles(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final allMode = _showAllStreams.value;
      final tracks = allMode
          ? widget.controller.getAllStreamSubtitleOptions()
          : widget.controller.getCurrentStreamSubtitleOptions();
      final selectedFile = widget.controller.selectedExternalSub.value.file;
      final localSubs = widget.controller.localSubtitles;

      final List<model.Track?> items = [null];
      for (final local in localSubs) {
        if (!tracks.any((t) => t.file == local.file)) {
          items.add(local);
        }
      }
      items.addAll(tracks);

      final totalCount = 2 + items.length;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer
                .opaque(0.45, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: context.colors.onSurface.opaque(0.08, iReallyMeanIt: true),
              width: 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: totalCount,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.6,
                indent: index == 0 ? 16 : 66.0,
                endIndent: 16,
                color:
                    context.colors.onSurface.opaque(0.08, iReallyMeanIt: true),
              ),
              itemBuilder: (context, index) {
                BorderRadius radius;
                if (totalCount == 1) {
                  radius = BorderRadius.circular(18.0);
                } else if (index == 0) {
                  radius =
                      const BorderRadius.vertical(top: Radius.circular(18.0));
                } else if (index == totalCount - 1) {
                  radius = const BorderRadius.vertical(
                      bottom: Radius.circular(18.0));
                } else {
                  radius = BorderRadius.zero;
                }

                if (index == 0) {
                  return AnymeXTile.toggle(
                    value: allMode,
                    icon: Icons.layers_rounded,
                    title: 'Show all streams',
                    onChanged: (val) {
                      _showAllStreams.value = val;
                      widget.controller.showAllStreamSubtitles.value = val;
                    },
                    borderRadius: radius,
                  );
                }

                if (index == 1) {
                  return AnymeXTile(
                    title: 'Import Local Subtitle',
                    subtitle:
                        'Choose a subtitle file from your device (.srt, .vtt, .ass, .ssa)',
                    icon: Icons.file_open_rounded,
                    onTap: () {
                      widget.controller.pickLocalSubtitle();
                      widget.onClose();
                    },
                    borderRadius: radius,
                  );
                }

                final item = items[index - 2];
                final checked = (selectedFile == null || selectedFile.isEmpty)
                    ? item == null
                    : item?.file == selectedFile;

                final isLocal =
                    item != null && !tracks.any((t) => t.file == item.file);

                return AnymeXTile.radio(
                  title: item == null ? 'None' : (item.label ?? 'No Title'),
                  subtitle: item == null
                      ? 'No subtitles'
                      : (isLocal
                          ? 'Local Subtitle File'
                          : (allMode ? 'All Streams' : 'Current Stream')),
                  icon: item == null ? Icons.subtitles_off : Icons.subtitles,
                  selected: checked,
                  onTap: () => widget.controller.setExternalSub(item),
                  borderRadius: radius,
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmbeddedSubtitles(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final tracks = widget.controller.embeddedSubs.value;
      final selectedTrack = widget.controller.selectedSubsTrack.value;

      final subtitleTrackItems = [SubtitleTrack.no(), ...tracks];
      final selectedItem = selectedTrack ?? subtitleTrackItems.first;

      if (tracks.isEmpty) {
        return _buildEmpty(
            cs, theme, Icons.closed_caption_rounded, 'No embedded subtitles');
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnymeXTileBuilder<SubtitleTrack>(
          items: subtitleTrackItems,
          selectedItem: selectedItem,
          getTitle: (t) => t.id == 'no'
              ? 'None'
              : (completeSubtitleLanguageName(t.language ?? '')).toUpperCase(),
          getSubtitle: (t) =>
              t.id == 'no' ? 'No subtitles' : 'Embedded Subtitle',
          getIcon: (t) =>
              t.id == 'no' ? Icons.subtitles_off : Icons.closed_caption_rounded,
          onItemPressed: (t) => widget.controller.setSubtitleTrack(t),
          lazy: true,
        ),
      );
    });
  }

  Widget _buildOnlineSubtitles(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: AnymeXSearchBar(
                  controller: _onlineSearchController,
                  hintText: 'Search anime / episode...',
                  onSubmitted: (_) => _performOnlineSearch(),
                ),
              ),
              const SizedBox(width: 8),
              AnymexOnTap(
                onTap: _performOnlineSearch,
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          final selectedLang = _selectedLanguageCode.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnymeXPills(
              items: subtitleLanguages.map((lang) {
                final isSelected = selectedLang == lang.code;
                return PillItem(
                  label: lang.name,
                  isSelected: isSelected,
                  onTap: () {
                    _selectedLanguageCode.value = lang.code;
                    _performOnlineSearch();
                  },
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (_isSearchingOnline.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_onlineResults.isEmpty) {
              return _buildEmpty(
                cs,
                theme,
                Icons.language_rounded,
                'No subtitles found. Try searching with a different title.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _onlineResults.length,
              itemBuilder: (context, index) {
                final sub = _onlineResults[index];
                final isDownloading = _downloadingSubtitleId.value == sub.id;
                final isSelected = _activeOnlineSubtitleId.value == sub.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: AnymeXTile(
                    title: sub.name,
                    subtitle:
                        '${sub.format.toUpperCase()} • ${sub.provider}${sub.downloads > 0 ? " • ${sub.downloads} dl" : ""}',
                    icon: sub.hearingImpaired
                        ? Icons.hearing_disabled_rounded
                        : Icons.subtitles_rounded,
                    trailing: isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: cs.primary)
                            : null),
                    onTap: () => _selectOnlineSubtitle(sub),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmpty(
      ColorScheme cs, ThemeData theme, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          AnymeXText(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
