import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/watch/watch_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet with servers from the room's content data.
/// When the user picks a server, the player opens directly.
void showWatchiumServerSheet({
  required BuildContext context,
  required WatchiumAnimeContent content,
}) {
  final servers = content.availableServers;
  if (servers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No servers available for this room')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _WatchiumServerSheet(content: content),
  );
}

class _WatchiumServerSheet extends StatelessWidget {
  final WatchiumAnimeContent content;
  const _WatchiumServerSheet({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servers = content.availableServers;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.opaque(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          AnymexText(
            text: content.animeTitle,
            size: 16,
            variant: TextVariant.semiBold,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          AnymexText(
            text: 'Episode ${content.episodeNumber}',
            size: 13,
            color: theme.colorScheme.onSurface.opaque(0.6),
          ),
          const SizedBox(height: 16),

          // Servers header
          Align(
            alignment: Alignment.centerLeft,
            child: AnymexText(
              text: 'Select Server',
              size: 13,
              variant: TextVariant.semiBold,
              color: theme.colorScheme.onSurface.opaque(0.7),
            ),
          ),
          const SizedBox(height: 8),

          // Server list
          ...servers.map(
            (server) => _ServerTile(
              server: server,
              content: content,
              onTap: () {
                Navigator.pop(context);
                _openPlayer(context, server);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context, WatchiumAnimeServer server) {
    final video = server.toVideo();
    if (video.url == null || video.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This server has no playable URL')),
      );
      return;
    }

    // Build all video tracks from available servers
    final allTracks = content.availableServers
        .where((s) => s.url != null && s.url!.isNotEmpty)
        .map((s) => s.toVideo())
        .toList();

    // Create a minimal Episode object
    final episode = Episode(
      number: content.episodeNumber.toString(),
      title: 'Episode ${content.episodeNumber}',
    );

    // Create a minimal Media object for the player
    final media = Media(
      id: content.anilistId?.toString() ??
          content.malId?.toString() ??
          content.animeId,
      title: content.animeTitle,
      romajiTitle: content.animeTitle,
      poster: content.animeCoverImage ?? '?',
      largePoster: content.animeCoverImage ?? '?',
      totalEpisodes: content.totalEpisodes?.toString() ?? '?',
      serviceType: ServicesType.anilist,
    );

    navigate(
      () => WatchScreen(
        episodeSrc: video,
        currentEpisode: episode,
        episodeList: [episode],
        anilistData: media,
        episodeTracks: allTracks,
        shouldTrack: false,
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final WatchiumAnimeServer server;
  final WatchiumAnimeContent content;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = server.url != null && server.url!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: hasUrl ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.opaque(0.15),
              ),
            ),
            child: Row(
              children: [
                // Server icon based on type
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasUrl
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _typeIcon(server.type),
                    size: 18,
                    color: hasUrl
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.opaque(0.3),
                  ),
                ),
                const SizedBox(width: 12),
                // Server info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexText(
                        text: server.serverName,
                        size: 14,
                        variant: TextVariant.semiBold,
                      ),
                      if (server.quality != null) ...[
                        const SizedBox(height: 2),
                        AnymexText(
                          text: server.quality!,
                          size: 11,
                          color: theme.colorScheme.onSurface.opaque(0.5),
                        ),
                      ],
                    ],
                  ),
                ),
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AnymexText(
                    text: server.type.toUpperCase(),
                    size: 10,
                    color: theme.colorScheme.onSurface.opaque(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                if (!hasUrl)
                  Icon(
                    Icons.block,
                    size: 16,
                    color: theme.colorScheme.error.opaque(0.6),
                  )
                else
                  Icon(
                    Icons.play_arrow,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hls':
        return Icons.stream;
      case 'mp4':
        return Icons.video_file;
      case 'dash':
        return Icons.dns;
      case 'embedded':
        return Icons.web;
      default:
        return Icons.tv;
    }
  }
}
