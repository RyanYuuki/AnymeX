import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anymex/utils/logger.dart' as d;
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/database/model/comment_new.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class CommentsDatabase {
  static const String baseUrl = 'https://ani-comments.vercel.app/api';
  
  void log(String msg) => d.Logger.i("[CommentsDatabase] $msg");

  // Get AniList token from authenticated user
  Future<String?> _getAuthToken() async {
    try {
      final storage = Hive.box('auth');
      final token = await storage.get('auth_token');
      return token;
    } catch (e) {
      log("Error getting auth token: $e");
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> get isLoggedIn async {
    final token = await _getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // Fetch comments for a media
  Future<List<Comment>> fetchComments(String mediaId, {String mediaType = 'ANIME'}) async {
    try {
      log("Fetching comments for media: $mediaId");
      
      final response = await http.get(
        Uri.parse('$baseUrl/comments?media_id=$mediaId&media_type=$mediaType&limit=50&offset=0'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      log("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final commentsData = data['data'] as List;
          final comments = commentsData.map((json) => Comment.fromJson(json)).toList();
          log("Fetched ${comments.length} comments");
          return comments;
        }
      }
      
      log("Failed to fetch comments: ${response.body}");
      return [];
    } catch (e) {
      log("Error fetching comments: $e");
      return [];
    }
  }

  // Add a new comment
  Future<Comment?> addComment({
    required String content,
    required int mediaId,
    required String mediaType,
    String? parentCommentId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        log("User not authenticated");
        return null;
      }

      log("Adding comment to media: $mediaId");

      final request = CreateCommentRequest(
        mediaId: mediaId,
        mediaType: mediaType,
        content: content,
        parentCommentId: parentCommentId,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 15));

      log("Add comment response status: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final comment = Comment.fromJson(data['data']);
          log("Comment added successfully: ${comment.id}");
          return comment;
        }
      }
      
      log("Failed to add comment: ${response.body}");
      return null;
    } catch (e) {
      log("Error adding comment: $e");
      return null;
    }
  }

  // Vote on a comment (upvote/downvote)
  Future<Map<String, dynamic>?> voteComment({
    required String commentId,
    required int voteType, // 1 for upvote, -1 for downvote
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        log("User not authenticated");
        return null;
      }

      log("Voting on comment: $commentId with type: $voteType");

      final request = VoteRequest(
        commentId: commentId,
        voteType: voteType,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/comments/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 15));

      log("Vote response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          log("Vote successful");
          return data['data'];
        }
      }
      
      log("Failed to vote: ${response.body}");
      return null;
    } catch (e) {
      log("Error voting: $e");
      return null;
    }
  }

  // Delete a comment (soft delete)
  Future<bool> deleteComment(String commentId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        log("User not authenticated");
        return false;
      }

      log("Deleting comment: $commentId");

      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      log("Delete response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          log("Comment deleted successfully");
          return true;
        }
      }
      
      log("Failed to delete comment: ${response.body}");
      return false;
    } catch (e) {
      log("Error deleting comment: $e");
      return false;
    }
  }

  // Get current user info from AniList
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'query': '''
            query {
              Viewer {
                id
                name
                avatar {
                  large
                  medium
                }
                moderatorStatus
              }
            }
          '''
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['Viewer'] != null) {
          return data['data']['Viewer'];
        }
      }
      
      return null;
    } catch (e) {
      log("Error getting user info: $e");
      return null;
    }
  }

  // Run database migration (for setup)
  Future<bool> migrateDatabase() async {
    try {
      log("Running database migration");
      
      final response = await http.post(
        Uri.parse('$baseUrl/db/migrate'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          log("Database migration successful");
          return true;
        }
      }
      
      log("Migration failed: ${response.body}");
      return false;
    } catch (e) {
      log("Error during migration: $e");
      return false;
    }
  }
}