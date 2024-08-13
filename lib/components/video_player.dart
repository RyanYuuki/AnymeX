import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lecle_yoyo_player/lecle_yoyo_player.dart';

class VideoPlayer extends StatelessWidget {
  final String? videoUrl;
  const VideoPlayer({super.key, this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return YoYoPlayer(
      aspectRatio: 16 / 9,
      url: videoUrl!,
      videoStyle: const VideoStyle(
        qualityStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        forwardAndBackwardBtSize: 30.0,
        playButtonIconSize: 40.0,
        playIcon: Icon(
          IconlyBold.play,
          size: 40.0,
          color: Colors.white,
        ),
        pauseIcon: Icon(
          Iconsax.pause,
          size: 40.0,
          color: Colors.white,
        ),
        videoQualityPadding: EdgeInsets.all(5.0),
      ),
      videoLoadingStyle: const VideoLoadingStyle(
        loading: Center(
          child: Text("Loading video"),
        ),
      ),
      allowCacheFile: true,
      onCacheFileCompleted: (files) {
        print('Cached file length ::: ${files?.length}');

        if (files != null && files.isNotEmpty) {
          for (var file in files) {
            print('File path ::: ${file.path}');
          }
        }
      },
      onCacheFileFailed: (error) {
        print('Cache file error ::: $error');
      },
    );
  }
}
