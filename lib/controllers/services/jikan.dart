import 'dart:convert';
import 'package:http/http.dart' as http;

class JikanService {
  static const String apiUrl = "https://api.jikan.moe/v4";

  static Future<Map<String, bool>> getFillerEpisodes(String? malId) async {
    if (malId == null) return {};
    
    final Map<String, bool> fillerMap = {};
    int page = 1;
    bool hasNextPage = true;

    try {
      while (hasNextPage) {
        final response = await http.get(
            Uri.parse('$apiUrl/anime/$malId/episodes?page=$page'));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final data = json['data'] as List<dynamic>;
          final pagination = json['pagination'];

          if (data.isEmpty) break;

          for (var item in data) {
            final epNum = item['mal_id'].toString();
            final isFiller = item['filler'] as bool? ?? false;
            if (isFiller) {
              fillerMap[epNum] = true;
            }
          }

          hasNextPage = pagination?['has_next_page'] ?? false;
          page++;
          
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          break;
        }
      }
    } catch (e) {
      print("Jikan API Error: $e");
    }
    
    return fillerMap;
  }
}
