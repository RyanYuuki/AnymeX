import 'package:anymex/models/Anilist/anilist_activity.dart';

class AnilistThreadComment {
  final int id;
  final int? userId;
  final int threadId;
  final String comment;
  int likeCount;
  bool isLiked;
  final String? siteUrl;
  final int createdAt;
  final int updatedAt;
  final ThreadCommentUser? user;
  final List<ActivityLiker> likes;
  final List<AnilistThreadComment> childComments;
  final bool isLocked;

  AnilistThreadComment({
    required this.id,
    this.userId,
    required this.threadId,
    this.comment = '',
    this.likeCount = 0,
    this.isLiked = false,
    this.siteUrl,
    required this.createdAt,
    this.updatedAt = 0,
    this.user,
    this.likes = const [],
    this.childComments = const [],
    this.isLocked = false,
  });

  factory AnilistThreadComment.fromJson(Map<String, dynamic> json) {
    final likesJson = json['likes'] as List<dynamic>? ?? [];
    final childrenJson = json['childComments'] as List<dynamic>?;

    return AnilistThreadComment(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      threadId: json['threadId'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      siteUrl: json['siteUrl'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      user: json['user'] != null
          ? ThreadCommentUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      likes: likesJson
          .map((e) => ActivityLiker.fromJson(e as Map<String, dynamic>))
          .toList(),
      childComments: childrenJson != null
          ? childrenJson
              .map((e) =>
                  AnilistThreadComment.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  String get timeAgo => formatTimeAgo(createdAt);
}

class ThreadCommentUser {
  final int id;
  final String name;
  final String? avatarUrl;

  ThreadCommentUser({required this.id, required this.name, this.avatarUrl});

  factory ThreadCommentUser.fromJson(Map<String, dynamic> json) {
    return ThreadCommentUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar']?['large'] as String?,
    );
  }
}
