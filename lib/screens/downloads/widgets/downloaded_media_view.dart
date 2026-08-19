import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/track/track_binding_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/downloads/widgets/downloaded_watch_page.dart';
import 'package:anymex/screens/downloads/widgets/track_sheet.dart';
import 'package:anymex/screens/downloads/widgets/video_thumbnail_widget.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class DownloadedMediaView extends StatefulWidget {
  final DownloadedMediaSummary summary;
  const DownloadedMediaView({super.key, required this.summary});

  @override
  State<DownloadedMediaView> createState() => _DownloadedMediaViewState();
}

class _DownloadedMediaViewState extends State<DownloadedMediaView> {
  DownloadedMediaMeta? _meta;
  DownloadedMangaMeta? _mangaMeta;
  final downloadController = Get.find<DownloadController>();

  DownloadedMediaSummary get _currentSummary =>
      downloadController.downloadedMedia
          .firstWhereOrNull((s) => s.folderName == widget.summary.folderName) ??
      widget.summary;

  bool get _isManga => _currentSummary.mediaType == 'Manga';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_isManga) {
      final fresh = await downloadController.getMangaMeta(
        _currentSummary.extensionName,
        _currentSummary.folderName,
      );
      if (mounted) setState(() => _mangaMeta = fresh);
    } else {
      final fresh = await downloadController.getMediaMeta(
        _currentSummary.extensionName,
        _currentSummary.folderName,
      );
      if (mounted) setState(() => _meta = fresh);
    }
  }

  String _relativeTime(int epochMs) {
    if (epochMs == 0) return 'Unknown';
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(epochMs));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  void _showDeleteEpisodeDialog(
      BuildContext context, DownloadedEpisodeMeta ep) {
    AnymeXDialog(
      title: 'Delete episode?',
      message:
          'Episode ${ep.number} will be permanently removed from your downloads.',
      onConfirm: () async {
        await downloadController.deleteEpisode(
          widget.summary.extensionName,
          widget.summary.title,
          ep.number,
          ep.sortMap,
        );
        await _refresh();
      },
    ).show(context);
  }

  void _showDeleteChapterDialog(
      BuildContext context, DownloadedChapterMeta ch) {
    final display = ch.displayTitle;
    AnymeXDialog(
      title: 'Delete chapter?',
      message: '$display will be permanently removed from your downloads.',
      onConfirm: () async {
        await downloadController.deleteChapter(
          widget.summary.extensionName,
          widget.summary.title,
          ch.chapter.number,
        );
        await _refresh();
      },
    ).show(context);
  }

  void _showDeleteAllDialog(BuildContext context) {
    final count = _isManga
        ? (_mangaMeta?.chapters.length ?? 0)
        : (_meta?.episodes.length ?? 0);
    AnymeXDialog(
      title: _isManga ? 'Delete all chapters?' : 'Delete all episodes?',
      message:
          '"${widget.summary.title}" — $count ${_isManga ? 'chapters' : 'episodes'} will be permanently removed.',
      onConfirm: () async {
        await downloadController.deleteMedia(
            widget.summary.extensionName, widget.summary.title,
            mediaType: widget.summary.mediaType);
        if (mounted) Navigator.pop(context);
      },
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final isLoading = _isManga ? _mangaMeta == null : _meta == null;
    final isEmpty = _isManga
        ? (_mangaMeta?.chapters.isEmpty ?? true)
        : (_meta?.episodes.isEmpty ?? true);

    return AnymeXScaffold(
        floatingActionButton: _buildContinueFab(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, theme),
                _buildSectionHeader(theme),
                if (isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (isEmpty)
                  _buildEmptyState(theme)
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      children: _isManga
                          ? _buildChapterList(theme)
                          : _buildEpisodeList(theme),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  Widget? _buildContinueFab() {
    if (_isManga) {
      if (_mangaMeta == null || _mangaMeta!.chapters.isEmpty) return null;
      final firstChapter = _mangaMeta!.chapters.first;
      return continueFab(
        label: 'Continue Reading',
        subtitle: firstChapter.displayTitle,
        icon: HugeIcons.strokeRoundedBookOpen01,
        onTap: () => _playChapter(firstChapter),
      );
    }

    if (_meta == null || _meta!.episodes.isEmpty) return null;

    final inProgress = _meta!.episodes.where((ep) {
      final ts = ep.episode.timeStampInMilliseconds;
      final dur = ep.episode.durationInMilliseconds;
      if (ts == null || dur == null || dur <= 0) return false;
      final ratio = ts / dur;
      return ratio > 0.01 && ratio < 0.9;
    }).toList();

    DownloadedEpisodeMeta? target;
    if (inProgress.isNotEmpty) {
      inProgress.sort((a, b) => (b.episode.lastWatchedTime ?? 0)
          .compareTo(a.episode.lastWatchedTime ?? 0));
      target = inProgress.first;
    } else {
      final unwatched = _meta!.episodes.where((ep) {
        final ts = ep.episode.timeStampInMilliseconds;
        final dur = ep.episode.durationInMilliseconds;
        if (ts == null || dur == null || dur <= 0) return true;
        return (ts / dur) < 0.9;
      }).toList();
      if (unwatched.isNotEmpty) target = unwatched.first;
    }

    if (target == null) return null;

    final ts = target.episode.timeStampInMilliseconds;
    final dur = target.episode.durationInMilliseconds;
    String subtitle = target.displayId;
    if (ts != null && dur != null && dur > 0 && ts > 0) {
      final leftMs = (dur - ts).clamp(0, dur);
      final minutes = leftMs ~/ 60000;
      if (minutes > 0) subtitle += ' · ${minutes}m left';
    }

    return continueFab(
      label: 'Continue Watching',
      subtitle: subtitle,
      icon: Icons.play_arrow_rounded,
      onTap: () => _playEpisode(target!),
    );
  }

  Future<void> _playEpisode(DownloadedEpisodeMeta ep) async {
    await navigate(() => DownloadedWatchPage(
          episode: ep,
          allEpisodes: _meta!.episodes,
          meta: _meta!,
          summary: widget.summary,
        ));
    await Future.delayed(const Duration(milliseconds: 300));
    await _refresh();
    await _syncBoundTrackersAfterPlay();
  }

  Future<void> _playChapter(DownloadedChapterMeta ch) async {
    final media = Media.fromOfflineMedia(
      OfflineMedia(
        mediaId: widget.summary.folderName,
        name: widget.summary.title,
        poster: widget.summary.poster,
      ),
      ItemType.manga,
    );

    final chapterList = _mangaMeta!.chapters.map((meta) {
      final baseChapter = meta.chapter;
      baseChapter.localPath = meta.imageDir;
      return baseChapter;
    }).toList();

    final currentChapter = ch.chapter;
    currentChapter.localPath = ch.imageDir;

    await navigate(() => ReadingPage(
          anilistData: media,
          chapterList: chapterList,
          currentChapter: currentChapter,
          shouldTrack: false,
        ));
    await Future.delayed(const Duration(milliseconds: 300));
    await _refresh();
    await _syncBoundTrackersAfterPlay();
  }

  Future<void> _syncBoundTrackersAfterPlay() async {
    try {
      final trackCtrl = Get.find<TrackBindingController>();
      final mediaId = widget.summary.folderName;
      if (!trackCtrl.hasAnyBinding(mediaId)) return;

      int progress = 0;
      final threshold =
          settingsController.markAsCompleted; // user-configured % (default 90)
      if (!_isManga && _meta != null) {
        for (final e in _meta!.episodes) {
          final n = int.tryParse(e.number) ?? 0;
          if (n == 0) continue;
          final ts = e.episode.timeStampInMilliseconds ?? 0;
          final dur = e.episode.durationInMilliseconds ?? 0;
          final watched = dur > 0 && ts >= dur * (threshold / 100);
          if (watched && n > progress) progress = n;
        }
      } else if (_isManga && _mangaMeta != null) {
        for (final c in _mangaMeta!.chapters) {
          final num = c.chapter.number;
          if (num == null) continue;
          final isRead = (c.chapter.lastReadTime ?? 0) > 0 ||
              (c.chapter.totalPages != null &&
                  c.chapter.pageNumber != null &&
                  c.chapter.totalPages! > 0 &&
                  c.chapter.pageNumber! >= c.chapter.totalPages!);
          if (isRead && num.toInt() > progress) progress = num.toInt();
        }
      }

      if (progress <= 0) return;
      await trackCtrl.pushProgress(mediaId, progress, isAnime: !_isManga);
    } catch (e) {
      debugPrint('post-play track sync skipped: $e');
    }
  }

  List<Widget> _buildEpisodeList(ColorScheme theme) {
    return List.generate(_meta!.episodes.length, (index) {
      final ep = _meta!.episodes[index];
      return Column(
        children: [
          _buildEpisodeTile(
            context: context,
            theme: theme,
            episode: ep,
            relativeTime: _relativeTime(ep.downloadedAt),
            onPlay: () => _playEpisode(ep),
            onDelete: () => _showDeleteEpisodeDialog(context, ep),
          ),
          if (index < _meta!.episodes.length - 1)
            Divider(
              height: 3,
              indent: 108,
              color: theme.outlineVariant.withOpacity(0.2),
            ),
        ],
      );
    });
  }

  List<Widget> _buildChapterList(ColorScheme theme) {
    return List.generate(_mangaMeta!.chapters.length, (index) {
      final ch = _mangaMeta!.chapters[index];
      return Column(
        children: [
          _buildChapterTile(
            context: context,
            theme: theme,
            chapter: ch,
            relativeTime: _relativeTime(ch.downloadedAt),
            onPlay: () => _playChapter(ch),
            onDelete: () => _showDeleteChapterDialog(context, ch),
          ),
          if (index < _mangaMeta!.chapters.length - 1)
            Divider(
              height: 3,
              indent: 108,
              color: theme.outlineVariant.withOpacity(0.2),
            ),
        ],
      );
    });
  }

  Widget _buildHero(BuildContext context, ColorScheme theme) {
    final summary = _currentSummary;
    final hasPoster = summary.poster != null && summary.poster!.isNotEmpty;
    final count = _isManga
        ? (_mangaMeta?.chapters.length ?? '-')
        : (_meta?.episodes.length ?? '-');

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              _buildNavBtn(
                context: context,
                theme: theme,
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              _buildTrackBtn(context: context, theme: theme),
              const SizedBox(width: 8),
              _buildNavBtn(
                context: context,
                theme: theme,
                icon: Icons.refresh_rounded,
                onTap: _refresh,
              ),
              const SizedBox(width: 8),
              _buildNavBtn(
                context: context,
                theme: theme,
                icon: Icons.delete_sweep_rounded,
                onTap: () => _showDeleteAllDialog(context),
                danger: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasPoster
                    ? AnymeXImage(
                        imageUrl: summary.poster!,
                        width: 88,
                        height: 124,
                        fit: BoxFit.cover,
                        radius: 14,
                      )
                    : Container(
                        width: 88,
                        height: 124,
                        color: theme.surfaceContainer.withOpacity(0.4),
                        child: Icon(
                          _isManga
                              ? HugeIcons.strokeRoundedBook02
                              : HugeIcons.strokeRoundedPlay,
                          color: theme.onSurface.withOpacity(0.2),
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AnymeXText(
                        summary.extensionName.toUpperCase(),
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnymeXText(
                      summary.title,
                      style: TextStyle(
                        color: theme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.secondary,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                              right: Radius.circular(5),
                            ),
                          ),
                          child: AnymeXText(
                            '$count ${_isManga ? 'CH' : 'EPS'}',
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.tertiary,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(5),
                              right: Radius.circular(8),
                            ),
                          ),
                          child: AnymeXText(
                            'DOWNLOADED',
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme theme) {
    final count =
        _isManga ? (_mangaMeta?.chapters.length) : (_meta?.episodes.length);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.outlineVariant.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(
            HugeIcons.strokeRoundedDownload04,
            size: 14,
            color: theme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          AnymeXText(
            _isManga ? 'Downloaded Chapters' : 'Downloaded Episodes',
            style: TextStyle(
              color: theme.onSurface.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnymeXText(
                '$count',
                style: TextStyle(
                  color: theme.primary.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavBtn({
    required BuildContext context,
    required ColorScheme theme,
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return AnymexOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: theme.surfaceContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: danger
                ? theme.error.withOpacity(0.3)
                : theme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: danger ? theme.error : theme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTrackBtn({
    required BuildContext context,
    required ColorScheme theme,
  }) {
    final trackCtrl = Get.find<TrackBindingController>();
    final mediaId = _currentSummary.folderName;

    return AnymexOnTap(
      onTap: () async {
        await showTrackSheet(context, summary: _currentSummary);
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: theme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.track_changes_rounded, size: 15, color: theme.primary),
            const SizedBox(width: 6),
            AnymeXText(
              'Track',
              style: TextStyle(
                color: theme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Obx(() {
              trackCtrl.bindingsVersion.value;
              trackCtrl.loggedInTrackers();
              final bound = trackCtrl.bindingCount(mediaId);
              final total = trackCtrl.loggedInTrackers().length;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: bound > 0
                      ? theme.primary.withOpacity(0.25)
                      : theme.surfaceContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnymeXText(
                  total == 0 ? '0' : '$bound/$total',
                  style: TextStyle(
                    color: bound > 0
                        ? theme.primary
                        : theme.onSurface.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required ColorScheme theme,
    required String label,
    required bool useSecondary,
  }) {
    final color = useSecondary ? theme.tertiary : theme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: AnymeXText(
        label,
        style: TextStyle(
          color: color.withOpacity(0.85),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildInfoBadge(ColorScheme theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: AnymeXText(
        text,
        style: TextStyle(
          color: color.withOpacity(0.85),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEpisodeTile({
    required BuildContext context,
    required ColorScheme theme,
    required DownloadedEpisodeMeta episode,
    required String relativeTime,
    required VoidCallback onPlay,
    required VoidCallback onDelete,
  }) {
    final hasThumbnail =
        episode.thumbnail != null && episode.thumbnail!.contains('http');

    final ts = episode.episode.timeStampInMilliseconds;
    final dur = episode.episode.durationInMilliseconds;
    final progress = (ts != null && dur != null && dur > 0)
        ? (ts / dur).clamp(0.0, 1.0)
        : 0.0;
    final isWatched =
        (ts != null && dur != null && dur > 0) && ts >= (dur * 0.9);
    final hasProgress = progress > 0 && !isWatched;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnymexOnTap(
                  onTap: onPlay,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          hasThumbnail
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnymeXImage(
                                    imageUrl: episode.thumbnail!,
                                    width: 120,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    radius: 10,
                                  ),
                                )
                              : VideoThumbnailWidget(
                                  videoPath: episode.filePath,
                                  width: 120,
                                  height: 68,
                                  borderRadius: BorderRadius.circular(10),
                                  fallback: Container(
                                    width: 120,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: theme.surfaceContainer
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: AnymeXText(
                                        episode.number,
                                        style: TextStyle(
                                          color:
                                              theme.onSurface.withOpacity(0.3),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AnymeXText(
                                'EP ${episode.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          if (hasProgress)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 3,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primary),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnymeXText(
                              episode.title != null && episode.title!.isNotEmpty
                                  ? episode.title!
                                  : 'Episode ${episode.number}',
                              style: TextStyle(
                                color: isWatched
                                    ? theme.onSurface.withOpacity(0.4)
                                    : theme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.secondary,
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                            left: Radius.circular(8),
                                            right: Radius.circular(5),
                                          ),
                                        ),
                                        child: AnymeXText.semiBold(relativeTime.toUpperCase(),
                                          size: 9.0,
                                          color: theme.secondary
                                                      .computeLuminance() >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: theme.tertiary,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              left: Radius.circular(5),
                                              right: Radius.circular(8),
                                            ),
                                          ),
                                          child: AnymeXText.semiBold((episode.quality ?? 'VIDEO')
                                                .toUpperCase(),
                                            maxLines: 1,
                                            size: 9.0,
                                            color: theme.tertiary
                                                        .computeLuminance() >
                                                    0.5
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                if (episode.episode.filler == true) ...[
                                  const SizedBox(width: 6),
                                  _buildInfoBadge(
                                      theme, 'Filler', theme.secondary),
                                ],
                                if (isWatched) ...[
                                  const SizedBox(width: 6),
                                  _buildInfoBadge(
                                      theme, 'Watched', theme.primary),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 16),
                color: theme.error.withOpacity(0.85),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: theme.error.withOpacity(0.06),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                  side: BorderSide(
                    color: theme.error.withOpacity(0.18),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          if (episode.episode.desc != null &&
              episode.episode.desc!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnymeXText(
                episode.episode.desc!,
                style: TextStyle(
                  color: theme.onSurface.withOpacity(0.55),
                  fontSize: 11.5,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterTile({
    required BuildContext context,
    required ColorScheme theme,
    required DownloadedChapterMeta chapter,
    required String relativeTime,
    required VoidCallback onPlay,
    required VoidCallback onDelete,
  }) {
    File? firstImageFile;
    if (chapter.imageDir.isNotEmpty) {
      try {
        final dir = Directory(chapter.imageDir);
        if (dir.existsSync()) {
          final files = dir
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.endsWith('.jpg') ||
                  f.path.endsWith('.jpeg') ||
                  f.path.endsWith('.png') ||
                  f.path.endsWith('.webp'))
              .toList();
          if (files.isNotEmpty) {
            files.sort((a, b) => a.path.compareTo(b.path));
            firstImageFile = files.first;
          }
        }
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnymexOnTap(
                  onTap: onPlay,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 76,
                        decoration: BoxDecoration(
                          color: theme.surfaceContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          image: firstImageFile != null
                              ? DecorationImage(
                                  image: FileImage(firstImageFile),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: firstImageFile == null
                            ? Center(
                                child: Icon(
                                  HugeIcons.strokeRoundedBook02,
                                  size: 24,
                                  color: theme.primary.withOpacity(0.4),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnymeXText(
                              chapter.displayTitle,
                              style: TextStyle(
                                color: theme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
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
                                  child: AnymeXText(
                                    relativeTime.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 9.0,
                                      color:
                                          theme.secondary.computeLuminance() >
                                                  0.5
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
                                  child: AnymeXText(
                                    '${chapter.pageCount} PAGES',
                                    style: TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 9.0,
                                      color: theme.tertiary.computeLuminance() >
                                              0.5
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
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 16),
                color: theme.error.withOpacity(0.85),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: theme.error.withOpacity(0.06),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                  side: BorderSide(
                    color: theme.error.withOpacity(0.18),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme theme) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              HugeIcons.strokeRoundedDownload04,
              size: 36,
              color: theme.onSurface.withOpacity(0.12),
            ),
            const SizedBox(height: 14),
            AnymeXText(
              'Nothing downloaded yet',
              style: TextStyle(
                color: theme.onSurface.withOpacity(0.5),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            AnymeXText(
              'Media you download will appear here.',
              style: TextStyle(
                color: theme.onSurface.withOpacity(0.28),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget continueFab({
    required label,
    required subtitle,
    required icon,
    required onTap,
  }) {
    final theme = context.colors;
    return AnymexOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.onPrimary),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  label,
                  style: TextStyle(
                    color: theme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                AnymeXText(
                  subtitle,
                  style: TextStyle(
                    color: theme.onPrimary.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
