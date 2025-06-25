// import 'package:anymex/models/Media/media.dart';
// import 'package:anymex/screens/manga/controller/reader_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';

// import 'package:anymex/models/Offline/Hive/chapter.dart';

// class ReaderPage extends StatefulWidget {
//   final Media anilistData;
//   final List<Chapter> chapterList;
//   final Chapter currentChapter;

//   const ReaderPage({
//     super.key,
//     required this.anilistData,
//     required this.chapterList,
//     required this.currentChapter,
//   });

//   @override
//   State<ReaderPage> createState() => _ReaderPageState();
// }

// class _ReaderPageState extends State<ReaderPage> {
//   final controller = Get.put(ReaderController());

//   @override
//   void initState() {
//     super.initState();
//     controller.init(
//         widget.anilistData, widget.chapterList, widget.currentChapter);
//   }

//   @override
//   void dispose() {
//     Get.delete<ReaderController>();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Obx(() => GestureDetector(
//             onTap: () => controller.toggleControls(),
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 controller.buildReaderView(),
//                 AnimatedPositioned(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                   top: controller.showControls.value ? 0 : -200,
//                   left: 0,
//                   right: 0,
//                   child: controller.buildTopControls(context),
//                 ),
//                 AnimatedPositioned(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                   bottom: controller.showControls.value ? 0 : -200,
//                   left: 0,
//                   right: 0,
//                   child: controller,
//                 ),
//               ],
//             ),
//           )),
//     );
//   }
// }
