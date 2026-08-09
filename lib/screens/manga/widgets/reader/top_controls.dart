import 'dart:io';

import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/tabbed_reader_settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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
      final isDesktop = Platform.isWindows;
      final statusBarHeight = MediaQuery.paddingOf(context).top;
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
        borderRadius: BorderRadius.circular(50),
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
    String str = number.toStringAsFixed(4);
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      str = str.substring(0, str.length - 1);
    }
    return str;
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
                          child: AnymexText(
                            text: controller.currentChapter.value?.title ??
                                'Unknown Chapter',
                            size: 12,
                            variant: TextVariant.semiBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            isMarquee: true,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                    Text(
                      'Chapter ${_formatNumber(controller.currentChapter.value?.number)} of ${controller.chapterList.length}',
                      style: TextStyle(
                        color: context.colors.onSurface.withOpacity(0.7),
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
    AnymexSheet.custom(
      const ChapterListSheet(),
      context,
      showDragHandle: true,
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: context.colors.onSurface.opaque(0.2)),
      ),
      child: IconButton(
        onPressed: () =>
            TabbedReaderSettings(controller: controller).showSettings(context),
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
                  : (controller.currentSpreadIndex.value >= 0 &&
                          controller.currentSpreadIndex.value <
                              controller.spreads.length &&
                          controller
                              .spreads[controller.currentSpreadIndex.value]
                              .isTransition)
                      ? 'Chapter Transition'
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
}

class ChapterListSheet extends StatefulWidget {
  const ChapterListSheet({super.key});

  @override
  State<ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends State<ChapterListSheet> {
  final ReaderController controller = Get.find<ReaderController>();
  final TextEditingController _searchController = TextEditingController();
  bool _isReversed = false;
  bool _isGrid = false;
  String _searchQuery = '';
  late List<Chapter> _cachedChapters;

  @override
  void initState() {
    super.initState();
    _updateCachedChapters();
  }

  void _updateCachedChapters() {
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
    _cachedChapters = List<Chapter>.from(chapters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatNumber(double? number) {
    if (number == null) return '-';
    if (number % 1 == 0) return number.toInt().toString();
    String str = number.toStringAsFixed(4);
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 20, color: colors.primary),
                const SizedBox(width: 10),
                const AnymexText(
                  text: 'Chapters',
                  size: 16,
                  variant: TextVariant.bold,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_cachedChapters.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
                const Spacer(),
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
                    color: colors.primary,
                    size: 20,
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
                    _isGrid ? Icons.grid_view_rounded : Icons.view_list_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                  tooltip: _isGrid ? 'List View' : 'Grid View',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _updateCachedChapters();
                  });
                },
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search chapters...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface.withOpacity(0.45),
                  ),
                  prefixIcon: Icon(
                    IconlyLight.search,
                    size: 18,
                    color: colors.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 16,
                            color: colors.onSurface.withOpacity(0.5),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _updateCachedChapters();
                            });
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withOpacity(0.35),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.onSurface.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.primary.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _cachedChapters.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40,
                              color: colors.onSurface.withOpacity(0.4)),
                          const SizedBox(height: 8),
                          AnymexText(
                            text: 'No chapters found',
                            color: colors.onSurface.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  )
                : _isGrid
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _cachedChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _cachedChapters[index];
                          final isCurrent =
                              controller.currentChapter.value?.number ==
                                  chapter.number;
                          return _buildGridTile(chapter, isCurrent);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        itemCount: _cachedChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _cachedChapters[index];
                          final isCurrent =
                              controller.currentChapter.value?.number ==
                                  chapter.number;
                          return _buildListTile(chapter, isCurrent);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(Chapter chapter, bool isCurrent) {
    final colors = Theme.of(context).colorScheme;
    final formattedNum = _formatNumber(chapter.number);
    String displayTitle = chapter.title?.trim() ?? '';
    if (displayTitle.isEmpty ||
        displayTitle.toLowerCase() == 'chapter ${chapter.number}') {
      displayTitle = 'Chapter $formattedNum';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onChapterTap(chapter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? colors.primary.withOpacity(0.12)
                  : colors.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? colors.primary.withOpacity(0.4)
                    : colors.onSurface.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? colors.primary
                        : colors.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ch. $formattedNum',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? colors.onPrimary : colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnymexText.semiBold(
                    text: displayTitle,
                    size: 13,
                    color: isCurrent ? colors.primary : colors.onSurface,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(Chapter chapter, bool isCurrent) {
    final colors = Theme.of(context).colorScheme;
    final formattedNum = _formatNumber(chapter.number);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onChapterTap(chapter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isCurrent
                ? colors.primary.withOpacity(0.15)
                : colors.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? colors.primary.withOpacity(0.4)
                  : colors.onSurface.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ch. $formattedNum',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? colors.primary : colors.onSurface,
                ),
              ),
              if (chapter.title != null &&
                  chapter.title!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    chapter.title!.trim(),
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      color: isCurrent
                          ? colors.primary.withOpacity(0.8)
                          : colors.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onChapterTap(Chapter chapter) {
    FocusScope.of(context).unfocus();
    final index =
        controller.chapterList.indexWhere((c) => c.number == chapter.number);
    Navigator.of(context, rootNavigator: true).pop();
    if (index != -1 &&
        controller.currentChapter.value?.number != chapter.number) {
      controller.navigateToChapter(index);
    }
  }
}
