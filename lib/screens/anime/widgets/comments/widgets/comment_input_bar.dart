import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/gif_picker_sheet.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
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
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  TextEditingController get _effectiveTextController =>
      widget.textController ?? widget.controller.commentController;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
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

  void _openGifPicker(BuildContext context) {
    GifPickerSheet.show(
      context,
      onGifSelected: (url) => _insertGif(url),
    );
  }

  void _insertGif(String url) {
    final controller = _effectiveTextController;
    final currentText = controller.text;
    final space = currentText.isNotEmpty &&
            !currentText.endsWith(' ') &&
            !currentText.endsWith('\n')
        ? '\n'
        : '';
    controller.text = '$currentText$space$url\n';
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
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
      final isFocused = _effectiveFocusNode.hasFocus;

      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Replying to @user Sleek Micro-Chip
              if (replyingTo != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
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
                        Text(
                          'Replying to ',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '@${replyingTo.username}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.clearReplyTarget();
                          },
                          child: Container(
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

              // 2. Main Modern Input Box Row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current User Avatar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
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

                    // Modern Pill Input Area with instant tap activation
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _effectiveFocusNode.requestFocus(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isFocused
                                  ? colorScheme.primary.withValues(alpha: 0.6)
                                  : colorScheme.outlineVariant
                                      .withValues(alpha: 0.15),
                              width: isFocused ? 1.4 : 1,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: TextField(
                            controller: _effectiveTextController,
                            focusNode: _effectiveFocusNode,
                            autofocus: widget.autofocus,
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
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.55),
                                fontSize: 14,
                              ),
                              // Explicitly kill every Material border/fill variant
                              // so nothing bleeds outside our AnimatedContainer corners
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Sleek Modern Send Button
                    GestureDetector(
                      onTap: hasText && !isSubmitting
                          ? () async {
                              HapticFeedback.lightImpact();
                              await controller.submitCurrentText();
                              widget.onSubmitted?.call();
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasText && !isSubmitting
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                          boxShadow: hasText && !isSubmitting
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: ExpressiveLoadingIndicator(),
                                )
                              : Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 20,
                                  color: hasText
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Compact Formatting Toolbar & Locked Progress Tag — only when focused
              if (isFocused || hasText)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Row(
                    children: [
                      // Auto-Selected & Locked Progress Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.22),
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
                                fontSize: 11,
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
                          controller: _effectiveTextController,
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
