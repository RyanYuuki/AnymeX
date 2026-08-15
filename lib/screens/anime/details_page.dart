import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:flutter/material.dart';

class AnimeDetailsPage extends StatelessWidget {
  final Media media;
  final String tag;
  final int initialTabIndex;

  const AnimeDetailsPage({
    super.key,
    required this.media,
    required this.tag,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MediaDetailsPage(
      media: media,
      tag: tag,
      initialTabIndex: initialTabIndex,
    );
  }
}
