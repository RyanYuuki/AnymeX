// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:lecle_yoyo_player/lecle_yoyo_player.dart';

class StreamingPage extends StatefulWidget {
  final String? id;
  const StreamingPage({super.key, this.id});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Streaming Page'),
        centerTitle: true,
      ),
      body: YoYoPlayer(
        aspectRatio: 16 / 9,
        url: "https://fds.biananset.net/_v7/74a50cfd4c1c68eb65e43d21048f2e2dad2e8db6b42e757ada8fbfd1b4fb38d74b1c23d794f22381a22e44f43c7733f840067afe2e967767eb8a99a3c03102440da0706c30b5e4ed0751e68d7ffd5a686afffad7e16b4c77f16bf345606bdeab79112d52a761e9e003f90a8008a67d833314df0265b6c93971604bd7d00d4179/master.m3u8",
        videoStyle: const VideoStyle(
          qualityStyle: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          forwardAndBackwardBtSize: 30.0,
          playButtonIconSize: 40.0,
          playIcon: Icon(
            Icons.add_circle_outline_outlined,
            size: 40.0,
            color: Colors.white,
          ),
          pauseIcon: Icon(
            Icons.remove_circle_outline_outlined,
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
      ),
    );
  }
}
