import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/screens/local_source/model/detail_result.dart';
import 'package:dio/dio.dart';

class TmdbApi {
  static const String baseUrl = 'https://db.cineby.app/3';
  static const String apiKey = 'api_key=ad301b7cc82ffe19273e55e4d4206885';
  static const String page = '&page=1';
  static const String includeAdult = '&include_adult=false';
  static const String externalIds = '?append_to_response=external_ids';

  static String image(String path) => 'https://image.tmdb.org/t/p/w500$path';

  static const String postFix = '$page$includeAdult&$apiKey';

  static String url(String path) => '$baseUrl$path$postFix';

  static String urlWithId(String path, String id) =>
      '$baseUrl$path/$id$externalIds&$apiKey';

  static Future<DetailResult?> getDetails(String id) async {
    final params = jsonDecode(id);
    try {
      final url = urlWithId('/${params['type']}', params['id'].toString());
      final resp = await Dio().get(url);
      return DetailResult.fromJson(resp.data);
    } catch (e) {
      Logger.i(e.toString());
      return null;
    }
  }
}
