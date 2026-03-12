import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/screens/profile/widgets/profile_common.dart';
import 'package:anymex/screens/profile/widgets/hover_action_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/fullscreen_image_viewer.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UserProfileHeader extends StatefulWidget {
  final Profile user;
  final AnimationController bannerController;
  final Animation<Alignment> bannerAnim;
  final Color? avatarDominantColor;
  final bool? isFollowingUser;
  final bool? isFollowerOfUser;
  final bool followToggling;
  final VoidCallback onToggleFollow;

  const UserProfileHeader({
    super.key,
    required this.user,
    required this.bannerController,
    required this.bannerAnim,
    this.avatarDominantColor,
    this.isFollowingUser,
    this.isFollowerOfUser,
    required this.followToggling,
    required this.onToggleFollow,
  });

  @override
  State<UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<UserProfileHeader> {
  bool _isFollowHovered = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final hasBanner = user.cover != null && user.cover!.trim().isNotEmpty;
    final imageUrl = hasBanner ? user.cover! : '';
    final name = user.name ?? 'Guest';

    final donatorTier = user.donatorTier ?? 0;
    final donatorBadge = user.donatorBadge;
    final badgeText =
        (donatorTier > 0 && donatorBadge != null && donatorBadge.isNotEmpty)
            ? donatorBadge
            : 'AniList Member';

    final isDesktop =
        getResponsiveValue(context, mobileValue: false, desktopValue: true);

    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 330,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () {
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
                      },
                      child: Hero(
                        tag: 'profile_banner_$name',
                        child: AnymeXImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    )
                  else
                    Container(
                        color:
                            context.theme.colorScheme.surfaceContainerHighest),
                  
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            context.theme.colorScheme.surface.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Back Button
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, left: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
         
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (widget.avatarDominantColor != null)
                              BoxShadow(
                                color: widget.avatarDominantColor!
                                    .withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 0),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: user.avatar ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, size: 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Name & Badges
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontFamily: 'Poppins-Bold',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: context.theme.colorScheme.onSurface,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.7),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                    Shadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (donatorTier > 0) ...[
                                              const Icon(Icons.favorite,
                                                  size: 12,
                                                  color: Color(0xFFE85D75)),
                                              const SizedBox(width: 4),
                                            ],
                                            Text(
                                              badgeText,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: donatorTier > 0
                                                    ? const Color(0xFFE85D75)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (user.createdAt != null) ...[
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 12,
                                                  color: Colors.white70),
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
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Actions
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Row(
                          children: [
                            HoverActionButton(
                              icon: Icons.north_east_rounded,
                              onTap: () => launchUrlString(
                                  'https://anilist.co/user/$name'),
                            ),
                            const SizedBox(width: 10),
                            HoverActionButton(
                              icon: Icons.more_horiz,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: context
                                      .theme.colorScheme.surfaceContainer,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  builder: (ctx) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Container(
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: context.theme.colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(2),
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
                                              color: context
                                                  .theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          buildProfileSheetOption(
                                            ctx,
                                            icon: Icons.north_east_rounded,
                                            label: 'View on AniList',
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              launchUrlString(
                                                  'https://anilist.co/user/$name');
                                            },
                                          ),
                                          buildProfileSheetOption(
                                            ctx,
                                            icon: Iconsax.export,
                                            label: 'Share Profile',
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              Share.share(
                                                  'https://anilist.co/user/$name');
                                            },
                                          ),
                                          buildProfileSheetOption(
                                            ctx,
                                            icon: Iconsax.copy,
                                            label: 'Copy User ID',
                                            onTap: () async {
                                              Navigator.pop(ctx);
                                              await Clipboard.setData(
                                                  ClipboardData(
                                                      text:
                                                          user.id.toString()));
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                        'User ID copied to clipboard'),
                                                    backgroundColor: context
                                                        .theme
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    behavior: SnackBarBehavior
                                                        .floating,
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
                            const SizedBox(width: 10),
                            if (widget.isFollowingUser != null ||
                                widget.isFollowerOfUser != null) ...[
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) =>
                                    setState(() => _isFollowHovered = true),
                                onExit: (_) =>
                                    setState(() => _isFollowHovered = false),
                                child: GestureDetector(
                                  onTap: widget.followToggling
                                      ? null
                                      : widget.onToggleFollow,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isFollowHovered
                                          ? (widget.isFollowingUser == true
                                              ? const Color(0xFFE85D75)
                                              : context.theme.colorScheme
                                                  .primaryContainer
                                                  .withOpacity(0.4))
                                          : (widget.isFollowingUser == true
                                              ? context
                                                  .theme.colorScheme.primary
                                              : Colors.black.withOpacity(0.4)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: _isFollowHovered
                                          ? Border.all(
                                              color:
                                                  widget.isFollowingUser == true
                                                      ? const Color(0xFFE85D75)
                                                      : context.theme
                                                          .colorScheme.primary
                                                          .withOpacity(0.5),
                                            )
                                          : null,
                                      boxShadow: _isFollowHovered
                                          ? [
                                              BoxShadow(
                                                color: widget.isFollowingUser ==
                                                        true
                                                    ? const Color(0xFFE85D75)
                                                        .withOpacity(0.3)
                                                    : context.theme.colorScheme
                                                        .primary
                                                        .withOpacity(0.3),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.followToggling)
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _isFollowHovered
                                                  ? (widget.isFollowingUser ==
                                                          true
                                                      ? Colors.white
                                                      : context.theme
                                                          .colorScheme.primary)
                                                  : (widget.isFollowingUser ==
                                                          true
                                                      ? context.theme
                                                          .colorScheme.onPrimary
                                                      : Colors.white),
                                            ),
                                          )
                                        else
                                          Icon(
                                            _isFollowHovered &&
                                                    widget.isFollowingUser ==
                                                        true
                                                ? Icons.person_remove_rounded
                                                : (widget.isFollowingUser ==
                                                            true &&
                                                        widget.isFollowerOfUser ==
                                                            true)
                                                    ? Icons.people_rounded
                                                    : widget.isFollowingUser ==
                                                            true
                                                        ? Icons.check_rounded
                                                        : Icons
                                                            .person_add_rounded,
                                            size: 18,
                                            color: _isFollowHovered
                                                ? (widget.isFollowingUser ==
                                                        true
                                                    ? Colors.white
                                                    : context.theme.colorScheme
                                                        .primary)
                                                : (widget.isFollowingUser ==
                                                        true
                                                    ? context.theme.colorScheme
                                                        .onPrimary
                                                    : Colors.white),
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          (_isFollowHovered &&
                                                  widget.isFollowingUser ==
                                                      true)
                                              ? 'Unfollow'
                                              : getFollowLabel(isFollowing: widget.isFollowingUser, isFollower: widget.isFollowerOfUser),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Poppins-SemiBold',
                                            fontWeight: FontWeight.bold,
                                            color: _isFollowHovered
                                                ? (widget.isFollowingUser ==
                                                        true
                                                    ? Colors.white
                                                    : context.theme.colorScheme
                                                        .primary)
                                                : (widget.isFollowingUser ==
                                                        true
                                                    ? context.theme.colorScheme
                                                        .onPrimary
                                                    : Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
