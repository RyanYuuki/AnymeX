import 'package:anymex/database/comments/model/commentum_role.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
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
import 'package:anymex/services/commentum_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    return AnymeXSheet.custom(
      CommentsRepliesSheet(
        rootComment: rootComment,
        controller: controller,
        onShowContextMenu: onShowContextMenu,
      ),
      context,
    );
  }

  @override
  State<CommentsRepliesSheet> createState() => _CommentsRepliesSheetState();
}

class _CommentsRepliesSheetState extends State<CommentsRepliesSheet> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _sheetFocusNode = FocusNode();
  final Map<String, GlobalKey> _commentKeys = {};
  String? _highlightedCommentId;

  @override
  void dispose() {
    _scrollController.dispose();
    _sheetFocusNode.dispose();
    widget.controller.clearReplyTarget();
    super.dispose();
  }

  void _scrollToComment(String commentId) {
    final key = _commentKeys[commentId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
      setState(() {
        _highlightedCommentId = commentId;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _highlightedCommentId == commentId) {
          setState(() {
            _highlightedCommentId = null;
          });
        }
      });
    }
  }

  String _formatTime(String timestamp) {
    return CommentSectionController.formatCommentTimestamp(timestamp);
  }

  Color _getRoleColor(String role) {
    return CommentumRoleConfig.getRoleColor(context, role);
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
    final currentUserId =
        Get.find<ServiceHandler>().profileData.value.id?.toString();

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
                        if ((comment.badges != null && comment.badges!.isNotEmpty) ||
                            hasRole ||
                            (!isRoot && (comment.userId == widget.rootComment.userId))) ...[
                          const SizedBox(width: 4),
                          DiscordBadgesRow(
                            badges: comment.badges,
                            role: comment.userRole,
                            size: 13.0,
                            isOp: !isRoot && (comment.userId == widget.rootComment.userId),
                          ),
                        ],
                        if (showParentBreadcrumb) ...[
                          Icon(Icons.arrow_right,
                              size: 18, color: colorScheme.primary),
                          Flexible(
                            child: GestureDetector(
                              onTap: parentComment.deleted
                                  ? null
                                  : () => _scrollToComment(parentComment.id),
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

              // Actions Row: Reply + Edit + Upvote + Downvote + 3-Dot (all right-aligned)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Spacer(),
                    // Reply Button
                    if (onReplyTap != null) ...[
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReplyTap();
                        },
                        child: AnymeXText(
                          'Reply',
                          size: 12,
                          variant: TextVariant.semiBold,
                          color: colorScheme.onSurfaceVariant,
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Edit Button (if own comment)
                    if (comment.userId == currentUserId) ...[
                      Obx(() {
                        final isEditingThis =
                            controller.activeEditComment.value?.id ==
                                comment.id;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (isEditingThis) {
                              controller.cancelEdit();
                            } else {
                              controller.setEditTarget(comment);
                            }
                          },
                          child: AnymeXText(
                            isEditingThis ? 'Cancel' : 'Edit',
                            size: 12,
                            variant: TextVariant.semiBold,
                            color: isEditingThis
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                            maxLines: null,
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                    ],

                    // Upvote Button
                    _buildCompactVoteButton(
                      icon: Icons.arrow_upward_rounded,
                      count: comment.likes,
                      isActive: isUpvoted,
                      onTap: () => controller.handleVote(comment, 1),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 10),

                    // Downvote Button
                    _buildCompactVoteButton(
                      icon: Icons.arrow_downward_rounded,
                      count: comment.dislikes,
                      isActive: isDownvoted,
                      onTap: () => controller.handleVote(comment, -1),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 10),

                    // Context menu (3-dot)
                    if (widget.onShowContextMenu != null)
                      GestureDetector(
                        onTap: () => widget.onShowContextMenu!(comment),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.opaque(0.6),
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

      card = AnymeXContainer(
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
        child: AnymeXContainer(
          padding: const EdgeInsets.all(10),
          color: Colors.black.withOpacity(0.55),
          child: card,
        ),
      );
    }

    final isHighlighted = _highlightedCommentId == comment.id;
    final avatarSize = isNestedSubReply ? 26.0 : (isRoot ? 34.0 : 30.0);

    final content = isNestedSubReply && parentComment != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReplyHook(
                context: context,
                parentComment: parentComment,
                avatarSize: avatarSize,
                onTap: () => _scrollToComment(parentComment.id),
              ),
              card,
            ],
          )
        : card;

    return KeyedSubtree(
      key: _commentKeys.putIfAbsent(comment.id, () => GlobalKey()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isHighlighted
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = widget.controller;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
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
                      controller: _scrollController,
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
  }

  Widget _buildCompactVoteButton({
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

  Widget _buildReplyHook({
    required BuildContext context,
    required Comment parentComment,
    required double avatarSize,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final parentUsername =
        parentComment.deleted ? 'deleted' : parentComment.username;
    final parentSnippet = parentComment.deleted
        ? '[deleted comment]'
        : parentComment.commentText.replaceAll('\n', ' ').trim();
    final avatarCenter = avatarSize / 2;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.0,
          child: SizedBox(
            height: 15,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomPaint(
                  size: Size(avatarCenter + 6, 15),
                  painter: _HookLinePainter(
                    startX: avatarCenter,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 4),
                AnymeXText(
                  '@$parentUsername',
                  size: 11,
                  variant: TextVariant.bold,
                  color: colorScheme.primary.withValues(alpha: 0.85),
                  maxLines: 1,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AnymeXText(
                    parentSnippet,
                    size: 10.5,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HookLinePainter extends CustomPainter {
  final double startX;
  final Color color;

  _HookLinePainter({required this.startX, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(startX, size.height);
    path.lineTo(startX, size.height * 0.5 + 3);
    path.quadraticBezierTo(
        startX, size.height * 0.5, startX + 3, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HookLinePainter oldDelegate) {
    return oldDelegate.startX != startX || oldDelegate.color != color;
  }
}
