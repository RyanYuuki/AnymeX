import 'package:anymex/controllers/sync/gist_sync_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'cloud_sync_provider.dart';

class GistCloudSyncProvider implements CloudSyncProvider {
  final GistSyncService _service = GistSyncService();

  @override
  String get id => 'gist';

  @override
  String get displayName => 'GitHub Gist';

  void _ensureToken() {
    final token = SyncKeys.gistGithubToken.get<String>('');
    if (token.isNotEmpty) {
      _service.setToken(token);
    }
  }

  @override
  Future<bool> testConnection() async {
    _ensureToken();
    if (!_service.isReady) return false;
    try {
      return await _service.hasSyncGist();
    } catch (e) {
      Logger.e('GistCloudSyncProvider testConnection: $e');
      return false;
    }
  }

  @override
  Future<void> uploadData(Map<String, dynamic> data) async {
    _ensureToken();
    if (!_service.isReady) throw StateError('GitHub token not set');

    // 1. Download existing gist data to preserve all existing watch/read progress entries
    final raw = await _service.downloadRaw();

    // Extract or initialize progress map
    final progressMap = <String, dynamic>{};
    if (raw['progress'] is Map) {
      progressMap.addAll(Map<String, dynamic>.from(raw['progress'] as Map));
    } else {
      // Migrate legacy flat root entries (keys like "12345" where value is Map)
      for (final entry in raw.entries) {
        if (entry.key != 'schemaVersion' &&
            entry.key != 'lastUpdated' &&
            entry.key != 'library' &&
            entry.key != 'settings' &&
            entry.key != 'sourceMappings' &&
            entry.key != 'stats' &&
            entry.value is Map) {
          progressMap[entry.key] = entry.value;
        }
      }
    }

    // 2. Build structured payload
    final updated = <String, dynamic>{
      'schemaVersion': 2,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'library': {
        'anime': data['anime'] ?? [],
        'manga': data['manga'] ?? [],
        'novel': data['novel'] ?? [],
        'customLists': data['customLists'] ?? [],
      },
      'settings': data['settings'] ?? [],
      'sourceMappings': data['sourceMappings'] ?? [],
      'stats': {
        'dailyActivities': data['dailyActivities'] ?? [],
        'mediaStats': data['mediaStats'] ?? [],
      },
      'progress': progressMap,
    };

    // 3. Upload back to anymex_progress.json
    await _service.uploadRaw(updated);
  }

  @override
  Future<Map<String, dynamic>?> downloadData() async {
    _ensureToken();
    if (!_service.isReady) return null;

    final raw = await _service.downloadRaw();
    if (raw.isEmpty) return null;

    // Check if new structured format (v2)
    if (raw['library'] is Map || raw['schemaVersion'] != null) {
      final library = (raw['library'] as Map?) ?? const {};
      final stats = (raw['stats'] as Map?) ?? const {};

      return {
        'schemaVersion': raw['schemaVersion'] ?? 2,
        'anime': library['anime'] ?? [],
        'manga': library['manga'] ?? [],
        'novel': library['novel'] ?? [],
        'customLists': library['customLists'] ?? [],
        'settings': raw['settings'] ?? [],
        'sourceMappings': raw['sourceMappings'] ?? [],
        'dailyActivities': stats['dailyActivities'] ?? [],
        'mediaStats': stats['mediaStats'] ?? [],
        'progress': raw['progress'] ?? {},
      };
    }

    // Legacy format: raw dictionary of media progress
    return {
      'schemaVersion': 1,
      'anime': [],
      'manga': [],
      'novel': [],
      'customLists': [],
      'settings': [],
      'sourceMappings': [],
      'dailyActivities': [],
      'mediaStats': [],
      'progress': raw,
    };
  }

  @override
  Future<CloudFileMetadata?> getMetadata() async {
    _ensureToken();
    if (!_service.isReady) return null;

    final hasGist = await _service.hasSyncGist();
    if (!hasGist) return null;

    return const CloudFileMetadata(
      name: 'anymex_progress.json',
      sizeBytes: 0,
    );
  }

  @override
  Future<bool> deleteFile() async {
    _ensureToken();
    if (!_service.isReady) return false;

    // Remove only cloud sync sections, preserving progress map
    final raw = await _service.downloadRaw();
    raw.remove('library');
    raw.remove('settings');
    raw.remove('sourceMappings');
    raw.remove('stats');
    raw.remove('schemaVersion');
    await _service.uploadRaw(raw);
    return true;
  }
}
