class Comment {
  final String id;
  final int mediaId;
  final String mediaType; // ANIME, MANGA
  final String content;
  final int userId;
  final String username;
  final String? profilePictureUrl;
  final String? parentCommentId;
  final int upvotes;
  final int downvotes;
  final int userVote; // 1 for upvote, -1 for downvote, 0 for none
  final bool isMod;
  final bool isAdmin;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment>? replies;

  Comment({
    required this.id,
    required this.mediaId,
    required this.mediaType,
    required this.content,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    this.parentCommentId,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote = 0,
    this.isMod = false,
    this.isAdmin = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'].toString(),
      mediaId: json['media_id'] ?? 0,
      mediaType: json['media_type'] ?? 'ANIME',
      content: json['content'] ?? '',
      userId: json['anilist_user_id'] ?? 0,
      username: json['username'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      parentCommentId: json['parent_comment_id'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      userVote: json['user_vote'] ?? 0,
      isMod: json['is_mod'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      replies: json['replies'] != null 
          ? (json['replies'] as List).map((reply) => Comment.fromJson(reply)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_id': mediaId,
      'media_type': mediaType,
      'content': content,
      'anilist_user_id': userId,
      'username': username,
      'profile_picture_url': profilePictureUrl,
      'parent_comment_id': parentCommentId,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'user_vote': userVote,
      'is_mod': isMod,
      'is_admin': isAdmin,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'replies': replies?.map((reply) => reply.toJson()).toList(),
    };
  }

  Comment copyWith({
    String? id,
    int? mediaId,
    String? mediaType,
    String? content,
    int? userId,
    String? username,
    String? profilePictureUrl,
    String? parentCommentId,
    int? upvotes,
    int? downvotes,
    int? userVote,
    bool? isMod,
    bool? isAdmin,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userVote: userVote ?? this.userVote,
      isMod: isMod ?? this.isMod,
      isAdmin: isAdmin ?? this.isAdmin,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
    );
  }

  // For backward compatibility with existing code
  String get commentText => content;
  int get contentId => mediaId;
  String? get avatarUrl => profilePictureUrl;
  int get likes => upvotes;
  int get dislikes => downvotes;
  String get tag => parentCommentId ?? '0';
}

class CreateCommentRequest {
  final int mediaId;
  final String mediaType;
  final String content;
  final String? parentCommentId;

  CreateCommentRequest({
    required this.mediaId,
    required this.mediaType,
    required this.content,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'media_type': mediaType,
      'content': content,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
    };
  }
}

class VoteRequest {
  final String commentId;
  final int voteType; // 1 for upvote, -1 for downvote

  VoteRequest({
    required this.commentId,
    required this.voteType,
  });

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'vote_type': voteType,
    };
  }
}