import 'package:anymex/models/Media/media.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/logger.dart' as d;
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';

import 'model/comment.dart';

class CommentsDatabase {
  final commentumService = Get.find<CommentumService>();

  void log(String msg) => d.Logger.i("[CommentsDatabase] $msg");

  Future<List<Comment>> fetchComments(String mediaId) async {
    try {
      log("Fetching comments for media: $mediaId");
      final comments = await commentumService.fetchComments(mediaId);
      log("Fetched ${comments.length} comments");

      final organizedComments = _organizeComments(comments);
      log("Organized into ${organizedComments.length} top-level comments with replies");

      return organizedComments;
    } catch (e) {
      log("Error fetching comments: $e");
      snackBar('Error fetching comments');
      return [];
    }
  }

  List<Comment> _organizeComments(List<Comment> comments) {
    log("Organizing ${comments.length} comments");

    final Map<int, Comment> commentMap = {};
    final List<Comment> parentComments = [];
    int replyCount = 0;

    for (final comment in comments) {
      final commentId = int.tryParse(comment.id) ?? 0;
      commentMap[commentId] = comment;
      log("Comment ${comment.id} (ID: $commentId) - parentId: ${comment.parentId}, text: ${comment.commentText.substring(0, comment.commentText.length > 30 ? 30 : comment.commentText.length)}");
    }

    for (final comment in comments) {
      final parentId = comment.parentId;
      if (parentId == null || parentId == 0) {
        parentComments.add(comment);
        log("Added parent comment: ${comment.id}");
      } else {
        final parent = commentMap[parentId];
        if (parent != null) {
          parent.replies ??= [];
          parent.replies!.add(comment);
          replyCount++;
          log("Added reply ${comment.id} to parent ${parentId} (parent now has ${parent.replies!.length} replies)");
        } else {
          parentComments.add(comment);
          log("Parent $parentId not found for comment ${comment.id}, treating as parent comment");
        }
      }
    }

    parentComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final parent in parentComments) {
      if (parent.replies != null) {
        parent.replies!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        log("Parent ${parent.id} has ${parent.replies!.length} replies after sorting");
      }
    }

    log("Organized into ${parentComments.length} parent comments with $replyCount total replies");
    return parentComments;
  }

  Future<Comment?> addComment({
    required String comment,
    required Media media,
    required String mediaId,
    required String tag,
    int? parentId,
  }) async {
    try {
      log("Adding comment to media: $mediaId${parentId != null ? ' as reply to $parentId' : ''}");
      final newComment = await commentumService.createComment(
        mediaId: mediaId,
        media: media,
        content: comment,
        tag: tag,
        parentId: parentId,
      );

      if (newComment != null) {
        log('Comment added successfully: ${newComment.id}, parentId: ${newComment.parentId}');
      } else {
        log('Failed to add comment - API returned null');
      }

      return newComment;
    } catch (e) {
      log("Error adding comment: $e");
      snackBar('Error adding comment');
      return null;
    }
  }

  Future<Map<String, dynamic>?> likeOrDislikeComment(
      int commentId, int currentVote, int newVote) async {
    try {
      log("Voting on comment: $commentId, current: $currentVote, new: $newVote");

      String voteType;
      if (newVote == 0) {
        voteType = 'remove';
      } else if (newVote == 1) {
        voteType = 'upvote';
      } else if (newVote == -1) {
        voteType = 'downvote';
      } else {
        return null;
      }

      final result = await commentumService.voteComment(
        commentId: commentId,
        voteType: voteType,
      );

      if (result != null) {
        log("Vote updated successfully: $result");
        return {
          'likes': result['upvotes'],
          'dislikes': result['downvotes'],
          'userVote': result['userVote'] == 'upvote'
              ? 1
              : result['userVote'] == 'downvote'
                  ? -1
                  : 0,
        };
      } else {
        log('Failed to update vote');
        return null;
      }
    } catch (e) {
      log("Error updating vote: $e");
      snackBar('Error updating vote');
      return null;
    }
  }

  Future<Comment?> editComment(int commentId, String newContent) async {
    try {
      log("Editing comment: $commentId");
      final updatedComment = await commentumService.editComment(
        commentId: commentId,
        content: newContent,
      );

      if (updatedComment != null) {
        log('Comment edited successfully');
      } else {
        log('Failed to edit comment');
      }

      return updatedComment;
    } catch (e) {
      log("Error editing comment: $e");
      snackBar('Error editing comment');
      return null;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    try {
      log("Deleting comment: $commentId");
      final success =
          await commentumService.deleteComment(commentId: commentId);

      if (success) {
        log('Comment deleted successfully');
      } else {
        log('Failed to delete comment');
      }

      return success;
    } catch (e) {
      log("Error deleting comment: $e");
      snackBar('Error deleting comment');
      return false;
    }
  }

  Future<bool> reportComment(int commentId, String reason,
      {String? notes}) async {
    try {
      log("Reporting comment: $commentId, reason: $reason");
      final success = await commentumService.reportComment(
        commentId: commentId,
        reason: reason,
        notes: notes,
      );

      if (success) {
        log('Comment reported successfully');
        snackBar('Comment reported successfully');
      } else {
        log('Failed to report comment');
        snackBar('Failed to report comment');
      }

      return success;
    } catch (e) {
      log("Error reporting comment: $e");
      snackBar('Error reporting comment');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getModerationQueue() async {
    try {
      log("Fetching moderation queue");
      final queue = await commentumService.getModerationQueue();
      log("Fetched ${queue.length} items in moderation queue");
      return queue;
    } catch (e) {
      log("Error fetching moderation queue: $e");
      snackBar('Error fetching moderation queue');
      return [];
    }
  }

  Future<bool> moderateComment({
    required String action,
    required int commentId,
    required String reason,
  }) async {
    try {
      log("Moderating comment: $commentId, action: $action");
      final success = await commentumService.moderateComment(
        action: action,
        commentId: commentId,
        reason: reason,
      );

      if (success) {
        log('Comment moderated successfully');
        snackBar('Comment moderated successfully');
      } else {
        log('Failed to moderate comment');
        snackBar('Failed to moderate comment');
      }

      return success;
    } catch (e) {
      log("Error moderating comment: $e");
      snackBar('Error moderating comment');
      return false;
    }
  }

  Future<bool> manageUser({
    required String action,
    required String targetUserId,
    required String reason,
    String? severity,
    int? duration,
    bool shadowBan = false,
  }) async {
    try {
      log("Managing user: $targetUserId, action: $action");
      final success = await commentumService.manageUser(
        action: action,
        targetUserId: targetUserId,
        reason: reason,
        severity: severity,
        duration: duration,
        shadowBan: shadowBan,
      );

      if (success) {
        log('User managed successfully');
        snackBar('User managed successfully');
      } else {
        log('Failed to manage user');
        snackBar('Failed to manage user');
      }

      return success;
    } catch (e) {
      log("Error managing user: $e");
      snackBar('Error managing user');
      return false;
    }
  }

  bool get isLoggedIn => commentumService.currentUserId != null;

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    if (!isLoggedIn) return null;

    return {
      'id': commentumService.currentUserId,
      'username': commentumService.currentUsername,
      'avatar_url': commentumService.currentUserAvatar,
    };
  }

  Future<void> login() async {
    log("Using AnymeX authentication for Commentum v2");
  }

  Future<void> logout() async {
    log("Using AnymeX authentication for Commentum v2");
  }

  Future<void> syncUserDataWithAniList() async {
    log("User data sync handled by Commentum v2 API");
  }
}
