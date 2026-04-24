import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/downloads/widgets/downloaded_watch_page.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
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

  bool get _isManga => widget.summary.mediaType == 'Manga';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_isManga) {
      final fresh = await downloadController.getMangaMeta(
        widget.summary.extensionName,
        widget.summary.folderName,
      );
      if (mounted) setState(() => _mangaMeta = fresh);
    } else {
      final fresh = await downloadController.getMediaMeta(
        widget.summary.extensionName,
        widget.summary.folderName,
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
    AnymexDialog(
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
    AnymexDialog(
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
    AnymexDialog(
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

    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
        ),
      ),
    );
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
    await _refresh();
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
    await _refresh();
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
    final hasPoster =
        widget.summary.poster != null && widget.summary.poster!.isNotEmpty;
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
                        imageUrl: widget.summary.poster!,
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
                      child: Text(
                        widget.summary.extensionName.toUpperCase(),
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.summary.title,
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
                    Row(
                      children: [
                        _buildInfoChip(
                          theme: theme,
                          label: '$count ${_isManga ? 'Ch' : 'Eps'}',
                          useSecondary: false,
                        ),
                        const SizedBox(width: 6),
                        _buildInfoChip(
                          theme: theme,
                          label: 'Downloaded',
                          useSecondary: true,
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
          Text(
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
              child: Text(
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
      child: Text(
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

  Widget _buildEpisodeTile({
    required BuildContext context,
    required ColorScheme theme,
    required DownloadedEpisodeMeta episode,
    required String relativeTime,
    required VoidCallback onPlay,
    required VoidCallback onDelete,
  }) {
    final hasThumbnail =
        episode.thumbnail != null && episode.thumbnail!.isNotEmpty;

    final ts = episode.episode.timeStampInMilliseconds;
    final dur = episode.episode.durationInMilliseconds;
    final progress = (ts != null && dur != null && dur > 0)
        ? (ts / dur).clamp(0.0, 1.0)
        : 0.0;
    final isWatched =
        (ts != null && dur != null && dur > 0) && ts >= (dur * 0.9);
    final hasProgress = progress > 0 && !isWatched;

    String? timeLeft;
    if (ts != null && dur != null && dur > 0) {
      final leftMs = (dur - ts).clamp(0, dur);
      final minutes = leftMs ~/ 60000;
      if (minutes > 0) timeLeft = '${minutes}m left';
    }

    return AnymexOnTap(
      onTap: onPlay,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasThumbnail
                      ? AnymeXImage(
                          imageUrl: episode.thumbnail!,
                          width: 76,
                          height: 52,
                          fit: BoxFit.cover,
                          radius: 10,
                        )
                      : Container(
                          width: 76,
                          height: 52,
                          decoration: BoxDecoration(
                            color: theme.surfaceContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              episode.number,
                              style: TextStyle(
                                color: theme.onSurface.withOpacity(0.3),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                ),
                if (hasThumbnail)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        episode.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
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
                        minHeight: 2.5,
                        backgroundColor: theme.surfaceVariant.withOpacity(0.3),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primary),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        relativeTime,
                        style: TextStyle(
                          color: theme.onSurface.withOpacity(0.28),
                          fontSize: 11,
                        ),
                      ),
                      if (episode.quality != null) ...[
                        _buildDot(theme),
                        Text(
                          episode.quality!,
                          style: TextStyle(
                            color: theme.tertiary.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (episode.episode.filler == true) ...[
                        _buildDot(theme),
                        Text(
                          'Filler',
                          style: TextStyle(
                            color: theme.secondary.withOpacity(0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (isWatched) ...[
                        _buildDot(theme),
                        Text(
                          'Watched',
                          style: TextStyle(
                            color: theme.tertiary.withOpacity(0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (timeLeft != null) ...[
                        _buildDot(theme),
                        Text(
                          timeLeft,
                          style: TextStyle(
                            color: theme.primary.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (episode.episode.desc != null &&
                      episode.episode.desc!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      episode.episode.desc!,
                      style: TextStyle(
                        color: theme.onSurface.withOpacity(0.3),
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTinyBtn(
                  theme: theme,
                  icon: Icons.play_arrow_rounded,
                  color: theme.primary,
                  onTap: onPlay,
                ),
                const SizedBox(height: 5),
                _buildTinyBtn(
                  theme: theme,
                  icon: Icons.delete_outline_rounded,
                  color: theme.error.withOpacity(0.7),
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
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
    return AnymexOnTap(
      onTap: onPlay,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 52,
              decoration: BoxDecoration(
                color: theme.surfaceContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  HugeIcons.strokeRoundedBook02,
                  size: 24,
                  color: theme.primary.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chapter.displayTitle,
                    style: TextStyle(
                      color: theme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        relativeTime,
                        style: TextStyle(
                          color: theme.onSurface.withOpacity(0.28),
                          fontSize: 11,
                        ),
                      ),
                      _buildDot(theme),
                      Text(
                        '${chapter.pageCount} pages',
                        style: TextStyle(
                          color: theme.tertiary.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTinyBtn(
                  theme: theme,
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  color: theme.primary,
                  onTap: onPlay,
                ),
                const SizedBox(height: 5),
                _buildTinyBtn(
                  theme: theme,
                  icon: Icons.delete_outline_rounded,
                  color: theme.error.withOpacity(0.7),
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(ColorScheme theme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text(
          '·',
          style: TextStyle(
            color: theme.onSurface.withOpacity(0.25),
            fontSize: 13,
          ),
        ),
      );

  Widget _buildTinyBtn({
    required ColorScheme theme,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnymexOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
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
            Text(
              'Nothing downloaded yet',
              style: TextStyle(
                color: theme.onSurface.withOpacity(0.5),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
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
                Text(
                  label,
                  style: TextStyle(
                    color: theme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
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
