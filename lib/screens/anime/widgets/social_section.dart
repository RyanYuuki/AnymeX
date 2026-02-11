import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class SocialSection extends StatelessWidget {
  final List<TrackedMedia> friends;
  const SocialSection({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();
    final theme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: AnymexText(text: "Social", variant: TextVariant.bold, size: 18, color: theme.primary),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final user = friends[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(user.userAvatar ?? ''),
                        ),
                        if (user.userScore != null && user.userScore! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AnymexText(
                              text: (user.userScore! / 10).toStringAsFixed(1),
                              size: 10,
                              color: theme.onPrimary,
                              variant: TextVariant.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnymexText(text: user.userName ?? '', size: 12, maxLines: 1, overflow: TextOverflow.ellipsis),
                    AnymexText(
                      text: "${user.watchingStatus} (${user.userProgress})",
                      size: 10,
                      color: theme.onSurface.withOpacity(0.6),
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
