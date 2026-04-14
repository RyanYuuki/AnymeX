import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CommentumService extends GetxController {
  String get _baseUrl {
    final envBase = (dotenv.env['COMMENTS_BASE_URL'] ?? '').trim();
    if (envBase.isEmpty) {
      throw StateError('COMMENTS_BASE_URL is missing in .env');
    }
    return envBase.endsWith('/')
        ? envBase.substring(0, envBase.length - 1)
        : envBase;
  }

  final RxString currentUserRole = 'user'.obs;

  Profile? get currentUser => serviceHandler.profileData.value;
  String? get currentUserId => currentUser?.id?.toString();
  String? get currentUsername => currentUser?.name;
  String? get currentUserAvatar => currentUser?.avatar;

  Future<String?> get _authToken async {
    Get.find<AnilistAuth>();
    return AuthKeys.authToken.get<String?>();
  }

  String get _clientType => serviceHandler.serviceType.value.name;

  Future<List<Comment>> fetchComments(String mediaId,
      {int page = 1, int limit = 50, String sort = 'newest'}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/media?media_id=$mediaId&client_type=$_clientType&page=$page&limit=$limit&sort=$sort'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsList = data['comments'] as List<dynamic>? ?? [];

        return commentsList
            .map((commentData) => _mapCommentumToAnymeXComment(commentData))
            .toList();
      } else {
        Logger.i('Failed to fetch comments: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      Logger.i('Error fetching comments: $e');
      return [];
    }
  }

  Future<Comment?> createComment({
    required String mediaId,
    required Media media,
    required String tag,
    required String content,
    int? parentId,
  }) async {
    if (currentUserId == null) {
      Logger.i('User not logged in');
      return null;
    }

    try {
      int? parseYear(dynamic airedValue) {
        if (airedValue == null) return 2069;

        final airedStr = airedValue.toString();

        final year = int.tryParse(airedStr);
        if (year != null) return year;

        if (airedStr.contains('-')) {
          final yearStr = airedStr.split('-')[0];
          return int.tryParse(yearStr);
        }

        return 2069;
      }

      final requestBody = {
        'action': 'create',
        'client_type': _clientType,
        'content': content,
        'user_info': {
          "user_id": currentUserId,
          "username": currentUsername,
          if (currentUserAvatar != null) "avatar": currentUserAvatar,
        },
        'media_info': {
          "media_id": mediaId,
          "type": serviceHandler.serviceType.value.isSimkl
              ? media.id.split('*').last
              : media.mediaType.name,
          "title": media.title,
          "year": parseYear(media.aired),
          "poster": media.poster,
        },
        'tag': tag,
        if (parentId != null) 'parent_id': parentId,
      };

      Logger.i('Creating comment with body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      Logger.i('Comment creation response status: ${response.statusCode}');
      Logger.i('Comment creation response status: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        Logger.i('Comment creation response data: ${json.encode(data)}');
        final commentData = data['comment'];
        return _mapCommentumToAnymeXComment(commentData);
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to create comment: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error creating comment: $e');
      return null;
    }
  }

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
        Uri.parse('$_baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'edit',
          'comment_id': commentId,
          'client_type': _clientType,
          'user_info': {
            "user_id": currentUserId,
            "username": currentUsername,
            if (currentUserAvatar != null) "avatar": currentUserAvatar,
          },
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
        Logger.i(
            'Failed to edit comment: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error editing comment: $e');
      return null;
    }
  }

  Future<bool> deleteComment({
    required int commentId,
    String? userId,
  }) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      Logger.i('User not logged in');
      return false;
    }

    final isModDelete = userId != null && userId != currentUserId;
    final token = isModDelete ? await _authToken : null;

    if (isModDelete && token == null) {
      Logger.i('Admin token required for deleting others\' comments');
      return false;
    }

    try {
      Map<String, dynamic> body;
      if (isModDelete) {
        body = {
          'action': 'mod_delete',
          'comment_id': commentId,
          'client_type': _clientType,
          'access_token': token,
        };
      } else {
        body = {
          'action': 'delete',
          'comment_id': commentId,
          'user_info': {
            "user_id": targetUserId,
            "username": currentUsername,
            "avatar": currentUserAvatar,
          },
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to delete comment: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error deleting comment: $e');
      return false;
    }
  }

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
        Uri.parse('$_baseUrl/votes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'comment_id': commentId,
          'user_info': {
            "user_id": currentUserId,
          },
          'vote_type': voteType,
        }),
      );

      print('Response of upvote: ${response.body}');
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
        Logger.i(
            'Failed to vote on comment: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error voting on comment: $e');
      return null;
    }
  }

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
        Uri.parse('$_baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'create',
          'comment_id': commentId,
          'reporter_info': {
            'user_id': currentUserId,
          },
          'reason': reason,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to report comment: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error reporting comment: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReportsQueue() async {
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
        Uri.parse('$_baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'get_queue',
          'client_type': _clientType,
          'access_token': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['reports'] ?? []);
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to get reports queue: ${error['error'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      Logger.i('Error getting reports queue: $e');
      return [];
    }
  }

  Future<bool> resolveReport({
    required int commentId,
    required String reporterId,
    required String resolution,
    String? reviewNotes,
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
        Uri.parse('$_baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'resolve',
          'comment_id': commentId,
          'reporter_info': {'user_id': reporterId},
          'client_type': _clientType,
          'access_token': token,
          'resolution': resolution,
          'review_notes': reviewNotes,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to resolve report: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error resolving report: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserInfo({
    required String targetUserId,
    String? targetClientType,
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
      final body = <String, dynamic>{
        'action': 'get_user_info',
        'target_user_id': targetUserId,
        'client_type': _clientType,
        'access_token': token,
      };
      if (targetClientType != null) {
        body['target_client_type'] = targetClientType;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to get user info: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error getting user info: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserHistory({
    required String targetUserId,
    String? targetClientType,
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
      final body = <String, dynamic>{
        'action': 'get_user_history',
        'target_user_id': targetUserId,
        'client_type': _clientType,
        'access_token': token,
      };
      if (targetClientType != null) {
        body['target_client_type'] = targetClientType;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to get user history: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error getting user history: $e');
      return null;
    }
  }

  Future<bool> moderateComment({
    required String action,
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
        Uri.parse('$_baseUrl/moderation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': action,
          'comment_id': commentId,
          'client_type': _clientType,
          'access_token': token,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to moderate comment: ${error['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      Logger.i('Error moderating comment: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserStats({
    String? targetClientType,
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
      final body = <String, dynamic>{
        'action': 'get_user_stats',
        'client_type': _clientType,
        'access_token': token,
      };
      if (targetClientType != null) {
        body['target_client_type'] = targetClientType;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to get user stats: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error getting user stats: $e');
      return null;
    }
  }

  Future<bool> manageUser({
    required String action,
    required String targetUserId,
    required String reason,
    String? severity,
    int? duration,
    bool shadowBan = false,
    String? targetClientType,
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
        'access_token': token,
        'reason': reason,
      };

      if (targetClientType != null) {
        body['target_client_type'] = targetClientType;
      } else {
        body['target_client_type'] = _clientType;
      }
      if (severity != null) body['severity'] = severity;
      if (duration != null) body['duration'] = duration;
      if (shadowBan) body['shadow_ban'] = shadowBan;

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
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

  Comment _mapCommentumToAnymeXComment(Map<String, dynamic> commentData) {
    final userVotesData = commentData['user_votes'];
    Map<String, dynamic> userVotes = {};

    if (userVotesData is String) {
      try {
        userVotes = json.decode(userVotesData) as Map<String, dynamic>? ?? {};
      } catch (_) {
        userVotes = {};
      }
    } else if (userVotesData is Map) {
      userVotes = Map<String, dynamic>.from(userVotesData);
    }

    final currentUserVote = userVotes[currentUserId] ?? '0';

    int userVoteValue = 0;
    if (currentUserVote == 'upvote') {
      userVoteValue = 1;
    } else if (currentUserVote == 'downvote') {
      userVoteValue = -1;
    }

    // Parse tags from JSON array or string
    String tagValue = 'General';
    final tagsData = commentData['tags'];
    if (tagsData is List && tagsData.isNotEmpty) {
      tagValue = tagsData.first.toString();
    } else if (tagsData is String && tagsData.isNotEmpty) {
      try {
        final parsed = json.decode(tagsData);
        if (parsed is List && parsed.isNotEmpty) {
          tagValue = parsed.first.toString();
        } else {
          tagValue = tagsData;
        }
      } catch (_) {
        tagValue = tagsData;
      }
    }

    // Parse nested replies from API
    List<Comment>? replies;
    final repliesData = commentData['replies'];
    if (repliesData is List && repliesData.isNotEmpty) {
      replies = repliesData
          .map((r) => _mapCommentumToAnymeXComment(r as Map<String, dynamic>))
          .toList();
    }

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
      tag: tagValue,
      createdAt: commentData['created_at']?.toString() ??
          DateTime.now().toIso8601String(),
      updatedAt: commentData['updated_at']?.toString() ??
          DateTime.now().toIso8601String(),
      deleted: commentData['deleted'] as bool? ?? false,
      parentId: commentData['parent_id'] as int?,
      pinned: commentData['pinned'] as bool?,
      locked: commentData['locked'] as bool?,
      edited: commentData['edited'] as bool?,
      editCount: commentData['edit_count'] as int?,
      moderated: commentData['moderated'] as bool?,
      moderatedBy: commentData['moderated_by']?.toString(),
      moderationReason: commentData['moderation_reason']?.toString(),
      moderationAction: commentData['moderation_action']?.toString(),
      reported: commentData['reported'] as bool?,
      reportCount: commentData['report_count'] as int?,
      reportStatus: commentData['report_status']?.toString(),
      userRole: commentData['user_role']?.toString(),
      replies: replies,
    );
  }

  Future<String> getUserRole() async {
    if (currentUserId == null) return 'user';

    try {
      final token = await _authToken;
      if (token == null) return 'user';

      // Use get_user_info with our own ID — the response includes moderator.role
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'get_user_info',
          'target_user_id': currentUserId,
          'client_type': _clientType,
          'access_token': token,
        }),
      );

      Logger.i('getUserRole response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The backend returns moderator.role even if user has no admin rights,
        // but only when the user IS a moderator/admin.
        // For non-mod users, the endpoint returns 401 (insufficient permissions).
        final role = data['moderator']?['role'];
        if (role != null) {
          currentUserRole.value = role;
          return role;
        }
      }

      // If we get 401 or no role, user is a regular user
      currentUserRole.value = 'user';
      return 'user';
    } catch (e) {
      Logger.i('Error getting user role: $e');
      currentUserRole.value = 'user';
      return 'user';
    }
  }

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
        Uri.parse('$_baseUrl/moderation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'get_queue',
          'client_type': _clientType,
          'access_token': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['comments'] ?? []);
      } else {
        final error = json.decode(response.body);
        Logger.i(
            'Failed to get moderation queue: ${error['error'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      Logger.i('Error getting moderation queue: $e');
      return [];
    }
  }
}
