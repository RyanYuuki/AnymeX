import 'dart:convert';
import 'package:aurora/utils/sources/anime/base/source_base.dart';
import 'package:aurora/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:aurora/utils/sources/anime/extractors/kwik.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class AnimePahe implements SourceBase {
  final String baseUrl = "https://animepahe.ru";

  @override
  Future scrapeSearchResults(String query) async {
    final response = await http
        .get(Uri.parse("$baseUrl/api?m=search&l=8&q=$query"), headers: {
      'Cookie': "__ddg1_=;__ddg2_=;",
    });
    final jsonResult = json.decode(response.body);
    List<Map<String, dynamic>> searchResults = [];

    for (var item in jsonResult["data"]) {
      searchResults.add({
        'title': item["title"],
        'imageUrl': item["poster"],
        'animeId': item["id"],
      });
    }

    return searchResults;
  }

  @override
  Future scrapeEpisodes(String url, {args}) async {
    final session = await _getSession(args['animeName'], args['animeId']);
    final epUrl = "$baseUrl/api?m=release&id=$session&sort=episode_desc&page=1";
    final response = await http.get(Uri.parse(epUrl), headers: {
      'Cookie': "__ddg1_=;__ddg2_=;",
    });
    return await _recursiveFetchEpisodes(epUrl, response.body, session);
  }

  Future<dynamic> _recursiveFetchEpisodes(
      String url, String response, String session) async {
    final jsonResult = json.decode(response);
    final page = jsonResult["current_page"];
    final hasNextPage = page < jsonResult["last_page"];
    List<Map<String, dynamic>> episodes = [];

    for (var item in jsonResult["data"]) {
      episodes.add({
        'title': "Episode ${item["episode"]}",
        'episodeId': '$session/${item["session"]}',
        'number': item["episode"],
        'dateUpload': item["created_at"],
      });
    }

    if (hasNextPage) {
      final newUrl = "${url.split("&page=").first}&page=${page + 1}";
      final newResponse = await http.get(Uri.parse(newUrl), headers: {
        'Cookie': "__ddg1_=;__ddg2_=;",
      });
      episodes.addAll(
          await _recursiveFetchEpisodes(newUrl, newResponse.body, session));
    }

    final data = {
      'session': session,
      'totalEpisodes': jsonResult['total'],
      'episodes': episodes,
    };

    return data;
  }

  @override
  Future scrapeEpisodesSrcs(String episodeUrl,
      {AnimeServers? server, String? category, String? lang}) async {
    final response =
        await http.get(Uri.parse("$baseUrl/play/$episodeUrl"), headers: {
      'Cookie': "__ddg1_=;__ddg2_=;",
    });
    final document = parse(response.body);
    final buttons = document.querySelectorAll("div#resolutionMenu > button");
    List<Map<String, String>> videoLinks = [];

    for (var btn in buttons) {
      final kwikLink = btn.attributes["data-src"];
      final quality = btn.text;
      final videoUrl = await Kwik().extract(kwikLink!);

      videoLinks.add({
        'quality': quality,
        'url': videoUrl.toString(),
        'referer': "https://kwik.cx",
      });
    }

    return videoLinks;
  }

  Future<String> _getSession(String title, String animeId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/api?m=search&q=$title"), headers: {
      'Cookie': "__ddg1_=;__ddg2_=;",
    });
    final resBody = jsonDecode(response.body);
    final session =
        resBody['data'].firstWhere((anime) => anime['title'] == title);
    return session['session'];
  }

  String _unpackJavaScript(String script) {
    return script.split("const source='").last.split("';").first;
  }

  @override
  bool get isMulti => false;

  @override
  String get sourceName => 'AnimePahe';
}
