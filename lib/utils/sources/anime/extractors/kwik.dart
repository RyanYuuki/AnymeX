import 'dart:developer';

import 'package:http/http.dart';
import 'package:html/parser.dart' as html;

class Kwik {
  Future<String> extract(String streamUrl,
      {String? quality, String? server}) async {
    final res = await get(Uri.parse(streamUrl),
        headers: {'referer': 'https://animepahe.ru/'});
    final doc = html.parse(res.body);
    String? streamLink;
    doc.querySelectorAll("script").forEach((element) {
      final html = element.innerHtml;
      final regex = RegExp(r'eval\(function\(p,a,c,k,e,d\)');
      final match = regex.firstMatch(html);
      if (match != null) {
        final unpacked = JsUnpack(html).unpack();
        log(unpacked);
        final dataMatch = RegExp(r"const\s+source\s*=\s*'([^']+\.m3u8)'")
                .allMatches(unpacked)
                .firstOrNull?[1] ??
            '';
        streamLink = dataMatch.replaceAll(RegExp(r'{|}|\"|file:'), '');
      }
    });

    return streamLink!;
  }
}

class JsUnpack {
  final String source;
  const JsUnpack(this.source);
  static const alphabet =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  ///Unpacks P.A.C.K.E.R. packed js code
  String unpack() {
    final lst = _filterargs();
    final String payload =
        lst[0].replaceAll("\\\\", "\\").replaceAll("\\'", "'");
    final List<String> symtab = lst[1];
    String source = payload;
    final reg = RegExp(
      r"\b\w+\b",
    ).allMatches(payload);
    int correct = 0;
    for (RegExpMatch element in reg) {
      final word = payload.substring(element.start, element.end);
      String lookUp = "";
      final v = toBase10(word);
      if (v < symtab.length) {
        try {
          lookUp = symtab[v];
        } catch (_) {}
        if (lookUp.isEmpty) lookUp = word;
      } else {
        lookUp = word;
      }
      source = source.replaceRange(element.start + correct,
          element.start + word.length + correct, lookUp);
      correct += lookUp.length - (element.end - element.start);
    }
    return _replaceStrings(source);
  }

  String _replaceStrings(String source) {
    var re =
        RegExp(r'var *(_\w+)=\["(.*?)"];', dotAll: true).firstMatch(source);
    if (re == null) {
      return source;
    }
    final strings = re.group(1)!;
    return source.substring(strings.length);
  }

  List<dynamic> _filterargs() {
    final all =
        RegExp(r"}\s*\('(.*)',\s*(.*?),\s*(\d+),\s*'(.*?)'\.split\('\|'\)")
            .firstMatch(source);
    if (all == null) {
      throw 'Corrupted p.a.c.k.e.r. data.';
    }
    return [
      all.group(1),
      all.group(4)!.split("|"),
      int.tryParse(all.group(2)!) ?? 36,
      int.parse(all.group(3)!)
    ];
  }

  int toBase10(String string) {
    return string.split('').fold(0, (int out, char) {
      int charIndex = alphabet.indexOf(char);
      return out * alphabet.length + charIndex;
    });
  }
}
