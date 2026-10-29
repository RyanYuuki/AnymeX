
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/track/track_binding.dart';
import 'package:anymex/controllers/track/track_binding_controller.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/list_editor.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

Future<void> showTrackSheet(
  BuildContext context, {
  required DownloadedMediaSummary summary,
}) {
  return showTrackSheetForMedia(
    context,
    mediaId: summary.folderName,
    title: summary.title,
    poster: summary.poster,
    isManga: summary.mediaType == 'Manga',
  );
}

Future<void> showTrackSheetForMedia(
  BuildContext context, {
  required String mediaId,
  required String title,
  String? poster,
  bool isManga = false,
}) {
  return AnymeXSheet.custom(
    _TrackSheet(
      mediaId: mediaId,
      title: title,
      poster: poster,
      isManga: isManga,
    ),
    context,
    showDragHandle: true,
  );
}

class _TrackSearchResult {
  final Tracker tracker;
  final Media media;

  const _TrackSearchResult({
    required this.tracker,
    required this.media,
  });
}

class _TrackSheet extends StatefulWidget {
  final String mediaId;
  final String title;
  final String? poster;
  final bool isManga;

  const _TrackSheet({
    required this.mediaId,
    required this.title,
    this.poster,
    required this.isManga,
  });

  @override
  State<_TrackSheet> createState() => _TrackSheetState();
}

class _TrackSheetState extends State<_TrackSheet> {
  final TrackBindingController _ctrl =
      Get.find<TrackBindingController>();

  final TextEditingController _searchCtrl =
      TextEditingController();

  Tracker? _searchingTracker;
  bool _searchAll = false;

  List<_TrackSearchResult> _searchResults = [];

  bool _searching = false;
  bool _showAdult = false;

  SimklSearchCategory _simklCategory =
      SimklSearchCategory.anime;

  bool get _isManga => widget.isManga;
  String get _mediaId => widget.mediaId;

  Future<void> _runSearch(
    Tracker tracker,
    String query,
  ) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() => _searchResults = []);
      }
      return;
    }

    setState(() => _searching = true);

    try {
      final List<Media> results;

      if (tracker == Tracker.simkl) {
        results = await _ctrl.searchOnSimkl(
          query.trim(),
          category: _simklCategory,
        );
      } else {
        results = await _ctrl.searchOn(
          tracker,
          SearchParams(
            query: query.trim(),
            isManga: _isManga,
            args: _showAdult,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _searchResults = results
              .map(
                (media) => _TrackSearchResult(
                  tracker: tracker,
                  media: media,
                ),
              )
              .toList();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AnymeXText(
              'Search failed: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _runUnifiedSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() => _searchResults = []);
      }
      return;
    }

    setState(() => _searching = true);

    try {
      final results = await _ctrl.searchAll(
        SearchParams(
          query: query.trim(),
          isManga: _isManga,
          args: _showAdult,
        ),
        loggedInOnly: true,
      );

      final combined = <_TrackSearchResult>[];

      for (final tracker in _ctrl.loggedInTrackers()) {
        for (final media in results[tracker] ?? <Media>[]) {
          combined.add(
            _TrackSearchResult(
              tracker: tracker,
              media: media,
            ),
          );
        }
      }

      if (mounted) {
        setState(() => _searchResults = combined);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AnymeXText(
              'Unified search failed: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _toggleAdult(Tracker? tracker) {
    setState(() => _showAdult = !_showAdult);

    if (_searchCtrl.text.trim().isEmpty) return;

    if (tracker == null) {
      _runUnifiedSearch(_searchCtrl.text);
    } else {
      _runSearch(tracker, _searchCtrl.text);
    }
  }

  Future<void> _pickResult(
    Tracker tracker,
    Media result,
  ) async {
    final binding = _ctrl.bindingFromSearchResult(
      tracker,
      result,
      isAnime: !_isManga,
    );

    await _ctrl.bind(_mediaId, binding);

    try {
      final newPoster =
          (result.poster.isNotEmpty && result.poster != '?')
              ? result.poster
              : ((result.largePoster.isNotEmpty &&
                      result.largePoster != '?')
                  ? result.largePoster
                  : (result.cover ?? ''));

      if (Get.isRegistered<DownloadController>()) {
        final downloadCtrl =
            Get.find<DownloadController>();

        await downloadCtrl.updateDownloadedMediaMetadata(
          _mediaId,
          newTitle: result.title,
          newPoster: newPoster,
        );
      }
    } catch (error) {
      debugPrint(
        'Error updating downloaded media metadata: $error',
      );
    }

    if (mounted) {
      setState(() {
        _searchingTracker = null;
        _searchAll = false;
        _searchResults = [];
        _searchCtrl.clear();
      });
    }
  }

  Future<void> _unbind(TrackBinding binding) async {
    await _ctrl.unbind(
      _mediaId,
      binding.trackerId,
    );

    if (mounted) setState(() {});
  }

  void _startTrackerSearch(Tracker tracker) {
    setState(() {
      _searchingTracker = tracker;
      _searchAll = false;
      _searchResults = [];
      _simklCategory = SimklSearchCategory.anime;
      _searchCtrl.clear();
    });

    _runSearch(tracker, widget.title);
  }

  void _startUnifiedSearch() {
    setState(() {
      _searchingTracker = null;
      _searchAll = true;
      _searchResults = [];
      _searchCtrl.clear();
    });

    _runUnifiedSearch(widget.title);
  }

  void _goBack() {
    setState(() {
      _searchingTracker = null;
      _searchAll = false;
      _searchResults = [];
      _searchCtrl.clear();
      _searching = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final loggedTrackers = _ctrl.loggedInTrackers();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  size: 18,
                  color: theme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        _searchAll
                            ? 'Search all connected services'
                            : _searchingTracker != null
                                ? 'Search on ${_searchingTracker!.label}'
                                : 'Track this media',
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      AnymeXText(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_searchingTracker != null || _searchAll)
                  TextButton(
                    onPressed: _goBack,
                    child: const AnymeXText('Back'),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.outlineVariant.withOpacity(0.2),
          ),
          if (loggedTrackers.isEmpty)
            _buildNoTrackersState(theme)
          else if (_searchingTracker != null || _searchAll)
            _buildSearchView(context, _searchingTracker)
          else
            _buildHomeView(context, loggedTrackers),
        ],
      ),
    );
  }

  Widget _buildHomeView(
    BuildContext context,
    List<Tracker> trackers,
  ) {
    final theme = context.colors;

    return Obx(() {
      _ctrl.bindingsVersion.value;

      final bindings = _ctrl.getBindingsFor(_mediaId);

      return Flexible(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          shrinkWrap: true,
          children: [
            AnymeXText(
              'Logged-in tracking services',
              style: TextStyle(
                color: theme.onSurface.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startUnifiedSearch,
                icon: const Icon(
                  Icons.travel_explore_rounded,
                  size: 18,
                ),
                label: const AnymeXText(
                  'Search all connected services',
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final tracker in trackers)
              _buildTrackerCard(
                context,
                theme,
                tracker: tracker,
                binding: bindings
                    .cast<TrackBinding?>()
                    .firstWhere(
                      (binding) =>
                          binding?.trackerId == tracker.index,
                      orElse: () => null,
                    ),
              ),
            const SizedBox(height: 12),
            AnymeXText(
              'A single media can be tracked on all logged-in '
              'services. Progress is pushed to every bound '
              'service in parallel.',
              style: TextStyle(
                color: theme.onSurface.withOpacity(0.4),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrackerCard(
    BuildContext context,
    ColorScheme theme, {
    required Tracker tracker,
    required TrackBinding? binding,
  }) {
    final b = binding;
    final bound = b != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bound
              ? Color(tracker.color).withOpacity(0.4)
              : theme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              tracker.iconAsset,
              width: 34,
              height: 34,
              errorBuilder: (_, __, ___) => Container(
                width: 34,
                height: 34,
                color: Color(tracker.color),
                child: Center(
                  child: AnymeXText(
                    tracker.label.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: bound
                ? GestureDetector(
                    onTap: () => _showEditDialog(
                      context,
                      theme,
                      tracker,
                      b,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnymeXText(
                              tracker.label,
                              style: TextStyle(
                                color: theme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: theme.onSurface
                                  .withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnymeXText(
                          _formatBindingSummary(b),
                          style: TextStyle(
                            color: theme.onSurface
                                .withOpacity(0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        tracker.label,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        'Not tracked',
                        style: TextStyle(
                          color: theme.onSurface
                              .withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),
          if (bound)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: theme.primary.withOpacity(0.8),
                  ),
                  onPressed: () => _showEditDialog(
                    context,
                    theme,
                    tracker,
                    b,
                  ),
                ),
                IconButton(
                  tooltip: 'Unbind',
                  icon: Icon(
                    Icons.link_off_rounded,
                    size: 18,
                    color: theme.error.withOpacity(0.7),
                  ),
                  onPressed: () => _unbind(b),
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: () => _startTrackerSearch(tracker),
              icon: Icon(
                Icons.add_link_rounded,
                size: 16,
                color: theme.primary,
              ),
              label: AnymeXText(
                'Track',
                style: TextStyle(color: theme.primary),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    ColorScheme theme,
    Tracker tracker,
    TrackBinding binding,
  ) {
    final handler = Get.find<ServiceHandler>();

    final previousServiceType = handler.serviceType.value;
    final targetServiceType = tracker.servicesType;

    handler.changeService(targetServiceType);

    final media = Media(
      id: binding.remoteId,
      title: binding.title,
      poster: binding.poster ?? '',
      totalEpisodes: binding.totalEpisodes ?? '?',
      mediaType: binding.isAnime
          ? ItemType.anime
          : ItemType.manga,
      serviceType: targetServiceType,
    );

    final tracked = TrackedMedia(
      id: binding.remoteId,
      mediaListId: binding.remoteId,
      title: binding.title,
      poster: binding.poster,
      totalEpisodes: binding.totalEpisodes,
      episodeCount: binding.progress.toString(),
      watchingStatus: binding.status,
      score: binding.score?.toString(),
      isPrivate: binding.private,
      servicesType: targetServiceType,
    );

    final animeStatus = binding.status.obs;
    final animeScore = (binding.score ?? 0.0).obs;
    final animeProgress = binding.progress.obs;
    final currentAnime = tracked.obs;

    AnymeXSheet.custom(
      ListEditorModal(
        animeStatus: animeStatus,
        isManga: !binding.isAnime,
        animeScore: animeScore,
        animeProgress: animeProgress,
        currentAnime: currentAnime,
        media: media,
        onUpdate: (
          id,
          score,
          status,
          progress,
          season,
          startedAt,
          completedAt,
          isPrivate,
        ) async {
          await _ctrl.updateBindingFields(
            _mediaId,
            binding,
            progress: progress,
            status: status,
            score: score,
            isPrivate: isPrivate,
          );

          animeStatus.value = status;
          animeScore.value = score;
          animeProgress.value = progress;
        },
        onDelete: (service) async {
          await _ctrl.unbind(
            _mediaId,
            binding.trackerId,
          );
        },
      ),
      context,
    ).then((_) {
      handler.changeService(previousServiceType);
      if (mounted) setState(() {});
    });
  }

  Widget _buildSimklCategoryTabs(
    BuildContext context,
    ColorScheme theme,
    Tracker tracker,
  ) {
    final categories = [
      (
        SimklSearchCategory.anime,
        'Anime',
        Icons.play_circle_rounded,
      ),
      (
        SimklSearchCategory.movie,
        'Movies',
        Icons.movie_rounded,
      ),
      (
        SimklSearchCategory.show,
        'Shows',
        Icons.tv_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.surfaceContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.outlineVariant.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: categories.map((category) {
                  final cat = category.$1;
                  final label = category.$2;
                  final icon = category.$3;
                  final selected = cat == _simklCategory;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _simklCategory = cat);

                        if (_searchCtrl.text.trim().isNotEmpty) {
                          _runSearch(tracker, _searchCtrl.text);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(tracker.color)
                                  .withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: selected
                                ? Color(tracker.color)
                                    .withOpacity(0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 12,
                              color: selected
                                  ? Color(tracker.color)
                                  : theme.onSurface
                                      .withOpacity(0.5),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: AnymeXText(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Color(tracker.color)
                                      : theme.onSurface
                                          .withOpacity(0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView(
    BuildContext context,
    Tracker? tracker,
  ) {
    final theme = context.colors;
    final isAllServices = tracker == null;
    final isSimkl = tracker == Tracker.simkl;
    final supportsAdultFilter = isAllServices || !isSimkl;

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (query) {
                if (tracker == null) {
                  _runUnifiedSearch(query);
                } else {
                  _runSearch(tracker, query);
                }
              },
              decoration: InputDecoration(
                hintText: isAllServices
                    ? 'Search all connected services…'
                    : 'Search ${tracker.label} for "${widget.title}"…',
                hintStyle: TextStyle(
                  color: theme.onSurface.withOpacity(0.4),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: theme.onSurface.withOpacity(0.5),
                ),
                filled: true,
                fillColor: theme.surfaceContainer.withOpacity(0.4),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (tracker != null && isSimkl)
            _buildSimklCategoryTabs(
              context,
              theme,
              tracker,
            ),
          if (supportsAdultFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const AnymeXText(
                      '18+',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: _showAdult,
                    selectedColor: theme.error.withOpacity(0.25),
                    checkmarkColor: theme.error,
                    labelStyle: TextStyle(
                      color: _showAdult
                          ? theme.error
                          : theme.onSurface.withOpacity(0.6),
                    ),
                    backgroundColor:
                        theme.surfaceContainer.withOpacity(0.3),
                    side: BorderSide(
                      color: _showAdult
                          ? theme.error.withOpacity(0.4)
                          : theme.outlineVariant.withOpacity(0.2),
                    ),
                    showCheckmark: false,
                    avatar: Icon(
                      _showAdult
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 13,
                      color: _showAdult
                          ? theme.error
                          : theme.onSurface.withOpacity(0.4),
                    ),
                    onSelected: (_) => _toggleAdult(tracker),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnymeXText(
                      _showAdult
                          ? 'Showing all titles (incl. 18+)'
                          : 'Hiding 18+ content',
                      style: TextStyle(
                        color: theme.onSurface.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _searching
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: AnymeXText(
                            isAllServices
                                ? 'No results. Try another title or connect a tracking service.'
                                : 'No results. Try searching by title.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.onSurface.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          16,
                        ),
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final item = _searchResults[index];

                          return _buildSearchResultTile(
                            context,
                            theme,
                            item.tracker,
                            item.media,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatBindingSummary(TrackBinding binding) {
    final parts = <String>[];
    final total = binding.totalEpisodes;

    final hasTotal = total != null &&
        total.isNotEmpty &&
        total != '?' &&
        total != '0' &&
        total != '1';

    parts.add(
      hasTotal
          ? 'Ep ${binding.progress} / $total'
          : 'Ep ${binding.progress}',
    );

    parts.add(binding.status);

    if (binding.score != null && binding.score! > 0) {
      parts.add('★ ${binding.score}');
    }

    return parts.join(' · ');
  }

  String _formatSearchResultSubtitle(
    Media media,
    Tracker tracker,
  ) {
    final parts = <String>[];
    final total = media.totalEpisodes;

    final hasTotal = total.isNotEmpty &&
        total != '?' &&
        total != '0' &&
        total != '1';

    if (hasTotal) parts.add('$total eps');

    final status = media.status;

    if (status.isNotEmpty &&
        status != '?' &&
        status != 'UNKNOWN' &&
        status != 'N/A') {
      parts.add(status);
    }

    if (media.seasonYear != null) {
      parts.add('${media.seasonYear}');
    }

    parts.add(tracker.label);

    return parts.join(' · ');
  }

  Widget _buildSearchResultTile(
    BuildContext context,
    ColorScheme theme,
    Tracker tracker,
    Media media,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.outlineVariant.withOpacity(0.15),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (media.poster.isNotEmpty && media.poster != '?')
              ? AnymeXImage(
                  imageUrl: media.poster,
                  width: 44,
                  height: 62,
                  fit: BoxFit.cover,
                  radius: 8,
                )
              : Container(
                  width: 44,
                  height: 62,
                  color: theme.surfaceContainer.withOpacity(0.5),
                  child: Icon(
                    Icons.movie_outlined,
                    size: 20,
                    color: theme.onSurface.withOpacity(0.3),
                  ),
                ),
        ),
        title: AnymeXText(
          media.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: AnymeXText(
          _formatSearchResultSubtitle(media, tracker),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: () => _pickResult(tracker, media),
          style: FilledButton.styleFrom(
            backgroundColor:
                Color(tracker.color).withOpacity(0.15),
            foregroundColor: Color(tracker.color),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 34),
          ),
          child: const AnymeXText(
            'Track',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTrackersState(ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.login_rounded,
            size: 36,
            color: theme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 14),
          AnymeXText(
            'No tracking service connected',
            style: TextStyle(
              color: theme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          AnymeXText(
            'Log in to AniList, MyAnimeList or Simkl from '
            'Settings → Accounts to track this media.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.onSurface.withOpacity(0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              navigate(() => const SettingsAccounts());
            },
            icon: const Icon(
              Icons.settings_rounded,
              size: 16,
            ),
            label: const AnymeXText('Open Settings'),
          ),
        ],
      ),
    );
  }
}
