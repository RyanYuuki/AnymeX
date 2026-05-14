import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/database/comments/model/user_points.dart';
import 'package:anymex/database/comments/model/leaderboard_entry.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/notification.dart';
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
  final RxInt unreadNotificationCount = 0.obs;
  final Set<String> _registeredClientTypes = {};
  String? _pendingFcmToken;

  Profile? get currentUser => serviceHandler.profileData.value;
  String? get currentUserId => currentUser?.id?.toString();
  String? get currentUsername => currentUser?.name;
  String? get currentUserAvatar => currentUser?.avatar;

  @override
  void onInit() {
    super.onInit();
    ever(serviceHandler.serviceType, (_) => _tryRegisterFcm());
    ever(serviceHandler.profileData, (_) {
      _tryRegisterFcm();
      refreshUnreadCount();
    });
    Future.delayed(const Duration(seconds: 3), () {
      _tryRegisterFcm();
      refreshUnreadCount();
    });
  }

  Future<void> _tryRegisterFcm() async {
    final clientType = _clientType;
    final userId = currentUserId;
    if (userId == null) return;
    if (_registeredClientTypes.contains(clientType)) return;
    if (!Get.isRegistered<NotificationService>()) return;

    final ns = Get.find<NotificationService>();
    final token = ns.getToken();
    if (token == null) return;

    final success = await registerFcmToken(token);
    if (success) {
      _registeredClientTypes.add(clientType);
      _pendingFcmToken = token;
    }
  }

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
          'access_token': token,
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
    required String voteType,
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
            "username": currentUsername,
            if (currentUserAvatar != null) "avatar": currentUserAvatar,
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

  Future<Map<String, dynamic>?> listUsers({
    String? targetClientType,
    String? role,
    bool? banned,
    bool? muted,
    bool? shadowBanned,
    int page = 1,
    int limit = 50,
  }) async {
    if (currentUserId == null) return null;
    final token = await _authToken;
    if (token == null) return null;

    try {
      final body = <String, dynamic>{
        'action': 'list_users',
        'client_type': _clientType,
        'access_token': token,
        'page': page,
        'limit': limit,
      };
      if (targetClientType != null) body['target_client_type'] = targetClientType;
      if (role != null) body['role'] = role;
      if (banned != null) body['banned'] = banned;
      if (muted != null) body['muted'] = muted;
      if (shadowBanned != null) body['shadow_banned'] = shadowBanned;

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to list users: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error listing users: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> searchUsers({
    required String username,
    String? targetClientType,
  }) async {
    if (currentUserId == null) return null;
    final token = await _authToken;
    if (token == null) return null;

    try {
      final body = <String, dynamic>{
        'action': 'search_users',
        'client_type': _clientType,
        'access_token': token,
        'username': username.trim(),
      };
      if (targetClientType != null) body['target_client_type'] = targetClientType;

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to search users: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error searching users: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsersPublic({
    required String username,
  }) async {
    if (currentUserId == null) return [];
    final token = await _authToken;
    if (token == null) return [];

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode({
          'action': 'search_users_public',
          'client_type': _clientType,
          'access_token': token,
          'username': username.trim(),
          'target_client_type': _clientType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['users'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      Logger.i('Error searching users publicly: $e');
      return [];
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

  /// Alias for manageUser — used by user_management_page for warn/mute actions
  Future<bool> moderateUser({
    required String action,
    required String targetUserId,
    required String reason,
    int? duration,
    bool shadowBan = false,
  }) async {
    return await manageUser(
      action: action,
      targetUserId: targetUserId,
      reason: reason,
      duration: duration,
      shadowBan: shadowBan,
    );
  }

  /// Promote user role — admin+ only
  Future<bool> promoteUser({
    required String targetUserId,
    required String newRole,
    required String reason,
  }) async {
    return await manageUser(
      action: 'promote_user',
      targetUserId: targetUserId,
      reason: reason,
    );
  }

  /// Demote user role — admin+ only
  Future<bool> demoteUser({
    required String targetUserId,
    required String newRole,
    required String reason,
  }) async {
    return await manageUser(
      action: 'demote_user',
      targetUserId: targetUserId,
      reason: reason,
    );
  }

  Future<UserPoints?> getUserPoints({
    required String targetUserId,
    String? targetClientType,
  }) async {
    try {
      final effectiveClientType = targetClientType ?? _clientType;
      final body = <String, dynamic>{
        'action': 'get_user_points',
        'target_user_id': targetUserId,
        'target_client_type': effectiveClientType,
        // Send requester info so backend can determine privacy level
        if (currentUserId != null) 'requester_user_id': currentUserId,
        if (currentUserId != null) 'requester_client_type': _clientType,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/points'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend wraps in { success: true, data: {...} }
        final pointsData = data['data'] as Map? ?? data;
        return UserPoints.fromMap(pointsData);
      } else {
        final error = json.decode(response.body);
        Logger.i('Failed to get user points: ${error['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.i('Error getting user points: $e');
      return null;
    }
  }

  Future<Map<String, UserPoints>> getBatchUserPoints({
    required List<String> userIds,
    String? targetClientType,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'get_batch_user_points',
        'user_ids': userIds,
        'client_type': targetClientType ?? _clientType,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/points'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pointsMap = <String, UserPoints>{};
        // Backend returns { success: true, users: {...} }
        final entries = data['users'] as Map? ?? {};
        entries.forEach((key, value) {
          pointsMap[key.toString()] = UserPoints.fromMap(value as Map);
        });
        return pointsMap;
      } else {
        Logger.i('Failed to get batch user points');
        return {};
      }
    } catch (e) {
      Logger.i('Error getting batch user points: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getLeaderboard({
    String? targetClientType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'get_leaderboard',
        'target_client_type': targetClientType ?? _clientType,
        'page': page,
        'limit': limit,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/points'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final entries = (data['leaderboard'] as List? ?? [])
            .asMap()
            .entries
            .map((entry) {
          return LeaderboardEntry.fromMap(
            entry.value as Map,
            rank: entry.key + 1 + ((page - 1) * limit),
          );
        }).toList();
        final pagination = data['pagination'] as Map<String, dynamic>?;
        return {
          'entries': entries,
          'pagination': pagination,
        };
      } else {
        Logger.i('Failed to get leaderboard');
        return {'entries': <LeaderboardEntry>[], 'pagination': null};
      }
    } catch (e) {
      Logger.i('Error getting leaderboard: $e');
      return {'entries': <LeaderboardEntry>[], 'pagination': null};
    }
  }

  Future<Map<String, dynamic>?> getPointsConfig({
    String? targetClientType,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': 'get_points_config',
        'client_type': targetClientType ?? _clientType,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/points'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        Logger.i('Failed to get points config');
        return null;
      }
    } catch (e) {
      Logger.i('Error getting points config: $e');
      return null;
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
      userTier: commentData['user_tier']?.toString(),
      userPoints: commentData['user_points'] as int?,
      replies: replies,
    );
  }

  Future<String> getUserRole() async {
    if (currentUserId == null) return 'user';

    try {
      final token = await _authToken;
      if (token == null) return 'user';

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
        final role = data['moderator']?['role'];
        if (role != null) {
          currentUserRole.value = role;
          return role;
        }
      }

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
    return ['moderator', 'admin', 'super_admin', 'owner'].contains(role);
  }

  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return ['admin', 'super_admin', 'owner'].contains(role);
  }

  Future<bool> isSuperAdmin() async {
    final role = await getUserRole();
    return ['super_admin', 'owner'].contains(role);
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

  Future<bool> registerFcmToken(String fcmToken) async {
    if (currentUserId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode({
          'action': 'register_token',
          'client_type': _clientType,
          'user_id': currentUserId,
          'fcm_token': fcmToken,
          'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'other',
          'app_version': '3.0.7',
        }),
      );

      if (response.statusCode == 200) {
        Logger.i('FCM token registered successfully');
        return true;
      }
      Logger.i('Failed to register FCM token: ${response.body}');
      return false;
    } catch (e) {
      Logger.i('Error registering FCM token: $e');
      return false;
    }
  }

  Future<bool> unregisterFcmToken(String fcmToken) async {
    if (currentUserId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode({
          'action': 'unregister_token',
          'client_type': _clientType,
          'user_id': currentUserId,
          'fcm_token': fcmToken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error unregistering FCM token: $e');
      return false;
    }
  }

  Future<Map<String, bool>> getNotificationPreferences() async {
    if (currentUserId == null) return {};

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode({
          'action': 'get_preferences',
          'client_type': _clientType,
          'user_id': currentUserId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, bool>.from(data['preferences'] ?? {});
      }
      return {};
    } catch (e) {
      Logger.i('Error getting notification preferences: $e');
      return {};
    }
  }

  Future<bool> updateNotificationPreferences(Map<String, bool> preferences) async {
    if (currentUserId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: { 'Content-Type': 'application/json' },
        body: json.encode({
          'action': 'update_preferences',
          'client_type': _clientType,
          'user_id': currentUserId,
          'preferences': preferences,
        }),
      );

      if (response.statusCode == 200) {
        Logger.i('Notification preferences updated');
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Error updating notification preferences: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchNotificationHistory({
    int page = 1,
    int limit = 30,
    String? type,
    bool unreadOnly = false,
  }) async {
    if (currentUserId == null) {
      return {'notifications': [], 'total': 0, 'unread_count': 0};
    }

    try {
      final body = <String, dynamic>{
        'action': 'get_history',
        'client_type': _clientType,
        'user_id': currentUserId,
        'page': page,
        'limit': limit,
      };
      if (type != null) body['type'] = type;
      if (unreadOnly) body['unreadOnly'] = true;

      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'notifications':
              (data['notifications'] as List?)?.map((n) => n).toList() ?? [],
          'total': data['total'] ?? 0,
          'unread_count': data['unread_count'] ?? 0,
        };
      }
      return {'notifications': [], 'total': 0, 'unread_count': 0};
    } catch (e) {
      Logger.i('Error fetching notification history: $e');
      return {'notifications': [], 'total': 0, 'unread_count': 0};
    }
  }

  Future<bool> markNotificationRead(int notificationId) async {
    if (currentUserId == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'mark_read',
          'client_type': _clientType,
          'user_id': currentUserId,
          'notification_id': notificationId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsRead({String? type}) async {
    if (currentUserId == null) return false;

    try {
      final body = <String, dynamic>{
        'action': 'mark_all_read',
        'client_type': _clientType,
        'user_id': currentUserId,
      };
      if (type != null) body['type'] = type;

      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<int> getUnreadNotificationCount() async {
    if (currentUserId == null) return 0;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'get_unread_count',
          'client_type': _clientType,
          'user_id': currentUserId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['unread_count'] as int? ?? 0;
        unreadNotificationCount.value = count;
        return count;
      }
      return 0;
    } catch (e) {
      Logger.i('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> refreshUnreadCount() async {
    if (currentUserId == null) {
      unreadNotificationCount.value = 0;
      return;
    }
    final count = await getUnreadNotificationCount();
    unreadNotificationCount.value = count;
  }
}
