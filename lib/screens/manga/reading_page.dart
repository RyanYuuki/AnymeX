import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/bottom_controls.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_view.dart';
import 'package:anymex/screens/manga/widgets/reader/top_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:anymex/models/Offline/Hive/chapter.dart';

enum ReadingMode {
  webtoon,
  ltr,
  rtl,
}

class ReadingPage extends StatefulWidget {
  final Media anilistData;
  final List<Chapter> chapterList;
  final Chapter currentChapter;

  const ReadingPage({
    super.key,
    required this.anilistData,
    required this.chapterList,
    required this.currentChapter,
  });

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final controller = Get.put(ReaderController());

  @override
  void initState() {
    super.initState();
    controller.init(
        widget.anilistData, widget.chapterList, widget.currentChapter);
  }

  @override
  void dispose() {
    Get.delete<ReaderController>();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(
        () => Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => controller.toggleControls(),
              // Force multiple taps to trigger single tap instead
              onDoubleTap: () {},
              child: ReaderView(controller: controller),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: controller.showControls.value ? 0 : -200,
              left: 0,
              right: 0,
              child: ReaderTopControls(controller: controller),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: controller.showControls.value ? 0 : -200,
              left: 0,
              right: 0,
              child: ReaderBottomControls(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}
