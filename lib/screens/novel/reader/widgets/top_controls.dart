// ignore_for_file: deprecated_member_use

import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NovelTopControls extends StatelessWidget {
  final NovelReaderController controller;

  const NovelTopControls({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mediaQuery = MediaQuery.of(context);
      final statusBarHeight = mediaQuery.padding.top;
      const topControlsHeight = 50.0;
      const gapBetweenControls = 8.0;

      final topControlsVisiblePosition = statusBarHeight + 8;
      final topControlsHiddenPosition =
          -(statusBarHeight + topControlsHeight + gapBetweenControls + 20);

      return Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: controller.showControls.value
                ? topControlsVisiblePosition
                : topControlsHiddenPosition,
            left: 10,
            right: 10,
            child: SizedBox(
              height: topControlsHeight,
              child: Row(
                children: [
                  _buildBackButton(context),
                  const SizedBox(width: 6),
                  _buildChapterInfo(context),
                  const SizedBox(width: 6),
                  _buildSettingsButton(context),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.onSurface.opaque(0.2)),
      ),
      child: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(Icons.arrow_back_ios_new,
            color: context.colors.onSurface, size: 18),
      ),
    );
  }

  Widget _buildChapterInfo(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showChaptersList(context),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.onSurface.opaque(0.15)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: AnymexProgressIndicator(
                  value: controller.novelContent.isEmpty
                      ? 0
                      : controller.progress.value,
                  strokeWidth: 2,
                  backgroundColor: context.colors.onSurface.opaque(0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.currentChapter.value.title ??
                                'Unknown Chapter',
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Chapter ${controller.currentChapter.value.number?.round() ?? '-'} of ${controller.chapters.last.number?.round() ?? '-'}',
                            style: TextStyle(
                              color: context.colors.onSurface.opaque(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down,
                        size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChaptersList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.5],
          expand: false,
          builder: (context, scrollController) {
            return ChapterListSheet(
              controller: controller,
              // Pass the DraggableScrollableSheet's own controller so the
              // sheet itself can be dragged. ChapterListSheet will use this
              // for its own list, not the reader's scrollController.
              sheetScrollController: scrollController,
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.onSurface.opaque(0.2)),
      ),
      child: IconButton(
        onPressed: () => controller.toggleSettings(),
        icon: Icon(Icons.settings_rounded,
            color: context.colors.onSurface, size: 18),
      ),
    );
  }
}

class ChapterListSheet extends StatefulWidget {
  final NovelReaderController controller;
  final ScrollController sheetScrollController;

  const ChapterListSheet({
    super.key,
    required this.controller,
    required this.sheetScrollController,
  });

  @override
  State<ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends State<ChapterListSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isReversed = false;
  String _searchQuery = '';
  late List<Chapter> _cachedChapters;

  @override
  void initState() {
    super.initState();
    _updateCachedChapters();
    // After first frame, scroll so current chapter is visible in the list.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToCurrentChapter());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateCachedChapters() {
    var chapters = List.from(widget.controller.chapters);
    if (_isReversed) {
      chapters = chapters.reversed.toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      chapters = chapters.where((c) {
        final title = (c.title ?? '').toLowerCase();
        final num = (c.number?.toString() ?? '').toLowerCase();
        return title.contains(query) || num.contains(query);
      }).toList();
    }
    _cachedChapters = List<Chapter>.from(chapters);
  }

  void _scrollToCurrentChapter() {
    final currentNumber = widget.controller.currentChapter.value?.number;
    if (currentNumber == null) return;
    final index =
        _cachedChapters.indexWhere((c) => c.number == currentNumber);
    if (index <= 0) return;
    if (!widget.sheetScrollController.hasClients) return;
    // Dense ListTile ~48px; scroll so the current chapter is visible near top.
    final maxExtent =
        widget.sheetScrollController.position.maxScrollExtent;
    final target = (index * 48.0).clamp(0.0, maxExtent);
    widget.sheetScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _formatNumber(double? number) {
    if (number == null) return '-';
    if (number % 1 == 0) return number.toInt().toString();
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CustomScrollView(
          // Use the DraggableScrollableSheet controller so dragging works,
          // NOT the novel reader's scrollController.
          controller: widget.sheetScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    height: 5,
                    width: 40,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chapters (${_cachedChapters.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontFamily: 'Poppins-Bold',
                                  ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isReversed = !_isReversed;
                                  _updateCachedChapters();
                                });
                              },
                              icon: Icon(
                                _isReversed
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              tooltip: _isReversed ? 'Ascending' : 'Descending',
                            ),
                          ],
                        ),
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                              _updateCachedChapters();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search chapters...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.5),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _updateCachedChapters();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = _cachedChapters[index];
                  final isCurrent =
                      widget.controller.currentChapter.value?.number ==
                          chapter.number;
                  return _buildListItem(chapter, isCurrent);
                },
                childCount: _cachedChapters.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Chapter chapter, bool isCurrent) {
    final formattedNum = _formatNumber(chapter.number);
    String displayTitle = chapter.title ?? '';
    final prefix = 'Chapter $formattedNum';

    if (displayTitle.isEmpty ||
        displayTitle == 'Chapter ${chapter.number}') {
      displayTitle = prefix;
    } else if (!displayTitle.toLowerCase().contains('chapter')) {
      displayTitle = '$prefix: $displayTitle';
    }

    return Container(
      color: isCurrent
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        dense: true,
        title: Text(
          displayTitle,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        trailing: isCurrent
            ? Icon(Icons.check_circle_rounded,
                size: 20, color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () {
          FocusScope.of(context).unfocus();
          Get.back();
          if (!isCurrent) {
            final index = widget.controller.chapters
                .indexWhere((c) => c.number == chapter.number);
            if (index != -1) {
              widget.controller.navigateToChapter(index);
            }
          }
        },
      ),
    );
  }
}
