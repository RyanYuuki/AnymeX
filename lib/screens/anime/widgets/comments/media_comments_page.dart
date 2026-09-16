import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/comments_section.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/comment_input_bar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/policy_sheet.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaCommentsPage extends StatefulWidget {
  final Media media;
  final int initialProgress;
  final String? scrollToCommentId;

  const MediaCommentsPage({
    super.key,
    required this.media,
    this.initialProgress = 0,
    this.scrollToCommentId,
  });

  @override
  State<MediaCommentsPage> createState() => _MediaCommentsPageState();
}

class _MediaCommentsPageState extends State<MediaCommentsPage> {
  late CommentSectionController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final preloaded =
        CommentPreloader.to.getPreloadedController(widget.media.uniqueId);
    if (preloaded != null) {
      controller = preloaded;
      controller.updateProgress(widget.initialProgress);
    } else {
      controller = Get.put(
        CommentSectionController(
          media: widget.media,
          initialProgress: widget.initialProgress,
        ),
        tag: widget.media.uniqueId,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String formatName;
    switch (widget.media.mediaType) {
      case ItemType.anime:
        formatName = 'Anime';
        break;
      case ItemType.novel:
        formatName = 'Novel';
        break;
      case ItemType.manga:
      default:
        formatName = 'Manga';
        break;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            if (widget.media.poster.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AnymeXImage(
                  imageUrl: widget.media.poster,
                  width: 32,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            else
              AnymeXContainer(
                width: 32,
                height: 44,
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                child: Icon(
                  Icons.movie_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    widget.media.title.isNotEmpty
                        ? widget.media.title
                        : 'Comments',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    size: 14.5,
                    variant: TextVariant.bold,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      AnymeXContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        child: AnymeXText(
                          formatName,
                          size: 10,
                          variant: TextVariant.bold,
                          color: colorScheme.primary,
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Obx(() => AnymeXText(
                            '${controller.totalCommentsCount.value} Comments',
                            size: 11,
                            color: colorScheme.onSurfaceVariant,
                            maxLines: null,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (sort) => controller.setSort(sort),
            icon: Icon(
              Icons.sort_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Sort comments',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'top',
                child: Row(
                  children: [
                    if (controller.currentSort.value == 'top')
                      Icon(Icons.check_rounded,
                          size: 18, color: colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const AnymeXText('Top comments', maxLines: null),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    if (controller.currentSort.value == 'newest')
                      Icon(Icons.check_rounded,
                          size: 18, color: colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const AnymeXText('Newest first', maxLines: null),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    if (controller.currentSort.value == 'oldest')
                      Icon(Icons.check_rounded,
                          size: 18, color: colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const AnymeXText('Oldest first', maxLines: null),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined, size: 20),
            onPressed: () => showPolicySheet(context, PolicyType.commentRules),
            tooltip: 'Comment Rules',
          ),
          Obx(() => IconButton(
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
                    : const Icon(Icons.refresh_rounded, size: 20),
                onPressed: controller.isRefreshing.value
                    ? null
                    : () => controller.forceRefresh(),
                tooltip: 'Refresh comments',
              )),
          const SizedBox(width: 4),
        ],
      ),
      // resizeToAvoidBottomInset pushes the body upward when the keyboard appears,
      // which causes CommentInputBar (the last Column child) to naturally float
      // above the keyboard without any manual inset math needed.
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              // Dismiss keyboard when user scrolls down
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                children: [
                  CommentSection(
                    media: widget.media,
                    scrollToCommentId: widget.scrollToCommentId,
                    showInlineInput: false,
                    // AppBar already shows poster, title, count, sort, rules
                    // and refresh — the section's own header would duplicate it.
                    showHeader: false,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // CommentInputBar is OUTSIDE the scrollable — resizeToAvoidBottomInset
          // shrinks the Scaffold body so this widget always stays above the keyboard.
          CommentInputBar(
            controller: controller,
            focusNode: controller.commentFocusNode,
          ),
        ],
      ),
    );
  }
}
