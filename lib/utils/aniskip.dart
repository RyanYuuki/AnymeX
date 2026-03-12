import 'dart:convert';
import 'package:http/http.dart' as http;

class AniSkipApi {
  static const String apiUrl = "https://api.aniskip.com";
  static const String skipTimeEndpoint = "/v2/skip-times/";

  Future<EpisodeSkipTimes?> getSkipTimes(SkipSearchQuery query) async {
    if (query.idMAL == null || query.episodeNumber == null) return null;
    final String idMAL = query.idMAL!;
    final String episodeNumber = query.episodeNumber!;
    final int episodeLength = query.episodeLength ?? 0;

    final String uri =
        "$apiUrl$skipTimeEndpoint$idMAL/$episodeNumber"
        "?types[]=op&types[]=ed&types[]=recap&types[]=mixed-op&types[]=mixed-ed"
        "&episodeLength=$episodeLength";

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode != 200) return null;

      final skipData = jsonDecode(response.body);
      if (skipData['found'] == true) {
        final results = skipData['results'] as List<dynamic>;

        SkipIntervals? op;
        SkipIntervals? ed;
        SkipIntervals? recap;

        for (final element in results) {
          final String type = element['skipType'] as String? ?? '';
          final interval = element['interval'];
          final SkipIntervals parsed = SkipIntervals(
            start: (interval['startTime'] as num).toInt(),
            end: (interval['endTime'] as num).toInt(),
          );

          if (type == 'op' || type == 'mixed-op') {
            op ??= parsed;
          } else if (type == 'ed' || type == 'mixed-ed') {
            ed ??= parsed;
          } else if (type == 'recap') {
            recap ??= parsed;
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
