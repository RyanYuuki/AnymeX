import 'package:aurora/utils/methods.dart';
import 'package:html/parser.dart' as html;
import 'package:js_unpack/js_unpack.dart';

class StreamWish {
  Future<dynamic> extract(String streamUrl) async {
    if (streamUrl.isEmpty) {
      throw Exception("ERR_EMPTY_STREAM_LINK");
    }
    if (streamUrl.startsWith('https://awish.pro/') ||
        streamUrl.startsWith('https://alions.pro/')) {
      final serverName =
          streamUrl.startsWith('https://awish.pro/') ? "streamwish" : "alions";
      final res = await fetch(streamUrl);
      final doc = html.parse(res);
      String streamLink = '';
      doc.querySelectorAll('script').forEach((element) {
        if (streamLink.isEmpty) {
          try {
            final regex = RegExp(r'file:\s*"(.*?)"');
            final link = regex.allMatches(element.innerHtml);
            if (link.isNotEmpty) {
              streamLink = link.firstOrNull?[1].toString() ?? '';
            } else {
              throw Exception("WRONG FORMAT!");
            }
          } catch (err) {
            final regex = RegExp(r'eval\(function\(p,a,c,k,e,d\)');
            final html = element.innerHtml;
            final matched = regex.firstMatch(html);
            if (matched != null) {
              final String data = JsUnpack(html).unpack();
              final dataMatch = RegExp(r'sources:\s*\[([\s\S]*?)\]')
                      .allMatches(data)
                      .firstOrNull?[1] ??
                  '';
              streamLink = dataMatch.replaceAll(RegExp(r'{|}|\"|file:'), '');
            }
          }
        }
      });
      if (streamLink.isEmpty) {
        throw Exception("Couldnt get any $serverName streams");
      }
      return {
        'server': serverName,
        'link': streamLink,
        'quality': "multi-quality",
        'backup': false,
        'isM3u8': streamLink.endsWith('.m3u8')
      };
    }
    throw Exception("NO_MATCHING_LINKS_FOUND");
  }
}
