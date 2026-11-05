import 'package:anymex/models/Anilist/anilist_activity.dart';

enum AnilistNotificationKind {
  airing,
  activity,
  social,
  system,
}

class AnilistNotificationItem {
  final int id;
  final String type;
  final AnilistNotificationKind kind;
  final int createdAt;
  final int? mediaId;
  final String? mediaTitle;
  final String? mediaCover;
  final String? mediaType;
  final int? episode;
  final List<String>? contexts;
  final int? userId;
  final String? userName;
  final String? userAvatar;
  final int? activityId;
  final int? commentId;
  final String? contextText;
  final String? reason;
  final String? deletedMediaTitle;

  const AnilistNotificationItem({
    required this.id,
    required this.type,
    required this.kind,
    required this.createdAt,
    this.mediaId,
    this.mediaTitle,
    this.mediaCover,
    this.mediaType,
    this.episode,
    this.contexts,
    this.userId,
    this.userName,
    this.userAvatar,
    this.activityId,
    this.commentId,
    this.contextText,
    this.reason,
    this.deletedMediaTitle,
  });

  String get displayTitle {
    switch (kind) {
      case AnilistNotificationKind.airing:
        return mediaTitle ?? 'Anime Airing';
      case AnilistNotificationKind.social:
        return userName ?? 'Social Alert';
      case AnilistNotificationKind.activity:
        return userName ?? 'Activity';
      case AnilistNotificationKind.system:
        return mediaTitle ?? 'System Notification';
    }
  }

  String get displayBody {
    if (type.contains('AIRING')) {
      if (episode != null && mediaTitle != null) {
        return 'Episode $episode of $mediaTitle has aired.';
      }
      if (contexts != null && contexts!.isNotEmpty) {
        return contexts!.join('');
      }
      return 'New episode aired.';
    }
    if (contextText != null && contextText!.isNotEmpty) {
      if (userName != null && !contextText!.startsWith(userName!)) {
        return '$userName $contextText';
      }
      return contextText!;
    }
    if (type.contains('FOLLOWING')) {
      return '${userName ?? 'Someone'} followed you.';
    }
    if (type.contains('LIKE')) {
      return '${userName ?? 'Someone'} liked your activity.';
    }
    if (type.contains('REPLY')) {
      return '${userName ?? 'Someone'} replied to your activity.';
    }
    if (type.contains('MENTION')) {
      return '${userName ?? 'Someone'} mentioned you.';
    }
    if (type.contains('MESSAGE')) {
      return '${userName ?? 'Someone'} sent you a message.';
    }
    if (reason != null && reason!.isNotEmpty) {
      return reason!;
    }
    return 'New update on AniList.';
  }

  String? get thumbnail => mediaCover ?? userAvatar;

  String get timeAgo => formatTimeAgo(createdAt);

  factory AnilistNotificationItem.fromJson(Map<String, dynamic> json) {
    final type =
        json['type'] as String? ?? json['__typename'] as String? ?? '';
    final id = json['id'] as int? ?? 0;
    final createdAt = json['createdAt'] as int? ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    AnilistNotificationKind kind;
    final kindStr = json['kind'] as String?;
    if (kindStr != null) {
      kind = AnilistNotificationKind.values.firstWhere(
        (e) => e.name == kindStr,
        orElse: () => AnilistNotificationKind.system,
      );
    } else if (type.contains('AIRING')) {
      kind = AnilistNotificationKind.airing;
    } else if (type.contains('FOLLOWING')) {
      kind = AnilistNotificationKind.social;
    } else if (type.contains('ACTIVITY') || type.contains('THREAD')) {
      kind = AnilistNotificationKind.activity;
    } else {
      kind = AnilistNotificationKind.system;
    }

    final media = json['media'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final titleMap = media?['title'] as Map<String, dynamic>?;
    final mediaTitle = titleMap?['userPreferred'] as String? ??
        titleMap?['english'] as String? ??
        titleMap?['romaji'] as String? ??
        titleMap?['native'] as String? ??
        json['mediaTitle'] as String?;

    final coverImage = media?['coverImage'] as Map<String, dynamic>?;
    final mediaCover = coverImage?['extraLarge'] as String? ??
        coverImage?['large'] as String? ??
        coverImage?['medium'] as String? ??
        json['mediaCover'] as String?;

    final avatarMap = user?['avatar'] as Map<String, dynamic>?;
    final userAvatar = avatarMap?['large'] as String? ??
        avatarMap?['medium'] as String? ??
        json['userAvatar'] as String?;

    final contextsRaw = json['contexts'];
    List<String>? contexts;
    if (contextsRaw is List) {
      contexts = contextsRaw.map((e) => e.toString()).toList();
    }

    return AnilistNotificationItem(
      id: id,
      type: type,
      kind: kind,
      createdAt: createdAt,
      mediaId: media?['id'] as int? ??
          json['animeId'] as int? ??
          json['mediaId'] as int?,
      mediaTitle: mediaTitle,
      mediaCover: mediaCover,
      mediaType: media?['type'] as String? ?? json['mediaType'] as String?,
      episode: json['episode'] as int?,
      contexts: contexts,
      userId: user?['id'] as int? ?? json['userId'] as int?,
      userName: user?['name'] as String? ?? json['userName'] as String?,
      userAvatar: userAvatar,
      activityId: json['activityId'] as int?,
      commentId: json['commentId'] as int?,
      contextText: json['context'] as String? ?? json['contextText'] as String?,
      reason: json['reason'] as String?,
      deletedMediaTitle: json['deletedMediaTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'kind': kind.name,
        'createdAt': createdAt,
        'mediaId': mediaId,
        'mediaTitle': mediaTitle,
        'mediaCover': mediaCover,
        'mediaType': mediaType,
        'episode': episode,
        'contexts': contexts,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'activityId': activityId,
        'commentId': commentId,
        'contextText': contextText,
        'reason': reason,
        'deletedMediaTitle': deletedMediaTitle,
      };
}
