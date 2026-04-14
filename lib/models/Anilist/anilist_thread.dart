import 'package:anymex/models/Anilist/anilist_activity.dart';

class AnilistThread {
  final int id;
  final String title;
  final String body;
  final int userId;
  final int? replyUserId;
  final int? replyCommentId;
  final int replyCount;
  final int viewCount;
  final bool isLocked;
  final bool isSticky;
  bool isSubscribed;
  int likeCount;
  bool isLiked;
  final int? repliedAt;
  final int createdAt;
  final int updatedAt;
  final ThreadUser? user;
  final ThreadUser? replyUser;
  final List<ActivityLiker> likes;
  final String? siteUrl;
  final List<ThreadCategory> categories;
  final List<ThreadMediaCategory> mediaCategories;

  AnilistThread({
    required this.id,
    required this.title,
    this.body = '',
    required this.userId,
    this.replyUserId,
    this.replyCommentId,
    this.replyCount = 0,
    this.viewCount = 0,
    this.isLocked = false,
    this.isSticky = false,
    this.isSubscribed = false,
    this.likeCount = 0,
    this.isLiked = false,
    this.repliedAt,
    required this.createdAt,
    this.updatedAt = 0,
    this.user,
    this.replyUser,
    this.likes = const [],
    this.siteUrl,
    this.categories = const [],
    this.mediaCategories = const [],
  });

  factory AnilistThread.fromJson(Map<String, dynamic> json) {
    final likesJson = json['likes'] as List<dynamic>? ?? [];
    final categoriesJson = json['categories'] as List<dynamic>? ?? [];
    final mediaCategoriesJson = json['mediaCategories'] as List<dynamic>? ?? [];

    return AnilistThread(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      userId: json['userId'] as int,
      replyUserId: json['replyUserId'] as int?,
      replyCommentId: json['replyCommentId'] as int?,
      replyCount: json['replyCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      isLocked: json['isLocked'] as bool? ?? false,
      isSticky: json['isSticky'] as bool? ?? false,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      repliedAt: json['repliedAt'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      user: json['user'] != null
          ? ThreadUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      replyUser: json['replyUser'] != null
          ? ThreadUser.fromJson(json['replyUser'] as Map<String, dynamic>)
          : null,
      likes: likesJson
          .map((e) => ActivityLiker.fromJson(e as Map<String, dynamic>))
          .toList(),
      siteUrl: json['siteUrl'] as String?,
      categories: categoriesJson
          .map((e) => ThreadCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaCategories: mediaCategoriesJson
          .map((e) => ThreadMediaCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get timeAgo => formatTimeAgo(createdAt);
}

class ThreadUser {
  final int id;
  final String name;
  final String? avatarUrl;

  ThreadUser({required this.id, required this.name, this.avatarUrl});

  factory ThreadUser.fromJson(Map<String, dynamic> json) {
    return ThreadUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar']?['large'] as String?,
    );
  }
}

class ThreadCategory {
  final int id;
  final String name;

  ThreadCategory({required this.id, required this.name});

  factory ThreadCategory.fromJson(Map<String, dynamic> json) {
    return ThreadCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class ThreadMediaCategory {
  final int id;
  final String? title;

  ThreadMediaCategory({required this.id, this.title});

  factory ThreadMediaCategory.fromJson(Map<String, dynamic> json) {
    return ThreadMediaCategory(
      id: json['id'] as int,
      title: json['title']?['userPreferred'] as String?,
    );
  }
}
