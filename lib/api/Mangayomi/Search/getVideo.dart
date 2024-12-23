import '../Eval/dart/model/video.dart';
import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<List<Video>> getVideo({
  required Source source,
  required String url,
}) async {
  List<Video> list = [];
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    list = await DartExtensionService(source).getVideoList(url);
  } else {
    list = await JsExtensionService(source).getVideoList(url);
  }
  List<Video> videos = [];
  for (var video in list) {
    if (!videos.any((element) => element.quality == video.quality)) {
      videos.add(video);
    }
  }
  return videos..sort((a, b) => a.quality.compareTo(b.quality));
}
