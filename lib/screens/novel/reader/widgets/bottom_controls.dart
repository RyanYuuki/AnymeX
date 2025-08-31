import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';

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
                  Theme.of(context).colorScheme.surface.withOpacity(0.98),
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  Theme.of(context).colorScheme.surface.withOpacity(0.85),
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
                        _buildProgressSlider(context, isDesktop),
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

  Widget _buildProgressSlider(BuildContext context, bool isDesktop) {
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : 12,
            vertical: isDesktop ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                    ),
                    child: Text(
                      'Ch. ${controller.currentChapter.value.number ?? '?'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(controller.progress.value * 100).toInt()}%',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: isDesktop ? 13 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 12 : 8),
              Slider(
                value: controller.progress.value.clamp(0.0, 1.0),
                label: controller.progress.value.toStringAsFixed(2),
                year2023: false,
                onChanged: (value) {
                  if (controller.scrollController.hasClients) {
                    double maxScroll =
                        controller.scrollController.position.maxScrollExtent;
                    controller.scrollController.jumpTo(value * maxScroll);
                  }
                },
                onChangeStart: (_) => HapticFeedback.lightImpact(),
                onChangeEnd: (_) => HapticFeedback.lightImpact(),
              ),
            ],
          ),
        ));
  }

  Widget _buildControlsRow(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16,
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                ),
                child: Text(
                  '${controller.fontSize.value.toInt()}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
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
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
