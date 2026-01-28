import 'dart:async';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments_db.dart';
import 'package:anymex/database/model/comment.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CommentSectionController extends GetxController
    with GetTickerProviderStateMixin {
  final Media media;

  CommentSectionController({required this.media});

  final profile = serviceHandler.onlineService.profileData.value;
  final commentsDB = CommentsDatabase();
  final commentumService = Get.find<CommentumService>();

  bool get isLoggedIn => serviceHandler.onlineService.isLoggedIn.value;

  final TextEditingController commentController = TextEditingController();
  final Rx<TextEditingController> tagController =
      Rx(TextEditingController(text: 'Episode 1'));
  final Rx<String> tag = ''.obs;
  final Rx<String> commentContent = ''.obs;
  final FocusNode commentFocusNode = FocusNode();

  final RxList<Comment> comments = <Comment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isInputExpanded = false.obs;
  final RxBool isRefreshing = false.obs;

  final RxSet<String> votingComments = <String>{}.obs;

  final RxBool isModerator = false.obs;
  final RxBool isAdmin = false.obs;
  final RxBool isSuperAdmin = false.obs;
  final RxString currentUserRole = 'user'.obs;

  late AnimationController expandController;
  late AnimationController fadeController;

  @override
  void onInit() {
    super.onInit();
    tag.value = tagController.value.text;
    tagController.value.addListener(() {
      tag.value = tagController.value.text;
    });
    commentController.addListener(() {
      commentContent.value = commentController.text;
    });
    _initializeAnimations();
    _setupFocusListener();
    _checkUserRole();
    loadComments();
  }

  @override
  void onClose() {
    expandController.dispose();
    fadeController.dispose();
    commentController.dispose();
    commentFocusNode.dispose();
    super.onClose();
  }

  void _initializeAnimations() {
    expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _setupFocusListener() {
    commentFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (commentFocusNode.hasFocus && !isInputExpanded.value) {
      isInputExpanded.value = true;
      expandController.forward();
      fadeController.forward();
    }
  }

  Future<void> _checkUserRole() async {
    try {
      print('Checking user role for Commentum v2...');
      isModerator.value = await commentumService.isModerator();
      isAdmin.value = await commentumService.isAdmin();
      isSuperAdmin.value = await commentumService.isSuperAdmin();

      if (isSuperAdmin.value) {
        currentUserRole.value = 'super_admin';
      } else if (isAdmin.value) {
        currentUserRole.value = 'admin';
      } else if (isModerator.value) {
        currentUserRole.value = 'moderator';
      } else {
        currentUserRole.value = 'user';
      }

      print('User role checked: ${currentUserRole.value}');
    } catch (e) {
      print('Error checking user role: $e');
      currentUserRole.value = 'user';
    }
  }

  Future<void> loadComments() async {
    if (media.uniqueId.isEmpty) return;

    isLoading.value = true;
    try {
      final fetchedComments = await commentsDB.fetchComments(media.uniqueId);
      comments.assignAll(fetchedComments);
      print(
          'Loaded ${fetchedComments.length} comments for media: $media.uniqueId');
    } catch (e) {
      print('Error loading comments: $e');
      snackBar('Failed to load comments. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshComments({bool silent = false}) async {
    if (media.uniqueId.isEmpty) return;

    if (!silent) {
      isRefreshing.value = true;
    }

    try {
      await _checkUserRole();

      final fetchedComments = await commentsDB.fetchComments(media.uniqueId);

      comments.assignAll(fetchedComments);

      if (!silent) {
        final commentCount = fetchedComments.length;
        snackBar('$commentCount comments loaded');
      }
      print(
          'Refreshed ${fetchedComments.length} comments for media: $media.uniqueId');
    } catch (e) {
      print('Error refreshing comments: $e');
      if (!silent) {
        snackBar('Failed to refresh comments. Please try again.');
      }
    } finally {
      if (!silent) {
        isRefreshing.value = false;
      }
    }
  }

  Future<void> backgroundRefresh() async {
    if (media.uniqueId.isEmpty) return;

    try {
      final fetchedComments = await commentsDB.fetchComments(media.uniqueId);
      comments.assignAll(fetchedComments);
      print('Background refreshed ${fetchedComments.length} comments');
    } catch (e) {
      print('Error in background refresh: $e');
    }
  }

  Future<void> forceRefresh() async {
    await _checkUserRole();
    await refreshComments(silent: false);
  }

  // Future<void> addReply(Comment parentComment, String replyContent) async {
  //   if (replyContent.trim().isEmpty || isSubmitting.value) return;

  //   isSubmitting.value = true;
  //   try {
  //     final parentCommentId = int.tryParse(parentComment.id) ?? 0;
  //     if (parentCommentId == 0) {
  //       snackBar( 'Invalid parent comment ID');
  //       return;
  //     }

  //     final newComment = await commentsDB.addComment(
  //       comment: replyContent.trim(),
  //       mediaId: media.uniqueId,
  //       tag: tag ?? 'General',
  //       parentId: parentCommentId,
  //     );

  //     if (newComment != null) {
  //       await backgroundRefresh();
  //       snackBar(', 'Your reply has been posted successfully');
  //     }

  //     HapticFeedback.lightImpact();
  //   } catch (e) {
  //     snackBar( 'Failed to post reply. Please try again.');
  //   } finally {
  //     isSubmitting.value = false;
  //   }
  // }

  Future<void> addComment() async {
    if (commentController.text.trim().isEmpty || isSubmitting.value) return;

    isSubmitting.value = true;
    try {
      final newComment = await commentsDB.addComment(
        comment: commentController.text.trim(),
        mediaId: media.uniqueId,
        media: media,
        tag: tagController.value.text.trim(),
      );

      if (newComment != null) {
        await backgroundRefresh();
        snackBar('Comment posted successfully');
      }

      HapticFeedback.lightImpact();
      clearInputs();
    } catch (e) {
      snackBar('Failed to add comment. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearInputs() {
    commentController.clear();
    isInputExpanded.value = false;
    expandController.reverse();
    fadeController.reverse();
    commentFocusNode.unfocus();
  }

  Future<void> handleVote(Comment comment, int newVote) async {
    if (votingComments.contains(comment.id)) {
      return;
    }

    if (comment.userVote == newVote) {
      newVote = 0;
    }

    HapticFeedback.selectionClick();

    votingComments.add(comment.id);

    final index = comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) {
      votingComments.remove(comment.id);
      return;
    }

    final originalLikes = comment.likes;
    final originalDislikes = comment.dislikes;
    final originalUserVote = comment.userVote;

    final updatedComment = _createUpdatedComment(comment, newVote);
    comments[index] = updatedComment;

    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        throw Exception("Invalid comment ID: ${comment.id}");
      }

      final result = await commentsDB.likeOrDislikeComment(
          commentId, originalUserVote, newVote);

      if (result == null) {
        comment.likes = originalLikes;
        comment.dislikes = originalDislikes;
        comment.userVote = originalUserVote;
        comments[index] = comment;
        snackBar('Failed to update vote. Please try again.');
      } else {
        await backgroundRefresh();
      }
    } catch (e) {
      comment.likes = originalLikes;
      comment.dislikes = originalDislikes;
      comment.userVote = originalUserVote;
      comments[index] = comment;
      snackBar('Failed to update vote. Please try again.');
    } finally {
      votingComments.remove(comment.id);
    }
  }

  Comment _createUpdatedComment(Comment original, int newVote) {
    int newLikes = original.likes;
    int newDislikes = original.dislikes;

    if (original.userVote == 1) {
      newLikes--;
    } else if (original.userVote == -1) {
      newDislikes--;
    }

    if (newVote == 1) {
      newLikes++;
    } else if (newVote == -1) {
      newDislikes++;
    }

    newLikes = newLikes < 0 ? 0 : newLikes;
    newDislikes = newDislikes < 0 ? 0 : newDislikes;

    return Comment(
      id: original.id,
      userId: original.userId,
      commentText: original.commentText,
      contentId: original.contentId,
      tag: original.tag,
      likes: newLikes,
      dislikes: newDislikes,
      userVote: newVote,
      username: original.username,
      avatarUrl: original.avatarUrl,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
      deleted: original.deleted,
      pinned: original.pinned,
      locked: original.locked,
      edited: original.edited,
      editCount: original.editCount,
      editHistory: original.editHistory,
      reported: original.reported,
      reportCount: original.reportCount,
      reportStatus: original.reportStatus,
      userBanned: original.userBanned,
      userMutedUntil: original.userMutedUntil,
      userShadowBanned: original.userShadowBanned,
      userWarnings: original.userWarnings,
      moderatedBy: original.moderatedBy,
      moderationReason: original.moderationReason,
      parentId: original.parentId,
      replies: original.replies,
    );
  }

  Future<void> editComment(Comment comment, String newContent) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        snackBar('Invalid comment ID');
        return;
      }

      final updatedComment =
          await commentsDB.editComment(commentId, newContent);

      if (updatedComment != null) {
        await backgroundRefresh();
        snackBar('Comment edited successfully');
      } else {
        snackBar('Failed to edit comment');
      }
    } catch (e) {
      snackBar('Failed to edit comment');
    }
  }

  Future<void> deleteComment(Comment comment) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        snackBar('Invalid comment ID');
        return;
      }

      final success = await commentsDB.deleteComment(commentId);

      if (success) {
        await backgroundRefresh();
        snackBar('Comment deleted successfully');
      } else {
        snackBar('Failed to delete comment');
      }
    } catch (e) {
      snackBar('Failed to delete comment');
    }
  }

  Future<void> reportComment(Comment comment, String reason,
      {String? notes}) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        snackBar('Invalid comment ID');
        return;
      }

      final success =
          await commentsDB.reportComment(commentId, reason, notes: notes);

      if (success) {
        final index = comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          comments[index] = comments[index].copyWith(
            reported: true,
            reportCount: (comments[index].reportCount ?? 0) + 1,
          );
        }
      }
    } catch (e) {
      snackBar('Failed to report comment');
    }
  }

  Future<void> moderateComment({
    required Comment comment,
    required String action,
    required String reason,
  }) async {
    try {
      final commentId = int.tryParse(comment.id) ?? 0;
      if (commentId == 0) {
        snackBar('Invalid comment ID');
        return;
      }

      final success = await commentsDB.moderateComment(
        action: action,
        commentId: commentId,
        reason: reason,
      );

      if (success) {
        await loadComments();
      }
    } catch (e) {
      snackBar('Failed to moderate comment');
    }
  }

  Future<void> manageUser({
    required String targetUserId,
    required String action,
    required String reason,
    String? severity,
    int? duration,
    bool shadowBan = false,
  }) async {
    try {
      final success = await commentsDB.manageUser(
        action: action,
        targetUserId: targetUserId,
        reason: reason,
        severity: severity,
        duration: duration,
        shadowBan: shadowBan,
      );

      if (success) {
        await loadComments();
      }
    } catch (e) {
      snackBar('Failed to manage user');
    }
  }

  bool canEditComment(Comment comment) {
    return comment.userId == profile.id?.toString();
  }

  bool canDeleteComment(Comment comment) {
    if (comment.userId == profile.id?.toString()) {
      return true;
    }
    return isModerator.value || isAdmin.value;
  }

  bool canModerate() {
    return isModerator.value || isAdmin.value;
  }

  bool canManageUsers() {
    return isAdmin.value;
  }

  void onMediaChanged(Media newMedia, TrackedMedia trackedMedia) {
    if (newMedia.uniqueId != media.uniqueId) {
      comments.clear();
      votingComments.clear();

      loadComments();

      print('Media changed to: ${newMedia.uniqueId}, refreshing comments');
    }
  }

  void onUserAuthChanged() {
    _checkUserRole();
    refreshComments(silent: false);
  }
}
