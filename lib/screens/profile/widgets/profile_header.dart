import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/fullscreen_image_viewer.dart';
import 'package:anymex/screens/profile/widgets/hover_action_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';

Widget _buildBottomSheetOption(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: context.theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins-SemiBold',
            ),
          ),
        ],
      ),
    ),
  );
}

class DesktopProfileHeader extends StatelessWidget {
  final Profile user;
  final Animation<Alignment> bannerAnim;
  final AnimationController bannerController;
  final Color? avatarDominantColor;

  const DesktopProfileHeader({
    super.key,
    required this.user,
    required this.bannerAnim,
    required this.bannerController,
    this.avatarDominantColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = user.cover != null && user.cover!.trim().isNotEmpty;
    final imageUrl = hasBanner ? user.cover! : '';
    final name = user.name ?? 'Guest';

    final donatorTier =
        Get.find<ServiceHandler>().profileData.value.donatorTier ?? 0;
    final donatorBadge =
        Get.find<ServiceHandler>().profileData.value.donatorBadge;
    final badgeText =
        (donatorTier > 0 && donatorBadge != null && donatorBadge.isNotEmpty)
            ? donatorBadge
            : 'AniList Member';

    final isDesktop = getResponsiveValue(
      context,
      mobileValue: false,
      desktopValue: true,
    );

    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                        bannerController.stop();
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
                          bannerController.repeat(reverse: true);
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
                      color: context.theme.colorScheme.surfaceContainerHighest,
                    ),
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
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40.0 : 20.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (avatarDominantColor != null)
                              BoxShadow(
                                color: avatarDominantColor!.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 0),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: user.avatar ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, size: 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
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
                              Flexible(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
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
                                    if (user.tokenExpiry != null) ...[
                                      Builder(
                                        builder: (context) {
                                          final remaining = user.tokenExpiry!
                                              .difference(DateTime.now());
                                          final days = remaining.inDays;
                                          final hours =
                                              remaining.inHours.remainder(24);
                                          final minutes = remaining.inMinutes
                                              .remainder(60);
                                          final countdownText = days > 0
                                              ? 'Reconnect in ${days}d ${hours}h ${minutes}m'
                                              : hours > 0
                                                  ? 'Reconnect in ${hours}h ${minutes}m'
                                                  : 'Reconnect in ${minutes}m';
                                          return Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  countdownText,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    if (user.createdAt != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(
                                            0.4,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Row(
                          children: [
                            HoverActionButton(
                              icon: Icons.north_east_rounded,
                              onTap: () => launchUrlString(
                                'https://anilist.co/user/$name',
                              ),
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
                                      top: Radius.circular(20),
                                    ),
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
                                          _buildBottomSheetOption(
                                            ctx,
                                            icon: Icons.north_east_rounded,
                                            label: 'View on AniList',
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              launchUrlString(
                                                'https://anilist.co/user/$name',
                                              );
                                            },
                                          ),
                                          _buildBottomSheetOption(
                                            ctx,
                                            icon: Iconsax.export,
                                            label: 'Share Profile',
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              Share.share(
                                                'https://anilist.co/user/$name',
                                              );
                                            },
                                          ),
                                          _buildBottomSheetOption(
                                            ctx,
                                            icon: Iconsax.copy,
                                            label: 'Copy User ID',
                                            onTap: () async {
                                              Navigator.pop(ctx);
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: user.id.toString(),
                                                ),
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'User ID copied to clipboard',
                                                    ),
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

class MobileProfileHeaderSliver extends StatelessWidget {
  final String avatarUrl;
  final String? bannerUrl;
  final Profile user;
  final Animation<Alignment> bannerAnim;
  final AnimationController bannerController;

  const MobileProfileHeaderSliver({
    super.key,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.user,
    required this.bannerAnim,
    required this.bannerController,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = bannerUrl != null && bannerUrl!.trim().isNotEmpty;
    final imageUrl = hasBanner ? bannerUrl! : avatarUrl;
    final name = user.name ?? 'Guest';
    final handler = Get.find<ServiceHandler>();
    final donatorTier = handler.profileData.value.donatorTier ?? 0;
    final donatorBadge = handler.profileData.value.donatorBadge;
    final badgeText =
        (donatorTier > 0 && donatorBadge != null && donatorBadge.isNotEmpty)
            ? donatorBadge
            : 'AniList Member';

    String? expiryText;
    final expiry = handler.profileData.value.tokenExpiry;
    if (expiry != null) {
      final diff = expiry.difference(DateTime.now());
      if (diff.isNegative) {
        expiryText = 'Token expired';
      } else {
        int minutes = diff.inMinutes;
        int hours = minutes ~/ 60;
        minutes %= 60;
        int days = hours ~/ 24;
        hours %= 24;

        final daysStr = days < 1 ? '' : '${days}d ';
        final hoursStr = hours < 1 ? '' : '${hours}h ';
        final minutesStr = minutes < 1 ? '' : '${minutes}m';

        expiryText = 'Reconnect in $daysStr$hoursStr$minutesStr'.trim();
      }
    }

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
                        _buildBottomSheetOption(
                          ctx,
                          icon: Icons.north_east_rounded,
                          label: 'View on AniList',
                          onTap: () {
                            Navigator.pop(ctx);
                            launchUrlString('https://anilist.co/user/$name');
                          },
                        ),
                        _buildBottomSheetOption(
                          ctx,
                          icon: Iconsax.export,
                          label: 'Share Profile',
                          onTap: () {
                            Navigator.pop(ctx);
                            Share.share('https://anilist.co/user/$name');
                          },
                        ),
                        _buildBottomSheetOption(
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
                        bannerController.stop();
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
                          bannerController.repeat(reverse: true);
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
                    color: context.theme.colorScheme.surface.withOpacity(0.2),
                  ),
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
                    stops: const [0.0, 0.85, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
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
                          width: 110,
                          height: 110,
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              name,
                              maxLines: 1,
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
                            ),
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
                              if (expiryText != null && expiryText.isNotEmpty)
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
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        expiryText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
