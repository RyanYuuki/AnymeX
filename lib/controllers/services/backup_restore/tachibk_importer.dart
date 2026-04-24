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

// ---------------------------------------------------------------------------
// Minimal protobuf wire-format reader (no generated code needed)
// Wire types: 0=varint, 1=64-bit, 2=length-delimited, 5=32-bit
// ---------------------------------------------------------------------------

class _ProtoReader {
  final Uint8List _buf;
  int _pos = 0;

  _ProtoReader(this._buf);

  bool get hasMore => _pos < _buf.length;

  int _readRawByte() => _buf[_pos++];

  // Decode a base-128 varint
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

  // Read a 32-bit little-endian float (wire type 5)
  double readFloat32() {
    final bytes = _buf.sublist(_pos, _pos + 4);
    _pos += 4;
    return ByteData.sublistView(bytes).getFloat32(0, Endian.little);
  }

  // Read length-delimited bytes
  Uint8List readBytes() {
    final len = readVarint();
    final bytes = _buf.sublist(_pos, _pos + len);
    _pos += len;
    return bytes;
  }

  // Skip over a field we don't care about
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

  // Read next tag; returns null at end of buffer
  ({int fieldNumber, int wireType})? readTag() {
    if (!hasMore) return null;
    final tag = readVarint();
    return (fieldNumber: tag >> 3, wireType: tag & 0x7);
  }
}

// ---------------------------------------------------------------------------
// Proto model classes matching aniyomi/mihon backup schema
// Field numbers from Kotlin source files provided in context
// ---------------------------------------------------------------------------

/// BackupAnime tracking entry (field 18 in BackupAnime)
class _TachiAnimeTracking {
  int syncId = 0;       // field 1
  int mediaIdInt = 0;   // field 3 (deprecated, int)
  double lastEpisodeSeen = 0; // field 6 (float32, wire type 5)
  int status = 0;       // field 9
  int mediaId = 0;      // field 100 (long)

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
        case 6: // float (wire type 5)
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

  // Match Kotlin getTrackImpl() logic: prefer mediaIdInt if non-zero
  int get resolvedMediaId => mediaIdInt != 0 ? mediaIdInt : mediaId;
}

/// BackupAnime — anime entry in backup
class _TachiAnime {
  int source = 0;             // field 1
  String url = '';            // field 2
  String title = '';          // field 3
  String? thumbnailUrl;       // field 9
  bool favorite = true;       // field 100
  List<_TachiAnimeTracking> tracking = []; // field 18

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

/// BackupTracking — manga tracking entry (field 18 in BackupManga)
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

/// BackupManga — manga entry in backup
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

/// Top-level Backup proto — handles all three formats:
///   - Mihon / new aniyomi:  manga @ field 1, anime @ field 501
///   - Legacy aniyomi full:  manga @ field 1, anime @ field 3
///   - Very old aniyomi:     manga @ field 1 only (no anime)
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
        case 1: // backupManga — present in all formats
          obj.backupManga.add(_TachiManga.decode(r.readBytes()));
          break;
        case 3: // backupAnime — legacy aniyomi full backup format
          obj.backupAnime.add(_TachiAnime.decode(r.readBytes()));
          break;
        case 501: // backupAnime — new aniyomi/mihon-fork format
          obj.backupAnime.add(_TachiAnime.decode(r.readBytes()));
          break;
        default:
          r.skip(tag.wireType);
      }
    }
    return obj;
  }
}

// ---------------------------------------------------------------------------
// Tracker syncId constants (matches aniyomi TrackerManager IDs)
// ---------------------------------------------------------------------------

const int _kSyncIdMal = 1;
const int _kSyncIdAniList = 2;
const int _kSyncIdKitsu = 3;

// ---------------------------------------------------------------------------
// Main importer controller
// ---------------------------------------------------------------------------

class TachibkImporter extends GetxController {
  final OfflineStorageController _storageController = Get.find();

  var isImporting = false.obs;
  var importProgress = 0.0.obs;
  var statusMessage = ''.obs;

  // Pick a .tachibk file via system file picker
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

  // Decode file and return a preview summary without writing to DB
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

  // Import the backup into AnymeX's Isar database
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
        await isar.writeTxn(() async {
          for (final media in mediaList) {
            if (merge) {
              final id = media.mediaId ?? '';
              if (id.isEmpty || id == '0') {
                // No tracker ID — skip duplicates by title+type
                final existing = await isar.offlineMedias
                    .filter()
                    .titleEqualTo(media.title ?? '')
                    .and()
                    .mediaTypeIndexEqualTo(1)
                    .findFirst();
                if (existing == null) await isar.offlineMedias.put(media);
              } else {
                final existing = _storageController.getMediaById(id);
                if (existing == null) await isar.offlineMedias.put(media);
              }
            } else {
              await isar.offlineMedias.put(media);
            }
            processed++;
            importProgress.value = processed / total;
          }
        });
      }

      if (mangaToImport.isNotEmpty) {
        statusMessage.value = 'Importing manga (${mangaToImport.length})...';
        final mediaList = mangaToImport.map(_mangaToOfflineMedia).toList();
        await isar.writeTxn(() async {
          for (final media in mediaList) {
            if (merge) {
              final id = media.mediaId ?? '';
              if (id.isEmpty || id == '0') {
                final existing = await isar.offlineMedias
                    .filter()
                    .titleEqualTo(media.title ?? '')
                    .and()
                    .mediaTypeIndexEqualTo(0)
                    .findFirst();
                if (existing == null) await isar.offlineMedias.put(media);
              } else {
                final existing = _storageController.getMediaById(id);
                if (existing == null) await isar.offlineMedias.put(media);
              }
            } else {
              await isar.offlineMedias.put(media);
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

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<_TachiBackup> _decode(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');

    Uint8List bytes = await file.readAsBytes();

    // Detect gzip magic bytes 0x1f 0x8b and decompress
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      bytes = Uint8List.fromList(GZipCodec().decode(bytes));
    }

    return _TachiBackup.decode(bytes);
  }

  OfflineMedia _animeToOfflineMedia(_TachiAnime anime) {
    // Prefer AniList ID, then MAL ID, then Kitsu, else 0
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
      ..title = anime.title
      ..coverImage = anime.thumbnailUrl ?? ''
      ..mediaTypeIndex = 1; // anime
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
      ..title = manga.title
      ..coverImage = manga.thumbnailUrl ?? ''
      ..mediaTypeIndex = 0; // manga
  }

  void resetState() {
    isImporting.value = false;
    importProgress.value = 0.0;
    statusMessage.value = '';
  }
}
