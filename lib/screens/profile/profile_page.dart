import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

extension ColorToCss on Color {
  String toCssString() => 'rgba(${red}, ${green}, ${blue}, ${opacity})';
}

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
          final bannerUrl = user.avatar ?? '';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, bannerUrl, user.cover, user.name ?? 'Guest'),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildAvatarAndName(
                          context, user.avatar ?? '', user.name ?? 'Guest'),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildHighlightCard(
                              context,
                              'Anime',
                              user.stats?.animeStats?.animeCount?.toString() ??
                                  '0',
                              IconlyBold.video,
                              context.theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildHighlightCard(
                              context,
                              'Manga',
                              user.stats?.mangaStats?.mangaCount?.toString() ??
                                  '0',
                              IconlyBold.document,
                              context.theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildSectionHeader(
                          context, "Statistics", IconlyLight.chart),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.theme.colorScheme.outlineVariant
                                .withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStatRow(
                              context,
                              "Episodes Watched",
                              user.stats?.animeStats?.episodesWatched
                                      ?.toString() ??
                                  '0',
                              IconlyLight.play,
                            ),
                            const Divider(height: 24, thickness: 0.5),
                            _buildStatRow(
                              context,
                              "Minutes Watched",
                              user.stats?.animeStats?.minutesWatched
                                      ?.toString() ??
                                  '0',
                              IconlyLight.time_circle,
                            ),
                            const Divider(height: 24, thickness: 0.5),
                            _buildStatRow(
                              context,
                              "Chapters Read",
                              user.stats?.mangaStats?.chaptersRead
                                      ?.toString() ??
                                  '0',
                              IconlyLight.paper,
                            ),
                            const Divider(height: 24, thickness: 0.5),
                            _buildStatRow(
                              context,
                              "Volumes Read",
                              user.stats?.mangaStats?.volumesRead?.toString() ??
                                  '0',
                              IconlyLight.bookmark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildScoreCard(
                                  context,
                                  "Anime Score",
                                  user.stats?.animeStats?.meanScore
                                          ?.toString() ??
                                      '0')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildScoreCard(
                                  context,
                                  "Manga Score",
                                  user.stats?.mangaStats?.meanScore
                                          ?.toString() ??
                                      '0')),
                        ],
                      ),
                    ),

                    if (user.about != null && user.about!.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(
                            context, "About", IconlyLight.profile),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.theme.colorScheme.outlineVariant
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: HtmlWidget(
                            user.about!,
                            textStyle: TextStyle(
                              fontSize: 13.5,
                              height: 1.65,
                              color: context.theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'Poppins',
                            ),
                            customStylesBuilder: (element) {
                              if (element.localName == 'strong') {
                                return {
                                  'font-weight': '700',
                                  'color': context.theme.colorScheme.onSurface.toCssString(),
                                };
                              }
                              if (element.localName == 'em') {
                                return {
                                  'font-style': 'italic',
                                  'color': context.theme.colorScheme.onSurface.toCssString(),
                                };
                              }
                              if (element.localName == 'h1') {
                                return {
                                  'font-size': '18px',
                                  'font-weight': 'bold',
                                  'color': context.theme.colorScheme.onSurface.toCssString(),
                                };
                              }
                              if (element.localName == 'h2') {
                                return {
                                  'font-size': '16px',
                                  'font-weight': 'bold',
                                  'color': context.theme.colorScheme.onSurface.toCssString(),
                                };
                              }
                              if (element.localName == 'h3') {
                                return {
                                  'font-size': '14px',
                                  'font-weight': 'bold',
                                  'color': context.theme.colorScheme.onSurface.toCssString(),
                                };
                              }
                              if (element.localName == 'blockquote') {
                                return {
                                  'background-color': context.theme.colorScheme.primary.withOpacity(0.07).toCssString(),
                                  'padding': '8px',
                                  'border-left': '3px solid ${context.theme.colorScheme.primary.toCssString()}',
                                };
                              }
                              if (element.localName == 'code') {
                                return {
                                  'font-family': 'monospace',
                                  'font-size': '12px',
                                  'background-color': context.theme.colorScheme.surfaceContainer.toCssString(),
                                  'color': context.theme.colorScheme.primary.toCssString(),
                                };
                              }
                              if (element.localName == 'a') {
                                return {
                                  'color': context.theme.colorScheme.primary.toCssString(),
                                  'text-decoration': 'underline',
                                };
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],

                    if (user.favourites?.anime.isNotEmpty ?? false) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(
                            context, "Favourite Anime", IconlyBold.video),
                      ),
                      const SizedBox(height: 10),
                      _buildMediaFavCarousel(context, user.favourites!.anime),
                    ],

                    if (user.favourites?.manga.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(
                            context, "Favourite Manga", IconlyBold.document),
                      ),
                      const SizedBox(height: 10),
                      _buildMediaFavCarousel(context, user.favourites!.manga),
                    ],

                    if (user.favourites?.characters.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(context,
                            "Favourite Characters", IconlyBold.profile),
                      ),
                      const SizedBox(height: 10),
                      _buildPersonCarousel(
                          context,
                          user.favourites!.characters
                              .map((c) =>
                                  _PersonItem(name: c.name, image: c.image))
                              .toList()),
                    ],

                    if (user.favourites?.staff.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(
                            context, "Favourite Staff", Icons.people_rounded),
                      ),
                      const SizedBox(height: 10),
                      _buildPersonCarousel(
                          context,
                          user.favourites!.staff
                              .map((s) =>
                                  _PersonItem(name: s.name, image: s.image))
                              .toList()),
                    ],

                    if (user.favourites?.studios.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(context, "Favourite Studios",
                            Icons.business_rounded),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.favourites!.studios
                              .map(
                                (studio) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: context
                                        .theme.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: context.theme.colorScheme
                                          .outlineVariant
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    studio.name ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          context.theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, String avatarUrl, String? bannerUrl, String name) {
    final hasBanner = bannerUrl != null && bannerUrl.trim().isNotEmpty;
    final imageUrl = hasBanner ? bannerUrl : avatarUrl;

    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
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
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: context.theme.colorScheme.surfaceContainer),
            ),
            if (!hasBanner)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: context.theme.colorScheme.surface.withOpacity(0.2),
                ),
              ),
            Container(
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarAndName(
      BuildContext context, String avatarUrl, String name) {
    final handler = Get.find<ServiceHandler>();
    final expiry = handler.profileData.value.tokenExpiry;

    String expiryText = "";
    if (expiry != null) {
      final days = expiry.difference(DateTime.now()).inDays;
      final months = (days / 30).floor();
      expiryText = "Reconnect in $months months";
    }

    return Transform.translate(
      offset: const Offset(0, -50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: context.theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: context.theme.colorScheme.surfaceContainer,
              backgroundImage: NetworkImage(avatarUrl),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
              fontSize: 26,
              fontFamily: 'Poppins-Bold',
              fontWeight: FontWeight.w700,
              color: context.theme.colorScheme.onSurface,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  context.theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Anilist Member",
              style: TextStyle(
                fontSize: 12,
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
                color:
                    context.theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildHighlightCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
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

  Widget _buildScoreCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
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
            "$value%",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins-SemiBold',
            color: context.theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 16, color: context.theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaFavCarousel(
      BuildContext context, List<FavouriteMedia> items) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.only(right: 10),
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
                    errorBuilder: (_, __, ___) => Container(
                      width: 112,
                      height: 150,
                      color: context.theme.colorScheme.surfaceContainer,
                    ),
                  )
                : Container(
                    width: 112,
                    height: 150,
                    color: context.theme.colorScheme.surfaceContainer,
                  ),
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

  Widget _buildPersonCarousel(
      BuildContext context, List<_PersonItem> items) {
    return SizedBox(
      height: 128,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.only(right: 10),
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
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.colorScheme.surfaceContainer,
                      ),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.colorScheme.surfaceContainer,
                    ),
                  ),
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
}

class _PersonItem {
  final String? name;
  final String? image;

  const _PersonItem({this.name, this.image});
}
