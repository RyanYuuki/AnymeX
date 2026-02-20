import 'dart:convert';
import 'dart:io';
import 'package:anymex/utils/logger.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class CloudProgressEntry {
  final String mediaId;
  final String? malId;
  final String mediaType;
  final String? episodeNumber;
  final int? timestampMs;
  final int? durationMs;
  final double? chapterNumber;
  final int? pageNumber;
  final int? totalPages;
  final double? scrollOffset;
  final double? maxScrollOffset;
  final int updatedAt;

  const CloudProgressEntry({
    required this.mediaId,
    this.malId,
    required this.mediaType,
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

  factory CloudProgressEntry.fromJson(Map<String, dynamic> json) {
    return CloudProgressEntry(
      mediaId: json['mediaId'] as String,
      malId: json['malId'] as String?,
      mediaType: json['mediaType'] as String,
      episodeNumber: json['episodeNumber'] as String?,
      timestampMs: json['timestampMs'] as int?,
      durationMs: json['durationMs'] as int?,
      chapterNumber: (json['chapterNumber'] as num?)?.toDouble(),
      pageNumber: json['pageNumber'] as int?,
      totalPages: json['totalPages'] as int?,
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble(),
      maxScrollOffset: (json['maxScrollOffset'] as num?)?.toDouble(),
      updatedAt: json['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        if (malId != null) 'malId': malId,
        'mediaType': mediaType,
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

  CloudProgressEntry copyWith({
    String? mediaId,
    String? malId,
    String? mediaType,
    String? episodeNumber,
    int? timestampMs,
    int? durationMs,
    double? chapterNumber,
    int? pageNumber,
    int? totalPages,
    double? scrollOffset,
    double? maxScrollOffset,
    int? updatedAt,
  }) {
    return CloudProgressEntry(
      mediaId: mediaId ?? this.mediaId,
      malId: malId ?? this.malId,
      mediaType: mediaType ?? this.mediaType,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      timestampMs: timestampMs ?? this.timestampMs,
      durationMs: durationMs ?? this.durationMs,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      maxScrollOffset: maxScrollOffset ?? this.maxScrollOffset,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CloudSyncService {
  static const _fileName = 'anymex_progress_sync.json';
  static const _scopes = [drive.DriveApi.driveAppdataScope];
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  drive.DriveApi? _driveApi;
  String? _cachedFileId;
  
  void setCredentials(String accessToken, DateTime expiry) {
    final credentials = AccessCredentials(
      AccessToken('Bearer', accessToken, expiry.toUtc()),
      null,
      _scopes,
    );
    final client = authenticatedClient(http.Client(), credentials);
    _driveApi = drive.DriveApi(client);
    Logger.i('[CloudSync] Drive client initialised');
  }

  bool get isReady => _driveApi != null;

  void clear() {
    _driveApi = null;
    _cachedFileId = null;
  }
  
  Future<String?> _getRemoteFileId() async {
    if (_cachedFileId != null) return _cachedFileId;
    try {
      final list = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_fileName'",
        $fields: 'files(id)',
      );
      if (list.files != null && list.files!.isNotEmpty) {
        _cachedFileId = list.files!.first.id;
      }
    } catch (e) {
      Logger.e('[CloudSync] _getRemoteFileId error: $e');
    }
    return _cachedFileId;
  }

  Future<Map<String, CloudProgressEntry>> downloadAll() async {
    if (!isReady) return {};
    try {
      final fileId = await _getRemoteFileId();
      if (fileId == null) return {};
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final bytes = await _collectBytes(media.stream);
      final jsonStr = utf8.decode(bytes);
      final Map<String, dynamic> raw = json.decode(jsonStr);
      final result = <String, CloudProgressEntry>{};
      for (final entry in raw.values) {
        if (entry is Map<String, dynamic>) {
          final parsed = CloudProgressEntry.fromJson(entry);
          result[parsed.mediaId] = parsed;
          if (parsed.malId != null && parsed.malId!.isNotEmpty) {
            result[parsed.malId!] = parsed;
          }
        }
      }
      Logger.i('[CloudSync] Downloaded ${result.length} entries');
      return result;
    } catch (e) {
      Logger.e('[CloudSync] downloadAll error: $e');
      return {};
    }
  }
  
  Future<void> upsert(CloudProgressEntry entry) async {
    if (!isReady) return;
    try {
      final current = await _downloadRaw();
      final key = entry.mediaId;
      final existing = current[key];

      if (existing != null &&
          existing['updatedAt'] != null &&
          (existing['updatedAt'] as int) >= entry.updatedAt) {
        Logger.i('[CloudSync] Remote already newer for $key, skipping upload');
        return;
      }

      current[key] = entry.toJson();

      if (entry.malId != null && entry.malId!.isNotEmpty) {
        current[entry.malId!] = entry.toJson();
      }

      await _upload(current);
      Logger.i('[CloudSync] Upserted entry for $key');
    } catch (e) {
      Logger.e('[CloudSync] upsert error: $e');
    }
  }

  Future<CloudProgressEntry?> fetch(String mediaId, {String? malId}) async {
    if (!isReady) return null;
    try {
      final raw = await _downloadRaw();
      Map<String, dynamic>? found = raw[mediaId];
      if (found == null && malId != null && malId.isNotEmpty) {
        found = raw[malId];
      }
      if (found == null) return null;
      return CloudProgressEntry.fromJson(found);
    } catch (e) {
      Logger.e('[CloudSync] fetch error: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>> _downloadRaw() async {
    try {
      final fileId = await _getRemoteFileId();
      if (fileId == null) return {};

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await _collectBytes(media.stream);
      return json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      Logger.e('[CloudSync] _downloadRaw: $e');
      return {};
    }
  }

  Future<void> _upload(Map<String, dynamic> data) async {
    final bytes = utf8.encode(json.encode(data));
    final stream = Stream.value(bytes);
    final media = drive.Media(stream, bytes.length,
        contentType: 'application/json');

    final fileId = await _getRemoteFileId();
    if (fileId != null) {
      await _driveApi!.files.update(
        drive.File(),
        fileId,
        uploadMedia: media,
      );
    } else {
      final file = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];
      final created = await _driveApi!.files.create(
        file,
        uploadMedia: media,
        $fields: 'id',
      );
      _cachedFileId = created.id;
    }
  }

  Future<List<int>> _collectBytes(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return chunks;
  }
}
