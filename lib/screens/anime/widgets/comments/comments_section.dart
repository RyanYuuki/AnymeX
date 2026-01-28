import 'package:anymex/database/model/comment.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentSection extends StatefulWidget {
  final Media media;

  const CommentSection({
    super.key,
    required this.media,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late CommentSectionController controller;
  String? lastMediaId;

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

  @override
  void dispose() {
    final isPreloaded = CommentPreloader.to.isPreloaded(widget.media.uniqueId);
    if (!isPreloaded) {
      Get.delete<CommentSectionController>(tag: widget.media.uniqueId);
    }
    super.dispose();
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
            color: colorScheme.shadow.withOpacity(0.05),
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
                      ? colorScheme.primary.withOpacity(0.4)
                      : colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: controller.commentFocusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Comments',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                _getTotalCommentCount(controller.comments),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => IconButton(
                    onPressed: controller.isRefreshing.value
                        ? null
                        : () => controller.forceRefresh(),
                    icon: controller.isRefreshing.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.refresh,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    tooltip: 'Refresh comments',
                  )),
            ],
          ),
        ));
  }

  Widget _buildCommentInput(
      BuildContext context, CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: controller.commentFocusNode.hasFocus
                  ? colorScheme.primary.withOpacity(0.4)
                  : colorScheme.outlineVariant.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: controller.commentFocusNode.hasFocus
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.1),
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
                        color: colorScheme.surface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller.commentController,
                        focusNode: controller.commentFocusNode,
                        maxLines: controller.isInputExpanded.value ? 5 : 1,
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
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
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
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  height: 1,
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
                            : controller.addComment,
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
                        ? colorScheme.primary.withOpacity(0.15)
                        : colorScheme.surfaceContainerLow
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.4)
                          : colorScheme.outlineVariant.withOpacity(0.2),
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
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary.withOpacity(0.5),
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
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: controller.profile.avatar?.isNotEmpty == true
            ? Image.network(
                controller.profile.avatar!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
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
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        itemBuilder: (context, index) {
          return _buildCommentWithReplies(
              context, controller.comments[index], controller, 0);
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
      return '$total comments ($totalReplies replies)';
    } else {
      return '$total comments';
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

  Widget _buildCommentWithReplies(BuildContext context, Comment comment,
      CommentSectionController controller, int depth) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: depth > 0 ? 16.0 + (depth * 20.0) : 0,
          ),
          child: _buildCommentItem(context, comment, controller),
        ),
        if (comment.replies != null && comment.replies!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            margin: EdgeInsets.only(
              left: depth > 0 ? 16.0 + (depth * 20.0) : 56,
            ),
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comment.replies!.length > 1)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${comment.replies!.length} replies',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ...comment.replies!.asMap().entries.map((entry) {
                  final replyIndex = entry.key;
                  final reply = entry.value;
                  final isLastReply = replyIndex == comment.replies!.length - 1;

                  return Column(
                    children: [
                      _buildCommentWithReplies(
                          context, reply, controller, depth + 1),
                      if (!isLastReply)
                        Container(
                          margin: EdgeInsets.only(
                            left: 16.0 + ((depth + 1) * 20.0),
                            top: 16,
                            bottom: 16,
                          ),
                          height: 1,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant.withOpacity(0.15),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSpoiler = comment.tag.toLowerCase().contains('spoiler');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainer,
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: comment.avatarUrl?.isNotEmpty == true
                ? Image.network(
                    comment.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.username,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeago.format(DateTime.parse(comment.createdAt)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (comment.tag.isNotEmpty) _buildTag(context, comment.tag),
                ],
              ),
              const SizedBox(height: 12),
              _SpoilerText(
                text: comment.commentText,
                isSpoiler: isSpoiler,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildVoteButton(
                    context: context,
                    icon: Icons.keyboard_arrow_up_rounded,
                    count: comment.likes,
                    isActive: comment.userVote == 1,
                    onTap: () => controller.handleVote(comment, 1),
                    isUpvote: true,
                  ),
                  const SizedBox(width: 12),
                  _buildVoteButton(
                    context: context,
                    icon: Icons.keyboard_arrow_down_rounded,
                    count: comment.dislikes,
                    isActive: comment.userVote == -1,
                    onTap: () => controller.handleVote(comment, -1),
                    isUpvote: false,
                  ),
                  const Spacer(),
                  if (comment.userId == controller.profile.id?.toString())
                    _buildActionButton(
                      context: context,
                      icon: Icons.edit_outlined,
                      onTap: () =>
                          _showEditDialog(context, comment, controller),
                    ),
                  if (comment.userId == controller.profile.id?.toString())
                    const SizedBox(width: 8),
                  if (comment.userId == controller.profile.id?.toString())
                    _buildActionButton(
                      context: context,
                      icon: Icons.delete_outline,
                      onTap: () =>
                          _showDeleteDialog(context, comment, controller),
                    ),
                  if (comment.userId == controller.profile.id?.toString())
                    const SizedBox(width: 8),
                  if (comment.userId != controller.profile.id?.toString())
                    _buildActionButton(
                      context: context,
                      icon: Icons.flag_outlined,
                      onTap: () =>
                          _showReportDialog(context, comment, controller),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
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
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
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
                DropdownMenuItem(
                    value: 'inappropriate',
                    child: Text('Inappropriate Content')),
                DropdownMenuItem(
                    value: 'harassment', child: Text('Harassment')),
                DropdownMenuItem(
                    value: 'offensive', child: Text('Offensive Language')),
                DropdownMenuItem(
                    value: 'misinformation', child: Text('Misinformation')),
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

  Widget _buildTag(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required BuildContext context,
    required IconData icon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    required bool isUpvote,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = isUpvote ? colorScheme.primary : colorScheme.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.1)
                : colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? activeColor.withOpacity(0.3)
                  : colorScheme.outlineVariant.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? activeColor : colorScheme.onSurfaceVariant,
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: isActive ? activeColor : colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
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

  const _SpoilerText({
    required this.text,
    required this.isSpoiler,
    required this.theme,
    required this.colorScheme,
  });

  @override
  State<_SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<_SpoilerText> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpoiler) {
      return Text(
        widget.text,
        style: widget.theme.textTheme.bodyLarge?.copyWith(
          color: widget.colorScheme.onSurface,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isRevealed = !_isRevealed;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isRevealed
              ? Colors.transparent
              : widget.colorScheme.surfaceContainerHighest.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          widget.text,
          style: widget.theme.textTheme.bodyLarge?.copyWith(
            color:
                _isRevealed ? widget.colorScheme.onSurface : Colors.transparent,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            backgroundColor: _isRevealed
                ? Colors.transparent
                : widget.colorScheme.surfaceContainerHighest.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
