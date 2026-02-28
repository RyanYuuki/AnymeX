import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class NovelBottomControls extends StatelessWidget {
  final NovelReaderController controller;

  const NovelBottomControls({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Obx(() => AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: 0,
          right: 0,
          bottom: controller.showControls.value ? 0 : -300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  context.colors.surface.opaque(0.98),
                  context.colors.surface.opaque(0.95),
                  context.colors.surface.opaque(0.85),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 20,
                      vertical: isDesktop ? 20 : 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.showBatteryAndTime.value)
                          _buildStatusBar(context, isDesktop),
                        _buildProgressSection(context, isDesktop),
                        SizedBox(height: isDesktop ? 20 : 16),
                        _buildControlsRow(context, isDesktop),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildStatusBar(BuildContext context, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: isDesktop ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        border: Border.all(
          color: context.colors.outline.opaque(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeWidget(context),
          _buildBatteryWidget(context),
        ],
      ),
    );
  }

  Widget _buildTimeWidget(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: context.colors.onSurface.opaque(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: TextStyle(
                color: context.colors.onSurface.opaque(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBatteryWidget(BuildContext context) {
    // Note: You'll need to implement battery level using a plugin
    return Row(
      children: [
        Icon(
          Icons.battery_std,
          size: 16,
          color: context.colors.onSurface.opaque(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '100%',
          style: TextStyle(
            color: context.colors.onSurface.opaque(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, bool isDesktop) {
    if (controller.pageReaderMode.value) {
      return _buildPageProgress(context, isDesktop);
    }
    return _buildScrollProgress(context, isDesktop);
  }

  Widget _buildScrollProgress(BuildContext context, bool isDesktop) {
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 12,
            vertical: isDesktop ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest.opaque(0.3),
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(
              color: context.colors.outline.opaque(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 8,
                      vertical: isDesktop ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.opaque(0.1),
                      borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                    ),
                    child: Text(
                      'Ch. ${controller.currentChapter.value.number?.toStringAsFixed(0) ?? '?'}',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: isDesktop ? 13 : 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.currentChapter.value.title ??
                          'Unknown Chapter',
                      style: TextStyle(
                        color: context.colors.onSurface.opaque(0.8),
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (controller.showReadingProgress.value)
                    Text(
                      '${(controller.progress.value * 100).toInt()}%',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .opaque(0.6),
                        fontSize: isDesktop ? 13 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (controller.showReadingProgress.value) ...[
                SizedBox(height: isDesktop ? 12 : 8),
                if (controller.verticalSeekbar.value)
                  _buildVerticalSeekbar(context, isDesktop)
                else
                  Slider(
                    value: controller.progress.value.clamp(0.0, 1.0),
                    onChanged: (value) {
                      if (controller.scrollController.hasClients) {
                        double maxScroll = controller
                            .scrollController.position.maxScrollExtent;
                        controller.scrollController.jumpTo(value * maxScroll);
                      }
                    },
                    onChangeStart: (_) => HapticFeedback.lightImpact(),
                    onChangeEnd: (_) => HapticFeedback.lightImpact(),
                  ),
              ],
            ],
          ),
        ));
  }

  Widget _buildPageProgress(BuildContext context, bool isDesktop) {
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 12,
            vertical: isDesktop ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest.opaque(0.3),
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(
              color: context.colors.outline.opaque(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 8,
                      vertical: isDesktop ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.opaque(0.1),
                      borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                    ),
                    child: Text(
                      'Ch. ${controller.currentChapter.value.number?.toStringAsFixed(0) ?? '?'}',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: isDesktop ? 13 : 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.currentChapter.value.title ??
                          'Unknown Chapter',
                      style: TextStyle(
                        color: context.colors.onSurface.opaque(0.8),
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (controller.showReadingProgress.value)
                    Text(
                      '${controller.currentPage.value}/${controller.totalPages.value}',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .opaque(0.6),
                        fontSize: isDesktop ? 13 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildVerticalSeekbar(BuildContext context, bool isDesktop) {
    return Container(
      height: 40,
      child: Obx(() {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            if (!controller.scrollController.hasClients) return;
            
            double delta = details.primaryDelta ?? 0;
            double maxScroll =
                controller.scrollController.position.maxScrollExtent;
            double currentOffset = controller.scrollController.offset;
            
            double newOffset = currentOffset - delta * 2;
            newOffset = newOffset.clamp(0.0, maxScroll);
            
            controller.scrollController.jumpTo(newOffset);
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.opaque(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest.opaque(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: controller.progress.value,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControlsRow(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16,
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        border: Border.all(
          color: context.colors.outline.opaque(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPreviousButton(context, isDesktop),
          _buildFontControls(context, isDesktop),
          _buildNextButton(context, isDesktop),
        ],
      ),
    );
  }

  Widget _buildPreviousButton(BuildContext context, bool isDesktop) {
    return Obx(() => _buildControlButton(
          context: context,
          isDesktop: isDesktop,
          onPressed: controller.canGoPrevious.value
              ? () {
                  HapticFeedback.lightImpact();
                  controller.goToPreviousChapter();
                }
              : null,
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous Chapter',
          isEnabled: controller.canGoPrevious.value,
        ));
  }

  Widget _buildFontControls(BuildContext context, bool isDesktop) {
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 12,
            vertical: isDesktop ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer.opaque(0.3),
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFontButton(
                context: context,
                isDesktop: isDesktop,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.decreaseFontSize();
                },
                icon: Icons.text_decrease_rounded,
                tooltip: 'Decrease Font Size',
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 8,
                  vertical: isDesktop ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                ),
                child: Text(
                  '${controller.fontSize.value.toInt()}',
                  style: TextStyle(
                    color: context.colors.onPrimary,
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              _buildFontButton(
                context: context,
                isDesktop: isDesktop,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.increaseFontSize();
                },
                icon: Icons.text_increase_rounded,
                tooltip: 'Increase Font Size',
              ),
            ],
          ),
        ));
  }

  Widget _buildNextButton(BuildContext context, bool isDesktop) {
    return Obx(() => _buildControlButton(
          context: context,
          isDesktop: isDesktop,
          onPressed: controller.canGoNext.value
              ? () {
                  HapticFeedback.lightImpact();
                  controller.goToNextChapter();
                }
              : null,
          icon: Icons.skip_next_rounded,
          tooltip: 'Next Chapter',
          isEnabled: controller.canGoNext.value,
        ));
  }

  Widget _buildControlButton({
    required BuildContext context,
    required bool isDesktop,
    required VoidCallback? onPressed,
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 10),
            child: Icon(
              icon,
              size: isDesktop ? 28 : 24,
              color: isEnabled
                  ? context.colors.onSurface
                  : context.colors.onSurface.opaque(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontButton({
    required BuildContext context,
    required bool isDesktop,
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 8 : 6),
            child: Icon(
              icon,
              size: isDesktop ? 20 : 18,
              color: context.colors.onSurface.opaque(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
