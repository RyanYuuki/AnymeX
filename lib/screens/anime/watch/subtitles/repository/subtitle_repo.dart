import 'dart:convert';
import 'package:anymex/screens/anime/watch/subtitles/model/online_subtitle.dart';
import 'package:anymex/screens/anime/watch/subtitles/utils/language_utils.dart';
import 'package:anymex/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum SubtitleProvider {
  wyzie('Wyzie Subs', false, 'https://sub.wyzie.ru'),
  opensubtitles('OpenSubtitles', true, 'https://api.opensubtitles.com/api/v1'),
  subdl('SubDL', true, 'https://api.subdl.com/api/v1'),
  subsro('Subs.ro', true, 'https://subs.ro/api/v1.0'),
  jimaku('Jimaku', true, 'https://jimaku.cc/api');

  const SubtitleProvider(this.displayName, this.requiresApiKey, this.baseUrl);
  final String displayName;
  final bool requiresApiKey;
  final String baseUrl;
}

class SubtitleSearchParams {
  final String? imdbId;
  final String? tmdbId;
  final String? anilistId;
  final String? malId;
  final String title;
  final String type;
  final int? season;
  final int? episode;
  final List<String> languages;
  final bool excludeHearingImpaired;
  final Duration timeout;

  SubtitleSearchParams({
    this.imdbId,
    this.tmdbId,
    this.anilistId,
    this.malId,
    required this.title,
    required this.type,
    this.season,
    this.episode,
    required this.languages,
    this.excludeHearingImpaired = false,
    this.timeout = const Duration(seconds: 15),
  });
}

abstract class BaseSubtitleProvider {
  SubtitleProvider get providerType;
  Future<List<OnlineSubtitle>> search(SubtitleSearchParams params);
  Future<String> download(String url, {String? languageHint});
}

class WyzieProvider implements BaseSubtitleProvider {
  @override
  SubtitleProvider get providerType => SubtitleProvider.wyzie;

  static const String baseUrl = 'https://sub.wyzie.ru';

  @override
  Future<List<OnlineSubtitle>> search(SubtitleSearchParams params) async {
    try {
      String searchId = '';
      if (params.imdbId != null && params.imdbId!.isNotEmpty) {
        searchId = params.imdbId!.startsWith('tt') ? params.imdbId! : 'tt${params.imdbId}';
      } else if (params.tmdbId != null) {
        searchId = params.tmdbId!;
      } else {
        return [];
      }

      final queryParams = <String, String>{'id': searchId};
      
      if (params.type == 'episode' && params.episode != null) {
        queryParams['season'] = (params.season ?? 1).toString();
        queryParams['episode'] = params.episode.toString();
      }

      if (params.languages.isNotEmpty) {
        final iso1Langs = params.languages
            .map((lang) => LanguageUtils.toIso6391(lang))
            .where((code) => code != null)
            .map((code) {
              if (code == 'pt-br') return 'pb';
              if (code == 'zh-tw') return 'zt';
              if (code == 'zh-cn') return 'zh';
              return code!.split('-')[0];
            })
            .toSet()
            .join(',');
        
        if (iso1Langs.isNotEmpty) {
          queryParams['language'] = iso1Langs;
        }
      }

      queryParams['format'] = 'srt';
      
      final sourceList = ['opensubtitles', 'subf2m', 'subdl', 'podnapisi', 'gestdown', 'animetosho'];
      queryParams['source'] = sourceList.join(',');

      final url = Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);
      Logger.d('[Wyzie] Searching: $url');

      final response = await http.get(url).timeout(params.timeout);
      
      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      
      return data.map((e) {
        final normalizedLang = LanguageUtils.normalizeLanguageCode(e['language'] ?? '');
        return OnlineSubtitle(
          id: e['id'] ?? '',
          url: e['url'] ?? '',
          flagUrl: e['flagUrl'] ?? LanguageUtils.getFlagUrl(e['language'] ?? ''),
          format: e['format'] ?? 'srt',
          encoding: e['encoding'] ?? 'utf-8',
          label: e['display'] ?? e['fileName'] ?? e['media'] ?? 'Unknown',
          language: e['language'] ?? '',
          languageCode: normalizedLang,
          media: e['media'] ?? '',
          isHearingImpaired: e['isHearingImpaired'] ?? false,
          source: e['source']?.toString() ?? 'wyzie',
          provider: providerType.name,
          downloads: 0,
          rating: 0,
          isSeasonPack: false,
        );
      }).toList();
    } catch (e) {
      Logger.e('[Wyzie] Search failed: $e');
      return [];
    }
  }

  @override
  Future<String> download(String url, {String? languageHint}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }
      return utf8.decode(response.bodyBytes);
    } catch (e) {
      Logger.e('[Wyzie] Download failed: $e');
      rethrow;
    }
  }
}

class OpenSubtitlesProvider implements BaseSubtitleProvider {
  @override
  SubtitleProvider get providerType => SubtitleProvider.opensubtitles;
  
  String? _apiKey;
  String? _token;
  DateTime? _tokenExpiry;
  
  OpenSubtitlesProvider({String? apiKey}) {
    _apiKey = apiKey;
  }

  Future<bool> _ensureAuthenticated() async {
    if (_token != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return true;
    }

    if (_apiKey == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${providerType.baseUrl}/login'),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _apiKey!,
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 23));
        return true;
      }
    } catch (e) {
      Logger.e('[OpenSubtitles] Auth failed: $e');
    }
    return false;
  }

  @override
  Future<List<OnlineSubtitle>> search(SubtitleSearchParams params) async {
    try {
      if (!await _ensureAuthenticated()) return [];

      if (params.imdbId == null) return [];

      final imdbId = params.imdbId!.replaceAll('tt', '');
      
      final convertedLangs = params.languages
          .map((lang) => LanguageUtils.toIso6391(lang))
          .whereType<String>()
          .map((code) => code == 'pt-br' ? 'pt-br' : code.split('-')[0])
          .toList();

      final queryParams = {
        'imdb_id': imdbId,
        'languages': convertedLangs.join(','),
      };

      if (params.type == 'episode' && params.episode != null) {
        queryParams['season_number'] = (params.season ?? 1).toString();
        queryParams['episode_number'] = params.episode.toString();
      }

      if (params.excludeHearingImpaired) {
        queryParams['hearing_impaired'] = 'exclude';
      }

      final url = Uri.parse('${providerType.baseUrl}/subtitles').replace(queryParameters: queryParams);
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Api-Key': _apiKey!,
          'Content-Type': 'application/json',
        },
      ).timeout(params.timeout);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final subtitles = data['data'] as List? ?? [];

      return subtitles.map<OnlineSubtitle>((sub) {
        final attrs = sub['attributes'];
        final file = attrs['files']?[0] ?? {};
        final langCode = LanguageUtils.normalizeLanguageCode(attrs['language'] ?? '');
        
        return OnlineSubtitle(
          id: file['file_id']?.toString() ?? sub['id'].toString(),
          url: attrs['url'] ?? '',
          flagUrl: LanguageUtils.getFlagUrl(attrs['language'] ?? ''),
          format: attrs['format'] ?? 'srt',
          encoding: 'utf-8',
          label: file['file_name']?.replaceAll('.srt', '') ?? attrs['release'] ?? 'Unknown',
          language: attrs['language'] ?? '',
          languageCode: langCode,
          media: '',
          isHearingImpaired: attrs['hearing_impaired'] ?? false,
          source: 'opensubtitles',
          provider: providerType.name,
          downloads: int.tryParse(attrs['download_count']?.toString() ?? '0') ?? 0,
          rating: double.tryParse(attrs['ratings']?.toString() ?? '0') ?? 0,
          isSeasonPack: false,
        );
      }).toList();
    } catch (e) {
      Logger.e('[OpenSubtitles] Search failed: $e');
      return [];
    }
  }

  @override
  Future<String> download(String url, {String? languageHint}) async {
    try {
      final downloadResponse = await http.post(
        Uri.parse('${providerType.baseUrl}/download'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Api-Key': _apiKey!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'file_id': int.parse(url)}),
      );

      if (downloadResponse.statusCode != 200) {
        throw Exception('Download link failed');
      }

      final downloadData = jsonDecode(downloadResponse.body);
      final fileResponse = await http.get(Uri.parse(downloadData['link']));
      
      if (fileResponse.statusCode != 200) {
        throw Exception('File download failed');
      }

      return utf8.decode(fileResponse.bodyBytes);
    } catch (e) {
      Logger.e('[OpenSubtitles] Download failed: $e');
      rethrow;
    }
  }
}

class SubDLProvider implements BaseSubtitleProvider {
  @override
  SubtitleProvider get providerType => SubtitleProvider.subdl;
  
  final String? _apiKey;
  
  SubDLProvider({String? apiKey}) : _apiKey = apiKey;

  @override
  Future<List<OnlineSubtitle>> search(SubtitleSearchParams params) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) return [];
      if (params.imdbId == null) return [];

      final imdbId = params.imdbId!.startsWith('tt') ? params.imdbId! : 'tt${params.imdbId}';

      final convertedLangs = params.languages
          .map((lang) => LanguageUtils.toSubDLLanguage(lang))
          .whereType<String>()
          .toList();

      final queryParams = {
        'api_key': _apiKey!,
        'imdb_id': imdbId,
        'type': params.type,
        'subs_per_page': '30',
      };

      if (convertedLangs.isNotEmpty) {
        queryParams['languages'] = convertedLangs.join(',');
      }

      if (params.type == 'episode' && params.episode != null) {
        queryParams['season_number'] = (params.season ?? 1).toString();
        queryParams['episode_number'] = params.episode.toString();
      }

      final url = Uri.parse('${providerType.baseUrl}/subtitles').replace(queryParameters: queryParams);
      
      final response = await http.get(url).timeout(params.timeout);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data['status'] != true) return [];

      final subtitles = data['subtitles'] as List? ?? [];

      return subtitles.map<OnlineSubtitle>((sub) {
        final urlMatch = RegExp(r'/subtitle/(\d+)-(\d+)\.zip').firstMatch(sub['url'] ?? '');
        final sdId = urlMatch?.group(1);
        final subId = urlMatch?.group(2);
        final fileId = 'subdl_${sdId}_$subId';
        final langCode = LanguageUtils.normalizeLanguageCode(sub['lang'] ?? '');

        return OnlineSubtitle(
          id: fileId,
          url: sub['url'] ?? '',
          flagUrl: LanguageUtils.getFlagUrl(sub['lang'] ?? ''),
          format: 'srt',
          encoding: 'utf-8',
          label: sub['release_name'] ?? sub['name'] ?? 'Unknown',
          language: sub['lang'] ?? '',
          languageCode: langCode,
          media: '',
          isHearingImpaired: sub['hi'] == 1,
          source: 'subdl',
          provider: providerType.name,
          downloads: int.tryParse(sub['download_count']?.toString() ?? '0') ?? 0,
          rating: double.tryParse(sub['rating']?.toString() ?? '0') ?? 0,
          isSeasonPack: (params.type == 'episode' && 
                        sub['episode'] == null && 
                        sub['episode_from'] != sub['episode_end']),
        );
      }).toList();
    } catch (e) {
      Logger.e('[SubDL] Search failed: $e');
      return [];
    }
  }

  @override
  Future<String> download(String url, {String? languageHint}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }
      return utf8.decode(response.bodyBytes);
    } catch (e) {
      Logger.e('[SubDL] Download failed: $e');
      rethrow;
    }
  }
}

class JimakuProvider implements BaseSubtitleProvider {
  @override
  SubtitleProvider get providerType => SubtitleProvider.jimaku;
  
  final String? _apiKey;
  
  JimakuProvider({String? apiKey}) : _apiKey = apiKey;

  @override
  Future<List<OnlineSubtitle>> search(SubtitleSearchParams params) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) return [];

      String? searchId;
      if (params.anilistId != null) {
        searchId = 'anilist_id=${params.anilistId}';
      } else if (params.malId != null) {
        final anilistId = await _malToAnilist(params.malId!);
        if (anilistId != null) {
          searchId = 'anilist_id=$anilistId';
        }
      }

      if (searchId == null) {
        searchId = 'query=${Uri.encodeComponent(params.title)}';
      }

      final url = Uri.parse('${providerType.baseUrl}/entries/search?$searchId');
      
      final entriesResponse = await http.get(
        url,
        headers: {'Authorization': _apiKey!},
      ).timeout(params.timeout);

      if (entriesResponse.statusCode != 200) return [];

      final entries = jsonDecode(entriesResponse.body) as List;
      if (entries.isEmpty) return [];

      final entryId = entries.first['id'];
      
      final filesUrl = Uri.parse('${providerType.baseUrl}/entries/$entryId/files${params.episode != null ? '?episode=${params.episode}' : ''}');
      
      final filesResponse = await http.get(
        filesUrl,
        headers: {'Authorization': _apiKey!},
      ).timeout(params.timeout);

      if (filesResponse.statusCode != 200) return [];

      final files = jsonDecode(filesResponse.body) as List;

      return files.where((f) {
        final name = (f['name'] ?? '').toLowerCase();
        return !name.endsWith('.zip') && !name.endsWith('.rar') && !name.endsWith('.7z');
      }).map<OnlineSubtitle>((file) {
        final name = file['name'] ?? '';
        final format = name.split('.').last.toLowerCase();
        final langCode = _detectJimakuLanguage(name);

        return OnlineSubtitle(
          id: 'jimaku_${file['url']}',
          url: file['url'],
          flagUrl: LanguageUtils.getFlagUrl(langCode),
          format: format,
          encoding: 'utf-8',
          label: name.replaceAll('.srt', '').replaceAll('.ass', ''),
          language: LanguageUtils.iso2ToDisplay[langCode] ?? 'Japanese',
          languageCode: langCode,
          media: '',
          isHearingImpaired: name.contains(RegExp(r'[\[\(](?:hi|cc|sdh)[\]\)]', caseSensitive: false)),
          source: 'jimaku',
          provider: providerType.name,
          downloads: 0,
          rating: 0,
          isSeasonPack: false,
        );
      }).toList();
    } catch (e) {
      Logger.e('[Jimaku] Search failed: $e');
      return [];
    }
  }

  Future<String?> _malToAnilist(String malId) async {
    try {
      final query = '''
      query {
        Media(idMal: $malId, type: ANIME) { id }
      }
      ''';

      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['Media']['id']?.toString();
      }
    } catch (e) {
      Logger.e('[Jimaku] MAL to AniList conversion failed: $e');
    }
    return null;
  }

  String _detectJimakuLanguage(String filename) {
    final lower = filename.toLowerCase();
    if (lower.contains('.en.') || lower.contains('[en]')) return 'eng';
    if (lower.contains('.ja.') || lower.contains('[ja]')) return 'jpn';
    return 'jpn';
  }

  @override
  Future<String> download(String url, {String? languageHint}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': _apiKey!},
      );
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }
      return utf8.decode(response.bodyBytes);
    } catch (e) {
      Logger.e('[Jimaku] Download failed: $e');
      rethrow;
    }
  }
}

class SubtitleRepository {
  static final SubtitleRepository _instance = SubtitleRepository._internal();
  factory SubtitleRepository() => _instance;
  SubtitleRepository._internal();

  final Map<SubtitleProvider, BaseSubtitleProvider> _providers = {};
  final List<SubtitleProvider> _enabledProviders = [];

  Future<void> initialize() async {
    _registerProvider(WyzieProvider());
    
    final prefs = await SharedPreferences.getInstance();
    
    for (final provider in SubtitleProvider.values) {
      if (provider == SubtitleProvider.wyzie) {
        _enabledProviders.add(provider);
        continue;
      }
      
      final apiKey = prefs.getString('${provider.name}_api_key');
      if (apiKey != null && apiKey.isNotEmpty) {
        switch (provider) {
          case SubtitleProvider.opensubtitles:
            _registerProvider(OpenSubtitlesProvider(apiKey: apiKey));
            _enabledProviders.add(provider);
            break;
          case SubtitleProvider.subdl:
            _registerProvider(SubDLProvider(apiKey: apiKey));
            _enabledProviders.add(provider);
            break;
          case SubtitleProvider.jimaku:
            _registerProvider(JimakuProvider(apiKey: apiKey));
            _enabledProviders.add(provider);
            break;
          default:
            break;
        }
      }
    }
  }

  void _registerProvider(BaseSubtitleProvider provider) {
    _providers[provider.providerType] = provider;
  }

  List<SubtitleProvider> get enabledProviders => List.unmodifiable(_enabledProviders);

  Future<void> setProviderEnabled(SubtitleProvider provider, bool enabled, {String? apiKey}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (enabled) {
      if (apiKey != null) {
        await prefs.setString('${provider.name}_api_key', apiKey);
        
        switch (provider) {
          case SubtitleProvider.opensubtitles:
            _registerProvider(OpenSubtitlesProvider(apiKey: apiKey));
            break;
          case SubtitleProvider.subdl:
            _registerProvider(SubDLProvider(apiKey: apiKey));
            break;
          case SubtitleProvider.jimaku:
            _registerProvider(JimakuProvider(apiKey: apiKey));
            break;
          default:
            break;
        }
      }
      
      if (!_enabledProviders.contains(provider)) {
        _enabledProviders.add(provider);
      }
    } else {
      await prefs.remove('${provider.name}_api_key');
      _enabledProviders.remove(provider);
      _providers.remove(provider);
    }
  }

  Future<Map<SubtitleProvider, List<OnlineSubtitle>>> searchAll(SubtitleSearchParams params) async {
    final results = <SubtitleProvider, List<OnlineSubtitle>>{};
    final futures = <Future>[];

    for (final providerType in _enabledProviders) {
      final provider = _providers[providerType];
      if (provider == null) continue;

      futures.add(Future(() async {
        try {
          final subs = await provider.search(params);
          results[providerType] = subs;
        } catch (e) {
          Logger.e('[${providerType.name}] Search failed: $e');
          results[providerType] = [];
        }
      }));
    }

    await Future.wait(futures);
    return results;
  }

  Future<List<OnlineSubtitle>> searchFromProvider(SubtitleProvider providerType, SubtitleSearchParams params) async {
    final provider = _providers[providerType];
    if (provider == null) return [];
    
    try {
      return await provider.search(params);
    } catch (e) {
      Logger.e('[${providerType.name}] Search failed: $e');
      return [];
    }
  }

  Future<String> downloadFromProvider(SubtitleProvider providerType, String url, {String? languageHint}) async {
    final provider = _providers[providerType];
    if (provider == null) throw Exception('Provider not found');
    
    return await provider.download(url, languageHint: languageHint);
  }
}
