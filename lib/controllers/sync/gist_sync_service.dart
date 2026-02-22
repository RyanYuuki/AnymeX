import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:http/http.dart' as http;

class GistProgressEntry {
  final String mediaId;
  final String? malId;
  final String mediaType;
  final String? serviceType;
  final String? episodeNumber;
  final int? timestampMs;
  final int? durationMs;
  final double? chapterNumber;
  final int? pageNumber;
  final int? totalPages;
  final double? scrollOffset;
  final double? maxScrollOffset;
  final int updatedAt;

  const GistProgressEntry({
    required this.mediaId,
    this.malId,
    required this.mediaType,
    this.serviceType,
    this.episodeNumber,
    this.timestampMs,
    this.durationMs,
    this.chapterNumber,
    this.pageNumber,
    this.totalPages,
    this.scrollOffset,
    this.maxScrollOffset,
    required this.updatedAt,
  });

  factory GistProgressEntry.fromJson(Map<String, dynamic> j) =>
      GistProgressEntry(
        mediaId: j['mediaId'] as String,
        malId: j['malId'] as String?,
        mediaType: j['mediaType'] as String,
        serviceType: j['serviceType'] as String?,
        episodeNumber: j['episodeNumber'] as String?,
        timestampMs: j['timestampMs'] as int?,
        durationMs: j['durationMs'] as int?,
        chapterNumber: (j['chapterNumber'] as num?)?.toDouble(),
        pageNumber: j['pageNumber'] as int?,
        totalPages: j['totalPages'] as int?,
        scrollOffset: (j['scrollOffset'] as num?)?.toDouble(),
        maxScrollOffset: (j['maxScrollOffset'] as num?)?.toDouble(),
        updatedAt: j['updatedAt'] as int,
      );

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        if (malId != null) 'malId': malId,
        'mediaType': mediaType,
        if (serviceType != null) 'serviceType': serviceType,
        if (episodeNumber != null) 'episodeNumber': episodeNumber,
        if (timestampMs != null) 'timestampMs': timestampMs,
        if (durationMs != null) 'durationMs': durationMs,
        if (chapterNumber != null) 'chapterNumber': chapterNumber,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (totalPages != null) 'totalPages': totalPages,
        if (scrollOffset != null) 'scrollOffset': scrollOffset,
        if (maxScrollOffset != null) 'maxScrollOffset': maxScrollOffset,
        'updatedAt': updatedAt,
      };
}

enum GistRemoveResult { removed, notFound, failed }

const _dohProviders = [
  'https://dns.google/resolve',
  'https://cloudflare-dns.com/dns-query',
];

Future<String?> _resolveViaDoh(String hostname) async {
  for (final provider in _dohProviders) {
    try {
      final uri = Uri.parse(provider).replace(
        queryParameters: {'name': hostname, 'type': 'A'},
      );
      final resp = await http.get(uri, headers: {
        'Accept': 'application/dns-json'
      }).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final answers = data['Answer'] as List<dynamic>?;
        if (answers != null && answers.isNotEmpty) {
          for (final answer in answers) {
            if ((answer['type'] as int?) == 1) {
              final ip = answer['data'] as String?;
              if (ip != null && ip.isNotEmpty) {
                Logger.i(
                    '[GistSync] DoH resolved $hostname → $ip via $provider');
                return ip;
              }
            }
          }
        }
      }
    } catch (e) {
      Logger.i('[GistSync] DoH provider $provider failed: $e');
    }
  }
  return null;
}

Uri _uriWithIp(Uri originalUri, String ip) {
  return originalUri.replace(host: ip);
}

Future<http.Response> _resilientGet(
  Uri uri,
  Map<String, String> headers,
) async {
  try {
    final resp = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode < 500) return resp;
  } catch (e) {
    Logger.i('[GistSync] Normal GET failed, trying DoH fallback: $e');
  }

  final ip = await _resolveViaDoh(uri.host);
  if (ip == null) {
    return http.get(uri, headers: headers);
  }

  final fallbackUri = _uriWithIp(uri, ip);
  final fallbackHeaders = {
    ...headers,
    'Host': uri.host,
  };
  return http
      .get(fallbackUri, headers: fallbackHeaders)
      .timeout(const Duration(seconds: 10));
}

Future<http.Response> _resilientPost(
  Uri uri,
  Map<String, String> headers, {
  String? body,
}) async {
  try {
    final resp = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode < 500) return resp;
  } catch (e) {
    Logger.i('[GistSync] Normal POST failed, trying DoH fallback: $e');
  }

  final ip = await _resolveViaDoh(uri.host);
  if (ip == null) {
    return http.post(uri, headers: headers, body: body);
  }

  final fallbackUri = _uriWithIp(uri, ip);
  final fallbackHeaders = {...headers, 'Host': uri.host};
  return http
      .post(fallbackUri, headers: fallbackHeaders, body: body)
      .timeout(const Duration(seconds: 10));
}

Future<http.Response> _resilientPatch(
  Uri uri,
  Map<String, String> headers, {
  String? body,
}) async {
  try {
    final resp = await http
        .patch(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode < 500) return resp;
  } catch (e) {
    Logger.i('[GistSync] Normal PATCH failed, trying DoH fallback: $e');
  }

  final ip = await _resolveViaDoh(uri.host);
  if (ip == null) {
    return http.patch(uri, headers: headers, body: body);
  }

  final fallbackUri = _uriWithIp(uri, ip);
  final fallbackHeaders = {...headers, 'Host': uri.host};
  return http
      .patch(fallbackUri, headers: fallbackHeaders, body: body)
      .timeout(const Duration(seconds: 10));
}

Future<http.Response> _resilientDelete(
  Uri uri,
  Map<String, String> headers,
) async {
  try {
    final resp = await http
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode < 500) return resp;
  } catch (e) {
    Logger.i('[GistSync] Normal DELETE failed, trying DoH fallback: $e');
  }

  final ip = await _resolveViaDoh(uri.host);
  if (ip == null) {
    return http.delete(uri, headers: headers);
  }

  final fallbackUri = _uriWithIp(uri, ip);
  final fallbackHeaders = {...headers, 'Host': uri.host};
  return http
      .delete(fallbackUri, headers: fallbackHeaders)
      .timeout(const Duration(seconds: 10));
}

class GistSyncService {
  static const _fileName = 'anymex_progress.json';
  static const _apiBase = 'https://api.github.com';

  static final GistSyncService _instance = GistSyncService._();
  factory GistSyncService() => _instance;
  GistSyncService._();

  String? _token;
  String? _gistId;

  bool get isReady => _token != null && _token!.isNotEmpty;

  void setToken(String token) {
    _token = token.trim();
    _gistId = null;
    Logger.i('[GistSync] Token set');
  }

  void clear() {
    _token = null;
    _gistId = null;
    Logger.i('[GistSync] Cleared');
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/json',
      };

  Future<String?> _findExistingGistId() async {
    if (_gistId != null) return _gistId;
    try {
      final resp = await _resilientGet(
        Uri.parse('$_apiBase/gists'),
        _headers,
      );
      if (resp.statusCode != 200) {
        Logger.e('[GistSync] List gists failed: ${resp.statusCode}');
        return null;
      }

      final list = json.decode(resp.body) as List<dynamic>;
      for (final g in list) {
        final files = g['files'] as Map<String, dynamic>? ?? const {};
        if (files.containsKey(_fileName)) {
          _gistId = g['id'] as String;
          Logger.i('[GistSync] Found existing gist: $_gistId');
          return _gistId;
        }
      }
    } catch (e) {
      Logger.e('[GistSync] _findExistingGistId: $e');
    }
    return null;
  }

  Future<String?> _ensureGistId() async {
    final existing = await _findExistingGistId();
    if (existing != null) return existing;
    try {
      final create = await _resilientPost(
        Uri.parse('$_apiBase/gists'),
        _headers,
        body: json.encode({
          'description': 'AnymeX progress sync',
          'public': false,
          'files': {
            _fileName: {'content': '{}'},
          },
        }),
      );
      if (create.statusCode == 201) {
        final data = json.decode(create.body) as Map<String, dynamic>;
        _gistId = data['id'] as String;
        Logger.i('[GistSync] Created new gist: $_gistId');
        return _gistId;
      }
      Logger.e('[GistSync] Create gist failed: ${create.statusCode}');
    } catch (e) {
      Logger.e('[GistSync] _ensureGistId: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> _downloadRaw() async {
    try {
      final gistId = await _ensureGistId();
      if (gistId == null) return {};

      final resp = await _resilientGet(
        Uri.parse('$_apiBase/gists/$gistId'),
        _headers,
      );
      if (resp.statusCode != 200) return {};

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final content = ((data['files'] as Map<String, dynamic>?)?[_fileName]
          as Map<String, dynamic>?)?['content'] as String?;
      if (content == null || content.trim().isEmpty) return {};
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      Logger.e('[GistSync] _downloadRaw: $e');
      return {};
    }
  }

  Future<void> _upload(Map<String, dynamic> data) async {
    try {
      final gistId = await _ensureGistId();
      if (gistId == null) return;

      final resp = await _resilientPatch(
        Uri.parse('$_apiBase/gists/$gistId'),
        _headers,
        body: json.encode({
          'files': {
            _fileName: {'content': _encodeOneEntryPerLine(data)},
          },
        }),
      );
      if (resp.statusCode != 200) {
        Logger.e('[GistSync] Upload failed: ${resp.statusCode}');
      }
    } catch (e) {
      Logger.e('[GistSync] _upload: $e');
    }
  }

  String _encodeOneEntryPerLine(Map<String, dynamic> data) {
    if (data.isEmpty) return '{}';

    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final buffer = StringBuffer('{\n');
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final encodedKey = json.encode(entry.key);
      final encodedValue = json.encode(entry.value);
      final isLast = i == entries.length - 1;
      buffer.write('  $encodedKey: $encodedValue${isLast ? '' : ','}\n');
    }
    buffer.write('}');
    return buffer.toString();
  }

  Future<void> syncNow() async {
    if (!isReady) {
      throw StateError('Sync service is not ready.');
    }

    final gistId = await _ensureGistId();
    if (gistId == null) {
      throw Exception('Unable to create or locate the AnymeX sync gist.');
    }

    final resp = await _resilientGet(
      Uri.parse('$_apiBase/gists/$gistId'),
      _headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('GitHub returned HTTP ${resp.statusCode}.');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final content = ((data['files'] as Map<String, dynamic>?)?[_fileName]
        as Map<String, dynamic>?)?['content'] as String?;
    if (content != null && content.trim().isNotEmpty) {
      json.decode(content) as Map<String, dynamic>;
    }
  }

  Future<bool> deleteSyncGist() async {
    if (!isReady) {
      throw StateError('Sync service is not ready.');
    }

    final gistId = await _findExistingGistId();
    if (gistId == null) {
      return false;
    }

    final resp = await _resilientDelete(
      Uri.parse('$_apiBase/gists/$gistId'),
      _headers,
    );

    if (resp.statusCode == 204) {
      Logger.i('[GistSync] Deleted gist: $gistId');
      _gistId = null;
      return true;
    }

    if (resp.statusCode == 404) {
      Logger.i('[GistSync] Gist not found while deleting: $gistId');
      _gistId = null;
      return false;
    }

    throw Exception('Delete gist failed: HTTP ${resp.statusCode}.');
  }

  Future<bool> upsert(GistProgressEntry entry) async {
    if (!isReady) return false;
    try {
      final raw = await _downloadRaw();
      final existing = raw[entry.mediaId] as Map<String, dynamic>?;

      if (existing != null &&
          (existing['updatedAt'] as int? ?? 0) >= entry.updatedAt) {
        Logger.i('[GistSync] Remote already newer for ${entry.mediaId}');
        return true;
      }

      raw[entry.mediaId] = entry.toJson();
      if (entry.malId != null && entry.malId!.isNotEmpty) {
        raw[entry.malId!] = entry.toJson();
      }

      await _upload(raw);
      Logger.i('[GistSync] Upserted ${entry.mediaId}');
      return true;
    } catch (e) {
      Logger.e('[GistSync] upsert: $e');
      return false;
    }
  }

  Future<GistRemoveResult> remove(String mediaId, {String? malId}) async {
    if (!isReady) return GistRemoveResult.failed;
    try {
      final raw = await _downloadRaw();
      bool changed = raw.remove(mediaId) != null;
      if (malId != null && malId.isNotEmpty) {
        if (raw.remove(malId) != null) changed = true;
      }
      if (changed) {
        await _upload(raw);
        Logger.i('[GistSync] Removed $mediaId');
        return GistRemoveResult.removed;
      }
      return GistRemoveResult.notFound;
    } catch (e) {
      Logger.e('[GistSync] remove: $e');
      return GistRemoveResult.failed;
    }
  }

  Future<GistProgressEntry?> fetch(String mediaId, {String? malId}) async {
    if (!isReady) return null;
    try {
      final raw = await _downloadRaw();
      Map<String, dynamic>? found = raw[mediaId] as Map<String, dynamic>?;
      if (found == null && malId != null && malId.isNotEmpty) {
        found = raw[malId] as Map<String, dynamic>?;
      }
      if (found == null) return null;
      return GistProgressEntry.fromJson(found);
    } catch (e) {
      Logger.e('[GistSync] fetch: $e');
      return null;
    }
  }
}
