import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../../main.dart';

class _ProtoReader {
  final Uint8List _buf;
  int _pos = 0;

  _ProtoReader(this._buf);

  bool get hasMore => _pos < _buf.length;

  int _readRawByte() => _buf[_pos++];

  int readVarint() {
    int result = 0;
    int shift = 0;
    while (true) {
      final b = _readRawByte();
      result |= (b & 0x7F) << shift;
      if ((b & 0x80) == 0) break;
      shift += 7;
      if (shift > 63) throw Exception('Varint too long');
    }
    return result;
  }

  double readFloat32() {
    final bytes = _buf.sublist(_pos, _pos + 4);
    _pos += 4;
    return ByteData.sublistView(bytes).getFloat32(0, Endian.little);
  }

  Uint8List readBytes() {
    final len = readVarint();
    final bytes = _buf.sublist(_pos, _pos + len);
    _pos += len;
    return bytes;
  }

  void skip(int wireType) {
    switch (wireType) {
      case 0:
        readVarint();
        break;
      case 1:
        _pos += 8;
        break;
      case 2:
        final len = readVarint();
        _pos += len;
        break;
      case 5:
        _pos += 4;
        break;
      default:
        throw Exception('Unknown wire type: $wireType');
    }
  }

  ({int fieldNumber, int wireType})? readTag() {
    if (!hasMore) return null;
    final tag = readVarint();
    return (fieldNumber: tag >> 3, wireType: tag & 0x7);
  }
}

class _TachiAnimeTracking {
  int syncId = 0;
  int mediaIdInt = 0;
  double lastEpisodeSeen = 0;
  int status = 0;
  int mediaId = 0;

  static _TachiAnimeTracking decode(Uint8List bytes) {
    final r = _ProtoReader(bytes);
    final obj = _TachiAnimeTracking();
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag == null) break;
      switch (tag.fieldNumber) {
        case 1:
          obj.syncId = r.readVarint();
          break;
        case 3:
          obj.mediaIdInt = r.readVarint();
          break;
        case 6:
          if (tag.wireType == 5) {
            obj.lastEpisodeSeen = r.readFloat32();
          } else {
            r.skip(tag.wireType);
          }
          break;
        case 9:
          obj.status = r.readVarint();
          break;
        case 100:
          obj.mediaId = r.readVarint();
          break;
        default:
          r.skip(tag.wireType);
      }
    }
    return obj;
  }

  int get resolvedMediaId => mediaIdInt != 0 ? mediaIdInt : mediaId;
}

class _TachiAnime {
  int source = 0;
  String url = '';
  String title = '';
  String? thumbnailUrl;
  bool favorite = true;
  List<_TachiAnimeTracking> tracking = [];

  static _TachiAnime decode(Uint8List bytes) {
    final r = _ProtoReader(bytes);
    final obj = _TachiAnime();
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag == null) break;
      switch (tag.fieldNumber) {
        case 1:
          obj.source = r.readVarint();
          break;
        case 2:
          obj.url = utf8.decode(r.readBytes());
          break;
        case 3:
          obj.title = utf8.decode(r.readBytes());
          break;
        case 9:
          obj.thumbnailUrl = utf8.decode(r.readBytes());
          break;
        case 18:
          obj.tracking.add(_TachiAnimeTracking.decode(r.readBytes()));
          break;
        case 100:
          obj.favorite = r.readVarint() != 0;
          break;
        default:
          r.skip(tag.wireType);
      }
    }
    return obj;
  }
}

class _TachiMangaTracking {
  int syncId = 0;
  int mediaIdInt = 0;
  double lastChapterRead = 0;
  int status = 0;
  int mediaId = 0;

  static _TachiMangaTracking decode(Uint8List bytes) {
    final r = _ProtoReader(bytes);
    final obj = _TachiMangaTracking();
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag == null) break;
      switch (tag.fieldNumber) {
        case 1:
          obj.syncId = r.readVarint();
          break;
        case 3:
          obj.mediaIdInt = r.readVarint();
          break;
        case 6:
          if (tag.wireType == 5) {
            obj.lastChapterRead = r.readFloat32();
          } else {
            r.skip(tag.wireType);
          }
          break;
        case 9:
          obj.status = r.readVarint();
          break;
        case 100:
          obj.mediaId = r.readVarint();
          break;
        default:
          r.skip(tag.wireType);
      }
    }
    return obj;
  }

  int get resolvedMediaId => mediaIdInt != 0 ? mediaIdInt : mediaId;
}

class _TachiManga {
  int source = 0;
  String url = '';
  String title = '';
  String? thumbnailUrl;
  bool favorite = true;
  List<_TachiMangaTracking> tracking = [];

  static _TachiManga decode(Uint8List bytes) {
    final r = _ProtoReader(bytes);
    final obj = _TachiManga();
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag == null) break;
      switch (tag.fieldNumber) {
        case 1:
          obj.source = r.readVarint();
          break;
        case 2:
          obj.url = utf8.decode(r.readBytes());
          break;
        case 3:
          obj.title = utf8.decode(r.readBytes());
          break;
        case 9:
          obj.thumbnailUrl = utf8.decode(r.readBytes());
          break;
        case 18:
          obj.tracking.add(_TachiMangaTracking.decode(r.readBytes()));
          break;
        case 100:
          obj.favorite = r.readVarint() != 0;
          break;
        default:
          r.skip(tag.wireType);
      }
    }
    return obj;
  }
}

class _TachiBackup {
  List<_TachiManga> backupManga = [];
  List<_TachiAnime> backupAnime = [];

  static _TachiBackup decode(Uint8List bytes) {
    final r = _ProtoReader(bytes);
    final obj = _TachiBackup();
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag == null) break;
      switch (tag.fieldNumber) {
        case 1:
          obj.backupManga.add(_TachiManga.decode(r.readBytes()));
          break;
        case 3:
          obj.backupAnime.add(_TachiAnime.decode(r.readBytes()));
          break;
        case 501:
          obj.backupAnime.add(_TachiAnime.decode(r.readBytes()));
          break;
        default:
          r.skip(tag.wireType);
      }
    }
    return obj;
  }
}

const int _kSyncIdMal = 1;
const int _kSyncIdAniList = 2;
const int _kSyncIdKitsu = 3;

class TachibkImporter extends GetxController {
  final OfflineStorageController _storageController = Get.find();

  var isImporting = false.obs;
  var importProgress = 0.0.obs;
  var statusMessage = ''.obs;

  Future<String?> pickTachibkFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Aniyomi/Mihon Backup (.tachibk)',
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final picked = result.files.first;

      if (picked.path != null) {
        final ext = picked.path!.split('.').last.toLowerCase();
        if (ext != 'tachibk') {
          snackBar('Please select a .tachibk backup file');
          return null;
        }
        return picked.path;
      } else if (picked.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${picked.name}');
        await tempFile.writeAsBytes(picked.bytes!);
        return tempFile.path;
      }

      return null;
    } catch (e) {
      Logger.i('TachibkImporter: pickFile error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> previewTachibk(String filePath) async {
    try {
      final backup = await _decode(filePath);

      final favoriteAnime = backup.backupAnime.where((a) => a.favorite).toList();
      final favoriteManga = backup.backupManga.where((m) => m.favorite).toList();

      return {
        'animeCount': favoriteAnime.length,
        'mangaCount': favoriteManga.length,
        'totalAnime': backup.backupAnime.length,
        'totalManga': backup.backupManga.length,
        'sampleAnime': favoriteAnime.take(6).map((a) => {
          'title': a.title,
          'thumbnailUrl': a.thumbnailUrl ?? '',
        }).toList(),
        'sampleManga': favoriteManga.take(6).map((m) => {
          'title': m.title,
          'thumbnailUrl': m.thumbnailUrl ?? '',
        }).toList(),
      };
    } catch (e) {
      Logger.i('TachibkImporter: preview error: $e');
      return null;
    }
  }

  Future<void> importTachibk(
    String filePath, {
    bool merge = true,
    bool importAnime = true,
    bool importManga = true,
  }) async {
    isImporting.value = true;
    importProgress.value = 0.0;
    statusMessage.value = 'Decoding backup...';

    try {
      final backup = await _decode(filePath);

      final animeToImport = importAnime
          ? backup.backupAnime.where((a) => a.favorite).toList()
          : <_TachiAnime>[];
      final mangaToImport = importManga
          ? backup.backupManga.where((m) => m.favorite).toList()
          : <_TachiManga>[];

      final total = animeToImport.length + mangaToImport.length;
      if (total == 0) {
        snackBar('No favorited library entries found in backup');
        return;
      }

      int processed = 0;

      if (animeToImport.isNotEmpty) {
        statusMessage.value = 'Importing anime (${animeToImport.length})...';
        final mediaList = animeToImport.map(_animeToOfflineMedia).toList();

        final existingAnimeItems = await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(1)
            .findAll();
        final existingIds = existingAnimeItems.map((e) => e.mediaId).toSet();
        final existingNames = existingAnimeItems.map((e) => e.name).toSet();

        await isar.writeTxn(() async {
          for (final media in mediaList) {
            bool shouldAdd = true;
            if (merge) {
              final id = media.mediaId ?? '';
              if (id.isEmpty || id == '0') {
                if (existingNames.contains(media.name)) shouldAdd = false;
              } else {
                if (existingIds.contains(id)) shouldAdd = false;
              }
            }

            if (shouldAdd) {
              await isar.offlineMedias.put(media);
              if (media.mediaId != null) existingIds.add(media.mediaId);
              if (media.name != null) existingNames.add(media.name);
            }

            processed++;
            importProgress.value = processed / total;
          }
        });
      }

      if (mangaToImport.isNotEmpty) {
        statusMessage.value = 'Importing manga (${mangaToImport.length})...';
        final mediaList = mangaToImport.map(_mangaToOfflineMedia).toList();

        final existingMangaItems = await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(0)
            .findAll();
        final existingMangaIds = existingMangaItems.map((e) => e.mediaId).toSet();
        final existingMangaNames = existingMangaItems.map((e) => e.name).toSet();

        await isar.writeTxn(() async {
          for (final media in mediaList) {
            bool shouldAdd = true;
            if (merge) {
              final id = media.mediaId ?? '';
              if (id.isEmpty || id == '0') {
                if (existingMangaNames.contains(media.name)) shouldAdd = false;
              } else {
                if (existingMangaIds.contains(id)) shouldAdd = false;
              }
            }

            if (shouldAdd) {
              await isar.offlineMedias.put(media);
              if (media.mediaId != null) existingMangaIds.add(media.mediaId);
              if (media.name != null) existingMangaNames.add(media.name);
            }

            processed++;
            importProgress.value = processed / total;
          }
        });
      }

      statusMessage.value = 'Done!';
      importProgress.value = 1.0;
      Logger.i('TachibkImporter: imported ${animeToImport.length} anime, '
          '${mangaToImport.length} manga');
    } catch (e) {
      Logger.i('TachibkImporter: import failed: $e');
      rethrow;
    } finally {
      isImporting.value = false;
    }
  }

  Future<_TachiBackup> _decode(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');

    Uint8List bytes = await file.readAsBytes();

    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      bytes = Uint8List.fromList(GZipCodec().decode(bytes));
    }

    return _TachiBackup.decode(bytes);
  }

  OfflineMedia _animeToOfflineMedia(_TachiAnime anime) {
    int trackId = 0;
    for (final syncId in [_kSyncIdAniList, _kSyncIdMal, _kSyncIdKitsu]) {
      final t = anime.tracking.where((t) => t.syncId == syncId).firstOrNull;
      if (t != null && t.resolvedMediaId != 0) {
        trackId = t.resolvedMediaId;
        break;
      }
    }

    return OfflineMedia()
      ..mediaId = trackId != 0 ? trackId.toString() : null
      ..name = anime.title
      ..poster = anime.thumbnailUrl
      ..mediaTypeIndex = 1;
  }

  OfflineMedia _mangaToOfflineMedia(_TachiManga manga) {
    int trackId = 0;
    for (final syncId in [_kSyncIdAniList, _kSyncIdMal, _kSyncIdKitsu]) {
      final t = manga.tracking.where((t) => t.syncId == syncId).firstOrNull;
      if (t != null && t.resolvedMediaId != 0) {
        trackId = t.resolvedMediaId;
        break;
      }
    }

    return OfflineMedia()
      ..mediaId = trackId != 0 ? trackId.toString() : null
      ..name = manga.title
      ..poster = manga.thumbnailUrl
      ..mediaTypeIndex = 0;
  }

  void resetState() {
    isImporting.value = false;
    importProgress.value = 0.0;
    statusMessage.value = '';
  }
}
