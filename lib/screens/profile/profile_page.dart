import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/screens/anime/widgets/character_staff_sheet.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/function.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bannerController;
  late final Animation<Alignment> _bannerAnim;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _bannerAnim = Tween<Alignment>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _buildSliverAppBar(context, bannerUrl, user.cover,
                  user.name ?? 'Guest', _bannerAnim),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
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
                                  user.stats?.animeStats?.animeCount
                                          ?.toString() ??
                                      '0',
                                  IconlyBold.video,
                                  context.theme.colorScheme.primary,
                                  () => navigate(
                                      () => const AnimeList(initialTab: 'ALL')),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildHighlightCard(
                                  context,
                                  'Manga',
                                  user.stats?.mangaStats?.mangaCount
                                          ?.toString() ??
                                      '0',
                                  IconlyBold.document,
                                  context.theme.colorScheme.secondary,
                                  () => navigate(() => const AnilistMangaList(
                                      initialTab: 'ALL')),
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
                              color:
                                  context.theme.colorScheme.surfaceContainerLow,
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
                                    IconlyLight.play),
                                const Divider(height: 24, thickness: 0.5),
                                _buildStatRow(
                                    context,
                                    "Minutes Watched",
                                    user.stats?.animeStats?.minutesWatched
                                            ?.toString() ??
                                        '0',
                                    IconlyLight.time_circle),
                                const Divider(height: 24, thickness: 0.5),
                                _buildStatRow(
                                    context,
                                    "Chapters Read",
                                    user.stats?.mangaStats?.chaptersRead
                                            ?.toString() ??
                                        '0',
                                    IconlyLight.paper),
                                const Divider(height: 24, thickness: 0.5),
                                _buildStatRow(
                                    context,
                                    "Volumes Read",
                                    user.stats?.mangaStats?.volumesRead
                                            ?.toString() ??
                                        '0',
                                    IconlyLight.bookmark),
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
                        if (user.about != null &&
                            user.about!.trim().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildSectionHeader(
                                context, "About", IconlyLight.profile),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: context
                                    .theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context
                                      .theme.colorScheme.outlineVariant
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: AnilistAboutMe(about: user.about!),
                            ),
                          ),
                        ],
                        if (user.favourites?.anime.isNotEmpty ?? false) ...[
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildSectionHeader(
                                context, "Favourite Anime", IconlyBold.video),
                          ),
                          const SizedBox(height: 10),
                          _buildMediaFavCarousel(
                              context, user.favourites!.anime, true),
                        ],
                        if (user.favourites?.manga.isNotEmpty ?? false) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildSectionHeader(context,
                                "Favourite Manga", IconlyBold.document),
                          ),
                          const SizedBox(height: 10),
                          _buildMediaFavCarousel(
                              context, user.favourites!.manga, false),
                        ],
                        if (user.favourites?.characters.isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildSectionHeader(context,
                                "Favourite Characters", IconlyBold.profile),
                          ),
                          const SizedBox(height: 10),
                          _buildPersonCarousel(
                              context,
                              user.favourites!.characters
                                  .map((c) => _PersonItem(
                                      id: c.id, name: c.name, image: c.image))
                                  .toList(),
                              true),
                        ],
                        if (user.favourites?.staff.isNotEmpty ?? false) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildSectionHeader(context,
                                "Favourite Staff", Icons.people_rounded),
                          ),
                          const SizedBox(height: 10),
                          _buildPersonCarousel(
                              context,
                              user.favourites!.staff
                                  .map((s) => _PersonItem(
                                      id: s.id, name: s.name, image: s.image))
                                  .toList(),
                              false),
                        ],
                        if (user.favourites?.studios.isNotEmpty ?? false) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildSectionHeader(context,
                                "Favourite Studios", Icons.business_rounded),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
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
                                          color: context
                                              .theme.colorScheme.outlineVariant
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        studio.name ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context
                                              .theme.colorScheme.onSurface,
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
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String avatarUrl,
      String? bannerUrl, String name, Animation<Alignment> bannerAnim) {
    final hasBanner = bannerUrl != null && bannerUrl.trim().isNotEmpty;
    final imageUrl = hasBanner ? bannerUrl : avatarUrl;

    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = (screenHeight * 0.35).clamp(220.0, 400.0);

    return SliverAppBar(
      expandedHeight: bannerHeight,
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
            AnimatedBuilder(
              animation: bannerAnim,
              builder: (context, child) {
                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: AnymeXImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    alignment: hasBanner ? bannerAnim.value : Alignment.center,
                    radius: 0,
                  ),
                );
              },
            ),
            if (!hasBanner)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                    color: context.theme.colorScheme.surface.withOpacity(0.2)),
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
    String expiryText = '';
    if (expiry != null) {
      final days = expiry.difference(DateTime.now()).inDays;
      if (days < 0) {
        expiryText = 'Token expired. Please reconnect.';
      } else if (days < 30) {
        expiryText = 'Reconnect in $days day(s)';
      } else {
        final months = (days / 30).floor();
        expiryText = 'Reconnect in $months month(s)';
      }
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
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
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
              'Anilist Member',
              style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.primary,
                  fontWeight: FontWeight.w600),
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
      IconData icon, Color color,
      [VoidCallback? onTap]) {
    return _PressableHighlightCard(
      label: label,
      value: value,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildScoreCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value%',
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
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins-SemiBold',
                color: context.theme.colorScheme.onSurface)),
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
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon,
              size: 16, color: context.theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: context.theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildMediaFavCarousel(
      BuildContext context, List<FavouriteMedia> items, bool isAnime) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMediaCard(context, item, isAnime);
        },
      ),
    );
  }

  Widget _buildMediaCard(
      BuildContext context, FavouriteMedia item, bool isAnime) {
    return GestureDetector(
      onTap: () {
        if (item.id != null) {
          final media = Media(
            id: item.id!,
            title: item.title ?? '?',
            poster: item.cover ?? '',
            serviceType: ServicesType.anilist,
          );
          final tag = item.title ?? 'fav-${item.id}';
          if (isAnime) {
            navigate(() => AnimeDetailsPage(media: media, tag: tag));
          } else {
            navigate(() => MangaDetailsPage(media: media, tag: tag));
          }
        }
      },
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: item.title ?? 'fav-${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.cover != null
                    ? CachedNetworkImage(
                        imageUrl: item.cover!,
                        width: 112,
                        height: 150,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                            width: 112,
                            height: 150,
                            color: context.theme.colorScheme.surfaceContainer))
                    : Container(
                        width: 112,
                        height: 150,
                        color: context.theme.colorScheme.surfaceContainer),
              ),
            ),
            const SizedBox(height: 5),
            Text(item.title ?? '',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.theme.colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCarousel(
      BuildContext context, List<_PersonItem> items, bool isCharacter) {
    return SizedBox(
      height: 128,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildPersonCard(
              context, item.id, item.image, item.name, isCharacter);
        },
      ),
    );
  }

  Widget _buildPersonCard(BuildContext context, String? id, String? imageUrl,
      String? name, bool isCharacter) {
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          if (id != null) {
            showCharacterStaffSheet(context,
                item: _PersonItem(id: id, name: name, image: imageUrl),
                isCharacter: isCharacter);
          }
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  context.theme.colorScheme.surfaceContainer)))
                  : Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.theme.colorScheme.surfaceContainer)),
            ),
            const SizedBox(height: 6),
            Text(name ?? '',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: context.theme.colorScheme.onSurface),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PersonItem {
  final String? id;
  final String? name;
  final String? image;
  const _PersonItem({this.id, this.name, this.image});
}

class _PressableHighlightCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _PressableHighlightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_PressableHighlightCard> createState() =>
      _PressableHighlightCardState();
}

class _PressableHighlightCardState extends State<_PressableHighlightCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (pressed) {
              if (_isPressed != pressed) {
                setState(() => _isPressed = pressed);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Icon(widget.icon, color: widget.color, size: 28),
                  const SizedBox(height: 10),
                  Text(widget.value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface)),
                  Text(widget.label,
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
