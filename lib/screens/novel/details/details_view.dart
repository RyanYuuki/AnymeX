import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';

class NovelDetailsPage extends StatelessWidget {
  final Media media;
  final Source? source;
  final String tag;

  const NovelDetailsPage({
    super.key,
    required this.media,
    this.source,
    this.tag = '',
  });

  @override
  Widget build(BuildContext context) {
    return MediaDetailsPage(
      media: media,
      tag: tag,
      source: source,
    );
  }
}
