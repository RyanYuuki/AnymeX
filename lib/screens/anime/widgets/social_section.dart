import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class SocialSection extends StatelessWidget {
  final List<TrackedMedia> friends;
  final String? totalEpisodes;
  const SocialSection({super.key, required this.friends, this.totalEpisodes});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();
    final theme = context.colors;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final user = friends[index];
              return _buildFriendItem(user, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendItem(TrackedMedia user, dynamic theme) {
    String status = (user.watchingStatus ?? '').toLowerCase();
    status = status.isNotEmpty 
        ? status[0].toUpperCase() + status.substring(1) 
        : '';
    
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent,
                  backgroundImage: (user.userAvatar != null && user.userAvatar!.isNotEmpty)
                      ? NetworkImage(user.userAvatar!)
                      : const NetworkImage(
                          'https://s4.anilist.co/file/anilistcdn/user/avatar/large/default.png'),
                ),
              ),
              
              if (user.userScore != null && user.userScore! > 0)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 12, color: theme.onPrimary),
                        const SizedBox(width: 4),
                        AnymexText(
                          text: (user.userScore!).toStringAsFixed(1),
                          size: 11,
                          color: theme.onPrimary,
                          variant: TextVariant.bold,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (status.isNotEmpty)
            AnymexText(
              text: status,
              size: 12,
              color: theme.onSurface.withOpacity(0.7),
              fontStyle: FontStyle.italic,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 2),
          AnymexText(
            text: user.userName ?? 'Unknown',
            size: 13,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            variant: TextVariant.bold,
            color: theme.onSurface,
          ),
          const SizedBox(height: 2),
          if (user.userProgress != null)
             Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                children: [
                  TextSpan(
                    text: "${user.userProgress}",
                    style: TextStyle(color: theme.primary),
                  ),
                  TextSpan(
                    text: " | ${totalEpisodes ?? '?'}",
                    style: TextStyle(color: theme.onSurface.withOpacity(0.9)),
                  ),
                ],
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
