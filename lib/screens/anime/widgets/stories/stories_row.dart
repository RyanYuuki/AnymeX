import 'package:anymex/models/Anilist/story_group.dart';
import 'package:anymex/screens/anime/widgets/stories/controller/stories_controller.dart';
import 'package:anymex/screens/anime/widgets/stories/story_viewer.dart';
import 'package:anymex/screens/anime/widgets/stories/widgets/story_circle.dart';
import 'package:anymex/screens/anime/widgets/stories/widgets/story_composer_sheet.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      highlightColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
      child: Row(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 48,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openViewer(
    BuildContext context,
    StoriesController controller,
    List<StoryGroup> playableGroups,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: StoryViewer(
              groups: playableGroups,
              initialGroupIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoriesController());
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final h = isDesktop ? 24.0 : 16.0;

    return Obx(() {
      final own = controller.ownStory.value;
      final groups = controller.storyGroups;
      final isLoading = controller.isLoading.value;

      if (!isLoading && own == null && groups.isEmpty) {
        return const SizedBox.shrink();
      }

      final playableGroups = <StoryGroup>[
        if (own != null && own.activities.isNotEmpty) own,
        ...groups.where((g) => g.activities.isNotEmpty),
      ];

      return Container(
        height: 104,
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        child: isLoading && groups.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: h),
                child: _buildPlaceholder(context),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: h),
                itemCount: (own != null ? 1 : 0) + groups.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (own != null && index == 0) {
                    return StoryCircle(
                      group: own,
                      isOwn: true,
                      onTap: () {
                        if (own.activities.isEmpty) {
                          showStoryComposerSheet(context);
                        } else {
                          _openViewer(context, controller, playableGroups, 0);
                        }
                      },
                      onLongPress: () => showStoryComposerSheet(context),
                    );
                  }

                  final groupIndex = own != null ? index - 1 : index;
                  final group = groups[groupIndex];

                  return StoryCircle(
                    group: group,
                    isOwn: false,
                    onTap: () {
                      final targetIndex = playableGroups.indexWhere(
                        (g) => g.user.id == group.user.id,
                      );
                      if (targetIndex >= 0) {
                        _openViewer(
                          context,
                          controller,
                          playableGroups,
                          targetIndex,
                        );
                      }
                    },
                    onLongPress: () {
                      navigate(() => UserProfilePage(userId: group.user.id));
                    },
                  );
                },
              ),
      );
    });
  }
}
