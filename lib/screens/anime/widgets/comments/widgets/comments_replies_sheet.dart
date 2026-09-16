import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/comment_input_bar.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsRepliesSheet extends StatefulWidget {
  final Comment rootComment;
  final CommentSectionController controller;

  const CommentsRepliesSheet({
    super.key,
    required this.rootComment,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required Comment rootComment,
    required CommentSectionController controller,
    Comment? initialReplyTarget,
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
    try {
      final date = DateTime.parse(timestamp);
      return timeago.format(date, locale: 'en_short');
    } catch (_) {
      return timestamp;
    }
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
    final isSpoiler = comment.tag.toLowerCase().contains('spoiler');

    final hasRole = comment.userRole != null &&
        comment.userRole != 'user' &&
        comment.userRole!.isNotEmpty;

    final showParentBreadcrumb = isNestedSubReply &&
        parentComment != null &&
        rootComment != null &&
        parentComment.id != rootComment.id;

    Widget card = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        ClipOval(
          child: comment.avatarUrl?.isNotEmpty == true
              ? AnymeXImage(
                  imageUrl: comment.avatarUrl!,
                  width: isNestedSubReply ? 26 : (isRoot ? 34 : 30),
                  height: isNestedSubReply ? 26 : (isRoot ? 34 : 30),
                  fit: BoxFit.cover,
                  radius: 0,
                )
              : Container(
                  width: isNestedSubReply ? 26 : (isRoot ? 34 : 30),
                  height: isNestedSubReply ? 26 : (isRoot ? 34 : 30),
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                  if (hasRole) _buildRoleBadge(context, comment.userRole!),
                  Flexible(
                    child: Text(
                      comment.username,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hasRole
                            ? _getRoleColor(comment.userRole!)
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (showParentBreadcrumb) ...[
                    Icon(Icons.arrow_right,
                        size: 18, color: colorScheme.primary),
                    Flexible(
                      child: Text(
                        parentComment.username,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: parentComment.userRole != null &&
                                  parentComment.userRole != 'user' &&
                                  parentComment.userRole!.isNotEmpty
                              ? _getRoleColor(parentComment.userRole!)
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(comment.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.opaque(0.6),
                    ),
                  ),
                ],
              ),

              // Existing Comment Tag Badge (preserved)
              if (comment.tag.isNotEmpty && comment.tag != 'General')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSpoiler
                          ? colorScheme.error.withValues(alpha: 0.15)
                          : colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      comment.tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            isSpoiler ? colorScheme.error : colorScheme.primary,
                      ),
                    ),
                  ),
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
                              Text(
                                '${comment.likes}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isUpvoted
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

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
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
      return Container(
        margin: const EdgeInsets.only(left: 10, top: 12),
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.45),
              width: 2,
            ),
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollSheetController) {
          return Container(
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
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant.opaque(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
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
                            return Text(
                              'Replies ($count)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.15),
                              width: 1,
                            ),
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
                                  Text(
                                    'ORIGINAL COMMENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: colorScheme.primary,
                                    ),
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
                                  _sheetFocusNode.requestFocus();
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
                              child: Text(
                                'No replies yet. Be the first to reply!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      colorScheme.onSurfaceVariant.opaque(0.6),
                                ),
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
                                _sheetFocusNode.requestFocus();
                              },
                            );
                          }),
                      ],
                    );
                  }),
                ),

                // Bottom Pinned Input Bar with dedicated sheet focus node
                CommentInputBar(
                  controller: controller,
                  focusNode: _sheetFocusNode,
                  onSubmitted: () {
                    // Scroll to bottom or keep in view
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
