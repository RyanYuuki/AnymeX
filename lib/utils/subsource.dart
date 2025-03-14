import 'dart:convert';
import 'package:http/http.dart' as http;

class SubSourceApi {
  static const String apiUrl = "https://api.subsource.net/api";
  static const String downloadEndpoint = "$apiUrl/downloadSub";

  Future<List<SubtitleEntity>?> search(SubtitleSearch query) async {
    if (query.imdbId == null) return null;

    final response = await http.post(
      Uri.parse("$apiUrl/searchMovie"),
      body: jsonEncode({"query": query.imdbId}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) return null;
    final searchRes = ApiSearch.fromJson(jsonDecode(response.body));
    if (searchRes.found.isEmpty) return null;

    final postData = {
      "langs": "[]",
      "movieName": searchRes.found.first.linkName,
      if (query.seasonNumber != null) "season": "season-${query.seasonNumber}"
    };

    final getMovieRes = await http.post(
      Uri.parse("$apiUrl/getMovie"),
      body: jsonEncode(postData),
      headers: {"Content-Type": "application/json"},
    );

    if (getMovieRes.statusCode != 200) return null;
    final movieResponse = ApiResponse.fromJson(jsonDecode(getMovieRes.body));

    return movieResponse.subs
        .where((sub) =>
            sub.lang == query.lang &&
            (query.epNumber == null ||
                (sub.releaseName?.contains(
                        "E${query.epNumber!.toString().padLeft(2, '0')}") ??
                    false)))
        .map((subtitle) => SubtitleEntity(
              id: subtitle.subId.toString(),
              name: subtitle.releaseName!,
              lang: subtitle.lang!,
              movie: subtitle.linkName!,
              isHearingImpaired: subtitle.hi == 1,
            ))
        .toList();
  }

  Future<String?> getSubtitleDownloadUrl(SubtitleEntity subtitle) async {
    final response = await http.post(
      Uri.parse("$apiUrl/getSub"),
      body: jsonEncode({
        "movie": subtitle.movie,
        "lang": subtitle.lang,
        "id": subtitle.id,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) return null;
    final subLink = SubTitleLink.fromJson(jsonDecode(response.body));
    return "$downloadEndpoint/${subLink.sub.downloadToken}";
  }
}

// Models
class SubtitleSearch {
  final String? imdbId;
  final String lang;
  final int? seasonNumber;
  final int? epNumber;

  SubtitleSearch(
      {this.imdbId, required this.lang, this.seasonNumber, this.epNumber});
}

class SubtitleEntity {
  final String id;
  final String name;
  final String lang;
  final String movie;
  final bool isHearingImpaired;

  SubtitleEntity({
    required this.id,
    required this.name,
    required this.lang,
    required this.movie,
    required this.isHearingImpaired,
  });
}

class ApiSearch {
  final bool success;
  final List<Found> found;

  ApiSearch({required this.success, required this.found});

  factory ApiSearch.fromJson(Map<String, dynamic> json) => ApiSearch(
        success: json["success"],
        found: (json["found"] as List).map((e) => Found.fromJson(e)).toList(),
      );
}

class Found {
  final String linkName;

  Found({required this.linkName});

  factory Found.fromJson(Map<String, dynamic> json) => Found(
        linkName: json["linkName"],
      );
}

class ApiResponse {
  final bool success;
  final List<Sub> subs;

  ApiResponse({required this.success, required this.subs});

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
        success: json["success"],
        subs: (json["subs"] as List).map((e) => Sub.fromJson(e)).toList(),
      );
}

class Sub {
  final int? hi;
  final String? linkName;
  final String? lang;
  final String? releaseName;
  final int? subId;

  Sub({this.hi, this.linkName, this.lang, this.releaseName, this.subId});

  factory Sub.fromJson(Map<String, dynamic> json) => Sub(
        hi: json["hi"],
        linkName: json["linkName"],
        lang: json["lang"],
        releaseName: json["releaseName"],
        subId: json["subId"],
      );
}

class SubTitleLink {
  final SubToken sub;

  SubTitleLink({required this.sub});

  factory SubTitleLink.fromJson(Map<String, dynamic> json) => SubTitleLink(
        sub: SubToken.fromJson(json["sub"]),
      );
}

class SubToken {
  final String downloadToken;

  SubToken({required this.downloadToken});

  factory SubToken.fromJson(Map<String, dynamic> json) => SubToken(
        downloadToken: json["downloadToken"],
      );
}
