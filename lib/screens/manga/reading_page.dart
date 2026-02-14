import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/bottom_controls.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_view.dart';
import 'package:anymex/screens/manga/widgets/reader/top_controls.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:anymex/database/isar_models/chapter.dart';

class ReadingPage extends StatefulWidget {
  final Media anilistData;
  final List<Chapter> chapterList;
  final Chapter currentChapter;
  final bool shouldTrack;

  const ReadingPage({
    super.key,
    required this.anilistData,
    required this.chapterList,
    required this.currentChapter,
    required this.shouldTrack,
  });

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late final ReaderController controller =
      Get.put(ReaderController(shouldTrack: widget.shouldTrack));
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller.init(
        widget.anilistData, widget.chapterList, widget.currentChapter);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    Get.delete<ReaderController>();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final currentPage = controller.currentPageIndex.value;
      final totalPages = controller.pageList.length;


        final isReversed = controller.readingDirection.value.reversed;
        bool isNext = false;
        bool isPrev = false;

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          isNext = true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          isPrev = true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          isNext = !isReversed;
          isPrev = isReversed;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          isNext = isReversed;
          isPrev = !isReversed;
        }

        if (isNext) {
          if (currentPage < totalPages) {
            controller.navigateToPage(currentPage);
          }
        } else if (isPrev) {
          if (currentPage > 1) {
            controller.navigateToPage(currentPage - 2);
          }
        }

    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ReaderView(controller: controller),
              ReaderTopControls(controller: controller),
              ReaderBottomControls(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
