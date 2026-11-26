import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/models/Anilist/story_group.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex/screens/anime/widgets/stories/controller/stories_controller.dart';
import 'package:anymex/screens/anime/widgets/stories/widgets/story_progress_bar.dart';
import 'package:anymex/screens/profile/activity_details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart' hide formatTimeAgo;
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  const StoryViewer({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late final PageController _pageController;
  late int _currentGroupIndex;
  double _dragY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _pageController = PageController(initialPage: widget.initialGroupIndex);
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onGroupFinished(int groupIndex) {
    if (groupIndex < widget.groups.length - 1) {
      _pageController.animateToPage(
        groupIndex + 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _onGroupBack(int groupIndex) {
    if (groupIndex > 0) {
      _pageController.animateToPage(
        groupIndex - 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final progress = (_dragY / (size.height * 0.45)).clamp(0.0, 1.0);

    return AnymeXScaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) => setState(() => _isDragging = true),
        onVerticalDragUpdate: (d) => setState(
          () => _dragY = math.max(0.0, _dragY + d.delta.dy),
        ),
        onVerticalDragEnd: (d) {
          final fling = (d.primaryVelocity ?? 0) > 600;
          if (fling || _dragY > size.height * 0.2) {
            Navigator.of(context).maybePop();
          } else {
            setState(() {
              _dragY = 0.0;
              _isDragging = false;
            });
          }
        },
        child: AnimatedContainer(
          duration: _isDragging && _dragY > 0
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _dragY, 0.0)
            ..scale(1 - progress * 0.18, 1 - progress * 0.18, 1.0),
          transformAlignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(progress * 28),
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.groups.length,
              onPageChanged: (i) {
                setState(() => _currentGroupIndex = i);
              },
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    final page = _pageController.hasClients &&
                            _pageController.position.haveDimensions
                        ? _pageController.page ?? _currentGroupIndex.toDouble()
                        : _currentGroupIndex.toDouble();
                    final delta = (page - i).clamp(-1.0, 1.0);

                    return Opacity(
                      opacity: (1 - delta.abs() * 0.4).clamp(0.0, 1.0),
                      child: Transform(
                        alignment: delta > 0
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(-delta * 0.55),
                        child: child,
                      ),
                    );
                  },
                  child: _StoryGroupView(
                    key: ValueKey(widget.groups[i].user.id),
                    group: widget.groups[i],
                    isActive: i == _currentGroupIndex,
                    onFinished: () => _onGroupFinished(i),
                    onBack: () => _onGroupBack(i),
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryGroupView extends StatefulWidget {
  final StoryGroup group;
  final bool isActive;
  final VoidCallback onFinished;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _StoryGroupView({
    super.key,
    required this.group,
    required this.isActive,
    required this.onFinished,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<_StoryGroupView> createState() => _StoryGroupViewState();
}

class _StoryGroupViewState extends State<_StoryGroupView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer;
  int _currentIndex = 0;
  bool _isHeld = false;
  bool _showHeart = false;
  Timer? _heartTimer;

  List<AnilistActivity> get _items => widget.group.activities;
  AnilistActivity get _currentActivity => _items[_currentIndex];

  @override
  void initState() {
    super.initState();
    final firstUnseen =
        _items.indexWhere((a) => !StorySeenManager.isSeen(a.id));
    _currentIndex = firstUnseen >= 0 ? firstUnseen : 0;

    _timer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener(_onTimerStatus);

    if (widget.isActive) {
      _startCurrent();
    }
  }

  @override
  void didUpdateWidget(_StoryGroupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startCurrent();
    } else if (!widget.isActive && oldWidget.isActive) {
      _timer.stop();
    }
  }

  @override
  void dispose() {
    _heartTimer?.cancel();
    _timer.dispose();
    super.dispose();
  }

  void _startCurrent() {
    if (_items.isEmpty) return;
    StorySeenManager.markSeen(_currentActivity.id);
    _timer
      ..stop()
      ..value = 0.0;
    if (!_isHeld) {
      _timer.forward();
    }
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.isActive) {
      _next();
    }
  }

  void _next() {
    if (_currentIndex < _items.length - 1) {
      setState(() => _currentIndex++);
      _startCurrent();
    } else {
      widget.onFinished();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startCurrent();
    } else {
      widget.onBack();
    }
  }

  void _hold() {
    _isHeld = true;
    _timer.stop();
    setState(() {});
  }

  void _release() {
    _isHeld = false;
    if (!mounted) return;
    if (widget.isActive && !_timer.isCompleted) {
      _timer.forward();
    }
    setState(() {});
  }

  void _toggleLike(AnilistActivity activity) {
    final controller = Get.find<StoriesController>();
    controller.toggleLike(activity);
    final isNowLiked = activity.isLiked;
    setState(() {
      if (isNowLiked) {
        _showHeart = true;
      }
    });
    HapticFeedback.lightImpact();
    if (isNowLiked) {
      _heartTimer?.cancel();
      _heartTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showHeart = false);
      });
    }
  }

  void _onDoubleTap() {
    if (_currentActivity.isLiked) {
      setState(() => _showHeart = true);
      HapticFeedback.lightImpact();
      _heartTimer?.cancel();
      _heartTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showHeart = false);
      });
      return;
    }
    _toggleLike(_currentActivity);
  }

  void _openDetails(AnilistActivity activity) {
    _hold();
    if (activity.mediaId != null) {
      final isManga = activity.type == 'MANGA_LIST';
      final fallbackTitle = isManga ? context.l10n.manga : context.l10n.anime;
      final media = Media(
        id: activity.mediaId.toString(),
        title: activity.mediaTitle ?? fallbackTitle,
        romajiTitle: activity.mediaTitle ?? fallbackTitle,
        poster: activity.mediaCoverUrl ?? '',
        cover: activity.mediaBannerUrl,
        serviceType: ServicesType.anilist,
        type: isManga ? 'MANGA' : 'ANIME',
      );

      navigate(() => MediaDetailsPage(
            media: media,
            tag: 'story_${activity.id}',
          )).then((_) => _release());
    } else {
      showActivityDetailsSheet(context, activity).then((_) => _release());
    }
  }

  (IconData, String) _getStatusInfo(AnilistActivity activity) {
    final status = activity.status?.toLowerCase() ?? '';
    if (status.contains('completed')) {
      return (Icons.check_rounded, context.l10n.detailsCompleted);
    } else if (status.contains('watched') || status.contains('read')) {
      final p = activity.progress;
      final label = p != null && p.isNotEmpty
          ? (activity.type == 'MANGA_LIST'
              ? context.l10n.readChapter(p)
              : context.l10n.watchedEpisode(p))
          : context.l10n.watched;
      return (Icons.play_arrow_rounded, label);
    } else if (status.contains('plan')) {
      return (Icons.bookmark_border_rounded, context.l10n.planning);
    } else if (status.contains('drop')) {
      return (Icons.close_rounded, context.l10n.libraryDropped);
    } else if (status.contains('pause')) {
      return (Icons.pause_rounded, context.l10n.downloadsPaused);
    } else if (status.contains('rewatch') || status.contains('reread')) {
      return (Icons.refresh_rounded, context.l10n.rewatching);
    }
    final raw = activity.status;
    if (raw != null && raw.isNotEmpty) {
      return (
        Icons.play_arrow_rounded,
        '${raw[0].toUpperCase()}${raw.substring(1)}'
      );
    }
    return (
      Icons.article_rounded,
      activity.type == 'TEXT' ? context.l10n.statusUpdate : context.l10n.activity
    );
  }

  Widget _buildTopProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StoryProgressBar(
        count: _items.length,
        currentIndex: _currentIndex,
        progress: _timer,
      ),
    );
  }

  Widget _buildHeader(AnilistActivity activity) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _hold();
              navigate(() => UserProfilePage(userId: widget.group.user.id))
                  .then((_) => _release());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: widget.group.user.avatarUrl != null &&
                        widget.group.user.avatarUrl!.isNotEmpty
                    ? AnymeXImage(
                        imageUrl: widget.group.user.avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: colors.surfaceContainerHighest,
                        child: Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: colors.onSurface,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _hold();
                navigate(() => UserProfilePage(userId: widget.group.user.id))
                    .then((_) => _release());
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnymeXText(
                    widget.group.user.name,
                    size: 15,
                    variant: TextVariant.bold,
                    color: colors.onSurface,
                  ),
                  const SizedBox(height: 2),
                  AnymeXText(
                    '${formatTimeAgo(activity.createdAt)} · ${context.l10n.anilistActivity}',
                    size: 12,
                    variant: TextVariant.semiBold,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _isHeld ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.onSurface,
                    size: 22,
                  ),
                  onPressed: () {
                    _hold();
                    showActivityDetailsSheet(context, activity)
                        .then((_) => _release());
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.onSurface,
                    size: 24,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterCard(AnilistActivity activity) {
    final colors = context.colors;
    final isMedia = activity.mediaId != null ||
        (activity.mediaCoverUrl != null && activity.mediaCoverUrl!.isNotEmpty);
    final statusInfo = _getStatusInfo(activity);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _next,
      onLongPressStart: (_) => _hold(),
      onLongPressEnd: (_) => _release(),
      onLongPressCancel: () => _release(),
      onDoubleTap: _onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceContainer.opaque(0.55, iReallyMeanIt: true),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(36),
              bottomLeft: Radius.circular(16),
            ),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo.$1,
                        size: 14,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo.$2,
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (isMedia) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(28),
                      bottomLeft: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(28),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: AspectRatio(
                      aspectRatio: 206 / 290,
                      child: AnymeXImage(
                        imageUrl: activity.mediaCoverUrl ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnymeXText(
                  activity.mediaTitle ??
                      (activity.type == 'MANGA_LIST'
                          ? context.l10n.manga
                          : context.l10n.anime),
                  size: 18,
                  variant: TextVariant.bold,
                  color: colors.onSurface,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          activity.progress != null &&
                                  activity.progress!.isNotEmpty
                              ? (activity.progress!.toLowerCase().contains('ep')
                                  ? activity.progress!
                                  : '${activity.progress} ${activity.type == 'MANGA_LIST' ? context.l10n.chapters.toLowerCase() : context.l10n.episodes.toLowerCase()}')
                              : (activity.type == 'MANGA_LIST'
                                  ? context.l10n.manga
                                  : context.l10n.anime),
                          style: TextStyle(
                            color: colors.onSecondaryContainer,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activity.likeCount > 0
                                ? Icons.favorite_rounded
                                : Icons.star_rounded,
                            size: 13,
                            color: colors.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activity.likeCount > 0
                                ? context.l10n.likesCount(activity.likeCount.toString())
                                : (activity.type == 'MANGA_LIST'
                                    ? context.l10n.manga
                                    : context.l10n.anime),
                            style: TextStyle(
                              color: colors.onTertiaryContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 32,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        activity.displayText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(AnilistActivity activity) {
    final colors = context.colors;
    final isMedia = activity.mediaId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () => _openDetails(activity),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: const StadiumBorder(),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(
                isMedia ? Icons.play_arrow_rounded : Icons.forum_rounded,
                size: 20,
                color: colors.onPrimary,
              ),
              label: Text(
                isMedia ? context.l10n.viewInAnymex : context.l10n.viewDiscussion,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _hold();
                    showActivityDetailsSheet(context, activity)
                        .then((_) => _release());
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.replyCount > 0
                                ? context.l10n.repliesCount(activity.replyCount.toString())
                                : context.l10n.sendAReaction,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleLike(activity),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activity.isLiked
                        ? colors.errorContainer
                        : colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      activity.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: activity.isLiked
                          ? colors.error
                          : colors.onTertiaryContainer,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'https://anilist.co/activity/${activity.id}',
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: colors.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      12.0,
    );
    final activity = _currentActivity;

    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _previous,
                  onLongPressStart: (_) => _hold(),
                  onLongPressEnd: (_) => _release(),
                  onLongPressCancel: () => _release(),
                  onDoubleTap: _onDoubleTap,
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _next,
                  onLongPressStart: (_) => _hold(),
                  onLongPressEnd: (_) => _release(),
                  onLongPressCancel: () => _release(),
                  onDoubleTap: _onDoubleTap,
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: EdgeInsets.only(
                  top: topInset + 6,
                  bottom: bottomInset,
                ),
                child: Column(
                  children: [
                    _buildTopProgress(),
                    const SizedBox(height: 10),
                    _buildHeader(activity),
                    const Spacer(),
                    _buildCenterCard(activity),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _isHeld ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: _buildBottomActions(activity),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showHeart)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: context.colors.error.withValues(alpha: 0.9),
                    size: 96,
                    shadows: [
                      BoxShadow(
                        color: context.colors.shadow.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
