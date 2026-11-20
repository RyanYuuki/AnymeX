import 'package:get/get.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/notification/notification_item.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_notification.dart';
import 'package:anymex/services/anilist_notification_service.dart';

class NotificationController extends GetxController {
  final CommentumService _commentumService =
      Get.find<CommentumService>();

  final RxInt selectedTab = 0.obs;

  final RxList<AnilistNotificationItem> anilistNotifications =
      <AnilistNotificationItem>[].obs;
  final RxBool isAnilistLoading = false.obs;
  final RxBool isAnilistLoadingMore = false.obs;
  final RxString anilistError = ''.obs;
  final RxString selectedAnilistFilter = 'all'.obs;
  final RxBool hasFetchedAnilist = false.obs;
  Worker? _authWorker;
  int _anilistPage = 1;
  final int _anilistPageSize = 15;
  bool _anilistHasMore = true;

  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;

  int _currentPage = 1;
  final int _pageSize = 15;
  bool _hasMore = true;

  final RxString selectedFilter = 'all'.obs;

  String? get _apiFilterType {
    if (selectedFilter.value == 'all') return null;
    if (selectedFilter.value == 'mention') return 'user_mentioned';
    return selectedFilter.value;
  }

  final RxBool showUnreadOnly = false.obs;

  int countForCategory(String category) {
    if (category == 'all') return notifications.length;
    return notifications.where((n) {
      if (category == 'mention') return n.type == 'user_mentioned';
      return n.typeCategory == category;
    }).length;
  }

  int unreadCountForCategory(String category) {
    return notifications.where((n) {
      if (n.isRead) return false;
      if (category == 'all') return true;
      if (category == 'mention') return n.type == 'user_mentioned';
      return n.typeCategory == category;
    }).length;
  }

  List<AnilistNotificationItem> get filteredAnilistNotifications {
    if (selectedAnilistFilter.value == 'all') {
      return anilistNotifications;
    }
    return anilistNotifications.where((n) {
      if (selectedAnilistFilter.value == 'airing') {
        return n.kind == AnilistNotificationKind.airing;
      }
      if (selectedAnilistFilter.value == 'activity') {
        return n.kind == AnilistNotificationKind.activity;
      }
      if (selectedAnilistFilter.value == 'social') {
        return n.kind == AnilistNotificationKind.social;
      }
      return true;
    }).toList();
  }

  int countForAnilistCategory(String category) {
    if (category == 'all') return anilistNotifications.length;
    return anilistNotifications.where((n) {
      if (category == 'airing') {
        return n.kind == AnilistNotificationKind.airing;
      }
      if (category == 'activity') {
        return n.kind == AnilistNotificationKind.activity;
      }
      if (category == 'social') {
        return n.kind == AnilistNotificationKind.social;
      }
      return false;
    }).length;
  }

  void setAnilistFilter(String filter) {
    if (selectedAnilistFilter.value != filter) {
      selectedAnilistFilter.value = filter;
      _anilistPage = 1;
      _anilistHasMore = true;
    }
  }

  List<String>? _getTypesForCategory(String category) {
    switch (category) {
      case 'airing':
        return ['AIRING'];
      case 'activity':
        return [
          'ACTIVITY_LIKE',
          'ACTIVITY_REPLY',
          'ACTIVITY_MENTION',
          'ACTIVITY_REPLY_LIKE',
          'ACTIVITY_REPLY_SUBSCRIBED',
          'ACTIVITY_MESSAGE',
        ];
      case 'social':
        return [
          'FOLLOWING',
          'THREAD_COMMENT_MENTION',
          'THREAD_COMMENT_REPLY',
          'THREAD_COMMENT_SUBSCRIBED',
          'THREAD_COMMENT_LIKE',
          'THREAD_LIKE',
        ];
      default:
        return null;
    }
  }

  DateTime? _lastNotificationFetchTime;

  Future<void> loadAnilistNotifications({bool force = false}) async {
    final auth = Get.find<AnilistAuth>();
    final token = AuthKeys.authToken.get<String?>();
    if (!auth.isLoggedIn.value && (token == null || token.isEmpty)) {
      anilistNotifications.clear();
      return;
    }

    if (!force &&
        _lastNotificationFetchTime != null &&
        DateTime.now().difference(_lastNotificationFetchTime!).inSeconds < 90 &&
        anilistNotifications.isNotEmpty) {
      return;
    }

    isAnilistLoading.value = true;
    anilistError.value = '';
    _anilistPage = 1;
    _anilistHasMore = true;

    try {
      final items = await auth.getNotifications(
        page: 1,
        perPage: 30,
        resetCount: false,
      );

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      anilistNotifications.value = items;
      _lastNotificationFetchTime = DateTime.now();

      if (items.isNotEmpty) {
        AnilistNotificationService.instance
            .updateLastSeenTimestamp(items.first.createdAt);
      }
      _anilistHasMore = true;
      hasFetchedAnilist.value = true;
    } catch (e) {
      anilistError.value = 'Failed to load AniList notifications';
    } finally {
      isAnilistLoading.value = false;
    }
  }

  Future<void> loadMoreAnilistNotifications() async {
    if (isAnilistLoadingMore.value || !_anilistHasMore) return;
    final auth = Get.find<AnilistAuth>();
    final token = AuthKeys.authToken.get<String?>();
    if (!auth.isLoggedIn.value && (token == null || token.isEmpty)) return;

    isAnilistLoadingMore.value = true;
    _anilistPage++;

    try {
      final currentFilter = selectedAnilistFilter.value;
      final typeIn = _getTypesForCategory(currentFilter);
      final items = await auth.getNotifications(
        page: _anilistPage,
        perPage: _anilistPageSize,
        resetCount: false,
        typeIn: typeIn,
      );

      if (items.isEmpty) {
        _anilistHasMore = false;
      } else {
        final existingIds = anilistNotifications.map((e) => e.id).toSet();
        for (final item in items) {
          if (!existingIds.contains(item.id)) {
            anilistNotifications.add(item);
            existingIds.add(item.id);
          }
        }
        anilistNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _anilistHasMore = items.length >= _anilistPageSize;
      }
    } catch (e) {
      _anilistPage--;
    } finally {
      isAnilistLoadingMore.value = false;
    }
  }

  Future<void> markAnilistAllRead() async {
    await AnilistNotificationService.instance.markAllRead();
    await loadAnilistNotifications(force: true);
  }

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AnilistAuth>();
    _authWorker = ever(auth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        loadAnilistNotifications();
        loadNotifications();
        loadUnreadCount();
      } else {
        anilistNotifications.clear();
        hasFetchedAnilist.value = false;
      }
    });
    loadNotifications();
    loadUnreadCount();
    loadAnilistNotifications();
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
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
    final index =
        notifications.indexWhere((n) => n.id == notificationId);
    final item = index != -1 ? notifications[index] : null;
    final clientType = item?.clientType.isNotEmpty == true
        ? item!.clientType
        : (item?.type == 'announcement_published' ? 'anymex' : null);

    final success =
        await _commentumService.markNotificationRead(notificationId, clientType: clientType);
    if (success) {
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

  @override
  Future<void> refresh() async {
    if (selectedTab.value == 0) {
      await loadAnilistNotifications();
    } else {
      await loadNotifications();
      await loadUnreadCount();
    }
  }
}
