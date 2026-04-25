import 'dart:convert';

import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/main.dart';
import 'package:anymex/utils/cloud_encryption.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';

class CloudSyncService extends GetxController {
  CloudAuthService get _auth => Get.find<CloudAuthService>();

  String get _baseUrl {
    final envBase = (dotenv.env['COMMENTS_BASE_URL'] ?? '').trim();
    if (envBase.isEmpty) return '';
    return envBase.endsWith('/')
        ? envBase.substring(0, envBase.length - 1)
        : envBase;
  }

  String get _functionsUrl => '$_baseUrl/functions/v1';
  RxBool isSyncing = false.obs;
  RxString syncStatus = ''.obs;

  String? _getCloudProfileId(String localProfileId) {
    try {
      final col = isar.collection<KeyValue>();
      final result = col
          .filter()
          .keyEqualTo('__cloud_profile_map__$localProfileId')
          .findFirstSync();
      if (result?.value == null) return null;
      final data = jsonDecode(result!.value!);
      return data['cloud_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  void _setCloudProfileId(String localProfileId, String cloudProfileId) {
    try {
      final kv = KeyValue()
        ..key = '__cloud_profile_map__$localProfileId'
        ..value = jsonEncode({'cloud_id': cloudProfileId});
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error saving cloud profile map: $e');
    }
  }

  Future<Map<String, dynamic>?> getSyncStatus(String cloudProfileId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/status'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Map<String, dynamic>.from(data['sync_meta']);
      }
      return null;
    } catch (e) {
      Logger.i('Get sync status error: $e');
      return null;
    }
  }

  Future<bool> pushSettings(String cloudProfileId) async {
    try {
      final prefix = KvHelper.profilePrefix;
      final col = isar.collection<KeyValue>();
      final allKeys = col.where().findAllSync();

      final settings = <String, String>{};
      for (final kv in allKeys) {
        final key = kv.key;
        if (key.startsWith('__') && key.endsWith('__')) continue;
        if (prefix.isNotEmpty && !key.startsWith(prefix)) continue;
        if (key.startsWith('AuthKeys_')) continue;

        final suffix = prefix.isNotEmpty && key.startsWith(prefix)
            ? key.substring(prefix.length)
            : key;
        settings[suffix] = kv.value ?? '';
      }

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/settings'),
        headers: _auth.authHeaders,
        body: jsonEncode({'settings': settings}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Push settings error: $e');
      return false;
    }
  }

  Future<bool> pullSettings(String cloudProfileId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/settings'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return false;
      }

      final settings = Map<String, dynamic>.from(data['settings']);
      final prefix = KvHelper.profilePrefix;

      await isar.writeTxn(() async {
        for (final entry in settings.entries) {
          final fullKey = prefix.isEmpty ? entry.key : '$prefix${entry.key}';
          final kv = KeyValue()..key = fullKey..value = entry.value as String;
          await isar.collection<KeyValue>().put(kv);
        }
      });

      return true;
    } catch (e) {
      Logger.i('Pull settings error: $e');
      return false;
    }
  }

  Future<bool> pushLibrary(
    String cloudProfileId,
    String mediaType,
    List<OfflineMedia> items, {
    List<String>? removeMediaIds,
  }) async {
    try {
      final upsertItems = items.map((m) => _mediaToCloudJson(m)).toList();

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/library/$mediaType'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'upsert': upsertItems,
          if (removeMediaIds != null) 'remove': removeMediaIds,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Push library error: $e');
      return false;
    }
  }

  Future<List<OfflineMedia>> pullLibrary(
    String cloudProfileId,
    String mediaType, {
    int? sinceVersion,
  }) async {
    try {
      var url =
          '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/library/$mediaType';
      if (sinceVersion != null) {
        url += '?since_version=$sinceVersion';
      }

      final response = await http.get(Uri.parse(url), headers: _auth.authHeaders);

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return [];
      }

      final library = List<Map<String, dynamic>>.from(data['library'] ?? []);
      return library.map((item) => _cloudJsonToMedia(item)).toList();
    } catch (e) {
      Logger.i('Pull library error: $e');
      return [];
    }
  }

  Future<bool> pushCustomLists(
    String cloudProfileId,
    String mediaType,
    List<CustomList> lists,
  ) async {
    try {
      final listsJson = lists.map((l) => {
            'list_name': l.listName,
            'media_type_index': l.mediaTypeIndex,
            'media_ids': l.mediaIds ?? [],
          }).toList();

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/custom-lists/$mediaType'),
        headers: _auth.authHeaders,
        body: jsonEncode({'lists': listsJson}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Push custom lists error: $e');
      return false;
    }
  }

  Future<List<CustomList>> pullCustomLists(
    String cloudProfileId,
    String mediaType,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/custom-lists/$mediaType'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return [];
      }

      final lists = List<Map<String, dynamic>>.from(data['lists'] ?? []);
      return lists.map((l) => CustomList(
            listName: l['list_name'] as String? ?? 'Default',
            mediaIds: (l['media_ids'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            mediaTypeIndex: l['media_type_index'] as int? ?? 0,
          )).toList();
    } catch (e) {
      Logger.i('Pull custom lists error: $e');
      return [];
    }
  }

  Future<bool> pushTokens({
    required String cloudProfileId,
    required String service,
    required Map<String, dynamic> tokens,
    required String password,
    required String saltBase64,
  }) async {
    try {
      final salt = CloudEncryption.saltFromBase64(saltBase64);
      final encrypted =
          CloudEncryption.encrypt(jsonEncode(tokens), password, salt);

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/tokens'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'service': service,
          'encrypted_tokens': {'data': encrypted['encrypted']},
          'encryption_iv': encrypted['iv'],
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Push tokens error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> pullTokens({
    required String cloudProfileId,
    required String service,
    required String password,
    required String saltBase64,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/tokens'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return null;
      }

      final tokens = Map<String, dynamic>.from(data['tokens']);
      final serviceTokens = tokens[service];
      if (serviceTokens == null) return null;

      final encData = Map<String, dynamic>.from(serviceTokens);
      final encryptedData = (encData['encrypted_tokens'] as Map)['data'];
      final iv = encData['encryption_iv'] as String;

      final salt = CloudEncryption.saltFromBase64(saltBase64);
      final decrypted =
          CloudEncryption.decrypt(encryptedData, iv, password, salt);

      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      Logger.i('Pull tokens error: $e');
      return null;
    }
  }

  Future<bool> deleteTokens({
    required String cloudProfileId,
    required String service,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/tokens/$service'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Delete tokens error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fullExport(String cloudProfileId) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/$cloudProfileId/full-export'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      Logger.i('Full export error: $e');
      return null;
    }
  }

  Map<String, dynamic> _mediaToCloudJson(OfflineMedia m) {
    return {
      'media_id': m.mediaId,
      'jname': m.jname,
      'name': m.name,
      'english': m.english,
      'japanese': m.japanese,
      'description': m.description,
      'poster': m.poster,
      'cover': m.cover,
      'total_episodes': m.totalEpisodes,
      'total_chapters': m.totalChapters,
      'type': m.type,
      'season': m.season,
      'premiered': m.premiered,
      'duration': m.duration,
      'status': m.status,
      'rating': m.rating,
      'popularity': m.popularity,
      'format': m.format,
      'aired': m.aired,
      'genres': m.genres ?? [],
      'studios': m.studios ?? [],
      'service_index': m.serviceIndex ?? 0,
      'current_episode': m.currentEpisode?.toJson(),
      'current_chapter': m.currentChapter?.toJson(),
      'watched_episodes': m.watchedEpisodes?.map((e) => e.toJson()).toList() ?? [],
      'read_chapters': m.readChapters?.map((c) => c.toJson()).toList() ?? [],
      'chapters': m.chapters?.map((c) => c.toJson()).toList() ?? [],
      'episodes': m.episodes?.map((e) => e.toJson()).toList() ?? [],
    };
  }

  OfflineMedia _cloudJsonToMedia(Map<String, dynamic> json) {
    return OfflineMedia(
      mediaId: json['media_id'] as String?,
      jname: json['jname'] as String?,
      name: json['name'] as String?,
      english: json['english'] as String?,
      japanese: json['japanese'] as String?,
      description: json['description'] as String?,
      poster: json['poster'] as String?,
      cover: json['cover'] as String?,
      totalEpisodes: json['total_episodes']?.toString(),
      totalChapters: json['total_chapters']?.toString(),
      type: json['type'] as String?,
      season: json['season'] as String?,
      premiered: json['premiered'] as String?,
      duration: json['duration'] as String?,
      status: json['status'] as String?,
      rating: json['rating'] as String?,
      popularity: json['popularity'] as String?,
      format: json['format'] as String?,
      aired: json['aired'] as String?,
      genres: (json['genres'] as List?)?.cast<String>(),
      studios: (json['studios'] as List?)?.cast<String>(),
      serviceIndex: json['service_index'] as int?,
      mediaTypeIndex: json['media_type_index'] as int? ?? 0,
      currentEpisode: null,
      currentChapter: null,
      watchedEpisodes: [],
      readChapters: [],
      chapters: [],
      episodes: [],
    );
  }



  Future<bool> fullSyncPush({
    required String localProfileId,
    required String cloudProfileId,
    required String? encryptionPassword,
    required String encryptionSalt,
  }) async {
    isSyncing.value = true;
    syncStatus.value = 'Syncing settings...';

    try {
      if (!await pushSettings(cloudProfileId)) {
        syncStatus.value = 'Failed to sync settings';
        return false;
      }

      final pid = localProfileId;
      for (final entry in [
        {'type': 'anime', 'index': 1},
        {'type': 'manga', 'index': 0},
        {'type': 'novel', 'index': 2},
      ]) {
        syncStatus.value = 'Syncing ${entry['type']}...';
        final items = await isar
            .offlineMedias
            .filter()
            .profileIdEqualTo(pid)
            .and()
            .mediaTypeIndexEqualTo(entry['index'] as int)
            .findAll();

        if (items.isNotEmpty) {
          await pushLibrary(cloudProfileId, entry['type'] as String, items);
        }
      }

      for (final entry in [
        {'type': 'anime', 'index': 1},
        {'type': 'manga', 'index': 0},
        {'type': 'novel', 'index': 2},
      ]) {
        syncStatus.value = 'Syncing ${entry['type']} lists...';
        final lists = await isar
            .customLists
            .filter()
            .profileIdEqualTo(pid)
            .and()
            .mediaTypeIndexEqualTo(entry['index'] as int)
            .findAll();

        if (lists.isNotEmpty) {
          await pushCustomLists(cloudProfileId, entry['type'] as String, lists);
        }
      }

      if (encryptionPassword != null && encryptionPassword.isNotEmpty) {
        syncStatus.value = 'Syncing tokens...';

        final anilistToken = _getLocalToken('AuthKeys_authToken');
        if (anilistToken != null) {
          await pushTokens(
            cloudProfileId: cloudProfileId,
            service: 'anilist',
            tokens: {'authToken': anilistToken},
            password: encryptionPassword,
            saltBase64: encryptionSalt,
          );
        }

        final malToken = _getLocalToken('AuthKeys_malAuthToken');
        final malRefresh = _getLocalToken('AuthKeys_malRefreshToken');
        final malSession = _getLocalToken('AuthKeys_malSessionId');
        if (malToken != null || malRefresh != null) {
          await pushTokens(
            cloudProfileId: cloudProfileId,
            service: 'mal',
            tokens: {
              'authToken': malToken,
              'refreshToken': malRefresh,
              'sessionId': malSession,
            },
            password: encryptionPassword,
            saltBase64: encryptionSalt,
          );
        }

        final simklToken = _getLocalToken('AuthKeys_simklAuthToken');
        if (simklToken != null) {
          await pushTokens(
            cloudProfileId: cloudProfileId,
            service: 'simkl',
            tokens: {'authToken': simklToken},
            password: encryptionPassword,
            saltBase64: encryptionSalt,
          );
        }
      }

      syncStatus.value = 'Sync complete!';
      return true;
    } catch (e) {
      Logger.i('Full sync push error: $e');
      syncStatus.value = 'Sync failed';
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  String? _getLocalToken(String key) {
    try {
      final prefix = KvHelper.profilePrefix;
      final fullKey = prefix.isEmpty ? key : '$prefix$key';
      final col = isar.collection<KeyValue>();
      final result = col.filter().keyEqualTo(fullKey).findFirstSync();
      if (result?.value == null) return null;
      final data = jsonDecode(result!.value!);
      return data['val']?.toString();
    } catch (e) {
      return null;
    }
  }
}
