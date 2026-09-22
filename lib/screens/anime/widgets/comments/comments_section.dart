import 'package:anymex/database/comments/model/commentum_role.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/mention_autocomplete.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/moderation_action_sheet.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/policy_sheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/linked_accounts_badges.dart';
import 'package:anymex/widgets/anymex_widgets/discord_badge_widget.dart';
import 'package:anymex/widgets/non_widgets/activity_composer_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/comments_replies_sheet.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/user_comments_sheet.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/leaderboard_sheet.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';

class CommentSection extends StatefulWidget {
  final Media media;
  final String? scrollToCommentId;
  final bool showInlineInput;
  final bool showHeader;

  const CommentSection({
    super.key,
    required this.media,
    this.scrollToCommentId,
    this.showInlineInput = true,
    this.showHeader = true,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late CommentSectionController controller;
  String? lastMediaId;

  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, FocusNode> _replyFocusNodes = {};
  final Map<String, int> _visibleReplyCount = {};
  final Set<String> _collapsedThreads = <String>{};
  final GlobalKey _targetCommentKey = GlobalKey();
  bool _hasScrolledToTarget = false;

  /// The comments list renders with shrinkWrap + NeverScrollableScrollPhysics
  /// inside the page's CustomScrollView, so scroll notifications never reach
  /// the NotificationListener in build() — they bubble upward from the
  /// scrollable, away from its children. Load-more therefore has to observe
  /// the nearest ancestor Scrollable's position directly.
  ScrollPosition? _ancestorScrollPosition;

  @override
  void initState() {
    super.initState();
    lastMediaId = widget.media.uniqueId;

    final preloadedController =
        CommentPreloader.to.getPreloadedController(widget.media.uniqueId);
    if (preloadedController != null) {
      controller = preloadedController;
    } else {
      controller = Get.put(CommentSectionController(media: widget.media),
          tag: widget.media.uniqueId);
    }

    _setupScrollToComment();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachAncestorScrollListener();
  }

  void _attachAncestorScrollListener() {
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _ancestorScrollPosition)) return;
    _ancestorScrollPosition?.removeListener(_onAncestorScroll);
    _ancestorScrollPosition = position;
    position?.addListener(_onAncestorScroll);
  }

  void _onAncestorScroll() {
    final position = _ancestorScrollPosition;
    if (position == null) return;
    if (position.extentAfter < 350 &&
        !controller.isLoadingMore.value &&
        controller.hasMore.value &&
        !controller.isLoading.value) {
      controller.loadMoreComments();
    }
  }

  /// After comments load, scroll to the target comment if specified
  void _setupScrollToComment() {
    if (widget.scrollToCommentId == null || widget.scrollToCommentId!.isEmpty) {
      return;
    }

    ever(controller.isLoading, (isLoading) {
      if (!isLoading &&
          !_hasScrolledToTarget &&
          controller.comments.isNotEmpty) {
        final targetId = widget.scrollToCommentId!;
        final root = _findRootThreadOfComment(targetId, controller.comments);

        // Redesigned UI: depth-1+ replies render inside the replies sheet, so
        // the inline target key can never mount for them — open the thread
        // sheet directly instead of scrolling.
        if (root != null && root.id != targetId) {
          _hasScrolledToTarget = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            CommentsRepliesSheet.show(
              context,
              rootComment: root,
              controller: controller,
              onShowContextMenu: (target) {
                final isOwnComment =
                    target.userId == controller.profile.id?.toString();
                _showCommentContextMenu(context, target, controller,
                    isOwnComment, controller.canModerate());
              },
            );
          });
          return;
        }

        // Auto-expand any collapsed threads that contain the target comment
        _expandThreadForComment(targetId, controller.comments);

        // Wait for the widget tree to rebuild with expanded threads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTargetComment();
        });
      }
    });
  }

  /// Recursively find and expand collapsed threads containing the target comment
  void _expandThreadForComment(String targetId, List<Comment> comments,
      {int depth = 0}) {
    for (final comment in comments) {
      if (comment.id == targetId) return;
      if (comment.replies != null && comment.replies!.isNotEmpty) {
        if (_commentExistsInTree(comment.replies!, targetId)) {
          if (depth >= 3 ||
              _wouldBeCollapsed(comment.replies!, targetId, depth + 1)) {
            setState(() {
              _visibleReplyCount[comment.id] = 3;
            });
          }
          _expandThreadForComment(targetId, comment.replies!, depth: depth + 1);
        }
      }
    }
  }

  bool _commentExistsInTree(List<Comment> comments, String targetId) {
    for (final comment in comments) {
      if (comment.id == targetId) {
        return true;
      }
      if (comment.replies != null &&
          _commentExistsInTree(comment.replies!, targetId)) {
        return true;
      }
    }
    return false;
  }

  /// Returns the top-level comment that contains [targetId] in its reply
  /// tree, or the comment itself when it is top-level. Null when the target
  /// is not present in the currently loaded comments.
  Comment? _findRootThreadOfComment(String targetId, List<Comment> comments) {
    for (final comment in comments) {
      if (comment.id == targetId) return comment;
      if (_commentExistsInTree(comment.replies ?? [], targetId)) {
        return comment;
      }
    }
    return null;
  }

  bool _wouldBeCollapsed(List<Comment> comments, String targetId, int depth) {
    for (final comment in comments) {
      if (comment.id == targetId) {
        // This comment is at depth+1 relative to the current check
        // It would be collapsed if its depth >= 3
        return depth >= 3;
      }
      if (comment.replies != null) {
        if (_commentExistsInTree(comment.replies!, targetId)) {
          return _wouldBeCollapsed(comment.replies!, targetId, depth + 1);
        }
      }
    }
    return false;
  }

  void _scrollToTargetComment() {
    if (_hasScrolledToTarget) return;
    final keyContext = _targetCommentKey.currentContext;
    if (keyContext != null) {
      _hasScrolledToTarget = true;
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  @override
  void didUpdateWidget(CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.media.uniqueId != oldWidget.media.uniqueId) {
      final wasPreloaded =
          CommentPreloader.to.isPreloaded(oldWidget.media.uniqueId);
      if (!wasPreloaded) {
        Get.delete<CommentSectionController>(tag: oldWidget.media.uniqueId);
      }

      final preloadedController =
          CommentPreloader.to.getPreloadedController(widget.media.uniqueId);
      if (preloadedController != null) {
        controller = preloadedController;
      } else {
        controller = Get.put(CommentSectionController(media: widget.media),
            tag: widget.media.uniqueId);
      }
    }
  }

  FocusNode _getReplyFocusNode(String commentId) {
    return _replyFocusNodes.putIfAbsent(commentId, () => FocusNode());
  }

  @override
  void dispose() {
    _ancestorScrollPosition?.removeListener(_onAncestorScroll);
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    for (final f in _replyFocusNodes.values) {
      f.dispose();
    }
    _replyControllers.clear();
    _replyFocusNodes.clear();
    final isPreloaded = CommentPreloader.to.isPreloaded(widget.media.uniqueId);
    if (!isPreloaded) {
      Get.delete<CommentSectionController>(tag: widget.media.uniqueId);
    }
    super.dispose();
  }

  TextEditingController _getReplyController(String commentId) {
    return _replyControllers.putIfAbsent(
        commentId, () => TextEditingController());
  }

  void _handlePostComment() {
    final bool hasAccepted = General.hasAcceptedCommentRules.get<bool>(false);

    if (hasAccepted) {
      controller.addComment();
    } else {
      _showRulesAcceptanceDialog();
    }
  }

  void _showRulesAcceptanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const AnymeXText('Comment Policy', maxLines: null),
        content: const AnymeXText(
          'To maintain a safe and friendly community, please read and accept our comment policy before posting.\n\nWe do not tolerate spam, harassment, or offensive content.',
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showPolicySheet(context, PolicyType.commentRules);
            },
            child: const AnymeXText('Read Full Rules', maxLines: null),
          ),
          FilledButton(
            onPressed: () {
              General.hasAcceptedCommentRules.set(true);
              Navigator.pop(context);
              controller.addComment();
            },
            child: const AnymeXText('Accept & Post', maxLines: null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 350 &&
            !controller.isLoadingMore.value &&
            controller.hasMore.value &&
            !controller.isLoading.value) {
          controller.loadMoreComments();
        }
        return false;
      },
      child: AnymeXContainer(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.opaque(0.05, iReallyMeanIt: true),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) _buildHeader(context, controller),
            if (widget.showInlineInput) ...[
              if (controller.isLoggedIn)
                _buildCommentInput(context, controller)
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: controller.commentFocusNode.hasFocus
                          ? colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                          : colorScheme.outlineVariant
                              .opaque(0.3, iReallyMeanIt: true),
                      width: 1.5,
                    ),
                    boxShadow: controller.commentFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: colorScheme.primary
                                  .opaque(0.1, iReallyMeanIt: true),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: AnymeXText(
                    'You need to be logged in to comment.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: null,
                  ),
                ),
            ],
            const SizedBox(height: 8),
            _buildCommentsList(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() => AnymeXContainer(
          padding: const EdgeInsets.fromLTRB(24, 28, 16, 20),
          color: colorScheme.surfaceContainer.opaque(0.3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnymeXText(
                      'Comments',
                      variant: TextVariant.semiBold,
                      color: colorScheme.onSurface,
                      size: 24,
                      autoResize: true,
                      maxLines: 1,
                    ),
                  ),
                  if (widget.showInlineInput) ...[
                    _buildSortChip(context, controller),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => LeaderboardSheet.show(context),
                        icon: Icon(
                          Icons.emoji_events_outlined,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        tooltip: 'Leaderboard',
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            showPolicySheet(context, PolicyType.commentRules),
                        icon: Icon(
                          Icons.assignment_outlined,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                        tooltip: 'Comment Rules',
                      ),
                    ),
                    Obx(() => SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: controller.isRefreshing.value
                                ? null
                                : () => controller.forceRefresh(),
                            icon: controller.isRefreshing.value
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            tooltip: 'Refresh comments',
                          ),
                        )),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              AnymeXText(
                controller.totalCommentsCount.value > 0
                    ? '${controller.totalCommentsCount.value} comments'
                    : _getTotalCommentCount(controller.comments),
                color: colorScheme.onSurfaceVariant,
                size: 13,
                autoResize: true,
                maxLines: 1,
              ),
            ],
          ),
        ));
  }

  Widget _buildSortChip(
      BuildContext context, CommentSectionController controller) {
    final colorScheme = context.colors;
    final sortOptions = [
      ('newest', 'Newest'),
      ('oldest', 'Oldest'),
      ('top', 'Top'),
      ('controversial', 'Controversial'),
    ];

    return PopupMenuButton<String>(
      onSelected: (sort) => controller.setSort(sort),
      child: AnymeXContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(left: 4),
        color: colorScheme.surfaceContainer.opaque(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.opaque(0.3),
        ),
        child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                AnymeXText(
                  sortOptions
                      .firstWhere((s) => s.$1 == controller.currentSort.value)
                      .$2,
                  color: colorScheme.onSurfaceVariant,
                  size: 12,
                  variant: TextVariant.semiBold,
                  maxLines: null,
                ),
                Icon(Icons.arrow_drop_down_rounded,
                    size: 16, color: colorScheme.onSurfaceVariant),
              ],
            )),
      ),
      itemBuilder: (context) => sortOptions
          .map((s) => PopupMenuItem(
                value: s.$1,
                child: Row(
                  children: [
                    if (controller.currentSort.value == s.$1)
                      Icon(Icons.check_rounded,
                          size: 18, color: colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    AnymeXText(s.$2, maxLines: null),
                  ],
                ),
              ))
          .toList(),
    );
  }

  final Map<String, LayerLink> _mentionLayerLinks = {};
  LayerLink _getMentionLayerLink(String key) {
    return _mentionLayerLinks.putIfAbsent(key, () => LayerLink());
  }

  List<Map<String, dynamic>> _extractLocalUsers(List<Comment> comments) {
    final list = <Map<String, dynamic>>[];
    final seen = <String>{};

    void extract(Comment c) {
      final name = c.username.trim();
      if (!c.deleted &&
          name.isNotEmpty &&
          name.toLowerCase() != '[deleted]' &&
          seen.add(name.toLowerCase())) {
        list.add({
          'username': name,
          'avatar': c.avatarUrl,
          'avatar_decoration': c.avatarDecoration,
        });
      }
      if (c.replies != null && c.replies!.isNotEmpty) {
        for (final reply in c.replies!) {
          extract(reply);
        }
      }
    }

    for (final c in comments) {
      extract(c);
    }
    return list;
  }

  Widget _buildCommentInput(
      BuildContext context, CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _getMentionLayerLink('main'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.commentFocusNode.hasFocus
                        ? colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                        : colorScheme.outlineVariant
                            .opaque(0.3, iReallyMeanIt: true),
                    width: 1.5,
                  ),
                  boxShadow: controller.commentFocusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: colorScheme.primary
                                .opaque(0.1, iReallyMeanIt: true),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildUserAvatar(colorScheme, controller),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnymeXContainer(
                            height: 50,
                            clipBehavior: Clip.antiAlias,
                            color: colorScheme.surface
                                .opaque(0.3, iReallyMeanIt: true),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .opaque(0.2, iReallyMeanIt: true),
                              width: 1,
                            ),
                            child: TextField(
                              controller: controller.commentController,
                              focusNode: controller.commentFocusNode,
                              inputFormatters: [MarkdownListInputFormatter()],
                              maxLines:
                                  controller.isInputExpanded.value ? 5 : 1,
                              minLines: 1,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                  hintText: 'What\'s on your mind?',
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .opaque(0.6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.transparent),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (controller.isInputExpanded.value) ...[
                      const SizedBox(height: 16),
                      Divider(
                        color: colorScheme.outlineVariant.opaque(0.3),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      MarkdownFormattingToolbar(
                        controller: controller.commentController,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                      _buildTagSelector(context, controller),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: controller.clearInputs,
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const AnymeXText(
                              'Cancel',
                              variant: TextVariant.semiBold,
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Obx(() {
                            return FilledButton(
                              onPressed: controller.isSubmitting.value ||
                                      controller.tag.value.isEmpty ||
                                      controller.commentContent.value.isEmpty
                                  ? null
                                  : () => _handlePostComment(),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                disabledBackgroundColor:
                                    colorScheme.surfaceContainerHigh,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isSubmitting.value
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: ExpressiveLoadingIndicator(),
                                    )
                                  : const AnymeXText(
                                      'Post',
                                      variant: TextVariant.bold,
                                      size: 15,
                                      maxLines: null,
                                    ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            MentionAutocomplete(
              controller: controller.commentController,
              layerLink: _getMentionLayerLink('main'),
              focusNode: controller.commentFocusNode,
              localUsers: _extractLocalUsers(controller.comments),
            ),
          ],
        ));
  }

  Widget _buildTagSelector(
      BuildContext context, CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final quickTags = ['General', 'Spoiler', 'Theory', 'Review'];

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            'Tag',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: null,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickTags.map((t) {
              final isSelected = controller.tag.value == t;
              return InkWell(
                onTap: () {
                  controller.tag.value = t;
                  controller.tagController.value.text = t;
                },
                borderRadius: BorderRadius.circular(10),
                child: AnymeXContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: isSelected
                      ? colorScheme.primary.opaque(0.15, iReallyMeanIt: true)
                      : colorScheme.surfaceContainerLow.opaque(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary.opaque(0.4)
                        : colorScheme.outlineVariant.opaque(0.2),
                    width: 1.5,
                  ),
                  child: AnymeXText(
                    t,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    size: 13,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.tagController.value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Or type custom tag...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.opaque(0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.opaque(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.opaque(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.opaque(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary.opaque(0.5),
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildUserAvatar(
      ColorScheme colorScheme, CommentSectionController controller) {
    final deco = Get.isRegistered<CommentumService>()
        ? Get.find<CommentumService>().currentUserDecoration.value
        : null;
    return AnymeXDecoratedAvatar(
      avatarUrl: controller.profile.avatar,
      decorationUrl: (deco?.isNotEmpty == true) ? deco : null,
      size: 40,
    );
  }

  Widget _buildCommentsList(
      BuildContext context, CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(60),
          child: Center(
            child: Column(
              children: [
                ExpressiveLoadingIndicator(
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 20),
                AnymeXText(
                  'Loading comments...',
                  color: colorScheme.onSurfaceVariant,
                  size: 16,
                  variant: TextVariant.semiBold,
                  maxLines: null,
                ),
              ],
            ),
          ),
        );
      }

      if (controller.comments.isEmpty) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnymeXContainer(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              AnymeXText(
                'No comments yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: null,
              ),
              const SizedBox(height: 8),
              AnymeXText(
                'Start the conversation and share your thoughts!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: null,
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: controller.comments.length,
            separatorBuilder: (context, index) => AnymeXContainer(
              height: 1,
              margin: const EdgeInsets.only(left: 48, top: 16, bottom: 16),
              color: colorScheme.outlineVariant.opaque(0.15),
            ),
            itemBuilder: (context, index) {
              return _buildCommentWithReplies(
                  context, controller.comments[index], controller, 0,
                  isParentLocked: false);
            },
          ),
          Obx(() {
            if (controller.isLoadingMore.value) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnymeXText(
                        'Loading more comments...',
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!controller.hasMore.value && controller.comments.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnymeXContainer(
                        width: 32,
                        height: 1,
                        color: colorScheme.outlineVariant.opaque(0.25),
                      ),
                      const SizedBox(width: 10),
                      AnymeXText(
                        "You're all caught up",
                        size: 12,
                        color: colorScheme.onSurfaceVariant.opaque(0.6),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(width: 10),
                      AnymeXContainer(
                        width: 32,
                        height: 1,
                        color: colorScheme.outlineVariant.opaque(0.25),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      );
    });
  }

  String _getTotalCommentCount(List<Comment> comments) {
    int totalComments = comments.length;
    int totalReplies = 0;

    for (final comment in comments) {
      totalReplies += _countReplies(comment);
    }

    final total = totalComments + totalReplies;

    if (total == 1) {
      return '1 comment';
    } else if (totalReplies > 0) {
      return '$total ($totalReplies replies)';
    } else {
      return '$total';
    }
  }

  int _countReplies(Comment comment) {
    int replyCount = 0;

    if (comment.replies != null) {
      replyCount += comment.replies!.length;
      for (final reply in comment.replies!) {
        replyCount += _countReplies(reply);
      }
    }

    return replyCount;
  }

  bool _isTargetComment(String commentId) {
    return widget.scrollToCommentId != null &&
        widget.scrollToCommentId!.isNotEmpty &&
        commentId == widget.scrollToCommentId;
  }

  List<Comment> _flattenReplies(Comment comment) {
    final List<Comment> flat = [];
    if (comment.replies == null) return flat;
    for (final reply in comment.replies!) {
      flat.add(reply);
      flat.addAll(_flattenReplies(reply));
    }
    return flat;
  }

  String _formatTimestampShort(String isoString) {
    return CommentSectionController.formatCommentTimestamp(isoString);
  }

  Widget _buildCommentWithReplies(BuildContext context, Comment comment,
      CommentSectionController controller, int depth,
      {bool isParentLocked = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveLocked = comment.locked == true || isParentLocked;
    final isTarget = _isTargetComment(comment.id);

    // Deleted comments render statically (avoiding Obx with zero subscriptions).
    // If they have replies, the replies section is preserved so users can open the thread.
    if (comment.deleted) {
      final hasReplies = comment.replies != null && comment.replies!.isNotEmpty;
      return Column(
        key: isTarget ? _targetCommentKey : null,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTarget)
            AnymeXContainer(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: colorScheme.primary.opaque(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.opaque(0.3),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  AnymeXText(
                    'Notification Target',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: null,
                  ),
                ],
              ),
            ),
          if (comment.pinned == true && depth == 0)
            AnymeXContainer(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: colorScheme.primary.opaque(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.opaque(0.2),
              ),
              child: Row(
                children: [
                  Icon(Icons.push_pin_rounded,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  AnymeXText(
                    'Pinned',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: null,
                  ),
                ],
              ),
            ),
          _buildDeletedComment(context, comment, depth),
          if (hasReplies)
            _buildRepliesSection(context, comment, controller, effectiveLocked,
                depth: depth),
        ],
      );
    }

    return Obx(() => Column(
          key: isTarget ? _targetCommentKey : null,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTarget)
              AnymeXContainer(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: colorScheme.primary.opaque(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.opaque(0.3),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    AnymeXText(
                      'Notification Target',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            if (comment.pinned == true && depth == 0)
              AnymeXContainer(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: colorScheme.primary.opaque(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.opaque(0.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.push_pin_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    AnymeXText(
                      'Pinned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            _buildCommentItem(context, comment, controller,
                effectiveLocked: effectiveLocked, depth: depth),
            if (widget.showInlineInput &&
                controller.isReplyingTo(comment.id) &&
                !effectiveLocked) ...[
              const SizedBox(height: 8),
              _buildReplyInput(context, comment, controller, depth,
                  isParentLocked: isParentLocked),
            ],
            if (comment.replies != null && comment.replies!.isNotEmpty)
              _buildRepliesSection(
                  context, comment, controller, effectiveLocked),
          ],
        ));
  }

  Widget _buildRepliesSection(BuildContext context, Comment comment,
      CommentSectionController controller, bool effectiveLocked,
      {int depth = 0}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final replies = comment.replies ?? [];
    final totalReplies = _countReplies(comment);
    final isCollapsed = _collapsedThreads.contains(comment.id);

    if (replies.isEmpty) return const SizedBox.shrink();

    if (depth == 0) {
      return Padding(
        padding: const EdgeInsets.only(left: 46, top: 4),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            CommentsRepliesSheet.show(
              context,
              rootComment: comment,
              controller: controller,
              onShowContextMenu: (target) {
                final isOwnComment =
                    target.userId == controller.profile.id?.toString();
                _showCommentContextMenu(context, target, controller,
                    isOwnComment, controller.canModerate());
              },
            );
          },
          child: AnymeXContainer(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                AnymeXText(
                  '$totalReplies ${totalReplies == 1 ? "reply" : "replies"}',
                  size: 12,
                  variant: TextVariant.bold,
                  color: colorScheme.primary,
                  maxLines: null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.only(left: 14, top: 8),
        child: InkWell(
          onTap: () => setState(() => _collapsedThreads.remove(comment.id)),
          borderRadius: BorderRadius.circular(8),
          child: AnymeXContainer(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: colorScheme.surfaceContainerLow.opaque(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.opaque(0.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.unfold_more_rounded,
                    size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                AnymeXText(
                  '[+] $totalReplies replies collapsed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visibleCount = _visibleReplyCount[comment.id] ?? (depth >= 2 ? 2 : 4);
    final visibleReplies = replies.take(visibleCount).toList();
    final remainingCount = replies.length - visibleCount;

    // Indentation step clamped for deep nests to prevent narrow columns
    final indentLeft = depth >= 3 ? 4.0 : 10.0;

    return Padding(
      padding: EdgeInsets.only(left: indentLeft, top: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical thread connector line with tap-to-collapse
            GestureDetector(
              onTap: () => setState(() => _collapsedThreads.add(comment.id)),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 18,
                alignment: Alignment.center,
                child: AnymeXContainer(
                  width: 2,
                  color: colorScheme.primary.opaque(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...visibleReplies.map((reply) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCommentWithReplies(
                        context,
                        reply,
                        controller,
                        depth + 1,
                        isParentLocked: effectiveLocked,
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Row(
                      children: [
                        if (remainingCount > 0) ...[
                          InkWell(
                            onTap: () => setState(() {
                              _visibleReplyCount[comment.id] =
                                  (_visibleReplyCount[comment.id] ?? 4) + 4;
                            }),
                            borderRadius: BorderRadius.circular(8),
                            child: AnymeXContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              color:
                                  colorScheme.surfaceContainerLow.opaque(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outlineVariant.opaque(0.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnymeXText(
                                    'Show more replies ($remainingCount)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                    maxLines: null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        InkWell(
                          onTap: () =>
                              setState(() => _collapsedThreads.add(comment.id)),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove_circle_outline_rounded,
                                    size: 13,
                                    color: colorScheme.onSurfaceVariant
                                        .opaque(0.7)),
                                const SizedBox(width: 4),
                                AnymeXText(
                                  'Collapse',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .opaque(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _findParentUsername(Comment reply, Comment topLevelComment) {
    if (reply.parentId != null && topLevelComment.replies != null) {
      for (final r in topLevelComment.replies!) {
        if (r.id == reply.parentId.toString()) return r.username;
        if (r.replies != null) {
          for (final rr in r.replies!) {
            if (rr.id == reply.parentId.toString()) return rr.username;
          }
        }
      }
    }
    return topLevelComment.username;
  }

  String? _findParentRole(Comment reply, Comment topLevelComment) {
    if (reply.parentId != null && topLevelComment.replies != null) {
      for (final r in topLevelComment.replies!) {
        if (r.id == reply.parentId.toString()) return r.userRole;
        if (r.replies != null) {
          for (final rr in r.replies!) {
            if (rr.id == reply.parentId.toString()) return rr.userRole;
          }
        }
      }
    }
    return topLevelComment.userRole;
  }

  Widget _buildReplyItem(
      BuildContext context,
      Comment reply,
      CommentSectionController controller,
      String parentUsername,
      bool effectiveLocked,
      {int depth = 0,
      String? parentRole}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSpoiler = reply.tag.toLowerCase().contains('spoiler');
    final isLocked = reply.locked == true || effectiveLocked;
    final isOwnComment = reply.userId == controller.profile.id?.toString();
    final canModerate = controller.canModerate();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            final currentUserId =
                Get.find<ServiceHandler>().profileData.value.id;
            if (reply.userId == currentUserId) {
              navigate(() => const ProfilePage());
            } else {
              navigate(() =>
                  UserProfilePage(userId: int.tryParse(reply.userId) ?? 0));
            }
          },
          child: _buildCommentAvatar(context, reply, size: 28),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _showUserProfileSheet(context, reply),
                            child: AnymeXText(
                              reply.username,
                              color: reply.userRole != null &&
                                      reply.userRole != 'user'
                                  ? _getRoleColor(reply.userRole!)
                                  : colorScheme.onSurface,
                              size: 13,
                              variant: TextVariant.bold,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        if ((reply.badges != null &&
                            reply.badges!.isNotEmpty) ||
                            (reply.userRole != null &&
                            reply.userRole != 'user')) ...[
                          const SizedBox(width: 4),
                          DiscordBadgesRow(
                            badges: reply.badges,
                            role: reply.userRole,
                            size: 13.0,
                          ),
                        ],
                        Icon(Icons.arrow_right,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: AnymeXText(
                            parentUsername,
                            color: parentRole != null && parentRole != 'user'
                                ? _getRoleColor(parentRole)
                                : colorScheme.primary,
                            size: 13,
                            variant: TextVariant.bold,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (reply.edited == true) ...[
                          const SizedBox(width: 4),
                          AnymeXText(
                            '(edited)',
                            color: colorScheme.onSurfaceVariant.opaque(0.6),
                            size: 10,
                            fontStyle: FontStyle.italic,
                            maxLines: 1,
                          ),
                        ],
                        const SizedBox(width: 6),
                        AnymeXText(
                          _formatTimestampShort(reply.createdAt),
                          size: 11,
                          color: colorScheme.onSurfaceVariant.opaque(0.6),
                          maxLines: 1,
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.lock_rounded,
                              size: 11, color: colorScheme.error),
                        ],
                      ],
                    ),
                  ),
                  if (reply.tag.isNotEmpty && reply.tag != 'General') ...[
                    const SizedBox(width: 8),
                    _buildTag(context, reply.tag),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onLongPress: () => _showCommentContextMenu(
                    context, reply, controller, isOwnComment, canModerate),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SpoilerText(
                      text: reply.commentText,
                      isSpoiler: isSpoiler,
                      theme: theme,
                      colorScheme: colorScheme,
                      fontSize: 13,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (!isLocked) ...[
                          GestureDetector(
                            onTap: () {
                              if (!widget.showInlineInput) {
                                HapticFeedback.lightImpact();
                                controller.setReplyTarget(reply);
                                controller.focusCommentInput();
                              } else {
                                controller.toggleReply(reply.id);
                              }
                            },
                            child: AnymeXText(
                              'Reply',
                              color: colorScheme.onSurfaceVariant,
                              size: 11,
                              variant: TextVariant.semiBold,
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Spacer(),
                        _buildCompactVoteButton(
                          context: context,
                          icon: Icons.arrow_upward_rounded,
                          count: reply.likes,
                          isActive: reply.userVote == 1,
                          onTap: () => controller.handleVote(reply, 1),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        _buildCompactVoteButton(
                          context: context,
                          icon: Icons.arrow_downward_rounded,
                          count: reply.dislikes,
                          isActive: reply.userVote == -1,
                          onTap: () => controller.handleVote(reply, -1),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showCommentContextMenu(context, reply,
                              controller, isOwnComment, canModerate),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant.opaque(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.showInlineInput &&
                  controller.isReplyingTo(reply.id) &&
                  !isLocked) ...[
                const SizedBox(height: 8),
                _buildReplyInput(context, reply, controller, depth,
                    isParentLocked: effectiveLocked),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyInput(BuildContext context, Comment comment,
      CommentSectionController controller, int depth,
      {bool isParentLocked = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final replyController = _getReplyController(comment.id);
    final replyFocusNode = _getReplyFocusNode(comment.id);
    final replyLayerLink = _getMentionLayerLink('reply_${comment.id}');

    if (comment.locked == true || isParentLocked) {
      return const SizedBox.shrink();
    }

    return StatefulBuilder(
      builder: (context, setReplyState) {
        final hasText = replyController.text.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: replyLayerLink,
              child: AnymeXContainer(
                margin: const EdgeInsets.only(left: 16, right: 16),
                padding: const EdgeInsets.all(12),
                color: colorScheme.surfaceContainerLowest.opaque(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                  width: 1.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        AnymeXText(
                          'Replying to ${comment.username}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: null,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            controller.toggleReply(comment.id);
                            replyController.clear();
                          },
                          child: Icon(Icons.close_rounded,
                              size: 18, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: replyController,
                      focusNode: replyFocusNode,
                      maxLines: 3,
                      minLines: 1,
                      inputFormatters: [MarkdownListInputFormatter()],
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (_) => setReplyState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.opaque(0.5),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.opaque(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.opaque(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary.opaque(0.5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Obx(() => FilledButton.tonal(
                              onPressed: controller.isSubmitting.value ||
                                      !hasText
                                  ? null
                                  : () {
                                      controller.addReply(
                                          comment, replyController.text.trim());
                                      replyController.clear();
                                      setReplyState(() {});
                                    },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: controller.isSubmitting.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: ExpressiveLoadingIndicator(),
                                    )
                                  : const AnymeXText(
                                      'Reply',
                                      variant: TextVariant.bold,
                                      size: 13,
                                      maxLines: null,
                                    ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            MentionAutocomplete(
              controller: replyController,
              layerLink: replyLayerLink,
              focusNode: replyFocusNode,
              localUsers: _extractLocalUsers(controller.comments),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment,
      CommentSectionController controller,
      {bool effectiveLocked = false, int depth = 0}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSpoiler = comment.tag.toLowerCase().contains('spoiler');
    final isOwnComment = comment.userId == controller.profile.id?.toString();
    final canModerate = controller.canModerate();
    final isLocked = comment.locked == true || effectiveLocked;

    final commentContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showUserProfileSheet(context, comment),
          child: _buildCommentAvatar(context, comment,
              size: depth == 0 ? 36.0 : (depth == 1 ? 28.0 : 22.0)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () =>
                                _showUserProfileSheet(context, comment),
                            child: AnymeXText(
                              comment.username,
                              color: comment.userRole != null &&
                                      comment.userRole != 'user'
                                  ? _getRoleColor(comment.userRole!)
                                  : colorScheme.onSurface,
                              size: depth == 0 ? 14 : 13,
                              variant: TextVariant.bold,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        if ((comment.badges != null &&
                            comment.badges!.isNotEmpty) ||
                            (comment.userRole != null &&
                            comment.userRole != 'user')) ...[
                          const SizedBox(width: 4),
                          DiscordBadgesRow(
                            badges: comment.badges,
                            role: comment.userRole,
                            size: depth == 0 ? 15.0 : 13.0,
                          ),
                        ],
                        if (comment.edited == true) ...[
                          const SizedBox(width: 4),
                          AnymeXText(
                            '(edited)',
                            color: colorScheme.onSurfaceVariant.opaque(0.6),
                            size: 10,
                            fontStyle: FontStyle.italic,
                            maxLines: 1,
                          ),
                        ],
                        const SizedBox(width: 6),
                        AnymeXText(
                          _formatTimestampShort(comment.createdAt),
                          size: 11,
                          color: colorScheme.onSurfaceVariant.opaque(0.6),
                          maxLines: 1,
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.lock_rounded,
                              size: 12, color: colorScheme.error),
                        ],
                      ],
                    ),
                  ),
                  if (comment.tag.isNotEmpty && comment.tag != 'General') ...[
                    const SizedBox(width: 8),
                    _buildTag(context, comment.tag),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onLongPress: () => _showCommentContextMenu(
                    context, comment, controller, isOwnComment, canModerate),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SpoilerText(
                      text: comment.commentText,
                      isSpoiler: isSpoiler,
                      theme: theme,
                      colorScheme: colorScheme,
                      fontSize: 14,
                    ),
                    if (effectiveLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.lock_rounded,
                                size: 12, color: colorScheme.error),
                            const SizedBox(width: 4),
                            AnymeXText(
                              'Thread is locked',
                              color: colorScheme.error,
                              size: 11,
                              variant: TextVariant.semiBold,
                              maxLines: null,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (!effectiveLocked) ...[
                          GestureDetector(
                            onTap: () {
                              if (!widget.showInlineInput) {
                                HapticFeedback.lightImpact();
                                controller.setReplyTarget(comment);
                                controller.focusCommentInput();
                              } else {
                                controller.toggleReply(comment.id);
                              }
                            },
                            child: AnymeXText(
                              'Reply',
                              color: colorScheme.onSurfaceVariant,
                              size: 12,
                              variant: TextVariant.semiBold,
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        const Spacer(),
                        _buildCompactVoteButton(
                          context: context,
                          icon: Icons.arrow_upward_rounded,
                          count: comment.likes,
                          isActive: comment.userVote == 1,
                          onTap: () => controller.handleVote(comment, 1),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 10),
                        _buildCompactVoteButton(
                          context: context,
                          icon: Icons.arrow_downward_rounded,
                          count: comment.dislikes,
                          isActive: comment.userVote == -1,
                          onTap: () => controller.handleVote(comment, -1),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showCommentContextMenu(context, comment,
                              controller, isOwnComment, canModerate),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant.opaque(0.6),
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
      ],
    );

    final commentum = Get.isRegistered<CommentumService>()
        ? Get.find<CommentumService>()
        : null;
    final hasNameplate = (commentum?.renderNameplates.value ?? true) &&
        comment.nameplateTheme != null &&
        comment.nameplateTheme!.trim().isNotEmpty;

    if (hasNameplate) {
      String nameplateImg = comment.nameplateTheme!.trim();
      if (nameplateImg.endsWith('.webm')) {
        nameplateImg = nameplateImg
            .replaceAll('asset.webm', 'static.png')
            .replaceAll('.webm', '.png');
      }

      return AnymeXContainer(
        margin: const EdgeInsets.symmetric(vertical: 4),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: CachedNetworkImageProvider(nameplateImg),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 0.8,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          color: Colors.black.withOpacity(0.55),
          child: commentContent,
        ),
      );
    }

    return commentContent;
  }

  Widget _buildCompactVoteButton({
    required BuildContext context,
    required IconData icon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          AnymeXText(
            count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
            size: 12,
            variant: TextVariant.semiBold,
            color:
                isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            maxLines: null,
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedComment(
      BuildContext context, Comment comment, int depth) {
    final colorScheme = context.colors;
    final isCompact = depth >= 2;
    final avatarSize = isCompact ? 28.0 : 40.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 4.0 : 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest.opaque(0.4),
              border: Border.all(
                color: colorScheme.outlineVariant.opaque(0.2),
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: avatarSize * 0.5,
              color: colorScheme.onSurfaceVariant.opaque(0.5),
            ),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: AnymeXText(
              '[This comment was deleted]',
              color: colorScheme.onSurfaceVariant.opaque(0.5),
              size: isCompact ? 12.0 : 13.5,
              fontStyle: FontStyle.italic,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentAvatar(BuildContext context, Comment comment,
      {double size = 40}) {
    return AnymeXDecoratedAvatar(
      avatarUrl: comment.avatarUrl,
      decorationUrl: comment.avatarDecoration,
      size: size,
    );
  }

  Color _getRoleColor(String role) {
    return CommentumRoleConfig.getRoleColor(context, role);
  }

  void _showCommentContextMenu(
      BuildContext context,
      Comment comment,
      CommentSectionController controller,
      bool isOwnComment,
      bool canModerate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: AnymeXContainer(
              borderRadius: BorderRadius.circular(24),
              color: colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.2),
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: AnymeXContainer(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 36,
                      height: 4,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMenuOption(
                    context: context,
                    icon: Icons.copy_rounded,
                    label: 'Copy Comment',
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(
                          ClipboardData(text: comment.commentText));
                      snackBar('Comment copied to clipboard');
                    },
                  ),
                  if (isOwnComment) ...[
                    const SizedBox(height: 4),
                    _buildMenuOption(
                      context: context,
                      icon: Icons.edit_outlined,
                      label: 'Edit Comment',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showEditDialog(context, comment, controller);
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildMenuOption(
                      context: context,
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Comment',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDeleteDialog(context, comment, controller);
                      },
                    ),
                  ],
                  if (!isOwnComment) ...[
                    const SizedBox(height: 4),
                    _buildMenuOption(
                      context: context,
                      icon: Icons.flag_outlined,
                      label: 'Report Comment',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showReportDialog(context, comment, controller);
                      },
                    ),
                  ],
                  if (canModerate) ...[
                    const SizedBox(height: 8),
                    AnymeXContainer(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuOption(
                      context: context,
                      icon: Icons.shield_outlined,
                      label: 'Moderate',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showModerationSheet(context, comment, controller,
                            isOwnComment: isOwnComment);
                      },
                    ),
                    if (!isOwnComment) ...[
                      const SizedBox(height: 4),
                      _buildMenuOption(
                        context: context,
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'User Actions',
                        onTap: () {
                          Navigator.pop(ctx);
                          _showUserManagementSheet(
                              context, comment, controller);
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemColor = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnymeXContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderRadius: BorderRadius.circular(14),
          color: Colors.transparent,
          child: Row(
            children: [
              AnymeXContainer(
                width: 38,
                height: 38,
                borderRadius: BorderRadius.circular(10),
                color: isDestructive
                    ? colorScheme.error.withOpacity(0.12)
                    : colorScheme.primary.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnymeXText(
                  label,
                  color: itemColor,
                  size: 14,
                  variant: TextVariant.semiBold,
                  maxLines: null,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final TextEditingController editController =
        TextEditingController(text: comment.commentText);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnymeXContainer(
          borderRadius: BorderRadius.circular(24),
          color: colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnymeXContainer(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.primary.withOpacity(0.12),
                    child: Center(
                      child: Icon(Icons.edit_outlined,
                          color: colorScheme.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AnymeXText(
                      'Edit Comment',
                      size: 18,
                      variant: TextVariant.bold,
                      maxLines: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editController,
                maxLines: 5,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: 'Edit your comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: AnymeXText('Cancel',
                        color: colorScheme.onSurfaceVariant, maxLines: null),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (editController.text.trim().isNotEmpty) {
                        controller.editComment(
                            comment, editController.text.trim());
                        Navigator.pop(dialogCtx);
                      }
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const AnymeXText('Save', maxLines: null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnymeXContainer(
          borderRadius: BorderRadius.circular(24),
          color: colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnymeXContainer(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.error.withOpacity(0.12),
                    child: Center(
                      child: Icon(Icons.delete_outline_rounded,
                          color: colorScheme.error, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AnymeXText(
                      'Delete Comment',
                      size: 18,
                      variant: TextVariant.bold,
                      maxLines: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnymeXText(
                'Are you sure you want to delete this comment? This action cannot be undone.',
                color: colorScheme.onSurfaceVariant,
                size: 14,
                maxLines: null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: AnymeXText('Cancel',
                        color: colorScheme.onSurfaceVariant, maxLines: null),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      controller.deleteComment(comment);
                      Navigator.pop(dialogCtx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const AnymeXText('Delete', maxLines: null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnymeXContainer(
          borderRadius: BorderRadius.circular(24),
          color: colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnymeXContainer(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.error.withOpacity(0.12),
                    child: Center(
                      child: Icon(Icons.flag_outlined,
                          color: colorScheme.error, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AnymeXText(
                      'Report Comment',
                      size: 18,
                      variant: TextVariant.bold,
                      maxLines: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnymeXText(
                'Please select a reason for reporting this comment:',
                color: colorScheme.onSurfaceVariant,
                size: 14,
                maxLines: null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: reasonController.text.isEmpty
                    ? null
                    : reasonController.text,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'spam', child: AnymeXText('Spam', maxLines: null)),
                  DropdownMenuItem(
                      value: 'offensive',
                      child: AnymeXText('Offensive', maxLines: null)),
                  DropdownMenuItem(
                      value: 'harassment',
                      child: AnymeXText('Harassment', maxLines: null)),
                  DropdownMenuItem(
                      value: 'spoiler',
                      child: AnymeXText('Spoiler', maxLines: null)),
                  DropdownMenuItem(
                      value: 'nsfw', child: AnymeXText('NSFW', maxLines: null)),
                  DropdownMenuItem(
                      value: 'off_topic',
                      child: AnymeXText('Off-Topic', maxLines: null)),
                  DropdownMenuItem(
                      value: 'other',
                      child: AnymeXText('Other', maxLines: null)),
                ],
                onChanged: (value) {
                  reasonController.text = value ?? '';
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional notes (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: AnymeXText('Cancel',
                        color: colorScheme.onSurfaceVariant, maxLines: null),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (reasonController.text.trim().isNotEmpty) {
                        controller.reportComment(
                            comment, reasonController.text.trim(),
                            notes: notesController.text.trim());
                        Navigator.pop(dialogCtx);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const AnymeXText('Report', maxLines: null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModerationSheet(BuildContext context, Comment comment,
      CommentSectionController controller,
      {bool isOwnComment = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: AnymeXContainer(
                  width: 40,
                  height: 4,
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              AnymeXText(
                'Moderate Comment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: null,
              ),
              const SizedBox(height: 8),
              AnymeXContainer(
                padding: const EdgeInsets.all(12),
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                child: AnymeXText(
                  '"${comment.commentText}"',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              _buildModAction(
                context: context,
                icon: comment.pinned == true
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                label: comment.pinned == true ? 'Unpin Comment' : 'Pin Comment',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: comment.pinned == true
                        ? 'Unpin Comment'
                        : 'Pin Comment',
                    onConfirm: (reason) {
                      controller.moderateComment(
                        comment: comment,
                        action: comment.pinned == true
                            ? 'unpin_comment'
                            : 'pin_comment',
                        reason: reason,
                      );
                    },
                  );
                },
              ),
              _buildModAction(
                context: context,
                icon: comment.locked == true
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                label: comment.locked == true ? 'Unlock Thread' : 'Lock Thread',
                color: comment.locked == true
                    ? colorScheme.primary
                    : colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: comment.locked == true
                        ? 'Unlock Thread'
                        : 'Lock Thread',
                    onConfirm: (reason) {
                      controller.moderateComment(
                        comment: comment,
                        action: comment.locked == true
                            ? 'unlock_thread'
                            : 'lock_thread',
                        reason: reason,
                      );
                    },
                  );
                },
              ),
              if (!isOwnComment) ...[
                _buildModAction(
                  context: context,
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete Comment (Mod)',
                  color: colorScheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    _showReasonDialog(
                      context: context,
                      title: 'Delete Comment',
                      isDestructive: true,
                      onConfirm: (reason) {
                        controller.deleteComment(comment);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        height: 1,
      ),
    );
  }

  Widget _buildModAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            AnymeXContainer(
              width: 40,
              height: 40,
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            AnymeXText(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }

  void _showReasonDialog({
    required BuildContext context,
    required String title,
    required Function(String reason) onConfirm,
    bool isDestructive = false,
  }) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AnymeXText(title, maxLines: null),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Provide a reason for this action...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AnymeXText('Cancel', maxLines: null),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                onConfirm(reasonController.text.trim());
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              }
            },
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: context.colors.error,
                    foregroundColor: context.colors.onError,
                  )
                : null,
            child: AnymeXText(isDestructive ? 'Delete' : 'Confirm',
                maxLines: null),
          ),
        ],
      ),
    );
  }

  void _showUserManagementSheet(BuildContext context, Comment comment,
      CommentSectionController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: AnymeXContainer(
                  width: 40,
                  height: 4,
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (comment.bannerUrl != null &&
                  comment.bannerUrl!.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(comment.bannerUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  AnymeXDecoratedAvatar(
                    avatarUrl: comment.avatarUrl,
                    decorationUrl: comment.avatarDecoration,
                    size: 48,
                    decorationScale: 1.25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: AnymeXText(
                                comment.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (comment.linkedAccounts?.isNotEmpty == true) ...[
                              const SizedBox(width: 6),
                              LinkedAccountsBadges(
                                linkedAccounts: comment.linkedAccounts,
                                fontSize: 9.5,
                              ),
                            ],
                          ],
                        ),
                        AnymeXText(
                          'ID: ${comment.userId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnymeXText(
                'User Actions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: null,
              ),
              const SizedBox(height: 8),
              _buildModAction(
                context: context,
                icon: Icons.warning_rounded,
                label: 'Warn User',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _openUserModeration(comment, ModerationActionType.warn);
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.volume_off_rounded,
                label: 'Mute User',
                color: Colors.amber,
                onTap: () {
                  Navigator.pop(context);
                  _openUserModeration(comment, ModerationActionType.mute);
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.block_rounded,
                label: 'Ban User',
                color: colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                  _openUserModeration(comment, ModerationActionType.ban);
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.visibility_off_rounded,
                label: 'Shadow Ban User',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _openUserModeration(comment, ModerationActionType.shadowBan);
                },
              ),
              const SizedBox(height: 8),
              _buildDivider(context),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: AnymeXText(
                  'Restore Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.teal,
                      ),
                  maxLines: null,
                ),
              ),
              _buildModAction(
                context: context,
                icon: Icons.check_circle_rounded,
                label: 'Unban User',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _openUserModeration(comment, ModerationActionType.unban);
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.notifications_active_rounded,
                label: 'Unmute User',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _openUserModeration(comment, ModerationActionType.unmute);
                },
              ),
              const SizedBox(height: 8),
              _buildDivider(context),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: AnymeXText(
                  'Info',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: null,
                ),
              ),
              _buildModAction(
                context: context,
                icon: Icons.info_rounded,
                label: 'View User Info',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _showUserInfoDialog(context, comment.userId, controller);
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.history_rounded,
                label: 'View User History',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _showUserHistoryDialog(context, comment.userId, controller);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openUserModeration(Comment comment, ModerationActionType actionType) {
    AnymeXModerationActionSheet.show(
      context,
      targetUserId: comment.userId,
      targetUsername: comment.username,
      targetAvatar: comment.avatarUrl,
      targetDecoration: comment.avatarDecoration,
      targetRole: comment.userRole,
      initialAction: actionType,
      onConfirm: ({
        required String action,
        required String reason,
        int? duration,
        bool shadowBan = false,
      }) async {
        await controller.manageUser(
          targetUserId: comment.userId,
          action: action,
          reason: reason,
          duration: duration,
          shadowBan: shadowBan,
        );
        return true;
      },
    );
  }

  void _showUserInfoDialog(BuildContext context, String userId,
      CommentSectionController controller) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const AnymeXText('User Info', maxLines: null),
        content: FutureBuilder(
          future: controller.getUserInfoFromDb(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: ExpressiveLoadingIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const AnymeXText('Failed to load user info.',
                  maxLines: null);
            }

            final data = snapshot.data!;
            final users = data['users'] as List<dynamic>? ?? [];
            if (users.isEmpty) {
              return const AnymeXText('No user data found.', maxLines: null);
            }

            final user = users.first as Map<String, dynamic>;
            final isBanned = user['banned']?.toString() == 'true' ||
                user['commentum_user_banned']?.toString() == 'true';
            final isMuted = user['muted']?.toString() == 'true' ||
                user['commentum_user_muted']?.toString() == 'true';
            final isShadowBanned =
                user['shadow_banned']?.toString() == 'true' ||
                    user['commentum_user_shadow_banned']?.toString() == 'true';
            final username = user['username']?.toString() ??
                user['commentum_username']?.toString() ??
                'Unknown';
            final avatar = user['avatar']?.toString() ??
                user['commentum_user_avatar']?.toString();
            final decoration = user['avatar_decoration']?.toString() ??
                user['commentum_user_avatar_decoration']?.toString();
            final role = user['role']?.toString() ??
                user['commentum_user_role']?.toString() ??
                'user';
            final warnings = user['warnings']?.toString() ??
                user['commentum_user_warnings']?.toString() ??
                '0';
            final mutedUntil = user['muted_until']?.toString() ??
                user['commentum_user_muted_until']?.toString();
            final notes = user['notes']?.toString() ??
                user['commentum_user_notes']?.toString();
            final clientType = user['client_type']?.toString() ??
                user['commentum_client_type']?.toString() ??
                '';
            final createdAt = user['created_at']?.toString() ?? '';
            final colorScheme = Theme.of(context).colorScheme;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        AnymeXDecoratedAvatar(
                          avatarUrl: avatar,
                          decorationUrl: decoration,
                          size: 64,
                        ),
                        const SizedBox(height: 10),
                        AnymeXText(
                          username,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: null,
                        ),
                        const SizedBox(height: 4),
                        AnymeXContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          color: _getRoleColor(role).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getRoleColor(role).withOpacity(0.3),
                          ),
                          child: AnymeXText(
                            role.toUpperCase(),
                            color: _getRoleColor(role),
                            size: 11,
                            variant: TextVariant.bold,
                            maxLines: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _buildInfoRow('User ID', userId),
                  if (clientType.isNotEmpty)
                    _buildInfoRow('Client', clientType.toUpperCase()),
                  _buildInfoRow('Banned', isBanned ? 'Yes' : 'No'),
                  _buildInfoRow('Shadow Banned', isShadowBanned ? 'Yes' : 'No'),
                  _buildInfoRow('Muted', isMuted ? 'Yes' : 'No'),
                  _buildInfoRow('Warnings', warnings),
                  if (mutedUntil != null &&
                      mutedUntil.isNotEmpty &&
                      mutedUntil != 'null')
                    _buildInfoRow('Muted Until', _formatTimestamp(mutedUntil)),
                  if (createdAt.isNotEmpty && createdAt != 'null')
                    _buildInfoRow('Joined', _formatTimestamp(createdAt)),
                  if (notes != null && notes.isNotEmpty && notes != 'null')
                    _buildInfoRow('Notes', notes),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showUserHistoryDialog(context, userId, controller);
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const AnymeXText('View History', maxLines: null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const AnymeXText('Close', maxLines: null),
          ),
        ],
      ),
    );
  }

  void _showUserCommentsSheet(BuildContext context, Comment comment,
      CommentSectionController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return AnymeXContainer(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              color: colorScheme.surfaceContainerLow,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Column(
                children: [
                  Center(
                    child: AnymeXContainer(
                      width: 40,
                      height: 4,
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AnymeXDecoratedAvatar(
                        avatarUrl: comment.avatarUrl,
                        decorationUrl: comment.avatarDecoration,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnymeXText(
                          '${comment.username}\'s Comments',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder(
                      future: controller.getUserHistoryFromDb(comment.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: ExpressiveLoadingIndicator(),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                AnymeXText('Failed to load comments.',
                                    maxLines: null),
                              ],
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        final history = data['history'] as List<dynamic>? ?? [];

                        final comments = history.where((e) {
                          final action = (e as Map<String, dynamic>)['action']
                                  ?.toString() ??
                              '';
                          return action == 'comment';
                        }).toList();

                        if (comments.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.comment_outlined,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                AnymeXText('No comments found.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: null),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry =
                                comments[index] as Map<String, dynamic>;
                            final content = entry['content']?.toString() ?? '';
                            final mediaTitle =
                                entry['media_title']?.toString() ?? '';
                            final timestamp =
                                entry['created_at']?.toString() ?? '';
                            final deleted = entry['deleted'] == true;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (deleted)
                                        AnymeXContainer(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          color: colorScheme.error
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: AnymeXText('DELETED',
                                              color: colorScheme.error,
                                              size: 10,
                                              variant: TextVariant.bold,
                                              maxLines: null),
                                        )
                                      else
                                        AnymeXContainer(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          color: colorScheme.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: AnymeXText('COMMENT',
                                              color: colorScheme.primary,
                                              size: 10,
                                              variant: TextVariant.bold,
                                              maxLines: null),
                                        ),
                                      const Spacer(),
                                      if (timestamp.isNotEmpty)
                                        AnymeXText(
                                          _formatTimestamp(timestamp),
                                          color: colorScheme.onSurfaceVariant,
                                          size: 10,
                                          maxLines: null,
                                        ),
                                    ],
                                  ),
                                  if (content.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    AnymeXText(
                                      content,
                                      size: 13,
                                      color: deleted
                                          ? colorScheme.onSurfaceVariant
                                              .withOpacity(0.5)
                                          : colorScheme.onSurface,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (mediaTitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.movie_outlined,
                                            size: 12,
                                            color: colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: AnymeXText(
                                            'On: $mediaTitle',
                                            size: 11,
                                            color: colorScheme.primary,
                                            variant: TextVariant.semiBold,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUserProfileSheet(BuildContext context, Comment comment) {
    if (!context.mounted) return;
    UserCommentsSheet.show(
      context,
      comment: comment,
      controller: controller,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: AnymeXText(
              label,
              size: 13,
              variant: TextVariant.semiBold,
              maxLines: null,
            ),
          ),
          Expanded(
            child: AnymeXText(
              value,
              size: 13,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserHistoryDialog(BuildContext context, String userId,
      CommentSectionController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AnymeXText('User History', maxLines: null),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder(
            future: controller.getUserHistoryFromDb(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: ExpressiveLoadingIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const AnymeXText('Failed to load user history.',
                    maxLines: null);
              }

              final data = snapshot.data!;
              final history = data['history'] as List<dynamic>? ?? [];

              if (history.isEmpty) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 16),
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    AnymeXText('No history found.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                        maxLines: null),
                  ],
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = history[index] as Map<String, dynamic>;
                    final action = entry['action']?.toString() ?? 'Unknown';
                    final content = entry['content']?.toString() ?? '';
                    final reason = entry['reason']?.toString() ?? 'No reason';
                    final timestamp = entry['created_at']?.toString() ?? '';
                    final moderator =
                        entry['moderator_username']?.toString() ?? 'System';
                    final mediaTitle = entry['media_title']?.toString() ?? '';
                    final deleted = entry['deleted'] == true;

                    final actionIcon = switch (action) {
                      'warn' => Icons.warning_rounded,
                      'mute' => Icons.volume_off_rounded,
                      'ban' => Icons.block_rounded,
                      'shadow_ban' => Icons.visibility_off_rounded,
                      'unban' => Icons.check_circle_rounded,
                      'unmute' => Icons.notifications_active_rounded,
                      'moderated' => Icons.gavel_rounded,
                      'comment' => Icons.chat_bubble_outline_rounded,
                      _ => Icons.info_rounded,
                    };

                    final actionColor = switch (action) {
                      'warn' => Colors.orange,
                      'mute' => Colors.amber,
                      'ban' ||
                      'shadow_ban' =>
                        Theme.of(context).colorScheme.error,
                      'unban' || 'unmute' => Colors.teal,
                      'moderated' => Colors.deepPurple,
                      'comment' => Theme.of(context).colorScheme.primary,
                      _ => Theme.of(context).colorScheme.primary,
                    };

                    final actionLabel = switch (action) {
                      'moderated' => 'MODERATED',
                      'comment' => deleted ? 'DELETED COMMENT' : 'COMMENT',
                      _ => action.toUpperCase(),
                    };

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXContainer(
                            width: 32,
                            height: 32,
                            color: actionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            child:
                                Icon(actionIcon, size: 16, color: actionColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AnymeXText(
                                      actionLabel,
                                      color: actionColor,
                                      size: 12,
                                      variant: TextVariant.bold,
                                      maxLines: null,
                                    ),
                                    const Spacer(),
                                    if (timestamp.isNotEmpty)
                                      AnymeXText(
                                        _formatTimestamp(timestamp),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        size: 10,
                                        maxLines: null,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                if (content.isNotEmpty)
                                  AnymeXText(
                                    content,
                                    size: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (reason.isNotEmpty && reason != 'No reason')
                                  AnymeXText(
                                    'Reason: $reason',
                                    size: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.7),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (mediaTitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  AnymeXText(
                                    'On: $mediaTitle',
                                    size: 10,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    variant: TextVariant.semiBold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 2),
                                AnymeXText(
                                  'by $moderator',
                                  size: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                  maxLines: null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const AnymeXText('Close', maxLines: null),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 30) {
        return '${diff.inDays}d ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      return isoString.length > 10 ? isoString.substring(0, 10) : isoString;
    }
  }

  Widget _buildTag(BuildContext context, String tag) {
    final colorScheme = context.colors;

    Color tagColor = colorScheme.primary;
    if (tag.toLowerCase().contains('spoiler')) {
      tagColor = Colors.red;
    } else if (tag.toLowerCase().contains('theory')) {
      tagColor = Colors.orange;
    } else if (tag.toLowerCase().contains('review')) {
      tagColor = Colors.teal;
    }

    return AnymeXContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: tagColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: tagColor.withOpacity(0.2),
        width: 1,
      ),
      child: AnymeXText(
        tag,
        color: tagColor,
        size: 11,
        variant: TextVariant.bold,
        maxLines: null,
      ),
    );
  }
}

class _SpoilerText extends StatefulWidget {
  final String text;
  final bool isSpoiler;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final double fontSize;

  const _SpoilerText({
    required this.text,
    required this.isSpoiler,
    required this.theme,
    required this.colorScheme,
    this.fontSize = 15,
  });

  @override
  State<_SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<_SpoilerText> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.theme.textTheme.bodyMedium?.copyWith(
          fontSize: widget.fontSize,
          color: widget.colorScheme.onSurface,
        ) ??
        TextStyle(
          color: widget.colorScheme.onSurface,
          fontSize: widget.fontSize,
        );

    if (!widget.isSpoiler || _isRevealed) {
      return DiscordMarkdown(
        text: widget.text,
        colorScheme: widget.colorScheme,
        fontSize: widget.fontSize,
        baseStyle: textStyle,
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isRevealed = true),
      child: AnymeXContainer(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: widget.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.colorScheme.outlineVariant.opaque(0.3),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 16, color: widget.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            AnymeXText(
              'Spoiler — tap to reveal',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfileSheet extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String? decorationUrl;
  final String? userRole;

  const _UserProfileSheet({
    required this.username,
    this.avatarUrl,
    this.decorationUrl,
    this.userRole,
  });

  Color _getRoleColor(BuildContext context, String role) {
    return CommentumRoleConfig.getRoleColor(context, role);
  }

  String _getRoleLabel(String role) {
    return CommentumRoleConfig.getRoleLabel(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMod = userRole != null && userRole != 'user';

    return AnymeXContainer(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnymeXContainer(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                AnymeXDecoratedAvatar(
                  avatarUrl: avatarUrl,
                  decorationUrl: decorationUrl,
                  size: 72,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: AnymeXText(
                        username,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: null,
                      ),
                    ),
                    if (isMod)
                      AnymeXContainer(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: _getRoleColor(context, userRole!).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getRoleColor(context, userRole!).withOpacity(0.3),
                        ),
                        child: AnymeXText(
                          _getRoleLabel(userRole!),
                          size: 12,
                          variant: TextVariant.bold,
                          color: _getRoleColor(context, userRole!),
                          maxLines: null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
