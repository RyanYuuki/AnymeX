import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/notification/notification_item.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/media_comments_page.dart';
import 'package:anymex/screens/notifications/announcement_sheet.dart';
import 'package:anymex/screens/notifications/notification_controller.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_notification.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final anilistAuth = Get.find<AnilistAuth>();

    return AnymeXScaffold(
      body: Column(children: [
        NestedHeader(
          title: 'Notifications',
          action: Obx(() {
            final isAnilist = controller.selectedTab.value == 0;
            final hasUnread = isAnilist
                ? anilistAuth.unreadAnilistCount.value > 0
                : controller.unreadCount.value > 0;
            if (!hasUnread) return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: () {
                if (isAnilist) {
                  controller.markAnilistAllRead();
                } else {
                  controller.markAllAsRead();
                }
              },
              icon: Icon(
                Icons.done_all_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              label: AnymeXText(
                'Mark all read',
                variant: TextVariant.semiBold,
                size: 12,
                color: colorScheme.primary,
              ),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            );
          }),
        ),
        _buildTabs(context, colorScheme),
        Expanded(
          child: Obx(() {
            if (controller.selectedTab.value == 0) {
              return _buildAnilistTab(context, colorScheme);
            }
            return _buildCommunityTab(context, colorScheme);
          }),
        ),
      ]),
    );
  }

  Widget _buildTabs(BuildContext context, ColorScheme colorScheme) {
    final anilistAuth = Get.find<AnilistAuth>();
    return Obx(() {
      final selected = controller.selectedTab.value;
      final anilistUnread = anilistAuth.unreadAnilistCount.value;
      final communityUnread = controller.unreadCount.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.opaque(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.opaque(0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabItem(
                  context,
                  colorScheme: colorScheme,
                  label: 'AniList',
                  icon: Icons.notifications_active_outlined,
                  isSelected: selected == 0,
                  badgeCount: anilistUnread,
                  onTap: () => controller.selectedTab.value = 0,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTabItem(
                  context,
                  colorScheme: colorScheme,
                  label: 'Community',
                  icon: Icons.forum_outlined,
                  isSelected: selected == 1,
                  badgeCount: communityUnread,
                  onTap: () => controller.selectedTab.value = 1,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabItem(
    BuildContext context, {
    required ColorScheme colorScheme,
    required String label,
    required IconData icon,
    required bool isSelected,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            AnymeXText(
              label,
              variant: TextVariant.semiBold,
              size: 13,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimary.withOpacity(0.25)
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnymeXText(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  size: 10,
                  variant: TextVariant.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnilistTab(BuildContext context, ColorScheme colorScheme) {
    final anilistAuth = Get.find<AnilistAuth>();

    return Obx(() {
      if (!anilistAuth.isLoggedIn.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: colorScheme.primary.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                const AnymeXText(
                  'AniList Account Required',
                  variant: TextVariant.bold,
                  size: 16,
                ),
                const SizedBox(height: 8),
                AnymeXText(
                  'Log in to AniList to sync episode airing alerts, activity notifications, and social updates.',
                  variant: TextVariant.regular,
                  size: 13,
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => anilistAuth.login(context),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Log In with AniList'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.anilistNotifications.isEmpty &&
          !controller.isAnilistLoading.value &&
          !controller.hasFetchedAnilist.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.loadAnilistNotifications();
        });
      }

      if (controller.isAnilistLoading.value &&
          controller.anilistNotifications.isEmpty) {
        return _buildLoadingSkeleton(colorScheme);
      }

      if (controller.anilistError.value.isNotEmpty) {
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 12),
                    AnymeXText(controller.anilistError.value,
                        variant: TextVariant.semiBold, size: 14),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadAnilistNotifications(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final items = controller.filteredAnilistNotifications;

      return Column(
        children: [
          _buildAnilistFilterChips(context, colorScheme),
          Expanded(
            child: items.isEmpty
                ? RefreshIndicator(
                    onRefresh: controller.refresh,
                    color: colorScheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 56,
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              AnymeXText(
                                'No notifications found',
                                variant: TextVariant.semiBold,
                                size: 15,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              AnymeXText(
                                'You are all caught up!',
                                variant: TextVariant.regular,
                                size: 13,
                                color: colorScheme.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: controller.refresh,
                    color: colorScheme.primary,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if ((notification is ScrollUpdateNotification ||
                                notification is ScrollEndNotification) &&
                            notification.metrics.pixels >=
                                notification.metrics.maxScrollExtent - 200 &&
                            !controller.isAnilistLoadingMore.value) {
                          controller.loadMoreAnilistNotifications();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return Obx(() {
                              if (controller.isAnilistLoadingMore.value) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox(height: 20);
                            });
                          }
                          final item = items[index];
                          return _AnilistNotificationCard(
                            notification: item,
                            onTap: () => _handleAnilistTap(item),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  void _handleAnilistTap(AnilistNotificationItem item) {
    if (item.mediaId != null) {
      navigate(() => MediaDetailsPage(
            media: Media(
              id: item.mediaId.toString(),
              title: item.mediaTitle ?? 'Anime',
              poster: item.mediaCover ?? '',
              mediaType: item.mediaType == 'MANGA'
                  ? ItemType.manga
                  : ItemType.anime,
              serviceType: ServicesType.anilist,
            ),
            tag: 'anilist_${item.id}_${item.mediaId}',
          ));
    } else if (item.userId != null) {
      navigate(() => UserProfilePage(userId: item.userId!));
    }
  }

  Widget _buildAnilistFilterChips(
      BuildContext context, ColorScheme colorScheme) {
    final filters = [
      ('all', 'All', Icons.all_inclusive_rounded),
      ('airing', 'Airing', Icons.play_circle_outline_rounded),
      ('activity', 'Activity', Icons.favorite_border_rounded),
      ('social', 'Social', Icons.people_outline_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final (value, label, icon) = filters[index];
            return Obx(() {
              final isSelected =
                  controller.selectedAnilistFilter.value == value;
              final count = controller.countForAnilistCategory(value);
              final displayCount = count > 99 ? '99+' : '$count';

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => controller.setAnilistFilter(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest.opaque(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.opaque(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        AnymeXText(
                          '$label ($displayCount)',
                          variant: TextVariant.semiBold,
                          size: 12,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildCommunityTab(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildFilterChips(context, colorScheme),
        _buildUnreadToggle(context, colorScheme),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value &&
                controller.notifications.isEmpty) {
              return _buildLoadingSkeleton(colorScheme);
            }

            if (controller.error.value.isNotEmpty) {
              return RefreshIndicator(
                onRefresh: controller.refresh,
                color: colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildErrorState(colorScheme),
                ),
              );
            }

            if (controller.notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: controller.refresh,
                color: colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildEmptyState(colorScheme),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.refresh,
              color: colorScheme.primary,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if ((notification is ScrollUpdateNotification ||
                          notification is ScrollEndNotification) &&
                      notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200 &&
                      !controller.isLoadingMore.value) {
                    controller.loadMoreNotifications();
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: controller.notifications.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.notifications.length) {
                      return Obx(() {
                        if (controller.isLoadingMore.value) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 20);
                      });
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationCard(
                        notification: controller.notifications[index],
                        onTap: () => _handleNotificationTap(
                            controller.notifications[index]),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, ColorScheme colorScheme) {
    final filters = [
      ('all', 'All', Icons.all_inclusive_rounded),
      ('comment', 'Comments', Icons.chat_bubble_outline_rounded),
      ('mention', 'Mentions', Icons.alternate_email_rounded),
      ('vote', 'Votes', Icons.thumb_up_alt_outlined),
      ('report', 'Reports', Icons.flag_outlined),
      ('moderation', 'Moderation', Icons.shield_outlined),
      ('announcement', 'Announcements', Icons.campaign_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final (value, label, icon) = filters[index];
            return Obx(() {
              final isSelected = controller.selectedFilter.value == value;
              final unreadCount = controller.unreadCountForCategory(value);
              final count = controller.countForCategory(value);
              final displayCount = count > 99 ? '99+' : '$count';
              final displayUnread = unreadCount > 99 ? '99+' : '$unreadCount';

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => controller.setFilter(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest.opaque(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.opaque(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        AnymeXText(
                          '$label ($displayCount)',
                          variant: TextVariant.semiBold,
                          size: 12,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          AnymeXContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.25)
                                : colorScheme.primary,
                            radius: 10,
                            child: AnymeXText(
                              displayUnread,
                              variant: TextVariant.bold,
                              size: 10,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildUnreadToggle(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.toggleUnreadOnly(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.showUnreadOnly.value
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: controller.showUnreadOnly.value
                          ? colorScheme.primary
                          : colorScheme.onSurface.opaque(0.5),
                    ),
                    const SizedBox(width: 6),
                    AnymeXText(
                      'Unread only',
                      variant: TextVariant.regular,
                      size: 12,
                      color: controller.showUnreadOnly.value
                          ? colorScheme.primary
                          : colorScheme.onSurface.opaque(0.6),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.unreadCount.value > 0)
              AnymeXContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: colorScheme.primary.withValues(alpha: 0.15),
                radius: 10,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                child: AnymeXText(
                  '${controller.unreadCount.value} unread',
                  variant: TextVariant.semiBold,
                  size: 11,
                  color: colorScheme.primary,
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildLoadingSkeleton(ColorScheme colorScheme) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: List.generate(
          6,
          (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnymeXContainer(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surfaceContainer.opaque(0.3),
                  radius: 12,
                  border: Border.all(
                    color: colorScheme.outline.opaque(0.1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXContainer(
                        width: 44,
                        height: 44,
                        color: colorScheme.surfaceContainerHigh.opaque(0.4),
                        radius: 12,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnymeXContainer(
                              height: 14,
                              width: double.infinity,
                              color: colorScheme.surfaceContainerHigh
                                  .opaque(0.4),
                              radius: 4,
                            ),
                            const SizedBox(height: 8),
                            AnymeXContainer(
                              height: 12,
                              width: 200,
                              color: colorScheme.surfaceContainer.opaque(0.3),
                              radius: 4,
                            ),
                            const SizedBox(height: 8),
                            AnymeXContainer(
                              height: 12,
                              width: 140,
                              color: colorScheme.surfaceContainer.opaque(0.3),
                              radius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            AnymeXContainer(
              padding: const EdgeInsets.all(20),
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainer.opaque(0.3),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AnymeXText(
              'No notifications yet',
              variant: TextVariant.semiBold,
              size: 16,
              color: colorScheme.onSurface,
            ),
            const SizedBox(height: 6),
            AnymeXText(
              'When someone interacts with your comments,\nyou\'ll see it here',
              variant: TextVariant.regular,
              size: 13,
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            AnymeXContainer(
              padding: const EdgeInsets.all(20),
              shape: BoxShape.circle,
              color: colorScheme.errorContainer.opaque(0.3),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            AnymeXText(
              'Something went wrong',
              variant: TextVariant.semiBold,
              size: 16,
              color: colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => controller.refresh(),
                child: AnymeXContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: colorScheme.primary,
                  radius: 12,
                  child: AnymeXText(
                    'Retry',
                    variant: TextVariant.semiBold,
                    size: 13,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ServicesType? _serviceTypeFromClientType(String clientType) {
    switch (clientType.toLowerCase()) {
      case 'anilist':
        return ServicesType.anilist;
      case 'mal':
      case 'myanimelist':
        return ServicesType.mal;
      case 'simkl':
        return ServicesType.simkl;
      default:
        return null;
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    // Announcements open their dedicated bottom sheet (full info + markdown),
    // NOT the comment/media navigation flow.
    if (notification.type == 'announcement_published') {
      final sheetContext = Get.context;
      if (sheetContext != null) {
        AnnouncementSheet.show(
          sheetContext,
          announcementId:
              notification.metadata['announcement_id']?.toString() ?? '',
          fallbackTitle: notification.title,
          fallbackBody: notification.body,
        );
      }
      return;
    }

    if (notification.mediaId == null || notification.mediaType == null) return;
    if (!Get.isRegistered<ServiceHandler>()) return;

    final mediaType = notification.mediaType!.toLowerCase();
    final isManga = mediaType == 'manga' || mediaType == 'novel';
    final mediaId = notification.mediaId!;
    final handler = Get.find<ServiceHandler>();

    // Fix: Use notification's clientType to determine the correct service
    final serviceType = _serviceTypeFromClientType(notification.clientType) ??
        handler.serviceType.value;

    // Switch to the correct service if needed
    if (handler.serviceType.value != serviceType) {
      handler.changeService(serviceType);
    }

    final media = Media(
      id: mediaId,
      serviceType: serviceType,
      mediaType: isManga ? ItemType.manga : ItemType.anime,
    );

    // Open the standalone comments page directly — the details page's
    // comments tab auto-pushes this exact page, so going straight here skips
    // a full details-page load. Reply targets open the replies sheet inside
    // CommentSection.
    navigate(() => MediaCommentsPage(
          media: media,
          scrollToCommentId: notification.commentId,
        ));
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final categoryColor = _getCategoryColor(colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnymeXCard(
          color: notification.isRead
              ? null
              : colorScheme.surfaceContainerHigh.opaque(0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: notification.isRead
                  ? colorScheme.outline.opaque(0.08)
                  : categoryColor.opaque(0.35),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Glowing Category Accent Bar
                AnymeXContainer(
                  width: 4,
                  color: categoryColor,
                  shadow: !notification.isRead
                      ? BoxShadow(
                          color: categoryColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatar(colorScheme, categoryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: AnymeXText(
                                            notification.title,
                                            variant: notification.isRead
                                                ? TextVariant.semiBold
                                                : TextVariant.bold,
                                            size: 13,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            color: notification.isRead
                                                ? colorScheme.onSurface.opaque(0.7)
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        if (!notification.isRead) ...[
                                          const SizedBox(width: 6),
                                          AnymeXContainer(
                                            width: 7,
                                            height: 7,
                                            shape: BoxShape.circle,
                                            color: categoryColor,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnymeXText(
                                    _formatTimeAgo(notification.createdAt),
                                    variant: TextVariant.regular,
                                    size: 11,
                                    color: colorScheme.onSurfaceVariant.opaque(0.7),
                                  ),
                                ],
                              ),
                              if (notification.body.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                DiscordMarkdown(
                                  text: notification.body,
                                  colorScheme: colorScheme,
                                  baseStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  fontSize: 12,
                                ),
                              ],
                              if (notification.mediaTitle != null &&
                                  notification.mediaTitle!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                AnymeXContainer(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  color: categoryColor.withValues(alpha: 0.1),
                                  radius: 6,
                                  border: Border.all(
                                    color: categoryColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.movie_outlined,
                                        size: 12,
                                        color: categoryColor,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: AnymeXText(
                                          notification.mediaTitle!,
                                          variant: TextVariant.semiBold,
                                          size: 11,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          color: categoryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (notification.actorUsername != null &&
                                  notification.actorUsername!.isNotEmpty &&
                                  notification.body.isEmpty) ...[
                                const SizedBox(height: 4),
                                AnymeXText(
                                  '@${notification.actorUsername}',
                                  variant: TextVariant.regular,
                                  size: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the leading avatar: profile image > initial letter > category icon
  Widget _buildAvatar(ColorScheme colorScheme, Color categoryColor) {
    final hasAvatar = notification.actorAvatar != null &&
        notification.actorAvatar!.isNotEmpty;
    final hasActor = notification.actorUsername != null &&
        notification.actorUsername!.isNotEmpty;

    if (hasAvatar) {
      return _AvatarWithBadge(
        size: 42,
        showBadge: !notification.isRead,
        badgeColor: colorScheme.primary,
        child: ClipOval(
          child: AnymeXImage(
            imageUrl: notification.actorAvatar!,
            width: 42,
            height: 42,
            radius: 21,
          ),
        ),
      );
    }

    if (hasActor) {
      // Fallback: circle with first letter of username
      final initial =
          notification.actorUsername!.toUpperCase().characters.first;
      return _AvatarWithBadge(
        size: 42,
        showBadge: !notification.isRead,
        badgeColor: colorScheme.primary,
        child: AnymeXContainer(
          width: 42,
          height: 42,
          shape: BoxShape.circle,
          color: categoryColor.opaque(0.15),
          alignment: Alignment.center,
          child: AnymeXText(
            initial,
            variant: TextVariant.semiBold,
            size: 18,
            color: categoryColor,
          ),
        ),
      );
    }

    // No actor (announcements, etc): category icon in circle
    return _AvatarWithBadge(
      size: 42,
      showBadge: !notification.isRead,
      badgeColor: colorScheme.primary,
      child: AnymeXContainer(
        width: 42,
        height: 42,
        shape: BoxShape.circle,
        color: categoryColor.opaque(0.12),
        alignment: Alignment.center,
        child: Icon(
          _getCategoryIcon(),
          size: 20,
          color: categoryColor,
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (notification.type) {
      case 'user_mentioned':
      case 'comment_created':
        return Icons.chat_bubble_outline_rounded;
      case 'comment_reply':
        return Icons.reply_rounded;
      case 'comment_updated':
        return Icons.edit_outlined;
      case 'comment_deleted':
        return Icons.delete_outline_rounded;
      case 'comment_pinned':
        return Icons.push_pin_outlined;
      case 'comment_unpinned':
        return Icons.push_pin_outlined;
      case 'comment_locked':
        return Icons.lock_outline_rounded;
      case 'comment_unlocked':
        return Icons.lock_open_outlined;
      case 'vote_cast':
        return Icons.thumb_up_outlined;
      case 'vote_removed':
        return Icons.thumb_down_outlined;
      case 'report_filed':
        return Icons.flag_outlined;
      case 'report_resolved':
        return Icons.check_circle_outline_rounded;
      case 'report_dismissed':
        return Icons.cancel_outlined;
      case 'user_warned':
        return Icons.warning_amber_rounded;
      case 'user_muted':
        return Icons.volume_off_outlined;
      case 'user_unmuted':
        return Icons.volume_up_outlined;
      case 'user_banned':
        return Icons.block_outlined;
      case 'user_unbanned':
        return Icons.remove_circle_outline_rounded;
      case 'user_shadow_banned':
        return Icons.visibility_off_outlined;
      case 'announcement_published':
        return Icons.campaign_outlined;
      case 'moderation_action':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getCategoryColor(ColorScheme colorScheme) {
    switch (notification.typeCategory) {
      case 'comment':
        return colorScheme.primary;
      case 'vote':
        return colorScheme.tertiary;
      case 'report':
        return colorScheme.error;
      case 'moderation':
        return colorScheme.secondary;
      case 'announcement':
        return Colors.orange;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
    return '${(difference.inDays / 365).floor()}y ago';
  }
}

/// Circular avatar with optional unread badge dot (like Discord/WhatsApp)
class _AvatarWithBadge extends StatelessWidget {
  final double size;
  final Widget child;
  final bool showBadge;
  final Color badgeColor;

  const _AvatarWithBadge({
    required this.size,
    required this.child,
    required this.showBadge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 4, // extra space for badge
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (showBadge)
            Positioned(
              right: 0,
              top: 0,
              child: AnymeXContainer(
                width: 10,
                height: 10,
                shape: BoxShape.circle,
                color: badgeColor,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
                shadow: BoxShadow(
                  color: badgeColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnilistNotificationCard extends StatelessWidget {
  final AnilistNotificationItem notification;
  final VoidCallback onTap;

  const _AnilistNotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final (icon, badgeColor) =
        _getBadgeIconAndColor(notification, colorScheme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.opaque(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.opaque(0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 48,
                      height: 58,
                      child: notification.thumbnail != null
                          ? AnymeXImage(
                              imageUrl: notification.thumbnail!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnymeXText(
                            notification.displayTitle,
                            variant: TextVariant.semiBold,
                            size: 13,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnymeXText(
                          notification.timeAgo,
                          variant: TextVariant.regular,
                          size: 11,
                          color: colorScheme.outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnymeXText(
                      notification.displayBody,
                      variant: TextVariant.regular,
                      size: 12,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AnymeXText(
                        _getKindLabel(notification.kind),
                        size: 10,
                        variant: TextVariant.semiBold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _getBadgeIconAndColor(
      AnilistNotificationItem item, ColorScheme colorScheme) {
    switch (item.kind) {
      case AnilistNotificationKind.airing:
        return (Icons.play_arrow_rounded, colorScheme.primary);
      case AnilistNotificationKind.social:
        return (Icons.person_add_rounded, Colors.teal);
      case AnilistNotificationKind.activity:
        if (item.type.contains('LIKE')) {
          return (Icons.favorite_rounded, Colors.redAccent);
        }
        if (item.type.contains('REPLY') || item.type.contains('COMMENT')) {
          return (Icons.chat_bubble_rounded, Colors.blueAccent);
        }
        return (Icons.notifications_rounded, colorScheme.primary);
      case AnilistNotificationKind.system:
        return (Icons.info_outline_rounded, Colors.amber);
    }
  }

  String _getKindLabel(AnilistNotificationKind kind) {
    switch (kind) {
      case AnilistNotificationKind.airing:
        return 'Airing';
      case AnilistNotificationKind.social:
        return 'Social';
      case AnilistNotificationKind.activity:
        return 'Activity';
      case AnilistNotificationKind.system:
        return 'System';
    }
  }
}
