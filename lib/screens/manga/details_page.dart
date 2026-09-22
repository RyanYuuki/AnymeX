import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';

class MangaDetailsPage extends StatelessWidget {
  final Media media;
  final String tag;
  final int initialTabIndex;
  final String? scrollToCommentId;

  const MangaDetailsPage({
    super.key,
    required this.media,
    required this.tag,
    this.initialTabIndex = 0,
    this.scrollToCommentId,
  });

  @override
  Widget build(BuildContext context) {
    if (media.mediaType == ItemType.anime) {
      media.mediaType = ItemType.manga;
    }
    return MediaDetailsPage(
      media: media,
      tag: tag,
      initialTabIndex: initialTabIndex,
      scrollToCommentId: scrollToCommentId,
    );
  }
}
