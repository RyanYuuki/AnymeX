class AnilistNotification {
  final int id;
  final String type;
  final int? episode;
  final String? context;
  final int createdAt;
  final NotificationMedia? media;

  AnilistNotification({
    required this.id,
    required this.type,
    this.episode,
    this.context,
    required this.createdAt,
    this.media,
  });

  factory AnilistNotification.fromJson(Map<String, dynamic> json) {
    String? contextData;
    if (json['contexts'] != null && (json['contexts'] as List).isNotEmpty) {
      contextData = (json['contexts'] as List).first;
    } else {
      contextData = json['context'];
    }

    return AnilistNotification(
      id: json['id'],
      type: json['type'],
      episode: json['episode'],
      context: contextData,
      createdAt: json['createdAt'],
      media:
          json['media'] != null ? NotificationMedia.fromJson(json['media']) : null,
    );
  }
}

class NotificationMedia {
  final int id;
  final String title;
  final String coverImage;
  final String type;

  NotificationMedia({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.type,
  });

  factory NotificationMedia.fromJson(Map<String, dynamic> json) {
    return NotificationMedia(
      id: json['id'],
      title: json['title']['userPreferred'],
      coverImage: json['coverImage']['large'],
      type: json['type'],
    );
  }
}
