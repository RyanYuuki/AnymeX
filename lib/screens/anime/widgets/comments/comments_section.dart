import 'package:anymex/database/model/comment.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentSection extends StatefulWidget {
  final String mediaId;
  final String? currentTag;

  const CommentSection({
    super.key,
    required this.mediaId,
    this.currentTag,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late CommentSectionController controller;

  @override
  void initState() {
    controller = Get.put(CommentSectionController(
      mediaId: widget.mediaId,
      currentTag: widget.currentTag,
    ));
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          _buildCommentInput(context, controller),
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
            color: colorScheme.surface.withValues(alpha: 0.5),
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
                '${controller.comments.length} ${controller.comments.length == 1 ? 'comment' : 'comments'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
          margin: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          padding: const EdgeInsets.all(20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (controller.currentTag != null)
                      _buildCurrentTag(context, controller.currentTag!),
                    const Spacer(),
                    Row(
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
                        FilledButton(
                          onPressed: controller.isSubmitting.value
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
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ));
  }

  Widget _buildCurrentTag(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_rounded,
            color: colorScheme.primary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            tag,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
          return _buildCommentItem(
              context, controller.comments[index], controller);
        },
      );
    });
  }

  Widget _buildCommentItem(BuildContext context, Comment comment,
      CommentSectionController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  if (comment.tag.isNotEmpty && comment.tag != 'General')
                    _buildTag(context, comment.tag),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comment.commentText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
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
                ],
              ),
            ],
          ),
        ),
      ],
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
                : colorScheme.surfaceContainerLow,
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
