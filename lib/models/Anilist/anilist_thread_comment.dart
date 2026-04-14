import 'dart:convert';

import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/utils/logger.dart';

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

    // childComments is AniList Json type - can come back as List or as JSON string
    List<dynamic>? childrenJson;
    final rawChildren = json['childComments'];
    if (rawChildren != null) {
      if (rawChildren is String && rawChildren.isNotEmpty) {
        try {
          childrenJson = jsonDecode(rawChildren) as List<dynamic>;
        } catch (e) {
          Logger.e('Failed to decode childComments JSON string: $e');
          childrenJson = [];
        }
      } else if (rawChildren is List) {
        childrenJson = rawChildren;
      } else {
        Logger.w('childComments unexpected type: ${rawChildren.runtimeType}');
        childrenJson = [];
      }
    }

    List<AnilistThreadComment> parsedChildren = [];
    if (childrenJson != null && childrenJson.isNotEmpty) {
      for (final e in childrenJson) {
        try {
          if (e is Map<String, dynamic>) {
            parsedChildren
                .add(AnilistThreadComment.fromJson(e));
          } else if (e is Map) {
            parsedChildren.add(
                AnilistThreadComment.fromJson(Map<String, dynamic>.from(e)));
          }
        } catch (e) {
          Logger.e('Failed to parse child comment: $e');
        }
      }
    }

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
      childComments: parsedChildren,
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
