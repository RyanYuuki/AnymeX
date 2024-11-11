import "dart:convert";

import "package:http/http.dart";
import "package:html/parser.dart" as html;
import "package:encrypt/encrypt.dart";

class Vidstream {
  final keys = {
    'key': Key.fromUtf8('37911490979715163134003223491201'),
    'secondKey': Key.fromUtf8('54674138327930866480207815084989'),
    'iv': IV.fromUtf8('3134003223491201'),
  };

  final baseUrl = "https://gogoanime3.net";

  Future<dynamic> extract(String streamLink) async {
    if (streamLink.isEmpty) {
      throw Exception("ERR_EMPTY_STREAM_LINK");
    }
    final epLink = Uri.parse(streamLink);
    final id = epLink.queryParameters['id'] ?? '';
    final encrypedKey = await getEncryptedKey(id);
    final decrypted = await decrypt(epLink);
    final params = "id=$encrypedKey&alias=$id&$decrypted";

    final res = (await get(
        Uri.parse(
            "${epLink.scheme}://${epLink.host}/encrypt-ajax.php?${params}"),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
        }));
    final encryptedData = json.decode(res.body)['data'];

    final Encrypter encrypter =
        Encrypter(AES(keys['secondKey'] as Key, mode: AESMode.cbc));
    final dec = encrypter.decrypt(Encrypted.fromBase64(encryptedData),
        iv: keys['iv'] as IV);

    final parsed = json.decode(dec);

    dynamic qualityList = [];

    if (parsed['source'] == null && parsed['source_bk'] == null)
      throw Exception("No stream found");

    for (final src in parsed['source']) {
      qualityList.add({
        'quality': "multi-quality",
        'link': src['file'],
        'isM3u8': src['file'].endsWith(".m3u8"),
        'server': "vidstreaming",
        'backup': false
      });
    }

    return qualityList;
  }

  Future<String> fetch(String url) async {
    final res = await get(Uri.parse(url));
    return res.body;
  }

  getEncryptedKey(String id) async {
    try {
      final encrypter = Encrypter(AES(keys['key'] as Key, mode: AESMode.cbc));
      final encrypedKey = encrypter.encrypt(id, iv: keys['iv'] as IV);
      return encrypedKey.base64;
    } catch (err) {
      print(err);
    }
  }

  decrypt(Uri streamLink) async {
    final res = await fetch(streamLink.toString());
    final doc = html.parse(res);
    final String val = doc
            .querySelector('script[data-name="episode"]')
            ?.attributes['data-value'] ??
        '';
    if (val.length == 0) return null;
    final Encrypter encrypter =
        Encrypter(AES(keys['key'] as Key, mode: AESMode.cbc, padding: null));
    final decrypted =
        encrypter.decrypt(Encrypted.fromBase64(val), iv: keys['iv'] as IV);
    return decrypted;
  }

  Future getIframeLink(String epLink) async {
    final res = await fetch(epLink);
    final doc = html.parse(res);
    final String link = doc.querySelector("iframe")?.attributes['src'] ?? '';
    if (link.length == 0) return null;
    return link;
  }

  Future<List<Map<String, String>>> generateQualityStreams(
      String multiQualityLink) async {
    final List<Map<String, String>> qualityArray = [];
    final streamMetadata = await fetch(multiQualityLink);
    final regex = RegExp(r'RESOLUTION=(\d+x\d+),NAME="([^"]+)"\n([^#]+)');
    final matchedData = regex.allMatches(streamMetadata);
    if (matchedData.isEmpty) throw Exception("No matches in the stream");
    for (final match in matchedData) {
      final item = match.group(0) ?? '';
      String edit = item.trim().replaceAll(RegExp(r'\n\s+|,|\n'), ' ');
      edit = edit.replaceAll(RegExp(r'RESOLUTION=|NAME='), '');
      final editParts = edit.split(' ');
      qualityArray.add({
        'resolution': editParts[0],
        'quality': editParts[1].replaceAll('"', ''),
        'link':
            '${multiQualityLink.split('/').sublist(0, multiQualityLink.split('/').length - 1).join('/')}/${editParts[2]}'
      });
    }
    return qualityArray;
  }
}
