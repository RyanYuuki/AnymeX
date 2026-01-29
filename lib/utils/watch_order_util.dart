import 'dart:convert';
import 'dart:developer';

import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

class WatchOrderItem {
  final String id;
  final String anilistId;
  final String image;
  final String name;
  final String? nameEnglish;
  final String relationType;
  final String airDate;
  final String mediaType;
  final String episodes;
  final String rating;
  final String? malLink;
  final String? anilistLink;
  final String? shikimoriLink;
  final String? simklLink;
  final String text;

  WatchOrderItem({
    required this.id,
    required this.anilistId,
    required this.image,
    required this.name,
    this.nameEnglish,
    this.relationType = "",
    this.airDate = "",
    this.mediaType = "",
    this.episodes = "",
    this.rating = "",
    this.malLink,
    this.anilistLink,
    this.shikimoriLink,
    this.simklLink,
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
    print(json);
    return WatchOrderSearch(
      id: json["id"]?.toString() ?? "",
      image: "https://chiaki.site/${json["image"]}",
      type: json["type"]?.toString() ?? "",
      name: json["value"]?.toString() ?? "",
      year: json["year"] ?? "",
    );
  }
}

class WatchOrderUtil {
  static const Map<String, String> _headers = {
    "Referer": "https://chiaki.site/?/tools/watch_order",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
    "X-Requested-With":
        "XMLHttpRequest", // Added this header often needed for AJAX endpoints
  };

  static Future<List<WatchOrderSearch>> searchWatchOrder(String name) async {
    try {
      final url = Uri.parse(
        "https://chiaki.site/?/tools/autocomplete_series&term=$name",
      );
      final res = await http.get(url, headers: _headers);

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      return (data as List<dynamic>)
          .map((e) => WatchOrderSearch.fromJson(e))
          .toList();
    } catch (e, st) {
      log(e.toString(), stackTrace: st);
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

      return rows
          .map((e) {
            final imgDiv = e.querySelector("td > div.wo_avatar_big");
            String imageUrl = "";
            if (imgDiv != null) {
              final style = imgDiv.attributes['style'] ?? "";
              if (style.contains("url('")) {
                final start = style.indexOf("url('") + 5;
                final end = style.indexOf("')", start);
                if (start != -1 && end != -1) {
                  imageUrl =
                      "https://chiaki.site/${style.substring(start, end)}";
                }
              }
            }

            final relationLabel = e.querySelector("td > div.wo_relation");
            final relationType = relationLabel?.text.trim() ?? "";

            final title = e.querySelector("td > span.wo_title")?.text.trim() ??
                "Unknown title";
            final englishTitle =
                e.querySelector("td > span.uk-text-small")?.text.trim();

            final metadataText = e
                    .querySelector("td > span.uk-text-muted.uk-text-small")
                    ?.text
                    .trim() ??
                "";

            final parts = metadataText.split('|').map((p) => p.trim()).toList();

            String airDate = "";
            String mediaType = "";
            String episodes = "";
            String rating = "";

            if (parts.isNotEmpty) airDate = parts[0];
            if (parts.length > 1) mediaType = parts[1];
            if (parts.length > 2) episodes = parts[2];
            if (parts.length > 3) {
              rating = parts[3];
            }

            final malLink = e
                .querySelector("a[href*='myanimelist.net']")
                ?.attributes['href'];
            final anilistLink =
                e.querySelector("a[href*='anilist.co']")?.attributes['href'];
            final shikimoriLink =
                e.querySelector("a[href*='shikimori.one']")?.attributes['href'];
            final simklLink =
                e.querySelector("a[href*='simkl.com']")?.attributes['href'];

            return WatchOrderItem(
              id: e.attributes["data-id"] ?? id,
              anilistId: e.attributes["data-anilist-id"] ?? "",
              image: imageUrl,
              name: title,
              nameEnglish: englishTitle,
              relationType: relationType,
              airDate: airDate,
              mediaType: mediaType,
              episodes: episodes,
              rating: rating,
              malLink: malLink,
              anilistLink: anilistLink,
              shikimoriLink: shikimoriLink,
              simklLink: simklLink,
              text: metadataText,
            );
          })
          .where((e) => e.name != "Unknown title")
          .toList();
    } catch (e) {
      return [];
    }
  }
}
