// ignore_for_file: deprecated_member_use

import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
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
        ],
      );
    });
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: () => Get.back(),
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildChapterInfo(BuildContext context) {
    return Expanded(
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
                value: controller.novelContent.isEmpty
                    ? 0
                    : controller.progress.value,
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
                  Text(
                    controller.currentChapter.value.title ?? 'Unknown Chapter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Chapter ${controller.currentChapter.value.number?.round() ?? '-'} of ${controller.chapters.last.number?.round() ?? '-'}',
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
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: () => controller.toggleSettings(),
        icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

// import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';

// class NovelTopControls extends StatelessWidget {
//   final NovelReaderController controller;
//   final Animation<double> animation;

//   const NovelTopControls({
//     super.key,
//     required this.controller,
//     required this.animation,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: SlideTransition(
//         position: Tween<Offset>(
//           begin: const Offset(0, -1),
//           end: Offset.zero,
//         ).animate(animation),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Theme.of(context).colorScheme.surface.withOpacity(0.95),
//                 Theme.of(context).colorScheme.surface.withOpacity(0.8),
//                 Colors.transparent,
//               ],
//             ),
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Row(
//                 children: [
//                   _buildBackButton(context),
//                   Expanded(child: _buildTitleSection(context)),
//                   _buildSettingsButton(context),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBackButton(BuildContext context) {
//     return IconButton(
//       onPressed: () => Navigator.pop(context),
//       icon: Icon(
//         Icons.arrow_back_rounded,
//         color: Theme.of(context).colorScheme.onSurface,
//       ),
//     );
//   }

//   Widget _buildTitleSection(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Obx(() => Text(
//               controller.currentChapter.value.title ?? 'Chapter',
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.onSurface,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             )),
//         Text(
//           controller.media.title,
//           style: TextStyle(
//             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//             fontSize: 12,
//           ),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }

//   Widget _buildSettingsButton(BuildContext context) {
//     return IconButton(
//       onPressed: () {
//         HapticFeedback.lightImpact();
//         controller.toggleSettings();
//       },
//       icon: Icon(
//         Icons.tune_rounded,
//         color: Theme.of(context).colorScheme.onSurface,
//       ),
//     );
//   }
// }
