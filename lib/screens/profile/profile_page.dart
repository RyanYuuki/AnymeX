import 'dart:ui';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:flutter/material.dart';
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
          final bannerUrl = user.avatar ?? '';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, bannerUrl, user.name ?? 'Guest'),
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
                    const SizedBox(height: 30),
                    ReusableCarousel(
                      data: authController.currentlyWatching,
                      title: "Currently Watching",
                      variant: DataVariant.anilist,
                    ),
                    const SizedBox(height: 10),
                    ReusableCarousel(
                      data: authController.currentlyReading,
                      title: "Currently Reading",
                      variant: DataVariant.anilist,
                    ),
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
      BuildContext context, String imageUrl, String name) {
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
}
