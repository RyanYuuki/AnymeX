import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/bottom_controls.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_view.dart';
import 'package:anymex/screens/manga/widgets/reader/top_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:anymex/models/Offline/Hive/chapter.dart';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          ReaderView(controller: controller),
          ReaderTopControls(controller: controller),
          ReaderBottomControls(controller: controller),
        ],
      ),
    );
  }
}
