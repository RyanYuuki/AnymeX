import 'package:anymex/controllers/media_mode_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_linear_indicator.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeContinueWatchingBar extends StatefulWidget {
  const HomeContinueWatchingBar({super.key});

  @override
  State<HomeContinueWatchingBar> createState() =>
      _HomeContinueWatchingBarState();
}

class _HomeContinueWatchingBarState extends State<HomeContinueWatchingBar> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleContinue(OfflineMedia item) {
    HapticFeedback.lightImpact();
    HistoryModel.fromOfflineMedia(item, ItemType.anime).onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final mediaModeController = Get.isRegistered<MediaModeController>()
        ? Get.find<MediaModeController>()
        : Get.put(MediaModeController());
    final theme = Theme.of(context);

    return Obx(() {
      final validItems = mediaModeController.animeHistory
          .where((e) => e.currentEpisode != null)
          .take(10)
          .toList();

      if (validItems.isEmpty) return const SizedBox.shrink();

      if (_pageController.hasClients &&
          _pageController.page != null &&
          _pageController.page!.round() >= validItems.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients &&
              _pageController.page != null &&
              _pageController.page!.round() >= validItems.length) {
            _pageController.jumpToPage(0);
          }
        });
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            child: PageView.builder(
              controller: _pageController,
              itemCount: validItems.length,
              itemBuilder: (context, index) {
                return _buildHorizontalLayout(
                  context,
                  theme,
                  validItems[index],
                );
              },
            ),
          ),
          if (validItems.length > 1) ...[
            const SizedBox(height: 6),
            SmoothPageIndicator(
              controller: _pageController,
              count: validItems.length,
              onDotClicked: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              effect: ExpandingDotsEffect(
                dotHeight: 4,
                dotWidth: 4,
                expansionFactor: 2.5,
                spacing: 4,
                activeDotColor: theme.colorScheme.primary,
                dotColor:
                    theme.colorScheme.outline.opaque(0.25, iReallyMeanIt: true),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    ThemeData theme,
    OfflineMedia item,
  ) {
    final episode = item.currentEpisode!;
    final thumbnail =
        (episode.thumbnail != null && episode.thumbnail!.trim().isNotEmpty)
            ? episode.thumbnail!
            : ((item.cover != null && item.cover!.trim().isNotEmpty)
                ? item.cover!
                : (item.poster ?? ''));

    final episodeNumber = formatEpisodeNumberLabel(episode.number, title: episode.title);
    final animeName = item.name ?? '';
    final rawEpisodeTitle = episode.title?.trim() ?? '';
    final hasSpecificTitle = rawEpisodeTitle.isNotEmpty &&
        !rawEpisodeTitle.toLowerCase().startsWith('episode');

    final displayTitle = hasSpecificTitle
        ? (animeName.isNotEmpty
            ? '$animeName • EP $episodeNumber - $rawEpisodeTitle'
            : 'EP $episodeNumber - $rawEpisodeTitle')
        : (animeName.isNotEmpty
            ? '$animeName • Episode $episodeNumber'
            : 'Episode $episodeNumber');

    final current = episode.timeStampInMilliseconds ?? 0;
    final total = episode.durationInMilliseconds ?? 0;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _handleContinue(item),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 52,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer
              .opaque(0.4, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(24.multiplyRadius()),
          border: Border.all(
            color: theme.colorScheme.outline.opaque(0.12, iReallyMeanIt: true),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.opaque(0.12, iReallyMeanIt: true),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 38,
                child: AnymeXImage(
                  imageUrl: thumbnail,
                  fit: BoxFit.cover,
                  radius: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    displayTitle,
                    size: 11.5,
                    variant: TextVariant.semiBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    isMarquee: true,
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: AnymeXLinearIndicator(
                      value: progress > 0 ? progress : 0.05,
                      minHeight: 8,
                      color: theme.colorScheme.primary,
                      backgroundColor:
                          theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _handleContinue(item),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.opaque(0.9),
                  borderRadius: BorderRadius.circular(32.multiplyRadius()),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
