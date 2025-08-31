import 'package:anymex/utils/logger.dart' as d;

// import 'package:anymex/controllers/service_handler/service_handler.dart';
// import 'package:anymex/utils/logger.dart';
// import 'package:anymex/utils/string_extensions.dart';
// import 'package:anymex/widgets/non_widgets/snackbar.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

import 'model/comment.dart';

int hashStringToInt(String str) {
  return str.hashCode.abs();
}

class CommentsDatabase {
  // final supabase = Supabase.instance.client;

  void log(String msg) => d.Logger.i("[CommentsDatabase] $msg");

  Future<void> login() async {
    // if (!serviceHandler.anilistService.isLoggedIn.value) {
    //   snackBar('Login on Anilist First');
    //   return;
    // }

    // final user = serviceHandler.anilistService.profileData.value;

    // try {
    //   final response = await supabase.auth.signInAnonymously();

    //   if (response.user != null) {
    //     final existingUser = await supabase
    //         .from('users')
    //         .select()
    //         .eq('anilist_id', user.id!)
    //         .maybeSingle();

    //     if (existingUser == null) {
    //       final hashedId = hashStringToInt(user.id!);
    //       await supabase.from('users').insert({
    //         'id': hashedId,
    //         'anilist_id': user.id,
    //         'username': user.name,
    //         'avatar_url': user.avatar,
    //       });
    //       log("Created new user with ID: $hashedId");
    //     } else {
    //       await supabase.from('users').update({
    //         'username': user.name,
    //         'avatar_url': user.avatar,
    //       }).eq('anilist_id', user.id!);
    //       log("Updated existing user: ${existingUser['id']}");
    //     }

    //     log("Logged in successfully: ${response.user!.id}");
    //   }
    // } catch (e) {
    //   log("Login failed: $e");
    //   snackBar('Login failed: $e');
    // }
  }

  Future<List<Comment>> fetchComments(String animeId) async {
    // final currentUser = serviceHandler.anilistService.profileData.value;
    // if (currentUser.id == null) {
    //   Logger.i('Please login first');
    //   return [];
    // }

    // try {
    //   final commentsData = await supabase
    //       .from('comments')
    //       .select(
    //           'id, comment, tag, likes_count, dislikes_count, user_id, created_at, updated_at, users!inner(username, avatar_url)')
    //       .eq('media_id', animeId)
    //       .order('created_at', ascending: false)
    //       .limit(20);

    //   if (commentsData.isEmpty) return [];

    //   final commentIds = commentsData.map((c) => c['id']).toList();
    //   final votesData = await supabase
    //       .from('votes')
    //       .select('comment_id, vote_type')
    //       .eq('user_id', hashStringToInt(currentUser.id!))
    //       .inFilter('comment_id', commentIds);

    //   final votesMap = {
    //     for (var v in votesData) v['comment_id']: v['vote_type'] ?? 0
    //   };

    //   return commentsData.map((c) {
    //     return Comment(
    //       id: c['id'].toString(),
    //       userId: currentUser.id!,
    //       commentText: c['comment'],
    //       contentId: animeId.toInt(),
    //       tag: c['tag'],
    //       likes: c['likes_count'] ?? 0,
    //       dislikes: c['dislikes_count'] ?? 0,
    //       userVote: votesMap[c['id']] ?? 0,
    //       username: c['users']['username'],
    //       avatarUrl: c['users']['avatar_url'],
    //       createdAt: c['created_at'],
    //       updatedAt: c['updated_at'],
    //       deleted: false,
    //     );
    //   }).toList();
    // } catch (e) {
    //   log("Error fetching comments: $e");
    //   snackBar('Error fetching comments');
    //   return [];
    // }
    return [];
  }

  Future<Comment?> addComment(
      {required String comment,
      required String mediaId,
      required String tag}) async {
    // final currentUser = serviceHandler.anilistService.profileData.value;
    // if (currentUser.id == null) {
    //   Logger.i('Please login first');
    //   return null;
    // }

    // try {
    //   final cmnt = await supabase
    //       .from('comments')
    //       .insert({
    //         'comment': comment,
    //         'media_id': mediaId,
    //         'tag': tag,
    //         'user_id': hashStringToInt(currentUser.id!),
    //         'likes_count': 0,
    //         'dislikes_count': 0,
    //       })
    //       .select()
    //       .single();

    //   log('Comment added successfully');
    //   return Comment.fromMap(cmnt);
    // } catch (e) {
    //   log("Error adding comment: $e");
    //   Logger.i('Error adding comment');
    // }
    // return null;
  }

  Future<Map<String, dynamic>?> likeOrDislikeComment(
      int commentId, int currentVote, int newVote) async {
    // final currentUser = serviceHandler.anilistService.profileData.value;
    // if (!serviceHandler.anilistService.isLoggedIn.value) {
    //   snackBar('Please login first');
    //   return null;
    // }

    // final userId = hashStringToInt(currentUser.id!);

    // try {
    //   final commentData = await supabase
    //       .from('comments')
    //       .select('likes_count, dislikes_count')
    //       .eq('id', commentId)
    //       .single();

    //   int currentLikesCount = commentData['likes_count'] ?? 0;
    //   int currentDislikesCount = commentData['dislikes_count'] ?? 0;

    //   int newLikesCount = currentLikesCount;
    //   int newDislikesCount = currentDislikesCount;

    //   if (currentVote == 1) {
    //     newLikesCount--;
    //   } else if (currentVote == -1) {
    //     newDislikesCount--;
    //   }

    //   if (newVote == 1) {
    //     newLikesCount++;
    //   } else if (newVote == -1) {
    //     newDislikesCount++;
    //   }

    //   newLikesCount = newLikesCount < 0 ? 0 : newLikesCount;
    //   newDislikesCount = newDislikesCount < 0 ? 0 : newDislikesCount;

    //   if (currentVote == newVote) {
    //     await supabase.from('votes').delete().match({
    //       'user_id': userId,
    //       'comment_id': commentId,
    //     });
    //     log("Vote removed for comment $commentId");
    //   } else {
    //     await supabase.from('votes').upsert({
    //       'user_id': userId,
    //       'comment_id': commentId,
    //       'vote_type': newVote,
    //     });
    //     log("Vote updated for comment $commentId: $newVote");
    //   }

    //   await supabase.from('comments').update({
    //     'likes_count': newLikesCount,
    //     'dislikes_count': newDislikesCount,
    //   }).eq('id', commentId);

    //   log("Comment counts updated: likes=$newLikesCount, dislikes=$newDislikesCount");

    //   return {
    //     'likes': newLikesCount,
    //     'dislikes': newDislikesCount,
    //     'userVote': currentVote == newVote ? 0 : newVote,
    //   };
    // } catch (e) {
    //   log("Error updating vote: $e");
    //   snackBar('Error updating vote');
    //   return null;
    // }
  }

  // bool get isLoggedIn => supabase.auth.currentUser != null;

  Future<void> logout() async {
    // try {
    //   await supabase.auth.signOut();
    //   log("Logged out successfully");
    // } catch (e) {
    //   log("Error logging out: $e");
    // }
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    // final currentUser = supabase.auth.currentUser;
    // if (currentUser == null) return null;

    // try {
    //   if (!serviceHandler.anilistService.isLoggedIn.value) return null;

    //   final anilistUser = serviceHandler.anilistService.profileData.value;

    //   final userInfo = await supabase
    //       .from('users')
    //       .select()
    //       .eq('anilist_id', anilistUser.id!)
    //       .single();

    //   return userInfo;
    // } catch (e) {
    //   log("Error getting user info: $e");
    //   return null;
    // }
  }

  Future<void> syncUserDataWithAniList() async {
    // if (!serviceHandler.anilistService.isLoggedIn.value) return;

    // final currentUser = supabase.auth.currentUser;
    // if (currentUser == null) return;

    // final user = serviceHandler.anilistService.profileData.value;

    // try {
    //   await supabase.from('users').update({
    //     'username': user.name,
    //     'avatar_url': user.avatar,
    //   }).eq('anilist_id', user.id!);

    //   log("User data synced with AniList");
    // } catch (e) {
    //   log("Error syncing user data: $e");
    // }
  }
}
