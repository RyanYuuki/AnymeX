import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';

class AnimeDetailsPage extends StatelessWidget {
  final Media media;
  final String tag;
  final Source? source;
  final int initialTabIndex;

  const AnimeDetailsPage({
    super.key,
    required this.media,
    required this.tag,
    this.source,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MediaDetailsPage(
      media: media,
      tag: tag,
      source: source,
      initialTabIndex: initialTabIndex,
    );
  }
}
