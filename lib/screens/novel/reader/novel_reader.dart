import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/screens/novel/reader/widgets/bottom_controls.dart';
import 'package:anymex/screens/novel/reader/widgets/novel_content.dart';
import 'package:anymex/screens/novel/reader/widgets/settings_view.dart';
import 'package:anymex/screens/novel/reader/widgets/top_controls.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

class NovelReader extends StatefulWidget {
  final Chapter chapter;
  final Media media;
  final List<Chapter> chapters;
  final Source source;

  const NovelReader({
    super.key,
    required this.chapter,
    required this.media,
    required this.chapters,
    required this.source,
  });

  @override
  State<NovelReader> createState() => _NovelReaderState();
}

class _NovelReaderState extends State<NovelReader>
    with TickerProviderStateMixin {
  late NovelReaderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NovelReaderController(
      initialChapter: widget.chapter,
      chapters: widget.chapters,
      media: widget.media,
      source: widget.source,
    ));
  }

  @override
  void dispose() {
    Get.delete<NovelReaderController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            NovelContentWidget(controller: controller),
            NovelTopControls(
              controller: controller,
            ),
            NovelBottomControls(
              controller: controller,
            ),
            NovelSettingsPanel(
              controller: controller,
            ),
          ],
        ),
      ),
    );
  }
}
