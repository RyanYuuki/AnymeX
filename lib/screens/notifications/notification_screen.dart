import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/notification/notification_item.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/notifications/notification_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              title: AnymexText(
                text: 'Notifications',
                variant: TextVariant.bold,
                size: 20,
              ),
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor.opaque(0.5),
              surfaceTintColor: Colors.transparent,
              actions: [
                Obx(() {
                  final hasUnread = controller.unreadCount.value > 0;
                  if (!hasUnread) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: () => controller.markAllAsRead(),
                      icon: Icon(
                        Icons.done_all_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      label: AnymexText(
                        text: 'Mark all read',
                        variant: TextVariant.semiBold,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  );
                }),
              ],
            ),

            SliverToBoxAdapter(
              child: _buildFilterChips(context, colorScheme),
            ),

            SliverToBoxAdapter(
              child: _buildUnreadToggle(context, colorScheme),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: Obx(() {
                if (controller.isLoading.value &&
                    controller.notifications.isEmpty) {
                  return _buildLoadingSkeleton(colorScheme);
                }

                if (controller.error.value.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildErrorState(colorScheme),
                  );
                }

                if (controller.notifications.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(colorScheme),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationCard(
                          notification: controller.notifications[index],
                          onTap: () =>
                              _handleNotificationTap(controller.notifications[index]),
                        ),
                      );
                    },
                    childCount: controller.notifications.length,
                  ),
                );
              }),
            ),

            SliverToBoxAdapter(
              child: Obx(() {
                if (controller.isLoadingMore.value) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
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
                return const SizedBox.shrink();
              }),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, ColorScheme colorScheme) {
    final filters = [
      ('all', 'All'),
      ('comment', 'Comments'),
      ('mention', 'Mentions'),
      ('vote', 'Votes'),
      ('report', 'Reports'),
      ('moderation', 'Moderation'),
      ('announcement', 'Announcements'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final (value, label) = filters[index];
            return Obx(() {
              final isSelected =
                  controller.selectedFilter.value == value;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => controller.setFilter(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest.opaque(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.opaque(0.15),
                      ),
                    ),
                    child: AnymexText(
                      text: label,
                      variant: TextVariant.semiBold,
                      size: 12,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.opaque(0.8),
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
        return InkWell(
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
                AnymexText(
                  text: 'Unread only',
                  variant: TextVariant.regular,
                  size: 12,
                  color: controller.showUnreadOnly.value
                      ? colorScheme.primary
                      : colorScheme.onSurface.opaque(0.6),
                ),
                Obx(() {
                  if (!controller.showUnreadOnly.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.opaque(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnymexText(
                        text: '${controller.notifications.length}',
                        variant: TextVariant.semiBold,
                        size: 11,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingSkeleton(ColorScheme colorScheme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.opaque(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.opaque(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer.opaque(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer.opaque(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer.opaque(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 140,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer.opaque(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        childCount: 6,
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.opaque(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: colorScheme.onSurface.opaque(0.4),
              ),
            ),
            const SizedBox(height: 16),
            AnymexText(
              text: 'No notifications yet',
              variant: TextVariant.semiBold,
              size: 16,
              color: colorScheme.onSurface.opaque(0.7),
            ),
            const SizedBox(height: 6),
            AnymexText(
              text: 'When someone interacts with your comments,\nyou\'ll see it here',
              variant: TextVariant.regular,
              size: 13,
              color: colorScheme.onSurface.opaque(0.4),
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
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error.opaque(0.7),
            ),
            const SizedBox(height: 16),
            AnymexText(
              text: 'Something went wrong',
              variant: TextVariant.semiBold,
              size: 16,
              color: colorScheme.onSurface.opaque(0.7),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => controller.refresh(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnymexText(
                    text: 'Retry',
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

    if (notification.mediaId == null || notification.mediaType == null) return;
    if (!Get.isRegistered<ServiceHandler>()) return;

    final mediaType = notification.mediaType!.toLowerCase();
    final isManga = mediaType == 'manga' || mediaType == 'novel';
    final mediaId = notification.mediaId!;
    final handler = Get.find<ServiceHandler>();

    // Fix: Use notification's clientType to determine the correct service
    final serviceType = _serviceTypeFromClientType(notification.clientType) ?? handler.serviceType.value;

    // Switch to the correct service if needed
    if (handler.serviceType.value != serviceType) {
      handler.changeService(serviceType);
    }

    final media = Media(
      id: mediaId,
      serviceType: serviceType,
      mediaType: isManga ? ItemType.manga : ItemType.anime,
    );

    final tag = 'notif-${notification.id}-${DateTime.now().millisecondsSinceEpoch}';

    if (isManga) {
      navigate(() => MangaDetailsPage(
        media: media,
        tag: tag,
        initialTabIndex: 2,
        scrollToCommentId: notification.commentId,
      ));
    } else {
      navigate(() => AnimeDetailsPage(
        media: media,
        tag: tag,
        initialTabIndex: 2,
        scrollToCommentId: notification.commentId,
      ));
    }
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? colorScheme.surfaceContainerHighest.opaque(0.25)
                : colorScheme.surfaceContainerHighest.opaque(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? colorScheme.outline.opaque(0.06)
                  : categoryColor.opaque(0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
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
                          child: AnymexText(
                            text: notification.title,
                            variant: notification.isRead
                                ? TextVariant.semiBold
                                : TextVariant.bold,
                            size: 14,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            color: notification.isRead
                                ? colorScheme.onSurface.opaque(0.7)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnymexText(
                          text: _formatTimeAgo(notification.createdAt),
                          variant: TextVariant.regular,
                          size: 11,
                          color: colorScheme.onSurface.opaque(0.4),
                        ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      DiscordMarkdown(
                        text: notification.body,
                        colorScheme: colorScheme,
                        baseStyle: TextStyle(
                          color: colorScheme.onSurface.opaque(0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        fontSize: 12,
                      ),
                    ],
                    if (notification.mediaTitle != null &&
                        notification.mediaTitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.movie_rounded,
                            size: 12,
                            color: colorScheme.onSurface.opaque(0.35),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AnymexText(
                              text: notification.mediaTitle!,
                              variant: TextVariant.regular,
                              size: 11,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (notification.actorUsername != null &&
                        notification.actorUsername!.isNotEmpty &&
                        notification.body.isEmpty) ...[
                      const SizedBox(height: 4),
                      AnymexText(
                        text: '@${notification.actorUsername}',
                        variant: TextVariant.regular,
                        size: 11,
                        color: colorScheme.onSurface.opaque(0.45),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
        child: ClipOval(
          child: AnymeXImage(
            imageUrl: notification.actorAvatar!,
            width: 42,
            height: 42,
            radius: 21,
          ),
        ),
        showBadge: !notification.isRead,
        badgeColor: colorScheme.primary,
      );
    }

    if (hasActor) {
      // Fallback: circle with first letter of username
      final initial = notification.actorUsername!.toUpperCase().characters.first;
      return _AvatarWithBadge(
        size: 42,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: categoryColor.opaque(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: categoryColor,
            ),
          ),
        ),
        showBadge: !notification.isRead,
        badgeColor: colorScheme.primary,
      );
    }

    // No actor (announcements, etc): category icon in circle
    return _AvatarWithBadge(
      size: 42,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: categoryColor.opaque(0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          _getCategoryIcon(),
          size: 20,
          color: categoryColor,
        ),
      ),
      showBadge: !notification.isRead,
      badgeColor: colorScheme.primary,
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
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
