String formatTimeAgo(int unixSeconds) {
  final now = DateTime.now();
  final time = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  final diff = now.difference(time);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

class ActivityLiker {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? bannerImage;

  const ActivityLiker({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bannerImage,
  });

  factory ActivityLiker.fromJson(Map<String, dynamic> json) {
    return ActivityLiker(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar']?['large'] as String? ??
          json['avatar']?['medium'] as String?,
      bannerImage: json['bannerImage'] as String?,
    );
  }
}

class AnilistActivity {
  final int id;
  final String type;
  final String? status;
  final String? progress; 
  String? text;
  final int? mediaId;
  final String? mediaTitle;
  final String? mediaCoverUrl;
  final String? mediaBannerUrl;
  final int? authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final int createdAt;


  int likeCount;
  int replyCount;
  bool isLiked;
  bool isPinned;
  bool isSubscribed;
  bool isPrivate;
  List<ActivityLiker> likes;

  AnilistActivity({
    required this.id,
    required this.type,
    this.status,
    this.progress,
    this.text,
    this.mediaId,
    this.mediaTitle,
    this.mediaCoverUrl,
    this.mediaBannerUrl,
    this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    this.isSubscribed = false,
    this.isPrivate = false,
    this.likes = const [],
  });

  factory AnilistActivity.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';

    final likesJson = json['likes'] as List<dynamic>? ?? [];
    final likes = likesJson
        .map((e) => ActivityLiker.fromJson(e as Map<String, dynamic>))
        .toList();

    if (type == 'TEXT') {
      return AnilistActivity(
        id: json['id'] as int,
        type: type,
        text: json['text'] as String?,
        authorId: json['user']?['id'] as int?,
        authorName: json['user']?['name'] as String?,
        authorAvatarUrl: json['user']?['avatar']?['large'] as String?,
        createdAt: json['createdAt'] as int? ?? 0,
        likeCount: json['likeCount'] as int? ?? 0,
        replyCount: json['replyCount'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
        isSubscribed: json['isSubscribed'] as bool? ?? false,
        likes: likes,
      );
    } else if (type == 'MESSAGE') {
      return AnilistActivity(
        id: json['id'] as int,
        type: type,
        text: json['message'] as String?,
        authorId: json['messenger']?['id'] as int?,
        authorName: json['messenger']?['name'] as String?,
        authorAvatarUrl: json['messenger']?['avatar']?['large'] as String?,
        createdAt: json['createdAt'] as int? ?? 0,
        likeCount: json['likeCount'] as int? ?? 0,
        replyCount: json['replyCount'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        isPinned: false, // Messages don't have isPinned
        isSubscribed: json['isSubscribed'] as bool? ?? false,
        isPrivate: json['isPrivate'] as bool? ?? false,
        likes: likes,
      );
    } else {
      // ANIME_LIST or MANGA_LIST
      final status = json['status'] as String? ?? '';
      final progress = json['progress'] as String?;

      return AnilistActivity(
        id: json['id'] as int,
        type: type,
        status: status,
        progress: progress,
        mediaId: json['media']?['id'] as int?,
        mediaTitle: json['media']?['title']?['userPreferred'] as String?,
        mediaCoverUrl: json['media']?['coverImage']?['large'] as String?,
        mediaBannerUrl: json['media']?['bannerImage'] as String?,
        authorId: json['user']?['id'] as int?,
        authorName: json['user']?['name'] as String?,
        authorAvatarUrl: json['user']?['avatar']?['large'] as String?,
        createdAt: json['createdAt'] as int? ?? 0,
        likeCount: json['likeCount'] as int? ?? 0,
        replyCount: json['replyCount'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
        isSubscribed: json['isSubscribed'] as bool? ?? false,
        likes: likes,
      );
    }
  }

  String get displayText {
    if (type == 'TEXT' || type == 'MESSAGE') {
      final rawText = text ?? '';
     
      var cleaned = rawText
          .replaceAll(
              RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true), '')
          .trim();
   
      cleaned = cleaned
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&#39;', "'")
          .replaceAll('&nbsp;', ' ');
      return cleaned;
    }
    // List activity
    final capitalizedStatus = (status != null && status!.isNotEmpty)
        ? '${status![0].toUpperCase()}${status!.substring(1)}'
        : '';
    if (progress != null && progress!.isNotEmpty) {
      return '$capitalizedStatus $progress of';
    }
    return capitalizedStatus;
  }

  String get timeAgo => formatTimeAgo(createdAt);
}

class ActivityReply {
  final int id;
  final String text;
  final int? authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final int createdAt;

  // Interactive fields
  int likeCount;
  bool isLiked;
  List<ActivityLiker> likes;

  ActivityReply({
    required this.id,
    required this.text,
    this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
    this.likes = const [],
  });

  factory ActivityReply.fromJson(Map<String, dynamic> json) {
    final likesJson = json['likes'] as List<dynamic>? ?? [];
    final likes = likesJson
        .map((e) => ActivityLiker.fromJson(e as Map<String, dynamic>))
        .toList();

    return ActivityReply(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      authorId: json['user']?['id'] as int?,
      authorName: json['user']?['name'] as String?,
      authorAvatarUrl: json['user']?['avatar']?['large'] as String?,
      createdAt: json['createdAt'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      likes: likes,
    );
  }

  String get timeAgo => formatTimeAgo(createdAt);
}
