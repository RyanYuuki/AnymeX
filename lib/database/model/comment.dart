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
      likes: m['likes_count'] ?? 0,
      dislikes: m['dislikes_count'] ?? 0,
      createdAt: m['created_at'].toString(),
      updatedAt: m['updated_at'].toString(),
      deleted: m['deleted'] ?? false,
      userVote: 0,
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
    );
  }
}
