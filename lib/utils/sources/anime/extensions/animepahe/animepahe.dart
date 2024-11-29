import 'dart:convert';
import 'dart:developer';
import 'package:anymex/utils/sources/anime/base/source_base.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:anymex/utils/sources/anime/extractors/kwik.dart';
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
        'name': item["title"],
        'poster': item["poster"],
        'id': '${item['id']}-${item["title"]}',
        'episodes': {"sub": item?['episodes'], "dub": '??'},
      });
    }

    return searchResults;
  }

  @override
  Future scrapeEpisodes(String url, {args}) async {
    final title = url.split('-')[1];
    final id = url.split('-').first;
    log(id + title);
    final session = await _getSession(title, id);
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
    var animeTitle = 'Could not fetch title';
    dynamic episodes = [];

    for (var item in jsonResult["data"]) {
      episodes.add({
        'title': "Episode ${item["episode"]}",
        'episodeId': '$session/${item["session"]}',
        'number': item["episode"],
        'image': item["snapshot"],
      });
    }

    if (hasNextPage) {
      final newUrl = "${url.split("&page=").first}&page=${page + 1}";
      final newResponse = await http.get(Uri.parse(newUrl), headers: {
        'Cookie': "__ddg1_=;__ddg2_=;",
      });
      episodes.addAll(
          await _recursiveFetchEpisodes(newUrl, newResponse.body, session));
    } else {
      final url = 'https://animepahe.ru/a/${jsonResult['data'][0]['anime_id']}';
      final newResponse = await http.get(Uri.parse(url), headers: {
        'Cookie': "__ddg1_=;__ddg2_=;",
      });
      if (newResponse.statusCode == 200) {
        var document = parse(newResponse.body);
        animeTitle =
            document.querySelector('.title-wrapper span')?.text.trim() ??
                'Could not fetch title';
      }
    }

    final data = {
      'title': animeTitle,
      'session': session,
      'totalEpisodes': jsonResult['total'],
      'episodes': episodes.reversed.toList(),
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
    String? episodeLink;

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

    final organizedLinks = organizeStreamLinks(videoLinks);
    if (category == "dub") {
      episodeLink = organizedLinks['dub']?[0] ?? organizedLinks['sub']?[0];
    } else {
      episodeLink = organizedLinks['sub']?[0] ?? organizedLinks['sub']?[1];
    }
    final res = {
      "sources": [
        {
          "url": episodeLink,
        }
      ],
      "multiSrc": videoLinks,
    };
    log(res.toString());
    return res;
  }

  Map<String, List<String>> organizeStreamLinks(
      List<Map<String, dynamic>> links) {
    final result = {'sub': <String>[], 'dub': <String>[]};
    final qualityOrder = ['1080p', '720p', '360p'];

    for (var link in links) {
      final isDub = link['quality'].toString().toLowerCase().contains('eng');
      final targetList = isDub ? result['dub']! : result['sub']!;
      targetList.add(link['url']);
    }

    result['sub']
        ?.sort((a, b) => qualityOrder.indexOf(b) - qualityOrder.indexOf(a));
    result['dub']
        ?.sort((a, b) => qualityOrder.indexOf(b) - qualityOrder.indexOf(a));

    return result;
  }

  Future<String> _getSession(String title, String animeId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/api?m=search&q=$title"), headers: {
      'Cookie': "__ddg1_=;__ddg2_=;",
    });
    final resBody = jsonDecode(response.body);
    final session = resBody['data'].firstWhere(
      (anime) => anime?['title'] == title,
      orElse: () => resBody['data'].first,
    );

    return session['session'];
  }

  @override
  bool get isMulti => false;

  @override
  String get sourceName => 'AnimePahe';
}
