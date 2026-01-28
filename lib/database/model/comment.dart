class Comment {
  String id;
  int contentId;
  String userId;
  String username;
  String? avatarUrl;
  String commentText;
  int likes;
  int userVote;
  int dislikes;
  String tag;
  String createdAt;
  String updatedAt;
  bool deleted;
  
  // Commentum v2 additional fields
  bool? pinned;
  bool? locked;
  bool? edited;
  int? editCount;
  String? editHistory;
  bool? reported;
  int? reportCount;
  String? reportStatus;
  bool? userBanned;
  String? userMutedUntil;
  bool? userShadowBanned;
  int? userWarnings;
  String? moderatedBy;
  String? moderationReason;
  int? parentId; // For nested comments
  List<Comment>? replies; // For nested comments

  Comment({
    required this.id,
    required this.userVote,
    required this.contentId,
    required this.userId,
    required this.username,
    required this.tag,
    required this.avatarUrl,
    required this.commentText,
    required this.likes,
    required this.dislikes,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    this.pinned,
    this.locked,
    this.edited,
    this.editCount,
    this.editHistory,
    this.reported,
    this.reportCount,
    this.reportStatus,
    this.userBanned,
    this.userMutedUntil,
    this.userShadowBanned,
    this.userWarnings,
    this.moderatedBy,
    this.moderationReason,
    this.parentId,
    this.replies,
  });

  factory Comment.fromMap(Map m) {
    return Comment(
      id: m['id'].toString(),
      contentId: int.parse(m['media_id'].toString()),
      tag: m['tag'] ?? '0',
      userId: m['user_id'].toString(),
      username: m['username']?.toString() ?? '',
      avatarUrl: m['avatar_url']?.toString(),
      commentText: m['comment']?.toString() ?? '',
      likes: m['likes_count'] ?? m['upvotes'] ?? 0,
      dislikes: m['dislikes_count'] ?? m['downvotes'] ?? 0,
      createdAt: m['created_at'].toString(),
      updatedAt: m['updated_at'].toString(),
      deleted: m['deleted'] ?? false,
      userVote: 0,
      // Commentum v2 fields
      pinned: m['pinned'],
      locked: m['locked'],
      edited: m['edited'],
      editCount: m['edit_count'],
      editHistory: m['edit_history'],
      reported: m['reported'],
      reportCount: m['report_count'],
      reportStatus: m['report_status'],
      userBanned: m['user_banned'],
      userMutedUntil: m['user_muted_until'],
      userShadowBanned: m['user_shadow_banned'],
      userWarnings: m['user_warnings'],
      moderatedBy: m['moderated_by'],
      moderationReason: m['moderation_reason'],
      parentId: m['parent_id'],
      replies: m['replies'] != null 
          ? (m['replies'] as List).map((reply) => Comment.fromMap(reply)).toList()
          : null,
    );
  }

  Comment copyWith({
    String? id,
    int? contentId,
    String? userId,
    String? username,
    String? avatarUrl,
    String? commentText,
    int? likes,
    int? userVote,
    int? dislikes,
    String? tag,
    String? createdAt,
    String? updatedAt,
    bool? deleted,
    // Commentum v2 fields
    bool? pinned,
    bool? locked,
    bool? edited,
    int? editCount,
    String? editHistory,
    bool? reported,
    int? reportCount,
    String? reportStatus,
    bool? userBanned,
    String? userMutedUntil,
    bool? userShadowBanned,
    int? userWarnings,
    String? moderatedBy,
    String? moderationReason,
    int? parentId,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      commentText: commentText ?? this.commentText,
      likes: likes ?? this.likes,
      userVote: userVote ?? this.userVote,
      dislikes: dislikes ?? this.dislikes,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      pinned: pinned ?? this.pinned,
      locked: locked ?? this.locked,
      edited: edited ?? this.edited,
      editCount: editCount ?? this.editCount,
      editHistory: editHistory ?? this.editHistory,
      reported: reported ?? this.reported,
      reportCount: reportCount ?? this.reportCount,
      reportStatus: reportStatus ?? this.reportStatus,
      userBanned: userBanned ?? this.userBanned,
      userMutedUntil: userMutedUntil ?? this.userMutedUntil,
      userShadowBanned: userShadowBanned ?? this.userShadowBanned,
      userWarnings: userWarnings ?? this.userWarnings,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderationReason: moderationReason ?? this.moderationReason,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
    );
  }
}
