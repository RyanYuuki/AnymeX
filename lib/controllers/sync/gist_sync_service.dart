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

  Future<String?> _ensureGistId() async {
    if (_gistId != null) return _gistId;
    try {
      final resp =
          await http.get(Uri.parse('$_apiBase/gists'), headers: _headers);
      if (resp.statusCode != 200) {
        Logger.e('[GistSync] List gists failed: ${resp.statusCode}');
        return null;
      }

      final list = json.decode(resp.body) as List<dynamic>;
      for (final g in list) {
        final files = g['files'] as Map<String, dynamic>;
        if (files.containsKey(_fileName)) {
          _gistId = g['id'] as String;
          Logger.i('[GistSync] Found existing gist: $_gistId');
          return _gistId;
        }
      }

      final create = await http.post(
        Uri.parse('$_apiBase/gists'),
        headers: _headers,
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

      final resp = await http.get(
        Uri.parse('$_apiBase/gists/$gistId'),
        headers: _headers,
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

      final resp = await http.patch(
        Uri.parse('$_apiBase/gists/$gistId'),
        headers: _headers,
        body: json.encode({
          'files': {
            _fileName: {'content': json.encode(data)},
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

  Future<void> upsert(GistProgressEntry entry) async {
    if (!isReady) return;
    try {
      final raw = await _downloadRaw();
      final existing = raw[entry.mediaId] as Map<String, dynamic>?;

      if (existing != null &&
          (existing['updatedAt'] as int? ?? 0) >= entry.updatedAt) {
        Logger.i('[GistSync] Remote already newer for ${entry.mediaId}');
        return;
      }

      raw[entry.mediaId] = entry.toJson();
      if (entry.malId != null && entry.malId!.isNotEmpty) {
        raw[entry.malId!] = entry.toJson();
      }

      await _upload(raw);
      Logger.i('[GistSync] Upserted ${entry.mediaId}');
    } catch (e) {
      Logger.e('[GistSync] upsert: $e');
    }
  }

  Future<void> remove(String mediaId, {String? malId}) async {
    if (!isReady) return;
    try {
      final raw = await _downloadRaw();
      bool changed = raw.remove(mediaId) != null;
      if (malId != null && malId.isNotEmpty) {
        if (raw.remove(malId) != null) changed = true;
      }
      if (changed) {
        await _upload(raw);
        Logger.i('[GistSync] Removed $mediaId');
      }
    } catch (e) {
      Logger.e('[GistSync] remove: $e');
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
