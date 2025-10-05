import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Get.find<AnilistAuth>();
    final profileData = Get.find<ServiceHandler>().profileData;
    return Glow(
      child: Scaffold(
        body: Obx(
          () {
            return ScrollWrapper(
              comfortPadding: false,
              customPadding: const EdgeInsets.all(0),
              children: [
                Stack(
                  children: [
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
                                NetworkImage(profileData.value.avatar ?? ''),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          profileData.value.name ?? 'Guest',
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Poppins-SemiBold',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // _buildStatContainer(
                            //   context,
                            //   isFirst: true,
                            //   isLast: false,
                            //   label: 'Followers',
                            //   value: profileData.value.followers?.toString() ??
                            //       '0',
                            // ),
                            // _buildStatContainer(
                            //   context,
                            //   isFirst: false,
                            //   isLast: false,
                            //   label: 'Following',
                            //   value: profileData.value.following?.toString() ??
                            //       '0',
                            // ),
                            _buildStatContainer(
                              context,
                              isFirst: true,
                              isLast: false,
                              label: 'Anime',
                              value: profileData
                                      .value.stats?.animeStats?.animeCount
                                      ?.toString() ??
                                  '0',
                            ),
                            _buildStatContainer(
                              context,
                              isFirst: false,
                              isLast: true,
                              label: 'Manga',
                              value: profileData
                                      .value.stats?.mangaStats?.mangaCount
                                      ?.toString() ??
                                  '0',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withValues(alpha: 0.3),
                                ),
                                child: Column(
                                  children: [
                                    StatsRow(
                                      name: 'Episodes Watched',
                                      value: profileData.value.stats?.animeStats
                                              ?.episodesWatched
                                              ?.toString() ??
                                          '0',
                                    ),
                                    StatsRow(
                                      name: 'Minutes Watched',
                                      value: profileData.value.stats?.animeStats
                                              ?.minutesWatched
                                              ?.toString() ??
                                          '0',
                                    ),
                                    StatsRow(
                                      name: 'Anime Mean Score',
                                      value: profileData.value.stats?.animeStats
                                              ?.meanScore
                                              ?.toString() ??
                                          '0',
                                    ),
                                    StatsRow(
                                      name: 'Chapters Read',
                                      value: profileData.value.stats?.mangaStats
                                              ?.chaptersRead
                                              ?.toString() ??
                                          '0',
                                    ),
                                    StatsRow(
                                      name: 'Volume Read',
                                      value: profileData.value.stats?.mangaStats
                                              ?.volumesRead
                                              ?.toString() ??
                                          '0',
                                    ),
                                    StatsRow(
                                      name: 'Manga Mean Score',
                                      value: profileData.value.stats?.mangaStats
                                              ?.meanScore
                                              ?.toString() ??
                                          '0',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ReusableCarousel(
                          data: data.currentlyWatching,
                          title: "Currently Watching",
                          variant: DataVariant.anilist,
                        ),
                        ReusableCarousel(
                          data: data.currentlyReading,
                          title: "Currently Reading",
                          variant: DataVariant.anilist,
                        )
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatContainer(
    context, {
    required String label,
    required String value,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      width: Get.width * 0.4,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.3),
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
              color: Theme.of(context)
                  .colorScheme
                  .onSecondaryContainer
                  .withOpacity(0.7),
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
