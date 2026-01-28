import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CommentumService extends GetxController {
  static const String baseUrl = 'https://whzwmfxngelicmjyxwmr.supabase.co/functions/v1';
  
  // Reactive user role
  final RxString currentUserRole = 'user'.obs;
  
  // Get current user info from AnymeX authentication
  Profile? get currentUser => serviceHandler.profileData.value;
  String? get currentUserId => currentUser?.id?.toString();
  String? get currentUsername => currentUser?.name;
  String? get currentUserAvatar => currentUser?.avatar;
  
  // Get authentication token
  Future<String?> get _authToken async {
    final storage = Get.find<AnilistAuth>().storage;
    return await storage.get('auth_token');
  }

  // Determine client type based on current service
  String get _clientType {
    switch (serviceHandler.serviceType.value) {
      case ServicesType.anilist:
        return 'anilist';
      case ServicesType.mal:
        return 'myanimelist';
      case ServicesType.simkl:
        return 'simkl';
      default:
        return 'other';
    }
  }

  // Fetch comments for a media
  Future<List<Comment>> fetchComments(String mediaId, {int page = 1, int limit = 50, String sort = 'newest'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/media?media_id=$mediaId&client_type=${_clientType}&page=$page&limit=$limit&sort=$sort'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsList = data['comments'] as List<dynamic>? ?? [];
        
        return commentsList.map((commentData) => _mapCommentumToAnymeXComment(commentData)).toList();
      } else {
        Logger.i('Failed to fetch comments: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      Logger.i('Error fetching comments: $e');
      return [];
    }
  }

  // Create a new comment
  Future<Comment?> createComment({
    required String mediaId,
    required String content,
    int? parentId,
    String? mediaType,
    String? mediaTitle,
    int? mediaYear,
    String? mediaPoster,
  }) async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return null;
    }

    try {
      final requestBody = {
        'action': 'create',
        'client_type': _clientType,
        'user_id': currentUserId,
        'media_id': mediaId,
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      };
      
      Logger.i('Creating comment with body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      Logger.i('Comment creation response status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        Logger.i('Comment creation response data: ${json.encode(data)}');
        final commentData = data['comment'];
        return _mapCommentumToAnymeXComment(commentData);
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to create comment: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error creating comment: $e');
      return null;
    }
  }

  // Edit a comment
  Future<Comment?> editComment({
    required int commentId,
    required String content,
  }) async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return null;
    }

    final token = await _authToken;
    if (token == null) {
      Logger.i('No auth token available');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'edit',
          'comment_id': commentId,
          'client_type': _clientType,
          'user_id': currentUserId,
          'token': token,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentData = data['comment'];
        return _mapCommentumToAnymeXComment(commentData);
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to edit comment: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error editing comment: $e');
      return null;
    }
  }

  // Delete a comment
  Future<bool> deleteComment({
    required int commentId,
    String? userId,
  }) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      Logger.i('User not logged in');
      return false;
    }

    // For deleting own comments, no token needed
    // For deleting others' comments, token required (admin only)
    final needsToken = userId != null && userId != currentUserId;
    final token = needsToken ? await _authToken : null;

    if (needsToken && token == null) {
      Logger.i('Admin token required for deleting others\' comments');
      return false;
    }

    try {
      final body = <String, dynamic>{
        'action': 'delete',
        'comment_id': commentId,
        'user_id': targetUserId,
      };

      if (needsToken) {
        body['client_type'] = _clientType;
        body['token'] = token;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to delete comment: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error deleting comment: $e');
      return false;
    }
  }

  // Vote on a comment
  Future<Map<String, dynamic>?> voteComment({
    required int commentId,
    required String voteType, // 'upvote', 'downvote', 'remove'
  }) async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/votes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'comment_id': commentId,
          'user_id': currentUserId,
          'vote_type': voteType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'upvotes': data['upvotes'],
          'downvotes': data['downvotes'],
          'voteScore': data['voteScore'],
          'userVote': data['userVote'],
        };
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to vote on comment: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error voting on comment: $e');
      return null;
    }
  }

  // Report a comment
  Future<bool> reportComment({
    required int commentId,
    required String reason,
    String? notes,
  }) async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'create',
          'comment_id': commentId,
          'reporter_id': currentUserId,
          'reason': reason,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to report comment: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error reporting comment: $e');
      return false;
    }
  }

  // Get moderation queue (admin/moderator only)
  Future<List<Map<String, dynamic>>> getModerationQueue() async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return [];
    }

    final token = await _authToken;
    if (token == null) {
      Logger.i('No auth token available');
      return [];
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'get_queue',
          'client_type': _clientType,
          'moderator_id': currentUserId,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['reports'] ?? []);
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to get moderation queue: ${error['error'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      Logger.i('Error getting moderation queue: $e');
      return [];
    }
  }

  // Moderate a comment (admin/moderator only)
  Future<bool> moderateComment({
    required String action, // 'pin_comment', 'unpin_comment', 'lock_thread', 'unlock_thread'
    required int commentId,
    required String reason,
  }) async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return false;
    }

    final token = await _authToken;
    if (token == null) {
      Logger.i('No auth token available');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/moderation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': action,
          'comment_id': commentId,
          'client_type': _clientType,
          'moderator_id': currentUserId,
          'token': token,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to moderate comment: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error moderating comment: $e');
      return false;
    }
  }

  // User management (admin only)
  Future<bool> manageUser({
    required String action, // 'warn_user', 'mute_user', 'ban_user', 'unban_user'
    required String targetUserId,
    required String reason,
    String? severity,
    int? duration,
    bool shadowBan = false,
  }) async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return false;
    }

    final token = await _authToken;
    if (token == null) {
      Logger.i('No auth token available');
      return false;
    }

    try {
      final body = <String, dynamic>{
        'action': action,
        'target_user_id': targetUserId,
        'client_type': _clientType,
        'moderator_id': currentUserId,
        'token': token,
        'reason': reason,
      };

      if (severity != null) body['severity'] = severity;
      if (duration != null) body['duration'] = duration;
      if (shadowBan) body['shadow_ban'] = shadowBan;

      final response = await http.post(
        Uri.parse('$baseUrl/moderation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to manage user: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error managing user: $e');
      return false;
    }
  }

  // Map Commentum v2 comment to AnymeX comment model
  Comment _mapCommentumToAnymeXComment(Map<String, dynamic> commentData) {
    // Map user votes from Commentum format to AnymeX format
    final userVotesData = commentData['user_votes'];
    Map<String, dynamic> userVotes = {};
    
    if (userVotesData is String) {
      userVotes = json.decode(userVotesData) as Map<String, dynamic>? ?? {};
    } else if (userVotesData is Map) {
      userVotes = Map<String, dynamic>.from(userVotesData);
    }
    
    final currentUserVote = userVotes[currentUserId] ?? '0';
    
    int userVoteValue = 0;
    if (currentUserVote == 'upvote') userVoteValue = 1;
    else if (currentUserVote == 'downvote') userVoteValue = -1;

    return Comment(
      id: commentData['id'].toString(),
      contentId: int.tryParse(commentData['media_id'].toString()) ?? 0,
      userId: commentData['user_id'].toString(),
      username: commentData['username']?.toString() ?? 'Unknown',
      avatarUrl: commentData['user_avatar']?.toString(),
      commentText: commentData['content']?.toString() ?? '',
      likes: commentData['upvotes'] as int? ?? 0,
      dislikes: commentData['downvotes'] as int? ?? 0,
      userVote: userVoteValue,
      tag: commentData['tags']?.toString() ?? 'General',
      createdAt: commentData['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: commentData['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      deleted: commentData['deleted'] as bool? ?? false,
      parentId: commentData['parent_id'] as int?, // Map parent ID for nested comments
    );
  }

  // Get user role from Commentum system
  Future<String> getUserRole() async {
    if (currentUserId == null) return 'user';
    
    try {
      // Use Commentum v2 API to check user role
      final token = await _authToken;
      if (token == null) return 'user';
      
      // Call Commentum v2 to get user role
      final response = await http.post(
        Uri.parse('$baseUrl/users/role'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'client_type': _clientType,
          'user_id': currentUserId,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final role = data['role'] ?? 'user';
        // Update reactive role
        currentUserRole.value = role;
        return role;
      }
      
      return 'user';
    } catch (e) {
      Logger.i('Error getting user role: $e');
      return 'user';
    }
  }

  // Check if current user is moderator or admin
  Future<bool> isModerator() async {
    final role = await getUserRole();
    return ['moderator', 'admin', 'super_admin'].contains(role);
  }

  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return ['admin', 'super_admin'].contains(role);
  }

  Future<bool> isSuperAdmin() async {
    final role = await getUserRole();
    return role == 'super_admin';
  }
}