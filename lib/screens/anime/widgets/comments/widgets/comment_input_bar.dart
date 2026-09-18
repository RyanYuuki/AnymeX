import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/mention_autocomplete.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/non_widgets/activity_composer_sheet.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CommentInputBar extends StatefulWidget {
  final CommentSectionController controller;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final TextEditingController? textController;
  final bool autofocus;

  const CommentInputBar({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.focusNode,
    this.textController,
    this.autofocus = false,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final LayerLink _layerLink = LayerLink();
  FocusNode? _internalFocusNode;
  List<Map<String, dynamic>>? _cachedLocalUsers;
  int _lastCommentsLength = -1;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  TextEditingController get _effectiveTextController =>
      widget.textController ?? widget.controller.commentController;

  List<Map<String, dynamic>> _getLocalUsers(List<Comment> comments) {
    if (_cachedLocalUsers != null && _lastCommentsLength == comments.length) {
      return _cachedLocalUsers!;
    }
    _lastCommentsLength = comments.length;
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
    _cachedLocalUsers = list;
    return list;
  }

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _effectiveFocusNode.requestFocus();
      });
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = widget.controller;

    return Obx(() {
      final replyingTo = controller.activeReplyComment.value;
      final isAnime = controller.media.mediaType == ItemType.anime;
      final tagText = controller.tag.value.isNotEmpty
          ? controller.tag.value
          : CommentSectionController.getAutoProgressTag(
              controller.media, controller.initialProgress);

      final localUsers = _getLocalUsers(controller.comments);

      return AnymeXContainer(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ActivityComposerSheet(
                  flavor: ComposerFlavor.comment,
                  textController: _effectiveTextController,
                  focusNode: _effectiveFocusNode,
                  layerLink: _layerLink,
                  hintText: replyingTo != null
                      ? (replyingTo.deleted
                          ? 'Reply to thread...'
                          : 'Reply to @${replyingTo.username}...')
                      : 'Add a comment...',
                  leadingWidget: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Obx(() {
                      final deco = Get.isRegistered<CommentumService>()
                          ? Get.find<CommentumService>().currentUserDecoration.value
                          : null;
                      return AnymeXDecoratedAvatar(
                        avatarUrl: controller.profile.avatar,
                        decorationUrl: deco,
                        size: 34,
                      );
                    }),
                  ),
                  headerWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Replying to @user Sleek Micro-Chip
                      if (replyingTo != null)
                        Padding(
                          key: const ValueKey('comment_replying_to_chip'),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AnymeXContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                AnymeXText(
                                  'Replying to ',
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                AnymeXText(
                                  replyingTo.deleted
                                      ? 'thread'
                                      : '@${replyingTo.username}',
                                  size: 12,
                                  variant: TextVariant.bold,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    controller.clearReplyTarget();
                                  },
                                  child: AnymeXContainer(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.7),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 2. Progress Tag Chip if text is not empty or focused
                      if (_effectiveFocusNode.hasFocus ||
                          _effectiveTextController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AnymeXContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.22),
                              width: 1,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAnime
                                      ? Icons.play_circle_outline_rounded
                                      : Icons.menu_book_rounded,
                                  size: 13,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                AnymeXText(
                                  tagText,
                                  size: 11,
                                  variant: TextVariant.bold,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  onSubmit: (text, {isPrivate = false}) async {
                    HapticFeedback.lightImpact();
                    await controller.submitCurrentText();
                    widget.onSubmitted?.call();
                    return true;
                  },
                ),
                MentionAutocomplete(
                  controller: _effectiveTextController,
                  layerLink: _layerLink,
                  focusNode: _effectiveFocusNode,
                  localUsers: localUsers,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
