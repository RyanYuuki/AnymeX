import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class WatchOrderItem {
  final String id;
  final String anilistId;
  final String image;
  final String name;
  final String? nameEnglish;
  final String text;

  WatchOrderItem({
    required this.id,
    required this.anilistId,
    required this.image,
    required this.name,
    required this.nameEnglish,
    required this.text,
  });
}

class WatchOrderSearch {
  final String id;
  final String image;
  final String type;
  final String name;
  final int year;

  WatchOrderSearch({
    required this.id,
    required this.image,
    required this.type,
    required this.name,
    required this.year,
  });

  factory WatchOrderSearch.fromJson(Map<String, dynamic> json) {
    return WatchOrderSearch(
      id: json["id"],
      image: "https://chiaki.site/${json["image"]}",
      type: json["type"],
      name: json["value"],
      year: json["year"],
    );
  }
}

class WatchOrderUtil {
  static const Map<String, String> _headers = {
    "Referer": "https://chiaki.site/?/tools/watch_order",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
  };

  static Future<List<WatchOrderSearch>> searchWatchOrder(String name) async {
    try {
      final url = Uri.parse(
        "https://chiaki.site/?/tools/autocomplete_series&term=$name",
      );
      final res = await http.get(url, headers: _headers);
      final data = jsonDecode(res.body) as List?;
      return data?.map((e) => WatchOrderSearch.fromJson(e)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<WatchOrderItem>> fetchWatchOrder(String id) async {
    try {
      final res = await http.get(
        Uri.parse("https://chiaki.site/?/tools/watch_order/id/$id"),
        headers: _headers,
      );
      
      final doc = parse(res.body);
      final rows = doc.querySelectorAll("table > tbody > tr");

      if (rows.isEmpty) return [];

      return rows.map((e) {
        final imgDiv = e.querySelector("td > div.wo_avatar_big");
        String imageUrl = "";
        
        if (imgDiv != null) {
          final style = imgDiv.attributes['style'] ?? "";
          if (style.contains("url('")) {
            final start = style.indexOf("url('") + 5;
            final end = style.indexOf("')", start);
            if (end != -1) {
              imageUrl = "https://chiaki.site/${style.substring(start, end)}";
            }
          }
        }

        return WatchOrderItem(
          id: e.attributes["data-id"] ?? id,
          anilistId: e.attributes["data-anilist-id"] ?? "",
          image: imageUrl,
          name: e.querySelector("td > span.wo_title")?.text.trim() ?? "Unknown",
          nameEnglish: e.querySelector("td > span.uk-text-small")?.text.trim(),
          text: e.querySelector("td > span.uk-text-muted.uk-text-small")?.text.trim() ?? "",
        );
      }).where((e) => e.name != "Unknown").toList();
    } catch (e) {
      return [];
    }
  }
}
