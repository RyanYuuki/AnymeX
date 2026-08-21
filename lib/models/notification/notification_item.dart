import 'package:get/get.dart';

class NotificationItem {
  final int id;
  final String clientType;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? commentId;
  final String? mediaId;
  final String? mediaType;
  final String? mediaTitle;
  final String? actorId;
  final String? actorUsername;
  final String? actorAvatar;
  final String? moderatorUsername;
  final String? reason;
  final String? clickAction;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  NotificationItem({
    required this.id,
    required this.clientType,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.commentId,
    this.mediaId,
    this.mediaType,
    this.mediaTitle,
    this.actorId,
    this.actorUsername,
    this.actorAvatar,
    this.moderatorUsername,
    this.reason,
    this.clickAction,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      clientType: json['client_type'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      commentId: json['comment_id']?.toString(),
      mediaId: json['media_id']?.toString(),
      mediaType: json['media_type'] as String?,
      mediaTitle: json['media_title'] as String?,
      actorId: json['actor_id']?.toString(),
      actorUsername: json['actor_username'] as String?,
      actorAvatar: json['actor_avatar'] as String?,
      moderatorUsername: json['moderator_username'] as String?,
      reason: json['reason'] as String?,
      clickAction: json['click_action'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  String? get rawCommentContent {
    return metadata['raw_comment_content'] as String?;
  }

  String get typeIcon {
    switch (type) {
      case 'user_mentioned':
        return '💬';
      case 'comment_reply':
        return '↩️';
      case 'comment_created':
        return '💬';
      case 'comment_updated':
        return '✏️';
      case 'comment_deleted':
        return '🗑️';
      case 'comment_pinned':
        return '📌';
      case 'comment_unpinned':
        return '📍';
      case 'comment_locked':
        return '🔒';
      case 'comment_unlocked':
        return '🔓';
      case 'vote_cast':
        return '▲';
      case 'vote_removed':
        return '➖';
      case 'report_filed':
        return '🚨';
      case 'report_resolved':
        return '✅';
      case 'report_dismissed':
        return '❌';
      case 'user_warned':
        return '⚠️';
      case 'user_muted':
        return '🔇';
      case 'user_unmuted':
        return '🔊';
      case 'user_banned':
        return '⛔';
      case 'user_unbanned':
        return '♻️';
      case 'user_shadow_banned':
        return '👻';
      case 'announcement_published':
        return '📢';
      case 'moderation_action':
        return '⚙️';
      default:
        return '🔔';
    }
  }

  String get typeCategory {
    if (type == 'user_mentioned') return 'comment';
    if (type.startsWith('comment_')) return 'comment';
    if (type.startsWith('vote_')) return 'vote';
    if (type.startsWith('report_')) return 'report';
    if (type.startsWith('user_')) return 'moderation';
    if (type == 'announcement_published') return 'announcement';
    return 'other';
  }
}
