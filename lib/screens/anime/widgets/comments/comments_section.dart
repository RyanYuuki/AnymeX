import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/mention_autocomplete.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/policy_sheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
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

  const CommentSection({
    super.key,
    required this.media,
    this.scrollToCommentId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late CommentSectionController controller;
  String? lastMediaId;

  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, FocusNode> _replyFocusNodes = {};
  final Set<String> _expandedThreads = {};
  final GlobalKey _targetCommentKey = GlobalKey();
  bool _hasScrolledToTarget = false;

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

  /// After comments load, scroll to the target comment if specified
  void _setupScrollToComment() {
    if (widget.scrollToCommentId == null || widget.scrollToCommentId!.isEmpty) {
      return;
    }

    ever(controller.isLoading, (isLoading) {
      if (!isLoading &&
          !_hasScrolledToTarget &&
          controller.comments.isNotEmpty) {
        // Auto-expand any collapsed threads that contain the target comment
        _expandThreadForComment(widget.scrollToCommentId!, controller.comments);

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
              _expandedThreads.add(comment.id);
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
        title: const Text('Comment Policy'),
        content: const Text(
          'To maintain a safe and friendly community, please read and accept our comment policy before posting.\n\nWe do not tolerate spam, harassment, or offensive content.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showPolicySheet(context, PolicyType.commentRules);
            },
            child: const Text('Read Full Rules'),
          ),
          FilledButton(
            onPressed: () {
              General.hasAcceptedCommentRules.set(true);
              Navigator.pop(context);
              controller.addComment();
            },
            child: const Text('Accept & Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
          _buildHeader(context, controller),
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
              child: Text(
                'You need to be logged in to comment.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 8),
          _buildCommentsList(context, controller),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() => Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 16, 20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.opaque(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnymexText(
                      text: 'Comments',
                      variant: TextVariant.semiBold,
                      color: colorScheme.onSurface,
                      size: 24,
                      autoResize: true,
                      maxLines: 1,
                    ),
                  ),
                  _buildSortChip(context, controller),
                  const SizedBox(width: 4),
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
              ),
              const SizedBox(height: 4),
              AnymexText(
                text: _getTotalCommentCount(controller.comments),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.opaque(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outlineVariant.opaque(0.3),
          ),
        ),
        child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  sortOptions
                      .firstWhere((s) => s.$1 == controller.currentSort.value)
                      .$2,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
                    Text(s.$2),
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
                          child: Container(
                            height: 50,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colorScheme.surface
                                  .opaque(0.3, iReallyMeanIt: true),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .opaque(0.2, iReallyMeanIt: true),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: controller.commentController,
                              focusNode: controller.commentFocusNode,
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
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
                                  : const Text(
                                      'Post',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
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
          Text(
            'Tag',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
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
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainer,
        border: Border.all(
          color: colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.opaque(0.1, iReallyMeanIt: true),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: controller.profile.avatar?.isNotEmpty == true
            ? AnymeXImage(
                imageUrl: controller.profile.avatar!,
                fit: BoxFit.cover,
                radius: 0,
              )
            : Icon(
                Icons.person_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
      ),
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
                Text(
                  'Loading comments...',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
              Container(
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
              Text(
                'No comments yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start the conversation and share your thoughts!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: controller.comments.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          margin: const EdgeInsets.only(left: 56, top: 24, bottom: 24),
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant.opaque(0.2),
          ),
        ),
        itemBuilder: (context, index) {
          return _buildCommentWithReplies(
              context, controller.comments[index], controller, 0,
              isParentLocked: false);
        },
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
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildCommentWithReplies(BuildContext context, Comment comment,
      CommentSectionController controller, int depth,
      {bool isParentLocked = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveLocked = comment.locked == true || isParentLocked;
    final isTarget = _isTargetComment(comment.id);

    return Obx(() => Column(
          key: isTarget ? _targetCommentKey : null,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTarget)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.opaque(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.opaque(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Notification Target',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (comment.pinned == true && depth == 0)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.opaque(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.opaque(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.push_pin_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Pinned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            _buildCommentItem(context, comment, controller,
                effectiveLocked: effectiveLocked, depth: depth),
            if (controller.isReplyingTo(comment.id) && !effectiveLocked) ...[
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
      CommentSectionController controller, bool effectiveLocked) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allReplies = _flattenReplies(comment);
    final totalReplies = allReplies.length;
    final isExpanded = _expandedThreads.contains(comment.id);
    const maxVisible = 3;

    if (!isExpanded) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: InkWell(
          onTap: () => setState(() => _expandedThreads.add(comment.id)),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow.opaque(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.opaque(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'View Replies ($totalReplies)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visibleReplies = allReplies.take(maxVisible).toList();
    final remainingCount = totalReplies - maxVisible;

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.opaque(0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...visibleReplies.asMap().entries.map((entry) {
                    final reply = entry.value;
                    final parentUsername = _findParentUsername(reply, comment);
                    final parentRole = _findParentRole(reply, comment);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < visibleReplies.length - 1 ? 10 : 0,
                      ),
                      child: _buildReplyItem(context, reply, controller,
                          parentUsername, effectiveLocked,
                          depth: 2, parentRole: parentRole),
                    );
                  }),
                  if (remainingCount > 0) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() {
                        _expandedThreads.add('${comment.id}_more');
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow.opaque(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outlineVariant.opaque(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View More Replies ($remainingCount)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  if (reply.userRole != null && reply.userRole != 'user') ...[
                    _buildRoleBadge(context, reply.userRole!),
                  ],
                  GestureDetector(
                    onTap: () => _showUserProfileSheet(context, reply),
                    child: Text(
                      reply.username,
                      style: TextStyle(
                        color:
                            reply.userRole != null && reply.userRole != 'user'
                                ? _getRoleColor(reply.userRole!)
                                : colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '→ ',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    parentUsername,
                    style: TextStyle(
                      color: parentRole != null && parentRole != 'user'
                          ? _getRoleColor(parentRole)
                          : colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '•',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (reply.tag.isNotEmpty && reply.tag != 'General') ...[
                    const SizedBox(width: 4),
                    _buildTag(context, reply.tag),
                  ],
                  if (reply.edited == true)
                    Text(
                      ' (edited)',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.opaque(0.6),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (isLocked)
                    Icon(Icons.lock_rounded,
                        size: 11, color: colorScheme.error),
                  const Spacer(),
                  _buildCommentMenu(
                      context, reply, controller, isOwnComment, canModerate),
                ],
              ),
              const SizedBox(height: 4),
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
                  Text(
                    _formatTimestampShort(reply.createdAt),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!isLocked) ...[
                    GestureDetector(
                      onTap: () => controller.toggleReply(reply.id),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
                ],
              ),
              if (controller.isReplyingTo(reply.id) && !isLocked) ...[
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
              child: Container(
                margin: const EdgeInsets.only(left: 16, right: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest.opaque(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Replying to ${comment.username}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
                                  : const Text(
                                      'Reply',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
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

    if (comment.deleted) {
      return _buildDeletedComment(context, comment, depth);
    }

    final isSpoiler = comment.tag.toLowerCase().contains('spoiler');
    final isOwnComment = comment.userId == controller.profile.id?.toString();
    final canModerate = controller.canModerate();
    final isLocked = comment.locked == true || effectiveLocked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            final currentUserId =
                Get.find<ServiceHandler>().profileData.value.id;
            if (comment.userId == currentUserId) {
              navigate(() => const ProfilePage());
            } else {
              navigate(() =>
                  UserProfilePage(userId: int.tryParse(comment.userId) ?? 0));
            }
          },
          child: _buildCommentAvatar(context, comment, size: 36),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (comment.userRole != null &&
                      comment.userRole != 'user') ...[
                    _buildRoleBadge(context, comment.userRole!),
                  ],
                  GestureDetector(
                    onTap: () => _showUserProfileSheet(context, comment),
                    child: Text(
                      comment.username,
                      style: TextStyle(
                        color: comment.userRole != null &&
                                comment.userRole != 'user'
                            ? _getRoleColor(comment.userRole!)
                            : colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (comment.tag.isNotEmpty && comment.tag != 'General') ...[
                    const SizedBox(width: 6),
                    _buildTag(context, comment.tag),
                  ],
                  if (comment.edited == true)
                    Text(
                      ' (edited)',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.opaque(0.6),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (isLocked)
                    Icon(Icons.lock_rounded,
                        size: 12, color: colorScheme.error),
                  const Spacer(),
                  _buildCommentMenu(
                      context, comment, controller, isOwnComment, canModerate),
                ],
              ),
              const SizedBox(height: 6),
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
                      Text(
                        'Thread is locked',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _formatTimestampShort(comment.createdAt),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!effectiveLocked) ...[
                    GestureDetector(
                      onTap: () => controller.toggleReply(comment.id),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
          Text(
            count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: avatarSize + (isCompact ? 8 : 12)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: avatarSize / 4),
            child: Text(
              '[deleted]',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.opaque(0.4),
                fontSize: isCompact ? 13.0 : 15.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentAvatar(BuildContext context, Comment comment,
      {double size = 40}) {
    final colorScheme = context.colors;
    final iconSize = size <= 28 ? 14.0 : 18.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainer,
        border: Border.all(
          color: colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
          width: 1,
        ),
        boxShadow: size > 28
            ? [
                BoxShadow(
                  color: colorScheme.shadow.opaque(0.08, iReallyMeanIt: true),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: comment.avatarUrl?.isNotEmpty == true
            ? AnymeXImage(
                imageUrl: comment.avatarUrl!,
                fit: BoxFit.cover,
                radius: 0,
              )
            : Icon(
                Icons.person_rounded,
                color: colorScheme.onSurfaceVariant,
                size: iconSize,
              ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final config = _getRoleBadgeConfig(role);
    if (config == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(config.$1, size: 16, color: config.$2),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.amber.shade800;
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  (IconData, Color)? _getRoleBadgeConfig(String role) {
    switch (role) {
      case 'owner':
        return (Icons.auto_awesome, Colors.amber.shade800);
      case 'super_admin':
        return (Icons.shield, Colors.red);
      case 'admin':
        return (Icons.verified_user, Colors.orange);
      case 'moderator':
        return (Icons.manage_accounts, Colors.teal);
      default:
        return null;
    }
  }

  Widget _buildCommentMenu(
      BuildContext context,
      Comment comment,
      CommentSectionController controller,
      bool isOwnComment,
      bool canModerate) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditDialog(context, comment, controller);
            break;
          case 'delete':
            _showDeleteDialog(context, comment, controller);
            break;
          case 'report':
            _showReportDialog(context, comment, controller);
            break;
          case 'moderate':
            _showModerationSheet(context, comment, controller,
                isOwnComment: isOwnComment);
            break;
          case 'user_actions':
            _showUserManagementSheet(context, comment, controller);
            break;
          case 'user_comments':
            _showUserCommentsSheet(context, comment, controller);
            break;
          case 'copy':
            Clipboard.setData(ClipboardData(text: comment.commentText));
            snackBar('Comment copied to clipboard');
            break;
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.copy_rounded,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text('Copy',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14)),
            ],
          ),
        ),
        if (isOwnComment) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'edit',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text('Edit',
                    style:
                        TextStyle(color: colorScheme.onSurface, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                const SizedBox(width: 12),
                Text('Delete',
                    style: TextStyle(color: colorScheme.error, fontSize: 14)),
              ],
            ),
          ),
        ],
        if (!isOwnComment) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'report',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.flag_outlined,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text('Report',
                    style:
                        TextStyle(color: colorScheme.onSurface, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'user_comments',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.comment_outlined,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text('User Comments',
                    style:
                        TextStyle(color: colorScheme.onSurface, fontSize: 14)),
              ],
            ),
          ),
        ],
        if (canModerate) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'moderate',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: colorScheme.tertiary),
                const SizedBox(width: 12),
                Text('Moderate',
                    style:
                        TextStyle(color: colorScheme.tertiary, fontSize: 14)),
              ],
            ),
          ),
          if (!isOwnComment) ...[
            PopupMenuItem(
              value: 'user_actions',
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      size: 18, color: colorScheme.tertiary),
                  const SizedBox(width: 12),
                  Text('User Actions',
                      style:
                          TextStyle(color: colorScheme.tertiary, fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _showEditDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final TextEditingController editController =
        TextEditingController(text: comment.commentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                controller.editComment(comment, editController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
            'Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.deleteComment(comment);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please select a reason for reporting this comment:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value:
                  reasonController.text.isEmpty ? null : reasonController.text,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'spam', child: Text('Spam')),
                DropdownMenuItem(value: 'offensive', child: Text('Offensive')),
                DropdownMenuItem(
                    value: 'harassment', child: Text('Harassment')),
                DropdownMenuItem(value: 'spoiler', child: Text('Spoiler')),
                DropdownMenuItem(value: 'nsfw', child: Text('NSFW')),
                DropdownMenuItem(value: 'off_topic', child: Text('Off-Topic')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                reasonController.text = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.reportComment(comment, reasonController.text.trim(),
                    notes: notesController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Report'),
          ),
        ],
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
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Moderate Comment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
        title: Text(title),
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
            child: const Text('Cancel'),
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
            child: Text(isDestructive ? 'Delete' : 'Confirm'),
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
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  comment.avatarUrl?.isNotEmpty == true
                      ? CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(comment.avatarUrl!),
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.surfaceContainer,
                          child: Icon(Icons.person_rounded,
                              size: 18, color: colorScheme.onSurfaceVariant),
                        ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.username,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'ID: ${comment.userId}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'User Actions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              _buildModAction(
                context: context,
                icon: Icons.warning_rounded,
                label: 'Warn User',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: 'Warn User',
                    onConfirm: (reason) {
                      controller.manageUser(
                        targetUserId: comment.userId,
                        action: 'warn_user',
                        reason: reason,
                      );
                    },
                  );
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.volume_off_rounded,
                label: 'Mute User (24h)',
                color: Colors.amber,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: 'Mute User',
                    onConfirm: (reason) {
                      controller.manageUser(
                        targetUserId: comment.userId,
                        action: 'mute_user',
                        reason: reason,
                        duration: 24,
                      );
                    },
                  );
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.block_rounded,
                label: 'Ban User',
                color: colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: 'Ban User',
                    isDestructive: true,
                    onConfirm: (reason) {
                      controller.manageUser(
                        targetUserId: comment.userId,
                        action: 'ban_user',
                        reason: reason,
                      );
                    },
                  );
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.visibility_off_rounded,
                label: 'Shadow Ban User',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: 'Shadow Ban User',
                    isDestructive: true,
                    onConfirm: (reason) {
                      controller.manageUser(
                        targetUserId: comment.userId,
                        action: 'ban_user',
                        reason: reason,
                        shadowBan: true,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildDivider(context),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Restore Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.teal,
                      ),
                ),
              ),
              _buildModAction(
                context: context,
                icon: Icons.check_circle_rounded,
                label: 'Unban User',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: 'Unban User',
                    onConfirm: (reason) {
                      controller.manageUser(
                        targetUserId: comment.userId,
                        action: 'unban_user',
                        reason: reason,
                      );
                    },
                  );
                },
              ),
              _buildModAction(
                context: context,
                icon: Icons.notifications_active_rounded,
                label: 'Unmute User',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _showReasonDialog(
                    context: context,
                    title: 'Unmute User',
                    onConfirm: (reason) {
                      controller.manageUser(
                        targetUserId: comment.userId,
                        action: 'unmute_user',
                        reason: reason,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildDivider(context),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Info',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
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

  void _showUserInfoDialog(BuildContext context, String userId,
      CommentSectionController controller) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('User Info'),
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
              return const Text('Failed to load user info.');
            }

            final data = snapshot.data!;
            final users = data['users'] as List<dynamic>? ?? [];
            if (users.isEmpty) {
              return const Text('No user data found.');
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
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colorScheme.surfaceContainer,
                          backgroundImage: avatar != null && avatar.isNotEmpty
                              ? NetworkImage(avatar)
                              : null,
                          child: avatar == null || avatar.isEmpty
                              ? Icon(Icons.person_rounded,
                                  size: 28, color: colorScheme.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          username,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRoleColor(role).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(role),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
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
                      label: const Text('View History'),
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
            child: const Text('Close'),
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
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      comment.avatarUrl?.isNotEmpty == true
                          ? CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(comment.avatarUrl!),
                            )
                          : CircleAvatar(
                              radius: 18,
                              backgroundColor: colorScheme.surfaceContainer,
                              child: Icon(Icons.person_rounded,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${comment.username}\'s Comments',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                                Text('Failed to load comments.'),
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
                                Text('No comments found.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text('DELETED',
                                              style: TextStyle(
                                                  color: colorScheme.error,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700)),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text('COMMENT',
                                              style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      const Spacer(),
                                      if (timestamp.isNotEmpty)
                                        Text(
                                          _formatTimestamp(timestamp),
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (content.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      content,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: deleted
                                            ? colorScheme.onSurfaceVariant
                                                .withOpacity(0.5)
                                            : colorScheme.onSurface,
                                      ),
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
                                          child: Text(
                                            'On: $mediaTitle',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
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

  void _showUserProfileSheet(BuildContext context, Comment comment) async {
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _UserProfileSheet(
        username: comment.username,
        avatarUrl: comment.avatarUrl,
        userRole: comment.userRole,
      ),
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
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
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
        title: const Text('User History'),
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
                return const Text('Failed to load user history.');
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
                    Text('No history found.',
                        style: TextStyle(fontWeight: FontWeight.w500)),
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
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: actionColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                                    Text(
                                      actionLabel,
                                      style: TextStyle(
                                        color: actionColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (timestamp.isNotEmpty)
                                      Text(
                                        _formatTimestamp(timestamp),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                if (content.isNotEmpty)
                                  Text(
                                    content,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (reason.isNotEmpty && reason != 'No reason')
                                  Text(
                                    'Reason: $reason',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (mediaTitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'On: $mediaTitle',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  'by $moderator',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
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
            child: const Text('Close'),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tagColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: tagColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
    if (!widget.isSpoiler) {
      return DiscordMarkdown(
        text: widget.text,
        colorScheme: widget.colorScheme,
        baseStyle: TextStyle(
          color: widget.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          height: 1.5,
          fontSize: widget.fontSize,
        ),
      );
    }

    if (_isRevealed) {
      return DiscordMarkdown(
        text: widget.text,
        colorScheme: widget.colorScheme,
        baseStyle: TextStyle(
          color: widget.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          height: 1.5,
          fontSize: widget.fontSize,
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isRevealed = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.colorScheme.outlineVariant.opaque(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 16, color: widget.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Spoiler — tap to reveal',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
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
  final String? userRole;

  const _UserProfileSheet({
    required this.username,
    this.avatarUrl,
    this.userRole,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.amber.shade800;
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'moderator':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return '👑 Owner';
      case 'super_admin':
        return '🛡️ S.Admin';
      case 'admin':
        return '⚔️ Admin';
      case 'moderator':
        return '🔨 Mod';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMod = userRole != null && userRole != 'user';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                if (avatarUrl != null)
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(avatarUrl!),
                  )
                else
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMod)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getRoleColor(userRole!).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getRoleColor(userRole!).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getRoleLabel(userRole!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _getRoleColor(userRole!),
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
    );
  }
}
