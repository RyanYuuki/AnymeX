import 'dart:convert';
import 'package:http/http.dart' as http;

const String USER_AGENT_HEADER =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36';

class Video {
  final String url;
  final String? quality;
  final bool isM3U8;

  Video({required this.url, this.quality, required this.isM3U8});
}

class StreamSB {
  final String _serverName = 'streamSB';
  final List<Video> _sources = [];
  final String _host = 'https://watchsb.com/sources50';
  final String _host2 = 'https://streamsss.net/sources16';

  String _payload(String hex) {
    return '566d337678566f743674494a7c7c${hex}7c7c346b6767586d6934774855537c7c73747265616d7362/6565417268755339773461447c7c346133383438333436313335376136323337373433383634376337633465366534393338373136643732373736343735373237613763376334363733353737303533366236333463353333363534366137633763373337343732363536313664373336327c7c6b586c3163614468645a47617c7c73747265616d7362';
  }

  Future<List<Video>> extract(Uri videoUrl, {bool isAlt = false}) async {
    var headers = {
      'watchsb': 'sbstream',
      'Referer': videoUrl.toString(),
      'User-Agent': USER_AGENT_HEADER,
    };

    String? id = videoUrl.pathSegments.last;
    if (id.contains('html')) {
      id = id.split('.html')[0];
    }

    final bytes = utf8.encode(id);
    final hex = base64.encode(bytes).replaceAll('=', '');

    final response = await http.get(
      Uri.parse('${isAlt ? _host2 : _host}/${_payload(hex)}'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('No source found. Try a different server');
    }

    final jsonResponse = json.decode(response.body);
    if (jsonResponse['stream_data'] == null) {
      throw Exception('No source found. Try a different server');
    }

    headers = {
      'User-Agent': USER_AGENT_HEADER,
      'Referer': videoUrl.toString().split('e/')[0],
    };

    final m3u8Response = await http.get(
      Uri.parse(jsonResponse['stream_data']['file']),
      headers: headers,
    );

    final videoList = m3u8Response.body.split('#EXT-X-STREAM-INF:');

    for (final video in videoList) {
      if (!video.contains('m3u8')) continue;
      final url = video.split('\n')[1];
      final quality = video.split('RESOLUTION=')[1].split(',')[0].split('x')[1];
      _sources.add(Video(
        url: url,
        quality: '${quality}p',
        isM3U8: true,
      ));
    }

    _sources.add(Video(
      url: jsonResponse['stream_data']['file'],
      quality: 'auto',
      isM3U8: jsonResponse['stream_data']['file'].contains('.m3u8'),
    ));

    return _sources;
  }

  void _addSources(Map<String, dynamic> source) {
    _sources.add(Video(
      url: source['file'],
      isM3U8: source['file'].contains('.m3u8'),
    ));
  }
}
