import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AnilistAuth>();
    final handler = Get.find<ServiceHandler>();
    final profileData = handler.profileData;

    return Glow(
      child: Scaffold(
        backgroundColor: context.theme.colorScheme.surface,
        body: Obx(() {
          final user = profileData.value;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, user),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarAndName(context, user),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildHighlightCard(
                              context,
                              'Anime',
                              user.stats?.animeStats?.animeCount ?? '0',
                              IconlyBold.video,
                              context.theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHighlightCard(
                              context,
                              'Manga',
                              user.stats?.mangaStats?.mangaCount ?? '0',
                              IconlyBold.document,
                              context.theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSectionHeader(
                          context, 'Statistics', IconlyLight.chart),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatsCard(context, user),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildScoreCard(context, 'Anime Score',
                                user.stats?.animeStats?.meanScore ?? '0'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildScoreCard(context, 'Manga Score',
                                user.stats?.mangaStats?.meanScore ?? '0'),
                          ),
                        ],
                      ),
                    ),

                    if (user.about != null &&
                        user.about!.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSectionHeader(
                            context, 'About', IconlyLight.profile),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildAboutCard(context, user.about!),
                      ),
                    ],

                    if (user.favourites?.anime.isNotEmpty ?? false) ...[
                      const SizedBox(height: 22),
                      _buildSectionHeaderPadded(
                          context, 'Favourite Anime', IconlyBold.video),
                      const SizedBox(height: 10),
                      _buildMediaFavCarousel(
                          context, user.favourites!.anime),
                    ],

                    if (user.favourites?.manga.isNotEmpty ?? false) ...[
                      const SizedBox(height: 22),
                      _buildSectionHeaderPadded(
                          context, 'Favourite Manga', IconlyBold.document),
                      const SizedBox(height: 10),
                      _buildMediaFavCarousel(
                          context, user.favourites!.manga),
                    ],

                    if (user.favourites?.characters.isNotEmpty ?? false) ...[
                      const SizedBox(height: 22),
                      _buildSectionHeaderPadded(
                          context, 'Favourite Characters', IconlyBold.profile),
                      const SizedBox(height: 10),
                      _buildPersonCarousel(
                          context,
                          user.favourites!.characters
                              .map((c) =>
                                  _PersonItem(name: c.name, image: c.image))
                              .toList()),
                    ],

                    if (user.favourites?.staff.isNotEmpty ?? false) ...[
                      const SizedBox(height: 22),
                      _buildSectionHeaderPadded(context, 'Favourite Staff',
                          IconlyBold.two_users),
                      const SizedBox(height: 10),
                      _buildPersonCarousel(
                          context,
                          user.favourites!.staff
                              .map((s) =>
                                  _PersonItem(name: s.name, image: s.image))
                              .toList()),
                    ],

                    if (user.favourites?.studios.isNotEmpty ?? false) ...[
                      const SizedBox(height: 22),
                      _buildSectionHeaderPadded(context, 'Favourite Studios',
                          Icons.business_rounded),
                      const SizedBox(height: 10),
                      _buildStudiosWrap(context, user.favourites!.studios),
                    ],

                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Profile user) {
    final hasBanner =
        user.cover != null && user.cover!.trim().isNotEmpty;
    final bannerUrl =
        hasBanner ? user.cover! : (user.avatar ?? '');

    return SliverAppBar(
      expandedHeight: 240.0,
      floating: false,
      pinned: true,
      backgroundColor: context.theme.colorScheme.surface,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(IconlyLight.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerUrl.isNotEmpty)
              Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: context.theme.colorScheme.surfaceContainer,
                ),
              ),
            if (!hasBanner && bannerUrl.isNotEmpty)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  color:
                      context.theme.colorScheme.surface.withOpacity(0.25),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    context.theme.colorScheme.surface.withOpacity(0.55),
                    context.theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.72, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarAndName(BuildContext context, Profile user) {
    final expiry = user.tokenExpiry;
    String expiryText = '';
    if (expiry != null) {
      final days = expiry.difference(DateTime.now()).inDays;
      final months = (days / 30).floor();
      expiryText =
          'Reconnect in $months month${months != 1 ? 's' : ''}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.theme.colorScheme.surface,
              border: Border.all(
                color:
                    context.theme.colorScheme.primary.withOpacity(0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      context.theme.colorScheme.shadow.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor:
                  context.theme.colorScheme.surfaceContainer,
              backgroundImage:
                  user.avatar != null && user.avatar!.isNotEmpty
                      ? NetworkImage(user.avatar!)
                      : null,
              child: user.avatar == null || user.avatar!.isEmpty
                  ? Icon(Icons.person,
                      size: 38,
                      color: context.theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name ?? 'Guest',
                  style: TextStyle(
                    fontSize: 21,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: context.theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.primaryContainer
                        .withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AniList Member',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (expiryText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expiryText,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.theme.colorScheme.onSurfaceVariant
                          .withOpacity(0.65),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, String about) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              context.theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: MarkdownBody(
        data: about,
        softLineBreak: true,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontSize: 13.5,
            height: 1.65,
            color: context.theme.colorScheme.onSurfaceVariant,
            fontFamily: 'Poppins',
          ),
          strong: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.theme.colorScheme.onSurface,
          ),
          em: TextStyle(
            fontStyle: FontStyle.italic,
            color: context.theme.colorScheme.onSurface,
          ),
          h1: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface,
          ),
          h2: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface,
          ),
          h3: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface,
          ),
          blockquoteDecoration: BoxDecoration(
            color:
                context.theme.colorScheme.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(
                color: context.theme.colorScheme.primary,
                width: 3,
              ),
            ),
          ),
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            backgroundColor:
                context.theme.colorScheme.surfaceContainer,
            color: context.theme.colorScheme.primary,
          ),
          a: TextStyle(
            color: context.theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, Profile user) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              context.theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildStatRow(
            context,
            'Episodes Watched',
            user.stats?.animeStats?.episodesWatched ?? '0',
            IconlyLight.play,
          ),
          const Divider(height: 20, thickness: 0.5),
          _buildStatRow(
            context,
            'Minutes Watched',
            user.stats?.animeStats?.minutesWatched ?? '0',
            IconlyLight.time_circle,
          ),
          const Divider(height: 20, thickness: 0.5),
          _buildStatRow(
            context,
            'Chapters Read',
            user.stats?.mangaStats?.chaptersRead ?? '0',
            IconlyLight.paper,
          ),
          const Divider(height: 20, thickness: 0.5),
          _buildStatRow(
            context,
            'Volumes Read',
            user.stats?.mangaStats?.volumesRead ?? '0',
            IconlyLight.bookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(BuildContext context, String label,
      String value, IconData icon, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
      BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.secondaryContainer
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$value%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value,
      IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 14,
              color: context.theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon,
            size: 17, color: context.theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: context.theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderPadded(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildSectionHeader(context, title, icon),
    );
  }

  Widget _buildMediaFavCarousel(
      BuildContext context, List<FavouriteMedia> items) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMediaCard(context, item.cover, item.title);
        },
      ),
    );
  }

  Widget _buildMediaCard(
      BuildContext context, String? imageUrl, String? title) {
    return Container(
      width: 112,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 112,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _coverPlaceholder(context),
                  )
                : _coverPlaceholder(context),
          ),
          const SizedBox(height: 5),
          Text(
            title ?? '',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(BuildContext context) {
    return Container(
      width: 112,
      height: 150,
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported_rounded,
        color: context.theme.colorScheme.onSurfaceVariant
            .withOpacity(0.35),
      ),
    );
  }

  Widget _buildPersonCarousel(
      BuildContext context, List<_PersonItem> items) {
    return SizedBox(
      height: 128,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildPersonCard(context, item.image, item.name);
        },
      ),
    );
  }

  Widget _buildPersonCard(
      BuildContext context, String? imageUrl, String? name) {
    return Container(
      width: 78,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _circleAvatarPlaceholder(context),
                  )
                : _circleAvatarPlaceholder(context),
          ),
          const SizedBox(height: 6),
          Text(
            name ?? '',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: context.theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _circleAvatarPlaceholder(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.theme.colorScheme.surfaceContainer,
      ),
      child: Icon(
        Icons.person,
        color: context.theme.colorScheme.onSurfaceVariant
            .withOpacity(0.35),
      ),
    );
  }

  Widget _buildStudiosWrap(
      BuildContext context, List<FavouriteStudio> studios) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: studios
            .map(
              (studio) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.theme.colorScheme.primary
                        .withOpacity(0.22),
                  ),
                ),
                child: Text(
                  studio.name ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PersonItem {
  final String? name;
  final String? image;

  const _PersonItem({this.name, this.image});
}
