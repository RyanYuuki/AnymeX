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
  String? moderationAction;
  bool? moderated;
  String? userRole;
  String? userTier;
  int? userPoints;
  int? parentId;
  String? avatarDecoration;
  String? bannerUrl;
  String? bannerTheme;
  String? nameplateTheme;
  Map<String, dynamic>? linkedAccounts;
  List<Comment>? replies;

  String? get linkedAnilistUsername => linkedAccounts?['anilist']?['username']?.toString();
  String? get linkedMalUsername => linkedAccounts?['mal']?['username']?.toString();
  String? get linkedSimklUsername => linkedAccounts?['simkl']?['username']?.toString();
  bool get hasLinkedAccounts => linkedAnilistUsername != null || linkedMalUsername != null || linkedSimklUsername != null;
  bool hasSecondaryLinkedAccounts([String exclude = 'anilist']) {
    final norm = exclude.toLowerCase();
    final hasAl = (norm != 'anilist') && linkedAnilistUsername != null && linkedAnilistUsername!.isNotEmpty;
    final hasMal = (norm != 'mal' && norm != 'myanimelist') && linkedMalUsername != null && linkedMalUsername!.isNotEmpty;
    final hasSimkl = (norm != 'simkl') && linkedSimklUsername != null && linkedSimklUsername!.isNotEmpty;
    return hasAl || hasMal || hasSimkl;
  }

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
    this.moderationAction,
    this.moderated,
    this.userRole,
    this.userTier,
    this.userPoints,
    this.parentId,
    this.avatarDecoration,
    this.bannerUrl,
    this.bannerTheme,
    this.nameplateTheme,
    this.linkedAccounts,
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
      moderationAction: m['moderation_action'],
      moderated: m['moderated'],
      userRole: m['user_role'],
      userTier: m['user_tier'],
      userPoints: m['user_points'],
      parentId: m['parent_id'],
      avatarDecoration: m['avatar_decoration']?.toString(),
      bannerUrl: m['banner_url']?.toString(),
      bannerTheme: m['banner_theme']?.toString(),
      nameplateTheme: m['nameplate_theme']?.toString(),
      linkedAccounts: m['linked_accounts'] is Map ? Map<String, dynamic>.from(m['linked_accounts']) : null,
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
    String? moderationAction,
    bool? moderated,
    String? userRole,
    String? userTier,
    int? userPoints,
    int? parentId,
    String? avatarDecoration,
    String? bannerUrl,
    String? bannerTheme,
    String? nameplateTheme,
    Map<String, dynamic>? linkedAccounts,
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
      moderationAction: moderationAction ?? this.moderationAction,
      moderated: moderated ?? this.moderated,
      userRole: userRole ?? this.userRole,
      userTier: userTier ?? this.userTier,
      userPoints: userPoints ?? this.userPoints,
      parentId: parentId ?? this.parentId,
      avatarDecoration: avatarDecoration ?? this.avatarDecoration,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerTheme: bannerTheme ?? this.bannerTheme,
      nameplateTheme: nameplateTheme ?? this.nameplateTheme,
      linkedAccounts: linkedAccounts ?? this.linkedAccounts,
      replies: replies ?? this.replies,
    );
  }
}
