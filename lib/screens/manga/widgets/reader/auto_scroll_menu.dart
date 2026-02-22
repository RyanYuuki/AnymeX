import 'dart:ui';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReaderAutoScrollMenu extends StatelessWidget {
  const ReaderAutoScrollMenu({super.key});

  static const double _minAutoScrollSpeed = 1.0;
  static const double _maxAutoScrollSpeed = 10.0;
  static const double _speedStep = 0.5;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReaderController>();
    final mediaQuery = MediaQuery.of(context);
    final rightInset = mediaQuery.padding.right + 10;

    return Obx(() {
      return Positioned(
        top: 0,
        bottom: 0,
        right: rightInset,
        child: IgnorePointer(
          ignoring: !controller.showControls.value,
          child: Center(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              offset: controller.showControls.value
                  ? Offset.zero
                  : const Offset(1.2, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: controller.showControls.value ? 1 : 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.opaque(0.4, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: context.colors.onSurface.opaque(0.18)),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.opaque(0.2, iReallyMeanIt: true),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _menuButton(
                            context: context,
                            icon: Icons.add_rounded,
                            tooltip: 'Increase auto-scroll speed',
                            onPressed: () =>
                                _changeSpeed(controller, -_speedStep),
                          ),
                          const SizedBox(height: 4),
                          _menuButton(
                            context: context,
                            icon: controller.autoScrollEnabled.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            tooltip: controller.autoScrollEnabled.value
                                ? 'Pause auto-scroll'
                                : 'Start auto-scroll',
                            isActive: controller.autoScrollEnabled.value,
                            onPressed: controller.toggleAutoScroll,
                          ),
                          const SizedBox(height: 4),
                          _menuButton(
                            context: context,
                            icon: Icons.remove_rounded,
                            tooltip: 'Decrease auto-scroll speed',
                            onPressed: () =>
                                _changeSpeed(controller, _speedStep),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _changeSpeed(ReaderController controller, double delta) {
    final next = (controller.autoScrollSpeed.value + delta)
        .clamp(_minAutoScrollSpeed, _maxAutoScrollSpeed)
        .toDouble();
    controller.setAutoScrollSpeed(next);
  }

  Widget _menuButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        backgroundColor: isActive
            ? context.colors.primary.opaque(0.2)
            : context.colors.surface.opaque(0.55),
        foregroundColor:
            isActive ? context.colors.primary : context.colors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}
