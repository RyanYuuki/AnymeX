import 'package:get/get.dart';
import 'package:anymex/models/notification/notification_item.dart';
import 'package:anymex/services/commentum_service.dart';

class NotificationController extends GetxController {
  final CommentumService _commentumService =
      Get.find<CommentumService>();

  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;

  int _currentPage = 1;
  final int _pageSize = 30;
  bool _hasMore = true;

  final RxString selectedFilter = 'all'.obs;

  String? get _apiFilterType {
    if (selectedFilter.value == 'all') return null;
    if (selectedFilter.value == 'mention') return 'user_mentioned';
    return selectedFilter.value;
  }
  final RxBool showUnreadOnly = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadUnreadCount();
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    error.value = '';
    _currentPage = 1;
    _hasMore = true;

    try {
      final result = await _commentumService.fetchNotificationHistory(
        page: _currentPage,
        limit: _pageSize,
        type: _apiFilterType,
        unreadOnly: showUnreadOnly.value,
      );

      final List<dynamic> notifs = result['notifications'] ?? [];
      notifications.value = notifs
          .map((n) =>
              NotificationItem.fromJson(n as Map<String, dynamic>))
          .toList();
      unreadCount.value = result['unread_count'] ?? 0;
      _commentumService.unreadNotificationCount.value = unreadCount.value;
      _hasMore = notifications.length >= _pageSize;
    } catch (e) {
      error.value = 'Failed to load notifications';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !_hasMore) return;

    isLoadingMore.value = true;
    _currentPage++;

    try {
      final result = await _commentumService.fetchNotificationHistory(
        page: _currentPage,
        limit: _pageSize,
        type: _apiFilterType,
        unreadOnly: showUnreadOnly.value,
      );

      final List<dynamic> notifs = result['notifications'] ?? [];
      final newItems = notifs
          .map((n) =>
              NotificationItem.fromJson(n as Map<String, dynamic>))
          .toList();

      notifications.addAll(newItems);
      _hasMore = newItems.length >= _pageSize;
    } catch (e) {
      _currentPage--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadUnreadCount() async {
    unreadCount.value =
        await _commentumService.getUnreadNotificationCount();
  }

  Future<void> markAsRead(int notificationId) async {
    final success =
        await _commentumService.markNotificationRead(notificationId);
    if (success) {
      final index =
          notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updated = NotificationItem(
          id: notifications[index].id,
          clientType: notifications[index].clientType,
          userId: notifications[index].userId,
          type: notifications[index].type,
          title: notifications[index].title,
          body: notifications[index].body,
          commentId: notifications[index].commentId,
          mediaId: notifications[index].mediaId,
          mediaType: notifications[index].mediaType,
          mediaTitle: notifications[index].mediaTitle,
          actorId: notifications[index].actorId,
          actorUsername: notifications[index].actorUsername,
          actorAvatar: notifications[index].actorAvatar,
          moderatorUsername: notifications[index].moderatorUsername,
          reason: notifications[index].reason,
          clickAction: notifications[index].clickAction,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: notifications[index].createdAt,
        );
        notifications[index] = updated;
      }
      if (unreadCount.value > 0) unreadCount.value--;
      _commentumService.unreadNotificationCount.value = unreadCount.value;
    }
  }

  Future<void> markAllAsRead() async {
    final success =
        await _commentumService.markAllNotificationsRead(
      type: _apiFilterType,
    );
    if (success) {
      notifications.value = notifications
          .map((n) => NotificationItem(
                id: n.id,
                clientType: n.clientType,
                userId: n.userId,
                type: n.type,
                title: n.title,
                body: n.body,
                commentId: n.commentId,
                mediaId: n.mediaId,
                mediaType: n.mediaType,
                mediaTitle: n.mediaTitle,
                actorId: n.actorId,
                actorUsername: n.actorUsername,
                actorAvatar: n.actorAvatar,
                moderatorUsername: n.moderatorUsername,
                reason: n.reason,
                clickAction: n.clickAction,
                isRead: true,
                readAt: DateTime.now(),
                createdAt: n.createdAt,
              ))
          .toList();
      unreadCount.value = 0;
      _commentumService.unreadNotificationCount.value = 0;
    }
  }

  void setFilter(String filter) {
    if (selectedFilter.value != filter) {
      selectedFilter.value = filter;
      loadNotifications();
    }
  }

  void toggleUnreadOnly() {
    showUnreadOnly.value = !showUnreadOnly.value;
    loadNotifications();
  }

  Future<void> refresh() async {
    await loadNotifications();
    await loadUnreadCount();
  }
}
