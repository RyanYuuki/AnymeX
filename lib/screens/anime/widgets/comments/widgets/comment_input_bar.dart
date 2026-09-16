import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/gif_picker_sheet.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommentInputBar extends StatefulWidget {
  final CommentSectionController controller;
  final VoidCallback? onSubmitted;

  const CommentInputBar({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  void _openGifPicker(BuildContext context) {
    GifPickerSheet.show(
      context,
      onGifSelected: (url) => _insertGif(url),
    );
  }

  void _insertGif(String url) {
    final controller = widget.controller.commentController;
    final currentText = controller.text;
    final space = currentText.isNotEmpty && !currentText.endsWith(' ') && !currentText.endsWith('\n')
        ? '\n'
        : '';
    final formatted = '<img src="$url" width="auto" height="auto">';
    controller.text = '$currentText$space$formatted\n';
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = widget.controller;

    return Obx(() {
      final replyingTo = controller.activeReplyComment.value;
      final isSubmitting = controller.isSubmitting.value;
      final text = controller.commentContent.value.trim();
      final hasText = text.isNotEmpty;
      final tagText = controller.tag.value.isNotEmpty
          ? controller.tag.value
          : CommentSectionController.getAutoProgressTag(
              controller.media, controller.initialProgress);

      final isAnime = controller.media.mediaType == ItemType.anime;

      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.opaque(0.96),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.opaque(0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Replying to @user Banner
              if (replyingTo != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: 'Replying to '),
                              TextSpan(
                                text: '@${replyingTo.username}',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.clearReplyTarget,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest.opaque(0.5),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. Main Input Box Row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current User Avatar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ClipOval(
                        child: controller.profile.avatar?.isNotEmpty == true
                            ? AnymeXImage(
                                imageUrl: controller.profile.avatar!,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                                radius: 0,
                              )
                            : Container(
                                width: 34,
                                height: 34,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Expandable Input Area
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.opaque(0.35),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: controller.commentFocusNode.hasFocus
                                ? colorScheme.primary.opaque(0.5)
                                : colorScheme.outlineVariant.opaque(0.2),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: controller.commentController,
                          focusNode: controller.commentFocusNode,
                          maxLines: 4,
                          minLines: 1,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: replyingTo != null
                                ? 'Reply to @${replyingTo.username}...'
                                : 'Add a comment...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.opaque(0.6),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send Button
                    GestureDetector(
                      onTap: hasText && !isSubmitting
                          ? () async {
                              await controller.submitCurrentText();
                              widget.onSubmitted?.call();
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasText && !isSubmitting
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest.opaque(0.4),
                          boxShadow: hasText && !isSubmitting
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: ExpressiveLoadingIndicator(),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                  color: hasText
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant.opaque(0.4),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Compact Formatting Toolbar & Locked Progress Tag
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Row(
                  children: [
                    // Auto-Selected & Locked Progress Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
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
                          Text(
                            tagText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Markdown Formatting Buttons (Bold, Italic, Strike, Code, Spoiler, Quote, GIF)
                    Expanded(
                      child: MarkdownFormattingToolbar(
                        controller: controller.commentController,
                        colorScheme: colorScheme,
                        onGifTap: () => _openGifPicker(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
