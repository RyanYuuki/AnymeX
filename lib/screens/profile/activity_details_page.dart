import 'package:flutter/material.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:get/get.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/widgets/non_widgets/activity_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/activity_composer_sheet.dart';

void showActivityDetailsSheet(BuildContext context, AnilistActivity activity) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return ActivityDetailsSheet(activity: activity);
    },
  );
}

class ActivityDetailsSheet extends StatefulWidget {
  final AnilistActivity activity;

  const ActivityDetailsSheet({super.key, required this.activity});

  @override
  State<ActivityDetailsSheet> createState() => _ActivityDetailsSheetState();
}

class _ActivityDetailsSheetState extends State<ActivityDetailsSheet> {
  List<ActivityReply>? replies;
  final GlobalKey<ActivityComposerSheetState> _composerKey =
      GlobalKey<ActivityComposerSheetState>();
  int? _editingReplyId;
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _fetchReplies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchReplies() async {
    final fetched =
        await Get.find<AnilistAuth>().fetchActivityReplies(widget.activity.id);
    if (mounted) {
      setState(() {
        replies = fetched;
      });
    }
  }

  Future<bool> _postReply(String text) async {
    if (_editingReplyId != null) {
      final success = await Get.find<AnilistAuth>()
          .editActivityReply(_editingReplyId!, text);
      if (success && mounted) {
        setState(() {
          _editingReplyId = null;
        });
        await _fetchReplies();
        return true;
      }
      return false;
    }

    final success = await Get.find<AnilistAuth>()
        .postActivityReply(widget.activity.id, text);

    if (success && mounted) {
      // reply count
      setState(() {
        widget.activity.replyCount++;
      });
      // Re-fetch replies
      await _fetchReplies();
      return true;
    }
    return false;
  }

  void _toggleReplyLike(ActivityReply reply) async {
    setState(() {
      reply.isLiked = !reply.isLiked;
      reply.likeCount += reply.isLiked ? 1 : -1;
    });

    final success =
        await Get.find<AnilistAuth>().toggleLike(reply.id, 'ACTIVITY_REPLY');

    if (!success && mounted) {
      setState(() {
        reply.isLiked = !reply.isLiked;
        reply.likeCount += reply.isLiked ? 1 : -1;
      });
    }
  }

  Future<void> _deleteReply(ActivityReply reply) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.colorScheme.surfaceContainerHigh,
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: context.theme.colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: context.theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await Get.find<AnilistAuth>().deleteActivityReply(reply.id);
      if (success && mounted) {
        setState(() {
          widget.activity.replyCount = (widget.activity.replyCount > 0)
              ? widget.activity.replyCount - 1
              : 0;
        });
        await _fetchReplies();
      }
    }
  }

  Future<void> _editReply(ActivityReply reply) async {
    // Strip html (edit)
    final rawText =
        reply.text.replaceAll('<br>', '\n').replaceAll(RegExp(r'<[^>]*>'), '');

    setState(() {
      _editingReplyId = reply.id;
    });

    _focusComposer(rawText);
  }

  void _focusComposer([String? initialText]) {
    final state = _composerKey.currentState;
    if (state != null) {
      if (initialText != null) {
        if (_editingReplyId != null) {
          state.setText(initialText);
        } else {
          final currentText = state.text;
          if (!currentText.contains(initialText.trim())) {
            state.appendText(initialText);
          }
          setState(() {
            _isReplying = true;
          });
        }
      }
      state.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchReplies,
                    child: ListView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      children: [
                        ActivityCard(
                          activity: widget.activity,
                          onTap: () {},
                          onReplyTap:
                              () {}, 
                        ),

                        const Divider(indent: 16, endIndent: 16),

                        if (replies == null)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (replies!.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text("No replies yet. Be the first!"),
                            ),
                          )
                        else
                          ...replies!.map((reply) => _buildReplyCard(reply)),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 12 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(
                        color: context.theme.dividerColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: ActivityComposerSheet(
                    key: _composerKey,
                    hintText: _editingReplyId != null
                        ? "Edit reply..."
                        : "Write a reply...",
                    showCancelButton: _editingReplyId != null || _isReplying,
                    onCancel: () {
                      setState(() {
                        _editingReplyId = null;
                        _isReplying = false;
                      });
                    },
                    onSubmit: (text, {isPrivate = false}) => _postReply(text),
                  ),
                ),
              ], 
            ), 
          ); 
        },
      ), 
    ); 
  }

  Widget _buildReplyCard(ActivityReply reply) {
    final subtleText = context.theme.colorScheme.onSurface.withOpacity(0.7);
    final currentUserId =
        Get.find<AnilistAuth>().profileData.value.id.toString();

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (reply.authorId != null) {
                  Navigator.pop(context); // Close bottom
                  final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
                  if (reply.authorId.toString() == currentUserId) {
                    navigateWithSlide(() => const ProfilePage());
                  } else {
                    navigateWithSlide(
                        () => UserProfilePage(userId: reply.authorId!));
                  }
                }
              },
              child: reply.authorAvatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: reply.authorAvatarUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          child: Icon(Icons.person, size: 20),
                        ),
                      ),
                    )
                  : const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: 16,
                      child: Icon(Icons.person, size: 20),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (reply.authorId != null) {
                            Navigator.pop(
                                context); // Close bottom sheet
                            final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
                            if (reply.authorId.toString() == currentUserId) {
                              navigateWithSlide(() => const ProfilePage());
                            } else {
                              navigateWithSlide(
                                  () => UserProfilePage(userId: reply.authorId!));
                            }
                          }
                        },
                        child: Text(
                          reply.authorName ?? 'User',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        reply.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: subtleText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnilistAboutMe(
                    about: reply.text,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (_editingReplyId != null) {
                                setState(() => _editingReplyId = null);
                              }
                              _focusComposer('@${reply.authorName} ');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'reply',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (reply.authorId.toString() == currentUserId) ...[
                            InkWell(
                              onTap: () => _deleteReply(reply),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  'delete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _editReply(reply),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  'edit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context
                                        .theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      InkWell(
                        onTap: () => _toggleReplyLike(reply),
                        onLongPress: () => _showReplyLikedBySheet(context, reply),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                reply.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 14,
                                color: reply.isLiked ? Colors.red : subtleText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${reply.likeCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      reply.isLiked ? Colors.red : subtleText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  void _showReplyLikedBySheet(BuildContext context, ActivityReply reply) {
    if (reply.likes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final likeCount = reply.likes.length;
        final contentHeight = 70.0 + (likeCount * 90.0) + 16.0;
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        final initialFraction =
            (contentHeight / screenHeight).clamp(0.25, 0.9);
        return DraggableScrollableSheet(
          initialChildSize: initialFraction,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (dragContext, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: dragContext.theme.colorScheme.surfaceContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Liked by',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: dragContext.theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${reply.likeCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: dragContext
                                .theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: dragContext.theme.colorScheme.outlineVariant
                        .withOpacity(0.3),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: reply.likes.length,
                      itemBuilder: (_, index) {
                        final liker = reply.likes[index];
                        return _buildLikerTile(dragContext, liker);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLikerTile(BuildContext context, ActivityLiker liker) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
          if (liker.id.toString() == currentUserId) {
            navigate(() => const ProfilePage());
          } else {
            navigate(() => UserProfilePage(userId: liker.id));
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 80,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (liker.bannerImage != null)
                  CachedNetworkImage(
                    imageUrl: liker.bannerImage!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: context.theme.colorScheme.surfaceContainerHigh,
                    ),
                  )
                else
                  Container(
                    color: context.theme.colorScheme.surfaceContainerHigh,
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        context.theme.colorScheme.surfaceContainer.withOpacity(0.95),
                        context.theme.colorScheme.surfaceContainer.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (liker.avatarUrl != null)
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: liker.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.transparent,
                              child: Icon(Icons.person, color: context.theme.colorScheme.onPrimaryContainer),
                            ),
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          child: Icon(Icons.person, color: context.theme.colorScheme.onPrimaryContainer),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          liker.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
