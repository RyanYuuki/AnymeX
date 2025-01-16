import 'package:anymex/utils/string_extensions.dart';

import 'package:html/parser.dart' show parse;
import 'package:http_interceptor/http_interceptor.dart';

import '../../../models/Offline/Hive/video.dart';
import '../http/m_client.dart';

class StreamTapeExtractor {
  Future<List<Video>> videosFromUrl(String url,
      {String quality = "StreamTape"}) async {
    final InterceptedClient client =
        MClient.init(reqcopyWith: {'useDartHttpClient': true});
    try {
      const baseUrl = "https://streamtape.com/e/";
      final newUrl =
          !url.startsWith(baseUrl) ? "$baseUrl${url.split("/")[4]}" : url;

      final response = await client.get(Uri.parse(newUrl));
      final document = parse(response.body);

      const targetLine = "document.getElementById('robotlink')";
      String script = "";
      final scri = document
          .querySelectorAll("script")
          .where((element) => element.innerHtml.contains(targetLine))
          .map((e) => e.innerHtml)
          .toList();
      if (scri.isEmpty) {
        return [];
      }
      script = scri.first.split("$targetLine.innerHTML = '").last;
      final videoUrl =
          "https:${script.substringBefore("'")}${script.substringAfter("+ ('xcd").substringBefore("'")}";

      return [Video(videoUrl, quality, videoUrl)];
    } catch (_) {
      return [];
    }
  }
}
