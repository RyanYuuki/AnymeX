import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///
class ListStatusCard extends StatelessWidget {
  final String title;
  final List<TypeStat> statuses;
  final int userId;
  final String userName;
  final bool isAnime;

  const ListStatusCard({
    super.key,
    required this.title,
    required this.statuses,
    required this.userId,
    required this.userName,
    required this.isAnime,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        getResponsiveValue(context, mobileValue: false, desktopValue: true);
    final order = ['CURRENT', 'COMPLETED', 'PAUSED', 'DROPPED', 'PLANNING'];

    final statusConfig = {
      'CURRENT': {
        'label': title == 'ANIME LIST' ? 'Watching' : 'Reading',
        'color': Colors.blue.shade400,
      },
      'COMPLETED': {'label': 'Completed', 'color': Colors.green.shade400},
      'PAUSED': {'label': 'On Hold', 'color': Colors.amber.shade400},
      'DROPPED': {'label': 'Dropped', 'color': Colors.red.shade400},
      'PLANNING': {'label': 'Planning', 'color': Colors.grey.shade400},
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 12 : 10.5,
              fontFamily: 'Poppins-Bold',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 8),
          ...List.generate(order.length, (index) {
            final typeStr = order[index];
            final config = statusConfig[typeStr]!;
            final color = config['color'] as Color;
            final label = config['label'] as String;

            final match = statuses
                .where((s) => s.type.toUpperCase() == typeStr.toUpperCase())
                .toList();
            final count = match.isNotEmpty ? match.first.count : 0;

            final mappedTabForNav = typeStr == 'CURRENT'
                ? (isAnime ? 'WATCHING' : 'READING')
                : (typeStr == 'COMPLETED' && isAnime)
                    ? 'COMPLETED TV'
                    : typeStr;

            return InkWell(
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final auth = Get.find<AnilistAuth>();
                final type = isAnime ? 'ANIME' : 'MANGA';
                final lists = await auth.fetchUserMediaList(userId, type);

                if (context.mounted) Navigator.pop(context);

                final data = lists['All'] ?? [];
                if (isAnime) {
                  Get.to(() => AnimeList(
                        data: data,
                        title: "Anime",
                        initialTab: mappedTabForNav,
                      ));
                } else {
                  Get.to(() => AnilistMangaList(
                        initialTab: mappedTabForNav,
                      ));
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 4.0 : 1.5),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: isDesktop ? 15 : 13,
                            fontFamily: 'Poppins-Bold',
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? color : color.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    if (index < order.length - 1)
                      Divider(
                        height: isDesktop ? 24 : 14,
                        thickness: 0.5,
                        color: context.theme.colorScheme.outlineVariant
                            .withOpacity(0.2),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
