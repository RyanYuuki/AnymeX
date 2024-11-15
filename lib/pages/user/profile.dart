import 'dart:ui';
import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/components/anilistExclusive/animeListCarousels.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  dynamic filterData(dynamic animeList) {
    if (animeList != null) {
      return animeList.where((anime) => anime['status'] == 'CURRENT').toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AniListProvider>(
        builder: (context, anilistProvider, child) {
          final isLoggedIn = anilistProvider.userData?['user']?['id'] != null;
          final userName =
              isLoggedIn ? anilistProvider.userData?['user']?['name'] : 'Guest';
          final avatarUrl = isLoggedIn
              ? (anilistProvider.userData?['user']?['avatar']?['large'])
              : null;
          final totalWatchedAnimes = isLoggedIn
              ? anilistProvider.userData?['user']?['statistics']?['anime']
                  ?['count']
              : 0;
          final totalReadManga = isLoggedIn
              ? anilistProvider.userData?['user']?['statistics']?['manga']
                  ?['count']
              : 0;
          final followers = isLoggedIn ? 0 : 0;
          final following = isLoggedIn ? 0 : 0;
          final hasAvatarImage = avatarUrl != null;
          final animeList = filterData(anilistProvider.userData['animeList']);
          final mangaList = filterData(anilistProvider.userData['mangaList']);

          return ListView(
            children: [
              Stack(
                children: [
                  Positioned(
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: [
                        if (hasAvatarImage)
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: SizedBox.expand(
                                child: Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.8),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context).colorScheme.surface,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0, 1],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 15,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(IconlyBold.arrow_left),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 70),
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          backgroundImage:
                              hasAvatarImage ? NetworkImage(avatarUrl) : null,
                          child: !hasAvatarImage
                              ? Icon(
                                  Icons.person,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatContainer(
                            isFirst: true,
                            isLast: false,
                            label: 'Followers',
                            value: followers.toString(),
                          ),
                          _buildStatContainer(
                            isFirst: false,
                            isLast: false,
                            label: 'Following',
                            value: following.toString(),
                          ),
                          _buildStatContainer(
                            isFirst: false,
                            isLast: false,
                            label: 'Anime',
                            value: totalWatchedAnimes.toString(),
                          ),
                          _buildStatContainer(
                            isFirst: false,
                            isLast: true,
                            label: 'Manga',
                            value: totalReadManga.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stats',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              margin: const EdgeInsets.all(5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                              ),
                              child: Column(
                                children: [
                                  StatsRow(
                                    name: 'Episodes Watched',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['anime']
                                                ?['episodesWatched']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                    name: 'Minutes Watched',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['anime']
                                                ?['minutesWatched']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                      name: 'Anime Mean Score',
                                      value: anilistProvider.userData['user']
                                                  ?['statistics']?['anime']
                                                  ?['meanScore']
                                              ?.toString() ??
                                          '0.0'),
                                  StatsRow(
                                    name: 'Chapters Read',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['manga']
                                                ?['chaptersRead']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                    name: 'Volume Read',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['manga']
                                                ?['volumeRead']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                    name: 'Manga Mean Score',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['manga']
                                                ?['meanScore']
                                            ?.toString() ??
                                        '0.0',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      anilistCarousel(
                        title: 'Currently Watching',
                        carouselData: animeList,
                        tag: 'currently-watching',
                      ),
                      anilistCarousel(
                        title: 'Currently Reading',
                        carouselData: mangaList,
                        tag: 'currently-reading',
                        isManga: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatContainer({
    required String label,
    required String value,
    required bool isFirst,
    required bool isLast,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.23,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(10) : Radius.zero,
          bottomLeft: isFirst ? const Radius.circular(10) : Radius.zero,
          topRight: isLast ? const Radius.circular(10) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'Poppins-SemiBold',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final String name;
  final String value;
  const StatsRow({
    super.key,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.inverseSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
