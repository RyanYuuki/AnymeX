import 'dart:ui';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/screens/profile/widgets/profile_common.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/fullscreen_image_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UserProfileAppBar extends StatefulWidget {
  final Profile user;
  final String avatarUrl;
  final String? bannerUrl;
  final AnimationController bannerController;
  final Animation<Alignment> bannerAnim;
  final bool? isFollowingUser;
  final bool? isFollowerOfUser;
  final bool followToggling;
  final VoidCallback onToggleFollow;

  const UserProfileAppBar({
    super.key,
    required this.user,
    required this.avatarUrl,
    this.bannerUrl,
    required this.bannerController,
    required this.bannerAnim,
    this.isFollowingUser,
    this.isFollowerOfUser,
    required this.followToggling,
    required this.onToggleFollow,
  });

  @override
  State<UserProfileAppBar> createState() => _UserProfileAppBarState();
}

class _UserProfileAppBarState extends State<UserProfileAppBar> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final avatarUrl = widget.avatarUrl;
    final bannerUrl = widget.bannerUrl;
    final bannerAnim = widget.bannerAnim;

    final hasBanner = bannerUrl != null && bannerUrl.trim().isNotEmpty;
    final imageUrl = hasBanner ? bannerUrl : avatarUrl;
    final name = user.name ?? 'Guest';
    final donatorTier = user.donatorTier ?? 0;
    final donatorBadge = user.donatorBadge;
    final badgeText =
        (donatorTier > 0 && donatorBadge != null && donatorBadge.isNotEmpty)
            ? donatorBadge
            : 'AniList Member';

    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = (screenHeight * 0.36).clamp(250.0, 390.0);

    return SliverAppBar(
      expandedHeight: bannerHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: context.theme.colorScheme.surface,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(IconlyLight.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: context.theme.colorScheme.surfaceContainer,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'More Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins-Bold',
                            fontWeight: FontWeight.bold,
                            color: context.theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        buildProfileSheetOption(
                          ctx,
                          icon: Icons.north_east_rounded,
                          label: 'View on AniList',
                          onTap: () {
                            Navigator.pop(ctx);
                            launchUrlString('https://anilist.co/user/$name');
                          },
                        ),
                        buildProfileSheetOption(
                          ctx,
                          icon: Iconsax.export,
                          label: 'Share Profile',
                          onTap: () {
                            Navigator.pop(ctx);
                            Share.share('https://anilist.co/user/$name');
                          },
                        ),
                        buildProfileSheetOption(
                          ctx,
                          icon: Iconsax.copy,
                          label: 'Copy User ID',
                          onTap: () async {
                            Navigator.pop(ctx);
                            await Clipboard.setData(
                              ClipboardData(text: user.id.toString()),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'User ID copied to clipboard',
                                  ),
                                  backgroundColor: context.theme.colorScheme
                                      .surfaceContainerHighest,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: bannerAnim,
              builder: (context, child) {
                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      if (imageUrl.isNotEmpty) {
                        widget.bannerController.stop();
                        Navigator.of(context, rootNavigator: true)
                            .push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                              imageUrl: imageUrl,
                              tag: 'profile_banner_$name',
                            ),
                          ),
                        )
                            .then((_) {
                          widget.bannerController.repeat(reverse: true);
                        });
                      }
                    },
                    child: Hero(
                      tag: 'profile_banner_$name',
                      child: AnymeXImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        alignment:
                            hasBanner ? bannerAnim.value : Alignment.center,
                        radius: 0,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!hasBanner)
              IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                      color:
                          context.theme.colorScheme.surface.withOpacity(0.2)),
                ),
              ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      context.theme.colorScheme.surface.withOpacity(0.8),
                      context.theme.colorScheme.surface,
                    ],
                    stops: const [0.0, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (avatarUrl.isNotEmpty) {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(
                                imageUrl: avatarUrl,
                                tag: 'profile_avatar_$name',
                              ),
                            ),
                          );
                        }
                      },
                      child: Hero(
                        tag: 'profile_avatar_$name',
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final hasFollowState =
                                  widget.isFollowingUser != null ||
                                      widget.isFollowerOfUser != null;
                              final shouldStackFollow =
                                  hasFollowState && constraints.maxWidth < 250;

                              final nameWidget = Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Poppins-Bold',
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              );

                              final followChip = GestureDetector(
                                onTap: widget.followToggling
                                    ? null
                                    : widget.onToggleFollow,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.isFollowingUser == true
                                        ? context.theme.colorScheme.primary
                                        : Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.followToggling)
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                widget.isFollowingUser == true
                                                    ? context.theme.colorScheme
                                                        .onPrimary
                                                    : Colors.white,
                                          ),
                                        )
                                      else
                                        Icon(
                                          (widget.isFollowingUser == true &&
                                                  widget.isFollowerOfUser ==
                                                      true)
                                              ? Icons.people_rounded
                                              : widget.isFollowingUser == true
                                                  ? Icons.check_rounded
                                                  : Icons.person_add_rounded,
                                          size: 12,
                                          color: widget.isFollowingUser == true
                                              ? context
                                                  .theme.colorScheme.onPrimary
                                              : Colors.white,
                                        ),
                                      const SizedBox(width: 5),
                                      Text(
                                        getFollowLabel(isFollowing: widget.isFollowingUser, isFollower: widget.isFollowerOfUser),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontFamily: 'Poppins-Bold',
                                          fontWeight: FontWeight.w700,
                                          color: widget.isFollowingUser == true
                                              ? context
                                                  .theme.colorScheme.onPrimary
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (!hasFollowState) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: nameWidget,
                                );
                              }

                              if (shouldStackFollow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    nameWidget,
                                    const SizedBox(height: 6),
                                    followChip,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: nameWidget),
                                  const SizedBox(width: 10),
                                  followChip,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (donatorTier > 0) ...[
                                      const Icon(
                                        Icons.favorite,
                                        size: 12,
                                        color: Color(0xFFE85D75),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.55,
                                      ),
                                      child: Text(
                                        badgeText,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: donatorTier > 0
                                              ? const Color(0xFFE85D75)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (user.createdAt != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Joined ${DateTime.fromMillisecondsSinceEpoch(user.createdAt! * 1000).year}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
