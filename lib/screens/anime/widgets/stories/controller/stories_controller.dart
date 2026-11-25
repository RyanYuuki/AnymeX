import 'dart:async';
import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_cache.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/models/Anilist/social_user.dart';
import 'package:anymex/models/Anilist/story_group.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class StoriesController extends GetxController {
  static StoriesController get instance => Get.find<StoriesController>();

  http.Client get _client => NetworkManager.instance.compatibleClient;
  final AnilistAuth _auth = Get.find<AnilistAuth>();

  final RxList<StoryGroup> storyGroups = <StoryGroup>[].obs;
  final Rx<StoryGroup?> ownStory = Rx<StoryGroup?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 3);
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();
    _authWorker = ever<bool>(_auth.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        fetchStories(forceRefresh: true);
      } else {
        storyGroups.clear();
        ownStory.value = null;
      }
    });

    if (_auth.isLoggedIn.value) {
      fetchStories();
    }
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchStories({bool forceRefresh = false}) async {
    if (!_auth.isLoggedIn.value) {
      storyGroups.clear();
      ownStory.value = null;
      return;
    }

    final token = AuthKeys.authToken.get<String?>();
    if (token == null || token.isEmpty) return;

    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        storyGroups.isNotEmpty) {
      return;
    }

    if (storyGroups.isEmpty) {
      isLoading.value = true;
    }
    hasError.value = false;

    try {
      final cutoff = DateTime.now()
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch ~/
          1000;
      final currentUserId = int.tryParse(_auth.profileData.value.id ?? '0') ?? 0;

      Map<String, dynamic>? payload;
      if (!forceRefresh) {
        payload = await AnilistCache.instance.get('anilist_stories');
      }

      payload ??= await AnilistCache.instance.deduplicate(
        'anilist_stories',
        () => _fetchStoriesBatched(token, currentUserId, cutoff),
      );

      final rawFollowing =
          (payload?['following'] as List<dynamic>?) ?? const [];
      final rawMine = (payload?['mine'] as List<dynamic>?) ?? const [];

      final followingActivities = rawFollowing
          .whereType<Map<String, dynamic>>()
          .where((e) => e['id'] != null)
          .map((e) => AnilistActivity.fromJson(e))
          .toList();
      final myActivities = rawMine
          .whereType<Map<String, dynamic>>()
          .where((e) => e['id'] != null)
          .map((e) => AnilistActivity.fromJson(e))
          .toList();

      final currentUserName = _auth.profileData.value.name ?? 'Your Story';

      final grouped = <int, List<AnilistActivity>>{};
      final userMap = <int, SocialUser>{};

      for (final activity in followingActivities) {
        if (activity.createdAt < cutoff) continue;
        final authorId = activity.authorId;
        if (authorId == null) continue;
        if (authorId == currentUserId) continue;

        grouped.putIfAbsent(authorId, () => []).add(activity);
        if (!userMap.containsKey(authorId)) {
          userMap[authorId] = SocialUser(
            id: authorId,
            name: activity.authorName ?? 'User',
            avatarUrl: activity.authorAvatarUrl,
          );
        }
      }

      final parsedGroups = <StoryGroup>[];
      for (final entry in grouped.entries) {
        final acts = entry.value;
        acts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final user = userMap[entry.key]!;
        parsedGroups.add(StoryGroup(user: user, activities: acts));
      }

      parsedGroups.sort((a, b) {
        if (a.hasUnseen != b.hasUnseen) {
          return a.hasUnseen ? -1 : 1;
        }
        return b.latestTimestamp.compareTo(a.latestTimestamp);
      });

      final validMyActivities =
          myActivities.where((a) => a.createdAt >= cutoff).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final myUser = SocialUser(
        id: currentUserId,
        name: currentUserName.isNotEmpty ? currentUserName : 'Your Story',
        avatarUrl: _auth.profileData.value.avatar,
        bannerImage: _auth.profileData.value.cover,
      );

      ownStory.value = StoryGroup(
        user: myUser,
        activities: validMyActivities,
      );

      storyGroups.value = parsedGroups;
      _lastFetchTime = DateTime.now();
    } catch (e, st) {
      Logger.e('Failed to fetch stories: $e', stackTrace: st);
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _fetchStoriesBatched(
    String token,
    int currentUserId,
    int cutoff,
  ) async {
    const batchedQuery = r'''
    query ($userId: Int) {
      following: Page(page: 1, perPage: 50) {
        activities(
          isFollowing: true,
          type_in: [TEXT, ANIME_LIST, MANGA_LIST, MEDIA_LIST],
          sort: ID_DESC
        ) {
          __typename
          ... on TextActivity {
            id
            userId
            type
            replyCount
            text(asHtml: false)
            siteUrl
            isLocked
            isSubscribed
            likeCount
            isLiked
            isPinned
            createdAt
            user {
              id
              name
              avatar { large }
              bannerImage
            }
          }
          ... on ListActivity {
            id
            userId
            type
            replyCount
            status
            progress
            siteUrl
            isLocked
            isSubscribed
            likeCount
            isLiked
            isPinned
            createdAt
            user {
              id
              name
              avatar { large }
              bannerImage
            }
            media {
              id
              type
              isAdult
              title { userPreferred }
              coverImage { large }
              bannerImage
            }
          }
        }
      }
      mine: Page(page: 1, perPage: 25) {
        activities(
          userId: $userId,
          type_in: [TEXT, ANIME_LIST, MANGA_LIST, MEDIA_LIST],
          sort: ID_DESC
        ) {
          __typename
          ... on TextActivity {
            id
            userId
            type
            replyCount
            text(asHtml: false)
            siteUrl
            likeCount
            isLiked
            createdAt
            user {
              id
              name
              avatar { large }
              bannerImage
            }
          }
          ... on ListActivity {
            id
            userId
            type
            replyCount
            status
            progress
            siteUrl
            likeCount
            isLiked
            createdAt
            user {
              id
              name
              avatar { large }
              bannerImage
            }
            media {
              id
              type
              isAdult
              title { userPreferred }
              coverImage { large }
              bannerImage
            }
          }
          ... on MessageActivity {
            id
            type
            replyCount
            message(asHtml: false)
            siteUrl
            likeCount
            isLiked
            createdAt
            messenger {
              id
              name
              avatar { large }
              bannerImage
            }
          }
        }
      }
    }
    ''';

    final followingRaw = <dynamic>[];
    var mineRaw = <dynamic>[];

    if (currentUserId <= 0) {
      final page1 = await _fetchFollowingPage(token, 1);
      followingRaw.addAll(page1);
    } else {
      final response = await _client.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'query': batchedQuery,
          'variables': {'userId': currentUserId},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;
        final root = data?['data'] as Map<String, dynamic>?;
        followingRaw.addAll(
            (root?['following']?['activities'] as List<dynamic>?) ?? const []);
        mineRaw =
            (root?['mine']?['activities'] as List<dynamic>?) ?? const [];
      }
    }

    if (followingRaw.length >= 50) {
      final lastCreatedAt =
          (followingRaw.last as Map<String, dynamic>?)?['createdAt'] as int?;
      if (lastCreatedAt != null && lastCreatedAt >= cutoff) {
        final page2 = await _fetchFollowingPage(token, 2);
        followingRaw.addAll(page2);
      }
    }

    final payload = <String, dynamic>{
      'following': followingRaw,
      'mine': mineRaw,
    };
    AnilistCache.instance.put(
      'anilist_stories',
      payload,
      ttl: const Duration(minutes: 5),
      persist: true,
    );
    return payload;
  }

  Future<List<dynamic>> _fetchFollowingPage(String token, int page) async {
    const query = r'''
    query ($page: Int) {
      Page(page: $page, perPage: 50) {
        activities(
          isFollowing: true,
          type_in: [TEXT, ANIME_LIST, MANGA_LIST, MEDIA_LIST],
          sort: ID_DESC
        ) {
          __typename
          ... on TextActivity {
            id
            userId
            type
            replyCount
            text(asHtml: false)
            siteUrl
            isLocked
            isSubscribed
            likeCount
            isLiked
            isPinned
            createdAt
            user {
              id
              name
              avatar { large }
              bannerImage
            }
          }
          ... on ListActivity {
            id
            userId
            type
            replyCount
            status
            progress
            siteUrl
            isLocked
            isSubscribed
            likeCount
            isLiked
            isPinned
            createdAt
            user {
              id
              name
              avatar { large }
              bannerImage
            }
            media {
              id
              type
              isAdult
              title { userPreferred }
              coverImage { large }
              bannerImage
            }
          }
        }
      }
    }
    ''';

    try {
      final response = await _client.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'query': query,
          'variables': {'page': page},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data?['data']?['Page']?['activities'] as List<dynamic>?) ??
            const [];
      }
    } catch (e) {
      Logger.e('Error querying page $page for stories: $e');
    }
    return const [];
  }

  void reorderStories() {
    final updated = List<StoryGroup>.from(storyGroups);
    updated.sort((a, b) {
      if (a.hasUnseen != b.hasUnseen) {
        return a.hasUnseen ? -1 : 1;
      }
      return b.latestTimestamp.compareTo(a.latestTimestamp);
    });
    storyGroups.value = updated;
  }

  Future<bool> toggleLike(AnilistActivity activity) async {
    final wasLiked = activity.isLiked;
    activity.isLiked = !wasLiked;
    activity.likeCount += wasLiked ? -1 : 1;
    storyGroups.refresh();
    ownStory.refresh();

    final success = await _auth.toggleLike(activity.id, 'ACTIVITY');
    if (!success) {
      activity.isLiked = wasLiked;
      activity.likeCount += wasLiked ? 1 : -1;
      storyGroups.refresh();
      ownStory.refresh();
    }
    return success;
  }

  Future<bool> postStory(String text) async {
    final success = await _auth.createActivity(text);
    if (success) {
      await fetchStories(forceRefresh: true);
    }
    return success;
  }
}
