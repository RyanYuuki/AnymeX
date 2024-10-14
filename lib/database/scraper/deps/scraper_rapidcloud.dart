import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;

class Video {
  final String url;
  final bool isM3U8;
  final String? quality;

  Video({required this.url, required this.isM3U8, this.quality});
}

class Subtitle {
  final String url;
  final String lang;

  Subtitle({required this.url, required this.lang});
}

class Intro {
  final int start;
  final int end;

  Intro({required this.start, required this.end});
}

class RapidCloud {
  final String serverName = "RapidCloud";
  final List<Video> sources = [];
  final String fallbackKey = "c1d17096f2ca11b7";
  final String host = "https://rapid-cloud.co";

  String substringAfter(String str, String toFind) {
    final index = str.indexOf(toFind);
    return index == -1 ? "" : str.substring(index + toFind.length);
  }

  String substringBefore(String str, String toFind) {
    final index = str.indexOf(toFind);
    return index == -1 ? "" : str.substring(0, index);
  }

  Future<Map<String, dynamic>> extract(Uri videoUrl) async {
    final Map<String, dynamic> result = {
      'sources': [],
      'subtitles': [],
      'intro': null,
      'outro': null,
    };

    try {
      final String? id = videoUrl.pathSegments.last.split("?")[0];
      final Map<String, String> headers = {
        "X-Requested-With": "XMLHttpRequest",
      };

      final res = await http.get(
        Uri.parse('$host/embed-2/ajax/e-1/getSources?id=$id'),
        headers: headers,
      );
      final responseData = json.decode(res.body);

      List<dynamic> sources = responseData['sources'];
      final List<dynamic> tracks = responseData['tracks'];
      final Map<String, dynamic>? intro = responseData['intro'];
      final Map<String, dynamic>? outro = responseData['outro'];
      final bool encrypted = responseData['encrypted'];

      String decryptKey = await _getDecryptKey();

      if (encrypted) {
        sources = await _decryptSources(responseData['sources'], decryptKey);
      }

      result['sources'] = sources.map((s) {
        return Video(
          url: s['file'],
          isM3U8: s['file'].contains(".m3u8"),
          quality: 'auto',
        ).toJson();
      }).toList();

      result['subtitles'] = tracks
          .map((s) => s['file'] != null
              ? Subtitle(url: s['file'], lang: s['label'] ?? "Thumbnails")
                  .toJson()
              : null)
          .where((s) => s != null)
          .toList();

      if (intro != null && intro['end'] > 1) {
        result['intro'] = Intro(start: intro['start'], end: intro['end']);
      }

      if (outro != null && outro['end'] > 1) {
        result['outro'] = Intro(start: outro['start'], end: outro['end']);
      }

      return result;
    } catch (err) {
      print(err.toString());
      throw Exception('Error during extraction');
    }
  }

  Future<String> _getDecryptKey() async {
    final res = await http.get(
        Uri.parse('https://raw.githubusercontent.com/cinemaxhq/keys/e1/key'));
    String decryptKey = res.body;
    decryptKey = substringBefore(
        substringAfter(decryptKey, '"blob-code blob-code-inner js-file-line">'),
        "</td>");

    return decryptKey.isNotEmpty ? decryptKey : fallbackKey;
  }

  Future<List<dynamic>> _decryptSources(
      String encryptedSources, String key) async {
    final keyBytes = encrypt.Key.fromUtf8(key);
    final iv =
        encrypt.IV.fromLength(16); // Assuming the IV is zero bytes for AES
    final encrypter = encrypt.Encrypter(encrypt.AES(keyBytes));

    final decryptedData = encrypter.decrypt64(encryptedSources, iv: iv);
    return json.decode(decryptedData);
  }
}

extension on Video {
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isM3U8': isM3U8,
      'quality': quality,
    };
  }
}

extension on Subtitle {
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'lang': lang,
    };
  }
}

extension on Intro {
  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }
}
