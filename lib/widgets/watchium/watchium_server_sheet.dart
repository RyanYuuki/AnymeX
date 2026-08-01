import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/watch/watch_view.dart';
import 'package:anymex/screens/anime/widgets/track_dialog.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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

  AnymexSheet.custom(
    _WatchiumServerSheetContent(content: content),
    context,
    showDragHandle: true,
  );
}

class _WatchiumServerSheetContent extends StatelessWidget {
  final WatchiumAnimeContent content;
  const _WatchiumServerSheetContent({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final servers = content.availableServers;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, theme),
        const Divider(height: 1, thickness: 0.5),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: servers
                .map(
                  (server) => _ServerTile(
                    server: server,
                    onTap: () {
                      Navigator.pop(context);
                      _openPlayer(context, server);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryContainer.opaque(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(HugeIcons.strokeRoundedPlay,
                size: 20, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnymexText(
                    text: 'Choose Quality',
                    variant: TextVariant.bold,
                    size: 16),
                AnymexText(
                  text: 'Select streaming server quality to watch',
                  size: 12,
                  color: theme.onSurface.opaque(0.5),
                ),
              ],
            ),
          ),
          AnymexOnTap(
            onTap: () => Navigator.pop(context),
            child:
                Icon(Icons.close_rounded, color: theme.onSurface.opaque(0.5)),
          ),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context, WatchiumAnimeServer server) async {
    final video = server.toVideo();
    if (video.url == null || video.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This server has no playable URL')),
      );
      return;
    }

    final allTracks = content.availableServers
        .where((s) => s.url != null && s.url!.isNotEmpty)
        .map((s) => s.toVideo())
        .toList();

    final episode = Episode(
      number: content.episodeNumber.toString(),
      title: 'Episode ${content.episodeNumber}',
    );

    final animeId = content.anilistId?.toString() ??
        content.malId?.toString() ??
        content.animeId;
    final media = Media(
      id: animeId,
      idMal: content.malId?.toString() ?? '0',
      title: content.animeTitle,
      romajiTitle: content.animeTitle,
      poster: content.animeCoverImage ?? '?',
      largePoster: content.animeCoverImage ?? '?',
      totalEpisodes: content.totalEpisodes?.toString() ?? '?',
      serviceType: ServicesType.anilist,
    );

    final dbId = '${animeId}_${ServicesType.anilist.name}_anime';
    final savedTracking = DynamicKeys.trackingPermission.get<bool?>(dbId);
    bool shouldTrack = false;

    if (savedTracking != null) {
      shouldTrack = savedTracking;
    } else if (General.shouldAskForTrack.get(true)) {
      shouldTrack = await showTrackingDialog(context, dbId: dbId) ?? false;
    }

    navigate(
      () => WatchScreen(
        episodeSrc: video,
        currentEpisode: episode,
        episodeList: [episode],
        anilistData: media,
        episodeTracks: allTracks,
        shouldTrack: shouldTrack,
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final WatchiumAnimeServer server;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final hasUrl = server.url != null && server.url!.isNotEmpty;
    final isHls = server.type.toLowerCase() == 'hls';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnymexOnTap(
        onTap: hasUrl ? onTap : null,
        child: Opacity(
          opacity: hasUrl ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.surfaceContainer.opaque(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.outline.opaque(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasUrl
                        ? theme.primaryContainer.opaque(0.3)
                        : theme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    hasUrl
                        ? Icons.play_arrow_rounded
                        : Icons.block,
                    size: 16,
                    color: hasUrl
                        ? theme.primary
                        : theme.onSurface.opaque(0.3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexText(
                        text: (server.quality ?? server.serverName)
                            .toUpperCase(),
                        variant: TextVariant.bold,
                        size: 14,
                        maxLines: 10,
                      ),
                      if (server.quality != null) ...[
                        const SizedBox(height: 2),
                        AnymexText(
                          text: server.serverName.toUpperCase(),
                          variant: TextVariant.semiBold,
                          size: 11,
                          color: theme.onSurface.opaque(0.6),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isHls)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text('HLS',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text('Direct',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
