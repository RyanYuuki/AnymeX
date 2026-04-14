import 'package:anymex/models/Anilist/anilist_activity.dart';

class AnilistReview {
  final int id;
  final int userId;
  final int mediaId;
  final String mediaType;
  final String summary;
  final String body;
  final int score;
  final int rating;
  final int ratingAmount;
  final String userRating;
  final bool isPrivate;
  final String? siteUrl;
  final int createdAt;
  final int updatedAt;
  final ReviewUser? user;
  final ReviewMedia? media;

  AnilistReview({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    this.summary = '',
    this.body = '',
    this.score = 0,
    this.rating = 0,
    this.ratingAmount = 0,
    this.userRating = 'NO_VOTE',
    this.isPrivate = false,
    this.siteUrl,
    required this.createdAt,
    this.updatedAt = 0,
    this.user,
    this.media,
  });

  factory AnilistReview.fromJson(Map<String, dynamic> json) {
    return AnilistReview(
      id: json['id'] as int,
      userId: json['userId'] as int,
      mediaId: json['mediaId'] as int,
      mediaType: json['mediaType'] as String? ?? 'ANIME',
      summary: json['summary'] as String? ?? '',
      body: json['body'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      rating: json['rating'] as int? ?? 0,
      ratingAmount: json['ratingAmount'] as int? ?? 0,
      userRating: json['userRating'] as String? ?? 'NO_VOTE',
      isPrivate: json['private'] as bool? ?? false,
      siteUrl: json['siteUrl'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      user: json['user'] != null
          ? ReviewUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      media: json['media'] != null
          ? ReviewMedia.fromJson(json['media'] as Map<String, dynamic>)
          : null,
    );
  }

  String get timeAgo => formatTimeAgo(createdAt);
}

class ReviewUser {
  final int id;
  final String name;
  final String? avatarUrl;

  ReviewUser({required this.id, required this.name, this.avatarUrl});

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar']?['large'] as String?,
    );
  }
}

class ReviewMedia {
  final int id;
  final String? title;
  final String? coverUrl;
  final String? bannerUrl;
  final String type;

  ReviewMedia({
    required this.id,
    this.title,
    this.coverUrl,
    this.bannerUrl,
    this.type = 'ANIME',
  });

  factory ReviewMedia.fromJson(Map<String, dynamic> json) {
    return ReviewMedia(
      id: json['id'] as int,
      title: json['title']?['userPreferred'] as String?,
      coverUrl: json['coverImage']?['large'] as String?,
      bannerUrl: json['bannerImage'] as String?,
      type: json['type'] as String? ?? 'ANIME',
    );
  }
}
