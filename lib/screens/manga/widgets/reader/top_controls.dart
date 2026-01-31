import 'dart:io';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReaderTopControls extends StatelessWidget {
  final ReaderController controller;

  const ReaderTopControls({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      final mediaQuery = MediaQuery.of(context);
      final statusBarHeight = mediaQuery.padding.top;
      const topControlsHeight = 50.0;
      const gapBetweenControls = 8.0;

      final topControlsVisiblePosition =
          statusBarHeight + 8 + (isDesktop ? 40 : 0);
      final topControlsHiddenPosition =
          -(statusBarHeight + topControlsHeight + gapBetweenControls + 20);

      final pageInfoVisiblePosition =
          topControlsVisiblePosition + topControlsHeight + gapBetweenControls;
      final pageInfoHiddenPosition = statusBarHeight + 8;

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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: controller.showControls.value
                ? pageInfoVisiblePosition
                : pageInfoHiddenPosition,
            left: 0,
            right: 0,
            child: Center(
              child: _buildPageInfo(context),
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

  String _formatNumber(double? number) {
    if (number == null) return '-';
    if (number % 1 == 0) return number.toInt().toString();
    return number.toString();
  }

  Widget _buildChapterInfo(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showChaptersList(context),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: AnymexProgressIndicator(
                  value: controller.pageList.isEmpty
                      ? 0
                      : (controller.currentPageIndex.value /
                          controller.pageList.length),
                  strokeWidth: 2,
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.currentChapter.value?.title ??
                                'Unknown Chapter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                    Text(
                      'Chapter ${_formatNumber(controller.currentChapter.value?.number)} of ${controller.chapterList.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
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
          minChildSize: 0.4,
          maxChildSize: 0.9,
          snap: true,
          expand: false,
          builder: (context, scrollController) {
            return ChapterListSheet(scrollController: scrollController);
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
        onPressed: () => _showSettings(context),
        icon: Icon(Icons.settings_rounded,
            color: context.colors.onSurface, size: 18),
      ),
    );
  }

  Widget _buildPageInfo(BuildContext context) {
    return AnimatedOpacity(
      opacity: controller.showPageIndicator.value
          ? 1
          : controller.showControls.value
              ? 1
              : 0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.onSurface.opaque(0.15)),
        ),
        child: Text(
          controller.loadingState.value == LoadingState.loading
              ? 'Loading...'
              : controller.loadingState.value == LoadingState.error
                  ? 'Error loading pages'
                  : 'Page ${controller.currentPageIndex.value} of ${controller.pageList.length}',
          style: TextStyle(
            color: context.colors.onSurface.opaque(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    ReaderSettings(controller: controller).showSettings(context);
  }
}

class ChapterListSheet extends StatefulWidget {
  final ScrollController scrollController;
  
  const ChapterListSheet({super.key, required this.scrollController});

  @override
  State<ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends State<ChapterListSheet> {
  final ReaderController controller = Get.find<ReaderController>();
  final TextEditingController _searchController = TextEditingController();
  bool _isReversed = false;
  bool _isGrid = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatNumber(double? number) {
    if (number == null) return '-';
    if (number % 1 == 0) return number.toInt().toString();
    return number.toString();
  }

  @override
  @override
  Widget build(BuildContext context) {
    var chapters = List.from(controller.chapterList);

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

    // final currentChapter = controller.currentChapter.value; (Unused)

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                   // Drag Handle
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
                              'Chapters (${chapters.length})',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontFamily: 'Poppins-Bold',
                                  ),
                            ),
                            Row(
                              children: [
                                 IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isReversed = !_isReversed;
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
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isGrid = !_isGrid;
                                    });
                                  },
                                  icon: Icon(
                                    _isGrid
                                        ? Icons.grid_view_rounded
                                        : Icons.view_list_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  tooltip: _isGrid ? 'List View' : 'Grid View',
                                ),
                              ],
                            ),
                          ],
                        ),
                       
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search chapters...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
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
            _buildContentSlivers(chapters),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSlivers(List chapters) {
    if (chapters.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: Colors.grey.withOpacity(0.5)),
              const SizedBox(height: 10),
              const Text('No chapters found'),
            ],
          ),
        ),
      );
    }

    if (_isGrid) {
      return SliverPadding(
        padding: const EdgeInsets.all(10),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final chapter = chapters[index];
              final isCurrent =
                  controller.currentChapter.value?.number == chapter.number;
              final formattedNum = _formatNumber(chapter.number);

              return InkWell(
                onTap: () => _onChapterTap(chapter),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        isCurrent ? null : Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formattedNum,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : null,
                        ),
                      ),
                      if (chapter.title != null && chapter.title!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            chapter.title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: isCurrent ? Colors.white70 : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            childCount: chapters.length,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chapter = chapters[index];
          final isCurrent =
              controller.currentChapter.value?.number == chapter.number;
          return _buildListItem(chapter, isCurrent);
        },
        childCount: chapters.length,
      ),
    );
  }

  Widget _buildListItem(dynamic chapter, bool isCurrent) {
    final formattedNum = _formatNumber(chapter.number);
    String displayTitle = chapter.title ?? '';
    final prefix = 'Chapter $formattedNum';

    if (displayTitle.isEmpty || displayTitle == 'Chapter ${chapter.number}') {
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
        onTap: () => _onChapterTap(chapter),
      ),
    );
  }

  void _onChapterTap(dynamic chapter) {
    FocusScope.of(context).unfocus();
    final index =
        controller.chapterList.indexWhere((c) => c.number == chapter.number);
    Get.back();
    if (index != -1 &&
        controller.currentChapter.value?.number != chapter.number) {
      controller.navigateToChapter(index);
    }
  }
}
