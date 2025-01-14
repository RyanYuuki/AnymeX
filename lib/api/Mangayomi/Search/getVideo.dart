import '../../../models/Offline/Hive/video.dart';
import '../Model/Source.dart';
import '../lib.dart';

Future<List<Video>> getVideo({
  required Source source,
  required String url,
}) async {
  List<Video> list =
  await getExtensionService(source).getVideoList(url);

  List<Video> videos = [];
  for (var video in list) {
    if (!videos.any((element) => element.quality == video.quality)) {
      videos.add(video);
    }
  }
  return videos..sort((a, b) => a.quality.compareTo(b.quality));
}
