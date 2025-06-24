import 'dart:convert';
import 'package:http/http.dart' as http;

class AniSkipApi {
  static const String apiUrl = "https://api.aniskip.com";
  static const String skipTimeEndpoint = "/v1/skip-times/";
  static const String skipTypesQuery = "?types=op&types=ed";

  SkipIntervals? getFromResults(String type, List<dynamic> result) {
    for (var element in result) {
      if (element["skip_type"] == type) {
        return SkipIntervals(
            start: element['interval']['start_time'].toInt(),
            end: element['interval']['end_time'].toInt());
      }
    }
    return null;
  }

  Future<EpisodeSkipTimes?> getSkipTimes(SkipSearchQuery query) async {
    if (query.idMAL == null || query.episodeNumber == null) return null;
    String idMAL = query.idMAL as String;
    String episodeNumber = query.episodeNumber as String;
    String uri = "$apiUrl$skipTimeEndpoint$idMAL/$episodeNumber$skipTypesQuery";

    final response = await http
        .get(Uri.parse(uri), headers: {"Content-Type": "application/json"});

    if (response.statusCode != 200) return null;

    final skipData = jsonDecode(response.body);
    if (skipData['found'] == true) {
      final op = getFromResults('op', skipData['results']);
      final ed = getFromResults('ed', skipData['results']);
      return EpisodeSkipTimes(op: op, ed: ed);
    } else {
      return null;
    }
  }
}

class EpisodeSkipTimes {
  final SkipIntervals? op;
  final SkipIntervals? ed;

  EpisodeSkipTimes({this.op, this.ed});
}

class SkipIntervals {
  final int start;
  final int end;

  SkipIntervals({required this.start, required this.end});
}

class SkipSearchQuery {
  final String? idMAL;
  final String? episodeNumber;

  SkipSearchQuery({this.idMAL, this.episodeNumber});
}
