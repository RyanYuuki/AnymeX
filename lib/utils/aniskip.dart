import 'dart:convert';
import 'package:http/http.dart' as http;

class AniSkipApi {
  static const String apiUrl = "https://api.aniskip.com";
  static const String skipTimeEndpoint = "/v2/skip-times/";

  Future<EpisodeSkipTimes?> getSkipTimes(SkipSearchQuery query) async {
    if (query.idMAL == null || query.episodeNumber == null) return null;
    String idMAL = query.idMAL as String;
    String episodeNumber = query.episodeNumber as String;
    int episodeLength = query.episodeLength ?? 0;
    
    String uri = "$apiUrl$skipTimeEndpoint$idMAL/$episodeNumber?types[]=op&types[]=ed&types[]=recap&types[]=mixed-op&types[]=mixed-ed&episodeLength=$episodeLength";

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode != 200) return null;

      final skipData = jsonDecode(response.body);
      if (skipData['found'] == true) {
        final results = skipData['results'] as List<dynamic>;
        
        SkipIntervals? op;
        SkipIntervals? ed;
        SkipIntervals? recap;

        for (var element in results) {
          final type = element["skipType"];
          final interval = SkipIntervals(
            start: element['interval']['start_time'].toInt(),
            end: element['interval']['end_time'].toInt(),
          );

          if (type == "op" || type == "mixed-op") {
            op = interval;
          } else if (type == "ed" || type == "mixed-ed") {
            ed = interval;
          } else if (type == "recap") {
            recap = interval;
          }
        }
        
        return EpisodeSkipTimes(op: op, ed: ed, recap: recap);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

class EpisodeSkipTimes {
  final SkipIntervals? op;
  final SkipIntervals? ed;
  final SkipIntervals? recap;

  EpisodeSkipTimes({this.op, this.ed, this.recap});
}

class SkipIntervals {
  final int start;
  final int end;

  SkipIntervals({required this.start, required this.end});
}

class SkipSearchQuery {
  final String? idMAL;
  final String? episodeNumber;
  final int? episodeLength;

  SkipSearchQuery({this.idMAL, this.episodeNumber, this.episodeLength});
}
