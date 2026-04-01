import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/markdown.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:anymex/widgets/non_widgets/activity_composer_sheet.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ActivityCard extends StatefulWidget {
  final AnilistActivity activity;
  final VoidCallback? onTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onDeleted;
  final bool isOwnProfile;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onReplyTap,
    this.onDeleted,
    this.isOwnProfile = false,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  final userProfile = Get.find<ServiceHandler>().profileData.value;
  
  Widget _buildFallbackAvatar(BuildContext context, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: Icon(Icons.person, size: radius * 0.8, color: context.theme.colorScheme.onSurfaceVariant),
    );
  }

  void _toggleLike() async {
    final activity = widget.activity;
    setState(() {
      activity.isLiked = !activity.isLiked;
      activity.likeCount += activity.isLiked ? 1 : -1;
    });

    final anilistAuth = Get.find<AnilistAuth>();
    String mutationType = 'ACTIVITY';
    if (activity.type == 'MESSAGE') mutationType = 'MESSAGE';

    final success = await anilistAuth.toggleLike(activity.id, mutationType);

    if (!success && mounted) {
      setState(() {
        activity.isLiked = !activity.isLiked;
        activity.likeCount += activity.isLiked ? 1 : -1;
      });
    }
  }

  void _showActivityOptions() {
    final activity = widget.activity;
    final handler = Get.find<ServiceHandler>();
    final currentUserId = handler.profileData.value.id;
    final currentUserIdInt =
        currentUserId == null ? null : int.tryParse(currentUserId);
    final isOwner =
        currentUserIdInt != null && activity.authorId == currentUserIdInt;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
              if (isOwner && widget.isOwnProfile)
                ListTile(
                  leading: Icon(
                    activity.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                  title: Text(activity.isPinned ? "Unpin" : "Pin Activity"),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final auth = Get.find<AnilistAuth>();
                    setState(() => activity.isPinned = !activity.isPinned);
                    final error = await auth.toggleActivityPin(
                        activity.id, activity.isPinned);
                    if (error != null && mounted) {
                      setState(() => activity.isPinned = !activity.isPinned);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                ),
              ListTile(
                leading: Icon(
                  activity.isSubscribed
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                ),
                title: Text(activity.isSubscribed
                    ? "Unsubscribe"
                    : "Subscribe to thread"),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final auth = Get.find<AnilistAuth>();
                  setState(
                      () => activity.isSubscribed = !activity.isSubscribed);
                  final success = await auth.toggleActivitySubscription(
                      activity.id, activity.isSubscribed);
                  if (!success && mounted) {
                    setState(
                        () => activity.isSubscribed = !activity.isSubscribed);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text("Open in Browser"),
                onTap: () {
                  Navigator.pop(sheetContext);
                  launchUrlString('https://anilist.co/activity/${activity.id}');
                },
              ),
              if (isOwner &&
                  (activity.type == 'TEXT' || activity.type == 'MESSAGE'))
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text("Edit Activity"),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditSheet();
                  },
                ),
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Delete Activity",
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final auth = Get.find<AnilistAuth>();
                    final success = await auth.deleteActivity(activity.id);
                    if (success) {
                      widget.onDeleted?.call();
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLikedBySheet(BuildContext context) {
    final activity = widget.activity;
    if (activity.likes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final likeCount = activity.likes.length;
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
                        const Icon(Icons.favorite,
                            color: Colors.red, size: 20),
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
                          '${activity.likeCount}',
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
                      itemCount: activity.likes.length,
                      itemBuilder: (_, index) {
                        final liker = activity.likes[index];
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
                        context.theme.colorScheme.surface.withOpacity(0.92),
                        context.theme.colorScheme.surface.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      if (liker.avatarUrl != null)
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: liker.avatarUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => _buildFallbackAvatar(context, 24),
                          ),
                        )
                      else
                        _buildFallbackAvatar(context, 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          liker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Poppins-Bold',
                            fontWeight: FontWeight.w600,
                            color: context.theme.colorScheme.onSurface,
                          ),
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

  void _showEditSheet() {
    final activity = widget.activity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ActivityComposerSheet(
                  initialText: activity.text,
                  isModal: true,
                  hintText: "Update your activity...",
                  onSubmit: (text, {isPrivate = false}) async {
                    final success = await Get.find<AnilistAuth>()
                        .editActivity(activity.id, text.trim());
                    if (success && mounted) {
                      setState(() {
                        activity.text = text.trim();
                      });
                    }
                    return success;
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final isListActivity =
        activity.type == 'ANIME_LIST' || activity.type == 'MANGA_LIST';
    final subtleText = context.theme.colorScheme.onSurface.withOpacity(0.7);

    return RepaintBoundary(
        child: InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.theme.colorScheme.outlineVariant.withOpacity(0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: context.theme.colorScheme.shadow.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (activity.mediaBannerUrl != null ||
                activity.mediaCoverUrl != null)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 3.2, sigmaY: 3.2),
                  child: CachedNetworkImage(
                    imageUrl:
                        (activity.mediaBannerUrl ?? activity.mediaCoverUrl)!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            if (activity.mediaBannerUrl != null ||
                activity.mediaCoverUrl != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.theme.colorScheme.surface.withOpacity(0.42),
                          context.theme.colorScheme.surface.withOpacity(0.10),
                        ],
                        stops: const [0.0, 0.52],
                      ),
                    ),
                  ),
                ),
              ),
            if (activity.mediaBannerUrl != null ||
                activity.mediaCoverUrl != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          context.theme.colorScheme.surface.withOpacity(0.20),
                          context.theme.colorScheme.surface.withOpacity(0.48),
                        ],
                        stops: const [0.26, 0.64, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            if (activity.mediaBannerUrl != null ||
                activity.mediaCoverUrl != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.42, -0.05),
                        radius: 0.95,
                        colors: [
                          context.theme.colorScheme.surface.withOpacity(0.22),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (activity.authorId != null) {
                            final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
                            if (activity.authorId.toString() == currentUserId) {
                              navigate(() => const ProfilePage());
                            } else {
                              navigate(() =>
                                  UserProfilePage(userId: activity.authorId!));
                            }
                          }
                        },
                        child: activity.authorAvatarUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: activity.authorAvatarUrl!,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => _buildFallbackAvatar(context, 14),
                                ),
                              )
                            : _buildFallbackAvatar(context, 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (activity.authorId != null) {
                                      final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
                                      if (activity.authorId.toString() == currentUserId) {
                                        navigateWithSlide(() => const ProfilePage());
                                      } else {
                                        navigateWithSlide(() => UserProfilePage(
                                            userId: activity.authorId!));
                                      }
                                    }
                                  },
                                  child: Text(
                                    activity.authorName ?? 'User',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          context.theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (activity.isPinned) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.push_pin, size: 12),
                                ],
                                if (activity.isPrivate) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.lock, size: 10, color: subtleText),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Private',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtleText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              activity.timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: subtleText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _showActivityOptions,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.more_horiz,
                              size: 18, color: subtleText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Builder(
                    builder: (context) {
                      final contentRow = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activity.mediaCoverUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: activity.mediaCoverUrl!,
                                width: 105,
                                height: 150,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  width: 105,
                                  height: 150,
                                  color: context.theme.colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                          if (activity.mediaCoverUrl == null)
                            Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: context.theme.colorScheme.primary
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isListActivity) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          activity.type == 'ANIME_LIST'
                                              ? Icons.movie_outlined
                                              : Icons.book_outlined,
                                          size: 14,
                                          color: context
                                              .theme.colorScheme.onPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          activity.status
                                                  ?.replaceAll(' episode', '')
                                                  .replaceAll(' chapter', '')
                                                  .capitalizeFirst ??
                                              '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: context
                                                .theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_formatListStatus(activity)
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatListStatus(activity),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: context
                                            .theme.colorScheme.onSurface
                                            .withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  MarqueeText(
                                    activity.mediaTitle ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins-Bold',
                                      fontWeight: FontWeight.bold,
                                      color:
                                          context.theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ] else ...[
                                  _buildRichActivityContent(activity),
                                ],
                                if (isListActivity) const Spacer(),
                                const SizedBox(height: 12),
                                Builder(builder: (context) {
                                  final colorScheme = context.theme.colorScheme;
                                  final likeColor = activity.isLiked
                                      ? Colors.redAccent
                                      : colorScheme.onSurfaceVariant;

                                  return Row(
                                    children: [
                                      _ActivityActionChip(
                                        icon: activity.isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_outline,
                                        count: '${activity.likeCount}',
                                        foreground: likeColor,
                                        onTap: _toggleLike,
                                        onLongPress: () =>
                                            _showLikedBySheet(context),
                                      ),
                                      const SizedBox(width: 8),
                                      _ActivityActionChip(
                                        icon: Icons.chat_bubble_outline,
                                        count: '${activity.replyCount}',
                                        foreground: colorScheme.onSurfaceVariant,
                                        onTap: widget.onReplyTap,
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      );
                      return isListActivity
                          ? SizedBox(height: 155, child: contentRow)
                          : contentRow;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  String _formatListStatus(AnilistActivity activity) {
    if (activity.status == null) return '';
    if (activity.progress != null && activity.progress!.isNotEmpty) {
      final unit = activity.type == 'MANGA_LIST' ? 'Chapter' : 'Episode';
      return '$unit ${activity.progress} of';
    }
    return '';
  }

  Widget _buildRichActivityContent(AnilistActivity activity) {
    final raw = activity.text ?? '';
    if (raw.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final normalized = raw
          .replaceAllMapped(
            RegExp(r'img(?:\d+%?)?\(([^)]+)\)', caseSensitive: false),
            (m) => '![](${m.group(1) ?? ''})',
          )
          .replaceAllMapped(
            RegExp(r'youtube\(([^)]+)\)', caseSensitive: false),
            (m) => '[YouTube](${m.group(1) ?? ''})',
          )
          .replaceAllMapped(
            RegExp(r'webm\(([^)]+)\)', caseSensitive: false),
            (m) => '[Video](${m.group(1) ?? ''})',
          );

      final hasHtml = RegExp(r'<[^>]+>').hasMatch(normalized);
      final html = hasHtml ? normalized : parseMarkdown(normalized);

      return _buildHtmlWithInlineCards(html);
    } catch (_) {
      try {
        return _buildHtmlWithInlineCards(parseMarkdown(raw));
      } catch (_) {
        return Text(
          activity.displayText,
          style: TextStyle(
            fontSize: 14,
            color: context.theme.colorScheme.onSurface,
          ),
        );
      }
    }
  }

  Widget _buildHtmlWithInlineCards(String html) {
    final linkPattern = RegExp(
      "<a[^>]*href=['\\\"]https?://(?:www\\.)?anilist\\.co/(anime|manga)/(\\d+)[^'\\\"]*['\\\"][^>]*>[\\s\\S]*?<\\/a>|https?://(?:www\\.)?anilist\\.co/(anime|manga)/(\\d+)[^\\s<]*",
      caseSensitive: false,
    );

    final matches = linkPattern.allMatches(html).toList();
    if (matches.isEmpty) {
      return AnilistAboutMe(about: html);
    }

    final widgets = <Widget>[];
    var cursor = 0;

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      if (start > cursor) {
        final segment = html.substring(cursor, start);
        if (segment.trim().isNotEmpty) {
          widgets.add(AnilistAboutMe(about: segment));
        }
      }

      final type = ((match.group(1) ?? match.group(3)) ?? '').toLowerCase();
      final id = int.tryParse((match.group(2) ?? match.group(4)) ?? '');
      if (id != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: _ActivityAnilistCard(id: id, isManga: type == 'manga'),
          ),
        );
      }

      cursor = end;
    }

    if (cursor < html.length) {
      final tail = html.substring(cursor);
      if (tail.trim().isNotEmpty) {
        widgets.add(AnilistAboutMe(about: tail));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _ActivityAnilistCard extends StatefulWidget {
  final int id;
  final bool isManga;

  const _ActivityAnilistCard({required this.id, required this.isManga});

  @override
  State<_ActivityAnilistCard> createState() => _ActivityAnilistCardState();
}

class _ActivityActionChip extends StatelessWidget {
  const _ActivityActionChip({
    required this.icon,
    required this.count,
    required this.foreground,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String count;
  final Color foreground;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.34),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.32),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 6),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityAnilistCardState extends State<_ActivityAnilistCard> {
  Future<dynamic>? _dataFuture;

  @override
  void initState() {
    super.initState();
    final handler = Get.find<ServiceHandler>();
    _dataFuture = handler.anilistService.fetchDetails(
      FetchDetailsParams(
        id: widget.id.toString(),
        isManga: widget.isManga,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 92,
            width: 260,
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.42),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.theme.colorScheme.outlineVariant.withOpacity(0.22),
              ),
            ),
          );
        }

        final media = snapshot.data;
        if (media == null) {
          return const SizedBox.shrink();
        }

        final String title = (media.title?.toString().trim().isNotEmpty == true)
            ? media.title.toString()
            : (media.romajiTitle?.toString() ?? 'AniList');
        final String poster = media.poster?.toString() ?? '';
        final String format = media.format?.toString() ?? '';

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (widget.isManga) {
              navigate(() => MangaDetailsPage(media: media, tag: title));
            } else {
              navigate(() => AnimeDetailsPage(media: media, tag: title));
            }
          },
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.52),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    context.theme.colorScheme.outlineVariant.withOpacity(0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: poster,
                    width: 54,
                    height: 76,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 54,
                      height: 76,
                      color: context.theme.colorScheme.surfaceContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.theme.colorScheme.onSurface,
                        ),
                      ),
                      if (format.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          format,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
