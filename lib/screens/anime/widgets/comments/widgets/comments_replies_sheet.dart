import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/comment_input_bar.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/user_comments_sheet.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/discord_badge_widget.dart';
import 'package:anymex/database/comments/model/discord_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CommentsRepliesSheet extends StatefulWidget {
  final Comment rootComment;
  final CommentSectionController controller;

  /// Optional hook so the host (CommentsSection) can open its full comment
  /// context menu (copy/edit/delete/report/moderate) for any comment shown
  /// in this sheet, keeping the replies view at feature parity with the
  /// main comment list.
  final void Function(Comment comment)? onShowContextMenu;

  const CommentsRepliesSheet({
    super.key,
    required this.rootComment,
    required this.controller,
    this.onShowContextMenu,
  });

  static Future<void> show(
    BuildContext context, {
    required Comment rootComment,
    required CommentSectionController controller,
    Comment? initialReplyTarget,
    void Function(Comment comment)? onShowContextMenu,
  }) {
    if (initialReplyTarget != null) {
      controller.setReplyTarget(initialReplyTarget);
    } else {
      controller.setReplyTarget(rootComment);
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsRepliesSheet(
        rootComment: rootComment,
        controller: controller,
        onShowContextMenu: onShowContextMenu,
      ),
    );
  }

  @override
  State<CommentsRepliesSheet> createState() => _CommentsRepliesSheetState();
}

class _CommentsRepliesSheetState extends State<CommentsRepliesSheet> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _sheetFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _sheetFocusNode.dispose();
    widget.controller.clearReplyTarget();
    super.dispose();
  }

  String _formatTime(String timestamp) {
    return CommentSectionController.formatCommentTimestamp(timestamp);
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final config = _getRoleBadgeConfig(role);
    if (config == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Icon(config.$1, size: 15, color: config.$2),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'app_owner':
      case 'appowner':
        return Colors.amber.shade800;
      case 'super_admin':
      case 'superadmin':
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
    switch (role.toLowerCase()) {
      case 'owner':
      case 'app_owner':
      case 'appowner':
        return (Icons.auto_awesome, Colors.amber.shade800);
      case 'super_admin':
      case 'superadmin':
        return (Icons.shield, Colors.red);
      case 'admin':
        return (Icons.verified_user, Colors.orange);
      case 'moderator':
        return (Icons.manage_accounts, Colors.teal);
      default:
        return null;
    }
  }


  List<Comment> _flattenReplies(Comment root) {
    final List<Comment> flat = [];
    void traverse(Comment c) {
      if (c.replies != null) {
        for (final r in c.replies!) {
          flat.add(r);
          traverse(r);
        }
      }
    }
    traverse(root);
    return flat;
  }

  int _countReplies(Comment root) {
    int count = 0;
    if (root.replies != null) {
      count += root.replies!.length;
      for (final r in root.replies!) {
        count += _countReplies(r);
      }
    }
    return count;
  }

  Comment? _findParentComment(Comment reply, Comment root) {
    if (reply.parentId == null) return null;
    final parentIdStr = reply.parentId.toString();
    if (root.id == parentIdStr) return root;

    Comment? search(Comment current) {
      if (current.id == parentIdStr) return current;
      if (current.replies != null) {
        for (final r in current.replies!) {
          final found = search(r);
          if (found != null) return found;
        }
      }
      return null;
    }

    final foundInRoot = search(root);
    if (foundInRoot != null) return foundInRoot;
    return widget.controller.findCommentById(parentIdStr);
  }

  Widget _buildCommentCard({
    required BuildContext context,
    required Comment comment,
    required bool isRoot,
    required bool isNestedSubReply,
    Comment? parentComment,
    Comment? rootComment,
    VoidCallback? onReplyTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = widget.controller;

    final isUpvoted = comment.userVote == 1;
    final isDownvoted = comment.userVote == -1;
    final isSpoiler = comment.tag.toLowerCase().contains('spoiler');

    final hasRole = comment.userRole != null &&
        comment.userRole != 'user' &&
        comment.userRole!.isNotEmpty;

    final showParentBreadcrumb = isNestedSubReply &&
        parentComment != null &&
        rootComment != null &&
        parentComment.id != rootComment.id;

    // Deleted replies render as a muted placeholder instead of stale content
    if (comment.deleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.opaque(0.6),
            ),
            const SizedBox(width: 6),
            AnymeXText(
              'This comment was deleted',
              size: 12,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant.opaque(0.6),
              maxLines: null,
            ),
          ],
        ),
      );
    }

    Widget card = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar -> navigates to profile
        GestureDetector(
          onTap: () {
            final currentUserId =
                Get.find<ServiceHandler>().profileData.value.id?.toString();
            if (comment.userId == currentUserId) {
              navigate(() => const ProfilePage());
            } else {
              navigate(() =>
                  UserProfilePage(userId: int.tryParse(comment.userId) ?? 0));
            }
          },
          child: AnymeXDecoratedAvatar(
            avatarUrl: comment.avatarUrl,
            decorationUrl: comment.avatarDecoration,
            size: isNestedSubReply ? 26 : (isRoot ? 34 : 30),
          ),
        ),
        const SizedBox(width: 10),

        // Body
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Role Icon + Username + Breadcrumb + Time
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => UserCommentsSheet.show(context, comment: comment, controller: controller),
                            child: AnymeXText(
                              comment.username,
                              overflow: TextOverflow.ellipsis,
                              size: 13,
                              variant: TextVariant.bold,
                              color: hasRole
                                  ? _getRoleColor(comment.userRole!)
                                  : colorScheme.onSurface,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        if (comment.badges != null && comment.badges!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          DiscordBadgesRow(
                            badges: comment.badges,
                            size: 13.0,
                            isOp: !isRoot && (comment.userId == widget.rootComment.userId),
                          ),
                        ] else ...[
                          if (hasRole) _buildRoleBadge(context, comment.userRole!),
                          if (!isRoot && (comment.userId == widget.rootComment.userId)) ...[
                            const SizedBox(width: 4),
                            const DiscordBadgeWidget(badge: DiscordBadge.opBadge, size: 13.0),
                          ],
                        ],
                        if (showParentBreadcrumb) ...[
                          Icon(Icons.arrow_right,
                              size: 18, color: colorScheme.primary),
                          Flexible(
                            child: GestureDetector(
                              onTap: parentComment.deleted
                                  ? null
                                  : () => UserCommentsSheet.show(context,
                                      comment: parentComment,
                                      controller: controller),
                              child: AnymeXText(
                                parentComment.deleted
                                    ? 'deleted'
                                    : parentComment.username,
                                overflow: TextOverflow.ellipsis,
                                size: 13,
                                variant: TextVariant.bold,
                                fontStyle: parentComment.deleted
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: parentComment.deleted
                                    ? colorScheme.onSurfaceVariant.opaque(0.6)
                                    : (parentComment.userRole != null &&
                                            parentComment.userRole != 'user' &&
                                            parentComment.userRole!.isNotEmpty
                                        ? _getRoleColor(parentComment.userRole!)
                                        : colorScheme.primary),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        AnymeXText(
                          _formatTime(comment.createdAt),
                          size: 11,
                          color: colorScheme.onSurfaceVariant.opaque(0.6),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  if (comment.tag.isNotEmpty && comment.tag != 'General') ...[
                    const SizedBox(width: 8),
                    AnymeXContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: isSpoiler
                          ? colorScheme.error.withValues(alpha: 0.15)
                          : colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      child: AnymeXText(
                        comment.tag,
                        size: 10,
                        variant: TextVariant.bold,
                        color: isSpoiler
                            ? colorScheme.error
                            : colorScheme.primary,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),

              // Comment Markdown Content
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: DiscordMarkdown(
                  text: comment.commentText,
                  colorScheme: colorScheme,
                  baseStyle: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: colorScheme.onSurface.opaque(0.9),
                  ),
                ),
              ),

              // Actions Row: Upvote + Reply
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    // Upvote Button
                    GestureDetector(
                      onTap: () => controller.handleVote(comment, 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              isUpvoted
                                    ? Icons.thumb_up_rounded
                                    : Icons.thumb_up_outlined,
                              size: 13,
                              color: isUpvoted
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            if (comment.likes > 0) ...[
                              const SizedBox(width: 4),
                              AnymeXText(
                                '${comment.likes}',
                                size: 11,
                                variant: TextVariant.semiBold,
                                color: isUpvoted
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                maxLines: null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Downvote Button
                    GestureDetector(
                      onTap: () => controller.handleVote(comment, -1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              isDownvoted
                                  ? Icons.thumb_down_rounded
                                  : Icons.thumb_down_outlined,
                              size: 13,
                              color: isDownvoted
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            if (comment.dislikes > 0) ...[
                              const SizedBox(width: 4),
                              AnymeXText(
                                '${comment.dislikes}',
                                size: 11,
                                variant: TextVariant.semiBold,
                                color: isDownvoted
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                maxLines: null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Reply Button
                    if (onReplyTap != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReplyTap();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          child: AnymeXText(
                            'Reply',
                            size: 11.5,
                            variant: TextVariant.bold,
                            color: colorScheme.onSurfaceVariant,
                            maxLines: null,
                          ),
                        ),
                      ),

                    // Context menu (3-dot) - full parity with the main list
                    const Spacer(),
                    if (widget.onShowContextMenu != null)
                      GestureDetector(
                        onTap: () => widget.onShowContextMenu!(comment),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
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
    );

    // Minimal micro-indent and stylish primary branch line for sub-replies
    if (isNestedSubReply) {
      return AnymeXContainer(
        margin: const EdgeInsets.only(left: 10, top: 12),
        padding: const EdgeInsets.only(left: 12),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.45),
            width: 2,
          ),
        ),
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = widget.controller;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollSheetController) {
          return AnymeXContainer(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Drag Handle & Title Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    children: [
                      Center(
                        child: AnymeXContainer(
                          width: 36,
                          height: 4,
                          color: colorScheme.outlineVariant.opaque(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Obx(() {
                            final currentParent = controller
                                    .findCommentById(widget.rootComment.id) ??
                                widget.rootComment;
                            final count = _countReplies(currentParent);
                            return AnymeXText(
                              'Replies ($count)',
                              size: 16,
                              variant: TextVariant.bold,
                              color: colorScheme.onSurface,
                              maxLines: null,
                            );
                          }),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.15)),

                // Scrollable Area
                Expanded(
                  child: Obx(() {
                    final latestParent = controller
                            .findCommentById(widget.rootComment.id) ??
                        widget.rootComment;
                    final flatReplies = _flattenReplies(latestParent);

                    return ListView(
                      controller: scrollSheetController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        // Pinned Original Comment Header Card
                        AnymeXContainer(
                          padding: const EdgeInsets.all(12),
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.15),
                            width: 1,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.push_pin_rounded,
                                    size: 13,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  AnymeXText(
                                    'ORIGINAL COMMENT',
                                    size: 10,
                                    color: colorScheme.primary,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildCommentCard(
                                context: context,
                                comment: latestParent,
                                isRoot: true,
                                isNestedSubReply: false,
                                rootComment: latestParent,
                                onReplyTap: () {
                                  controller.setReplyTarget(latestParent);
                                  controller.focusCommentInput(_sheetFocusNode);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Replies Feed
                        if (flatReplies.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: AnymeXText(
                                'No replies yet. Be the first to reply!',
                                size: 13,
                                color: colorScheme.onSurfaceVariant.opaque(0.6),
                                maxLines: null,
                              ),
                            ),
                          )
                        else
                          ...flatReplies.map((reply) {
                            final isSubReply = reply.parentId != null &&
                                reply.parentId.toString() != latestParent.id;
                            final parentComment =
                                _findParentComment(reply, latestParent);

                            return _buildCommentCard(
                              context: context,
                              comment: reply,
                              isRoot: false,
                              isNestedSubReply: isSubReply,
                              parentComment: parentComment,
                              rootComment: latestParent,
                              onReplyTap: () {
                                controller.setReplyTarget(reply);
                                controller.focusCommentInput(_sheetFocusNode);
                              },
                            );
                          }),
                      ],
                    );
                  }),
                ),

                // Bottom Pinned Input Bar — floats above keyboard
                Padding(
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: CommentInputBar(
                    controller: controller,
                    focusNode: _sheetFocusNode,
                    onSubmitted: () {
                      // Scroll to bottom or keep in view
                    },
                  ),
                ),
              ],
            ),
          );
        },
    );
  }
}
