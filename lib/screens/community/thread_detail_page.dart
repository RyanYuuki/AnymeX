import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_thread.dart';
import 'package:anymex/models/Anilist/anilist_thread_comment.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/thread_composer_sheet.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ThreadDetailPage extends StatefulWidget {
  final int threadId;
  final AnilistThread? thread;

  const ThreadDetailPage({
    super.key,
    required this.threadId,
    this.thread,
  });

  @override
  State<ThreadDetailPage> createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  AnilistThread? _thread;
  List<AnilistThreadComment> _comments = [];
  bool _isLoadingThread = true;
  bool _isLoadingComments = true;
  bool _isLoadingMoreComments = false;
  bool _hasNextPage = true;
  int _currentCommentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  int? _replyingToCommentId;
  String? _replyingToUsername;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
    _fetchThreadDetail();
    _fetchComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreComments &&
        _hasNextPage &&
        !_isLoadingComments) {
      _loadMoreComments();
    }
  }

  Future<void> _fetchThreadDetail() async {
    if (_thread != null) {
      setState(() => _isLoadingThread = false);
    }

    final anilistAuth = Get.find<AnilistAuth>();
    final result = await anilistAuth.fetchThreadDetail(widget.threadId);

    if (mounted && result != null) {
      setState(() {
        _thread = result;
        _isLoadingThread = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingThread = false);
    }
  }

  Future<void> _fetchComments({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoadingComments = true;
        _currentCommentPage = 1;
        _comments.clear();
        _hasNextPage = true;
      });
    }

    final anilistAuth = Get.find<AnilistAuth>();
    final results = await anilistAuth.fetchThreadComments(
      threadId: widget.threadId,
      page: _currentCommentPage,
      perPage: 25,
    );

    if (mounted) {
      setState(() {
        _isLoadingComments = false;
        _isLoadingMoreComments = false;
        if (reset) _comments.clear();
        _comments.addAll(results);
        _hasNextPage = results.length >= 25;
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMoreComments || !_hasNextPage) return;
    setState(() {
      _isLoadingMoreComments = true;
      _currentCommentPage++;
    });
    await _fetchComments(reset: false);
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchThreadDetail(),
      _fetchComments(reset: true),
    ]);
  }

  void _toggleThreadLike() async {
    if (_thread == null) return;
    final thread = _thread!;
    setState(() {
      thread.isLiked = !thread.isLiked;
      thread.likeCount += thread.isLiked ? 1 : -1;
    });

    final success =
    await Get.find<AnilistAuth>().toggleLike(thread.id, 'THREAD');

    if (!success && mounted) {
      setState(() {
        thread.isLiked = !thread.isLiked;
        thread.likeCount += thread.isLiked ? 1 : -1;
      });
    }
  }

  void _toggleSubscription() async {
    if (_thread == null) return;
    final thread = _thread!;
    setState(() {
      thread.isSubscribed = !thread.isSubscribed;
    });

    final success = await Get.find<AnilistAuth>()
        .toggleThreadSubscription(thread.id, thread.isSubscribed);

    if (!success && mounted) {
      setState(() {
        thread.isSubscribed = !thread.isSubscribed;
      });
    }
  }

  void _toggleCommentLike(AnilistThreadComment comment) async {
    setState(() {
      comment.isLiked = !comment.isLiked;
      comment.likeCount += comment.isLiked ? 1 : -1;
    });

    final success =
    await Get.find<AnilistAuth>().toggleLike(comment.id, 'THREAD_COMMENT');

    if (!success && mounted) {
      setState(() {
        comment.isLiked = !comment.isLiked;
        comment.likeCount += comment.isLiked ? 1 : -1;
      });
    }
  }

  void _setReplyTo(AnilistThreadComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUsername = comment.user?.name;
    });
    _commentController.text = '@${comment.user?.name ?? ''} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    _commentController.clear();
    _commentFocusNode.unfocus();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPostingComment = true);

    final anilistAuth = Get.find<AnilistAuth>();
    final result = await anilistAuth.saveThreadComment(
      threadId: widget.threadId,
      comment: text,
      parentCommentId: _replyingToCommentId,
    );

    if (mounted) {
      setState(() => _isPostingComment = false);
      if (result != null) {
        _commentController.clear();
        _commentFocusNode.unfocus();
        setState(() {
          _replyingToCommentId = null;
          _replyingToUsername = null;
        });
        await _fetchComments(reset: true);
      }
    }
  }

  Future<void> _deleteComment(AnilistThreadComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.theme.colorScheme.surfaceContainerHigh,
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: TextStyle(color: context.theme.colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete',
                style: TextStyle(color: context.theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
      await Get.find<AnilistAuth>().deleteThreadComment(comment.id);
      if (success && mounted) {
        await _fetchComments(reset: true);
      }
    }
  }

  void _navigateToUser(int? userId) {
    if (userId == null) return;
    final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
    if (userId.toString() == currentUserId) {
      navigate(() => const ProfilePage());
    } else {
      navigate(() => UserProfilePage(userId: userId));
    }
  }

  void _editThread() {
    if (_thread == null) return;
    ThreadComposerSheet.show(
      context,
      initialTitle: _thread!.title,
      initialBody: _thread!.body,
      onSubmit: (title, body) async {
        final result = await Get.find<AnilistAuth>().saveThread(
          threadId: _thread!.id,
          title: title,
          body: body,
        );
        if (result != null) {
          setState(() => _thread = result);
          return true;
        }
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colorScheme;
    final currentUserId =
        Get.find<ServiceHandler>().profileData.value.id;
    final currentUserIdInt =
    currentUserId == null ? null : int.tryParse(currentUserId);
    final isThreadOwner =
        currentUserIdInt != null && _thread?.userId == currentUserIdInt;

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(
              title: _thread?.title ?? 'Thread',
              action: Row(
                children: [
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: colors.onSurfaceVariant),
                    onSelected: (value) {
                      switch (value) {
                        case 'subscribe':
                          _toggleSubscription();
                          break;
                        case 'share':
                          if (_thread?.siteUrl != null) {
                            launchUrlString(_thread!.siteUrl!);
                          } else {
                            launchUrlString(
                                'https://anilist.co/forum/thread/${widget.threadId}');
                          }
                          break;
                        case 'edit':
                          _editThread();
                          break;
                        case 'delete':
                          _deleteThread();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'subscribe',
                        child: Row(
                          children: [
                            Icon(
                              _thread?.isSubscribed == true
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_active_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(_thread?.isSubscribed == true
                                ? 'Unsubscribe'
                                : 'Subscribe'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: const Row(
                          children: [
                            Icon(Icons.open_in_browser, size: 20),
                            SizedBox(width: 8),
                            Text('Open in Browser'),
                          ],
                        ),
                      ),
                      if (isThreadOwner) ...[
                        PopupMenuItem(
                          value: 'edit',
                          child: const Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Edit Thread'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 20, color: colors.error),
                              const SizedBox(width: 8),
                              Text('Delete Thread',
                                  style: TextStyle(color: colors.error)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingThread
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  controller: _scrollController,
                  physics:
                  const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [
                    if (_thread != null) ...[
                      _buildThreadHeader(colors, currentUserIdInt),
                    ],

                    const Divider(indent: 16, endIndent: 16, height: 32),

                    AnymexText(
                      text: 'Comments (${_thread?.replyCount ?? 0})',
                      variant: TextVariant.semiBold,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingComments)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                            child: CircularProgressIndicator()),
                      )
                    else if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: AnymexText(
                              text: 'No comments yet. Be the first!'),
                        ),
                      )
                    else
                      ..._comments
                          .map((comment) => _buildCommentCard(
                          comment, colors, currentUserIdInt)),

                    if (_isLoadingMoreComments)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            if (_thread?.isLocked != true)
              _buildCommentComposer(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadHeader(ColorScheme colors, int? currentUserIdInt) {
    final thread = _thread!;
    final isThreadOwner =
        currentUserIdInt != null && thread.userId == currentUserIdInt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymexText(
          text: thread.title,
          variant: TextVariant.bold,
          size: 20,
          maxLines: 3,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            GestureDetector(
              onTap: () => _navigateToUser(thread.user?.id ?? thread.userId),
              child: Row(
                children: [
                  if (thread.user?.avatarUrl != null)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: thread.user!.avatarUrl!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => CircleAvatar(
                          radius: 14,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(Icons.person,
                              size: 16, color: colors.onPrimaryContainer),
                        ),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(Icons.person,
                          size: 16, color: colors.onPrimaryContainer),
                    ),
                  const SizedBox(width: 10),
                  AnymexText(
                    text: thread.user?.name ?? 'User',
                    variant: TextVariant.semiBold,
                    size: 14,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnymexText(
              text: thread.timeAgo,
              size: 12,
              color: colors.onSurfaceVariant.withOpacity(0.7),
            ),
          ],
        ),

        if (thread.isLocked) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 16, color: colors.onErrorContainer),
                const SizedBox(width: 8),
                AnymexText(
                  text: 'This thread is locked',
                  size: 13,
                  variant: TextVariant.semiBold,
                  color: colors.onErrorContainer,
                ),
              ],
            ),
          ),
        ],

        if (thread.categories.isNotEmpty ||
            thread.mediaCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...thread.categories.map((cat) => Chip(
                label: AnymexText(
                  text: cat.name,
                  size: 11,
                  variant: TextVariant.semiBold,
                  color: colors.onSecondaryContainer,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                backgroundColor: colors.secondaryContainer,
                side: BorderSide.none,
              )),
              ...thread.mediaCategories.map((mc) => Chip(
                label: AnymexText(
                  text: mc.title ?? 'Media',
                  size: 11,
                  variant: TextVariant.semiBold,
                  color: colors.onPrimaryContainer,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                backgroundColor: colors.primaryContainer,
                side: BorderSide.none,
              )),
            ],
          ),
        ],

        if (thread.body.isNotEmpty) ...[
          const SizedBox(height: 16),
          AnilistAboutMe(about: thread.body),
        ],

        const SizedBox(height: 16),

        Row(
          children: [
            _ActionChip(
              icon: thread.isLiked ? Icons.favorite : Icons.favorite_outline,
              label: '${thread.likeCount}',
              color: thread.isLiked ? Colors.redAccent : colors.onSurfaceVariant,
              onTap: _toggleThreadLike,
            ),
            const SizedBox(width: 12),

            _ActionChip(
              icon: thread.isSubscribed
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
              label: thread.isSubscribed ? 'Subscribed' : 'Subscribe',
              color: thread.isSubscribed
                  ? colors.primary
                  : colors.onSurfaceVariant,
              onTap: _toggleSubscription,
            ),
            const SizedBox(width: 12),

            _ActionChip(
              icon: Icons.open_in_browser,
              label: 'Browser',
              color: colors.onSurfaceVariant,
              onTap: () {
                final url = thread.siteUrl ??
                    'https://anilist.co/forum/thread/${widget.threadId}';
                launchUrlString(url);
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            _StatChip(
                icon: Icons.chat_bubble_outline,
                count: thread.replyCount,
                color: colors.onSurfaceVariant),
            const SizedBox(width: 16),
            _StatChip(
                icon: Icons.visibility_outlined,
                count: thread.viewCount,
                color: colors.onSurfaceVariant),
            const SizedBox(width: 16),
            _StatChip(
                icon: Icons.favorite_outline,
                count: thread.likeCount,
                color: colors.onSurfaceVariant),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentCard(
      AnilistThreadComment comment, ColorScheme colors, int? currentUserIdInt) {
    final isOwnComment =
        currentUserIdInt != null && comment.userId == currentUserIdInt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSingleComment(comment, colors, isOwnComment, indent: 0),
          if (comment.childComments.isNotEmpty)
            _buildChildComments(comment.childComments, colors, currentUserIdInt),
        ],
      ),
    );
  }

  Widget _buildChildComments(List<AnilistThreadComment> children,
      ColorScheme colors, int? currentUserIdInt) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colors.outlineVariant.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((child) {
            final isOwnChild =
                currentUserIdInt != null && child.userId == currentUserIdInt;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSingleComment(child, colors, isOwnChild, indent: 1),
                  if (child.childComments.isNotEmpty)
                    _buildChildComments(
                        child.childComments, colors, currentUserIdInt),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSingleComment(
      AnilistThreadComment comment,
      ColorScheme colors,
      bool isOwnComment, {
        required int indent,
      }) {
    final subtleText = colors.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateToUser(comment.user?.id ?? comment.userId),
                child: Row(
                  children: [
                    if (comment.user?.avatarUrl != null)
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: comment.user!.avatarUrl!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => CircleAvatar(
                            radius: 12,
                            backgroundColor: colors.primaryContainer,
                            child: Icon(Icons.person,
                                size: 14, color: colors.onPrimaryContainer),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(Icons.person,
                            size: 14, color: colors.onPrimaryContainer),
                      ),
                    const SizedBox(width: 8),
                    AnymexText(
                      text: comment.user?.name ?? 'User',
                      variant: TextVariant.semiBold,
                      size: 13,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AnymexText(
                text: comment.timeAgo,
                size: 11,
                color: subtleText,
              ),
            ],
          ),

          const SizedBox(height: 8),
          AnilistAboutMe(about: comment.comment),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _setReplyTo(comment),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: AnymexText(
                        text: 'reply',
                        size: 12,
                        variant: TextVariant.semiBold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  if (isOwnComment)
                    InkWell(
                      onTap: () => _deleteComment(comment),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: AnymexText(
                          text: 'delete',
                          size: 12,
                          variant: TextVariant.semiBold,
                          color: colors.error,
                        ),
                      ),
                    ),
                ],
              ),
              InkWell(
                onTap: () => _toggleCommentLike(comment),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14,
                        color: comment.isLiked ? Colors.red : subtleText,
                      ),
                      const SizedBox(width: 4),
                      AnymexText(
                        text: '${comment.likeCount}',
                        size: 11,
                        color: comment.isLiked ? Colors.red : subtleText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentComposer(ColorScheme colors) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToCommentId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AnymexText(
                    text: 'Replying to @${_replyingToUsername ?? ''}',
                    size: 12,
                    variant: TextVariant.semiBold,
                    color: colors.primary,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null
                        ? 'Write a reply...'
                        : 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _commentController,
                builder: (context, value, child) {
                  final isEmpty = value.text.trim().isEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isEmpty || _isPostingComment
                          ? colors.surfaceContainerHighest
                          : colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isPostingComment
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(
                        Icons.send,
                        color: isEmpty
                            ? Colors.grey
                            : colors.onPrimary,
                      ),
                      onPressed: isEmpty || _isPostingComment
                          ? null
                          : _postComment,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteThread() async {
    if (_thread == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.theme.colorScheme.surfaceContainerHigh,
        title: const Text('Delete Thread'),
        content: const Text('Are you sure you want to delete this thread?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: TextStyle(color: context.theme.colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete',
                style: TextStyle(color: context.theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
      await Get.find<AnilistAuth>().deleteThread(_thread!.id);
      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainerHighest
              .withOpacity(0.34),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.theme.colorScheme.outlineVariant.withOpacity(0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            AnymexText(
              text: label,
              size: 12,
              variant: TextVariant.semiBold,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        AnymexText(
          text: _formatCount(count),
          size: 12,
          color: color,
          variant: TextVariant.semiBold,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}
