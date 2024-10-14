import 'dart:convert';
import 'package:http/http.dart' as http;

class Video {
  final String url;
  final String quality;
  final bool isM3U8;

  Video({required this.url, required this.quality, required this.isM3U8});
}

class StreamSB {
  final String serverName = "streamSB";
  final List<Video> sources = [];

  final String host = "https://watchsb.com/sources50";
  final String host2 = "https://streamsss.net/sources16";

  String PAYLOAD(String hex) {
    return '566d337678566f743674494a7c7c${hex}7c7c346b6767586d6934774855537c7c73747265616d7362/6565417268755339773461447c7c346133383438333436313335376136323337373433383634376337633465366534393338373136643732373736343735373237613763376334363733353737303533366236333463353333363534366137633763373337343732363536313664373336327c7c6b586c3163614468645a47617c7c73747265616d7362';
  }

  String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<List<Video>> extract(Uri videoUrl, {bool isAlt = false}) async {
    Map<String, String> headers = {
      'watchsb': 'sbstream',
      'Referer': videoUrl.toString(),
      'User-Agent': 'USER_AGENT_HEADER',
    };

    // Extract ID from URL
    String? id = videoUrl.pathSegments.last.split(".html").first;
    List<int> bytes = utf8.encode(id!);
    String payload = PAYLOAD(bytesToHex(bytes));
    Uri apiUrl = Uri.parse('${isAlt ? host2 : host}/$payload');

    // Fetch stream data with a timeout
    http.Response res;
    try {
      res = await http
          .get(apiUrl, headers: headers)
          .timeout(Duration(seconds: 10));
    } catch (e) {
      throw Exception("Failed to fetch stream data: $e");
    }

    if (res.statusCode != 200 || jsonDecode(res.body)['stream_data'] == null) {
      throw Exception('No source found. Try a different server');
    }

    Map<String, dynamic> streamData = jsonDecode(res.body)['stream_data'];

    headers = {
      'User-Agent': 'USER_AGENT_HEADER',
      'Referer': videoUrl.toString().split('/e/')[0],
    };

    // Fetch M3U8 URLs
    http.Response m3u8Res;
    try {
      m3u8Res = await http
          .get(Uri.parse(streamData['file']), headers: headers)
          .timeout(Duration(seconds: 10));
    } catch (e) {
      throw Exception("Failed to fetch M3U8 data: $e");
    }

    List<String> videoList = m3u8Res.body.split('#EXT-X-STREAM-INF:');

    for (String video in videoList) {
      if (!video.contains('m3u8')) continue;

      String url = video.split('\n')[1];
      String quality =
          video.split('RESOLUTION=')[1].split(',')[0].split('x')[1];

      sources.add(Video(
        url: url,
        quality: '${quality}p',
        isM3U8: true,
      ));
    }

    sources.add(Video(
      url: streamData['file'],
      quality: 'auto',
      isM3U8: streamData['file'].contains('.m3u8'),
    ));

    return sources;
  }
}
