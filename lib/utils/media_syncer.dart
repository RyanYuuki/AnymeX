import 'dart:convert';
import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:http/http.dart';

enum MappingType { anilist, mal }

class MediaSyncer {
  static Future<String?> mapMediaId(String id,
      {MappingType? type, bool isManga = false}) async {
    final mappingType = type ??
        (serviceHandler.serviceType.value == ServicesType.anilist
            ? MappingType.anilist
            : MappingType.mal);

    if (!isManga) {
      return await getMappedAnimeId(id, mappingType);
    } else {
      return await getMappedMangaId(id, mappingType);
    }
  }

  static Future<String?> getMappedAnimeId(String id, MappingType type) async {
    final url =
        'https://raw.githubusercontent.com/bal-mackup/mal-backup/refs/heads/master/${type.name}/anime/$id.json';
    final resp = await get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (type == MappingType.anilist) {
        return data['malId'].toString();
      } else {
        return data['aniId'].toString();
      }
    } else {
      Logger.i("URL => $url");
      Logger.i('Error While Mapping Id => ${resp.body}');
    }
    return null;
  }

  static Future<String?> getMappedMangaId(String id, MappingType type) async {
    final resp = await get(Uri.parse(
        'https://raw.githubusercontent.com/bal-mackup/mal-backup/refs/heads/master/${type.name}/manga/$id.json'));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (type == MappingType.anilist) {
        return data['malId'].toString();
      } else {
        return data['aniId'].toString();
      }
    } else {
      Logger.i('Error While Mapping Id => ${resp.body}');
    }
    return null;
  }

  /// Resolves an external ID (e.g. anilist, mal, kitsu, tvdb, imdb, etc.)
  /// to a Simkl ID using Simkl's redirect endpoint:
  /// `GET https://api.simkl.com/redirect?to=simkl&{service}={id}`
  static Future<String?> getSimklIdFromExternal({
    String? anilistId,
    String? malId,
    String? service,
    String? externalId,
  }) async {
    final client = Client();
    try {
      String? paramName;
      String? idToUse;

      if (service != null && externalId != null) {
        paramName = service;
        idToUse = externalId;
      } else if (anilistId != null) {
        paramName = 'anilist';
        idToUse = anilistId;
      } else if (malId != null) {
        paramName = 'mal';
        idToUse = malId;
      }

      if (paramName == null || idToUse == null) return null;

      final url = Uri.parse(
          'https://api.simkl.com/redirect?to=simkl&$paramName=$idToUse');
      final request = Request('GET', url)..followRedirects = false;
      final response = await client.send(request);

      final location = response.headers['location'];
      if (location != null) {
        final match =
            RegExp(r'/(?:anime|shows|movies)/(\d+)').firstMatch(location);
        if (match != null) {
          return match.group(1);
        }
      }

      // If resolving via anilist failed, fallback to malId if available
      if (paramName == 'anilist' && malId != null) {
        final fallbackUrl =
            Uri.parse('https://api.simkl.com/redirect?to=simkl&mal=$malId');
        final fallbackReq = Request('GET', fallbackUrl)..followRedirects = false;
        final fallbackResp = await client.send(fallbackReq);
        final fallbackLoc = fallbackResp.headers['location'];
        if (fallbackLoc != null) {
          final match =
              RegExp(r'/(?:anime|shows|movies)/(\d+)').firstMatch(fallbackLoc);
          if (match != null) {
            return match.group(1);
          }
        }
      }
    } catch (e) {
      Logger.i('Error resolving Simkl ID: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Fetches anime details from Simkl API by Simkl ID:
  /// `GET https://api.simkl.com/anime/{simklId}`
  static Future<Map<String, dynamic>?> fetchSimklAnimeDetails(
      String simklId) async {
    try {
      final url = Uri.parse('https://api.simkl.com/anime/$simklId');
      final resp = await get(url);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      Logger.i('Error fetching Simkl anime details: $e');
    }
    return null;
  }
}
