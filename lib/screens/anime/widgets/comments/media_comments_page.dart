import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:flutter/material.dart';

class MediaCommentsPage extends StatelessWidget {
  final Media media;
  final int initialProgress;
  final String? scrollToCommentId;

  const MediaCommentsPage({
    super.key,
    required this.media,
    this.initialProgress = 0,
    this.scrollToCommentId,
  });

  @override
  Widget build(BuildContext context) {
    return MediaDetailsPage(
      media: media,
      tag: '${media.uniqueId}_comments',
      initialTabIndex: 2,
      scrollToCommentId: scrollToCommentId,
    );
  }
}
