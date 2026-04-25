import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
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

const int _kSyncIdMal = 1;
const int _kSyncIdAniList = 2;
const int _kSyncIdKitsu = 3;
const int _kSyncIdSimkl = 6;
const int _kServiceAniList = 0;
const int _kServiceMal = 1;
const int _kServiceSimkl = 2;
const int _kStatusCurrent = 1;
const int _kStatusCompleted = 2;
const int _kStatusOnHold = 3;
const int _kStatusDropped = 4;
const int _kStatusPlanning = 5;
const int _kStatusRepeating = 6;

String _animeListName(int status) {
  switch (status) {
    case _kStatusCompleted:
      return 'Completed';
    case _kStatusOnHold:
      return 'On Hold';
    case _kStatusDropped:
      return 'Dropped';
    case _kStatusPlanning:
      return 'Plan to Watch';
    case _kStatusRepeating:
      return 'Rewatching';
    case _kStatusCurrent:
    default:
      return 'Watching';
  }
}

String _mangaListName(int status) {
  switch (status) {
    case _kStatusCompleted:
      return 'Completed';
    case _kStatusOnHold:
      return 'On Hold';
    case _kStatusDropped:
      return 'Dropped';
    case _kStatusPlanning:
      return 'Plan to Read';
    case _kStatusRepeating:
      return 'Rereading';
    case _kStatusCurrent:
    default:
      return 'Reading';
  }
}

class _TachiTracking {
  int syncId = 0;
  int mediaIdInt = 0;
  int mediaId = 0;
  int status = 0;

  static _TachiTracking decode(Uint8List bytes) {
    final r = _ProtoReader(bytes);
    final obj = _TachiTracking();
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
            r.readFloat32();
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
  List<_TachiTracking> tracking = [];

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
          obj.tracking.add(_TachiTracking.decode(r.readBytes()));
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

  ({String? mediaId, int serviceIndex, int status}) get resolvedTracking {
    final priority = [
      (_kSyncIdAniList, _kServiceAniList),
      (_kSyncIdSimkl, _kServiceSimkl),
      (_kSyncIdMal, _kServiceMal),
    ];
    for (final (syncId, serviceIdx) in priority) {
      final t = tracking.where((t) => t.syncId == syncId).firstOrNull;
      if (t != null && t.resolvedMediaId != 0) {
        return (
          mediaId: t.resolvedMediaId.toString(),
          serviceIndex: serviceIdx,
          status: t.status,
        );
      }
    }
    return (mediaId: null, serviceIndex: _kServiceAniList, status: _kStatusCurrent);
  }
}

class _TachiManga {
  int source = 0;
  String url = '';
  String title = '';
  String? thumbnailUrl;
  bool favorite = true;
  List<_TachiTracking> tracking = [];

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
          obj.tracking.add(_TachiTracking.decode(r.readBytes()));
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

  ({String? mediaId, int serviceIndex, int status}) get resolvedTracking {
    final priority = [
      (_kSyncIdAniList, _kServiceAniList),
      (_kSyncIdSimkl, _kServiceSimkl),
      (_kSyncIdMal, _kServiceMal),
    ];
    for (final (syncId, serviceIdx) in priority) {
      final t = tracking.where((t) => t.syncId == syncId).firstOrNull;
      if (t != null && t.resolvedMediaId != 0) {
        return (
          mediaId: t.resolvedMediaId.toString(),
          serviceIndex: serviceIdx,
          status: t.status,
        );
      }
    }
    return (mediaId: null, serviceIndex: _kServiceAniList, status: _kStatusCurrent);
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

      final animeTracked = favoriteAnime.where((a) => a.resolvedTracking.mediaId != null).length;
      final mangaTracked = favoriteManga.where((m) => m.resolvedTracking.mediaId != null).length;

      return {
        'animeCount': favoriteAnime.length,
        'mangaCount': favoriteManga.length,
        'animeTracked': animeTracked,
        'mangaTracked': mangaTracked,
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

        for (final listName in ['Watching', 'Completed', 'On Hold', 'Dropped', 'Plan to Watch', 'Rewatching']) {
          await _storageController.addCustomList(listName, mediaType: ItemType.anime);
        }

        final existingAnimeItems = await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(1)
            .findAll();
        final existingIds = existingAnimeItems.map((e) => e.mediaId).toSet();
        final existingNames = existingAnimeItems.map((e) => e.name).toSet();

        final animeLookupIds = <({String lookupId, String listName})>[];

        await isar.writeTxn(() async {
          for (final anime in animeToImport) {
            final tracked = anime.resolvedTracking;
            final media = OfflineMedia()
              ..mediaId = tracked.mediaId
              ..name = anime.title
              ..poster = anime.thumbnailUrl
              ..mediaTypeIndex = 1
              ..serviceIndex = tracked.serviceIndex;

            bool shouldAdd = true;
            final lookupId = tracked.mediaId ?? anime.title;

            if (merge) {
              if (tracked.mediaId == null) {
                if (existingNames.contains(anime.title)) shouldAdd = false;
              } else {
                if (existingIds.contains(tracked.mediaId)) shouldAdd = false;
              }
            }

            if (shouldAdd) {
              await isar.offlineMedias.put(media);
              existingIds.add(tracked.mediaId);
              existingNames.add(anime.title);
            }

            animeLookupIds.add((
              lookupId: lookupId,
              listName: _animeListName(tracked.status),
            ));

            processed++;
            importProgress.value = processed / total;
          }
        });

        for (final entry in animeLookupIds) {
          await _storageController.addMediaToList(
            entry.listName,
            entry.lookupId,
            mediaType: ItemType.anime,
          );
        }
      }

      if (mangaToImport.isNotEmpty) {
        statusMessage.value = 'Importing manga (${mangaToImport.length})...';

        for (final listName in ['Reading', 'Completed', 'On Hold', 'Dropped', 'Plan to Read', 'Rereading']) {
          await _storageController.addCustomList(listName, mediaType: ItemType.manga);
        }

        final existingMangaItems = await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(0)
            .findAll();
        final existingMangaIds = existingMangaItems.map((e) => e.mediaId).toSet();
        final existingMangaNames = existingMangaItems.map((e) => e.name).toSet();

        final mangaLookupIds = <({String lookupId, String listName})>[];

        await isar.writeTxn(() async {
          for (final manga in mangaToImport) {
            final tracked = manga.resolvedTracking;
            final media = OfflineMedia()
              ..mediaId = tracked.mediaId
              ..name = manga.title
              ..poster = manga.thumbnailUrl
              ..mediaTypeIndex = 0
              ..serviceIndex = tracked.serviceIndex;

            bool shouldAdd = true;
            final lookupId = tracked.mediaId ?? manga.title;

            if (merge) {
              if (tracked.mediaId == null) {
                if (existingMangaNames.contains(manga.title)) shouldAdd = false;
              } else {
                if (existingMangaIds.contains(tracked.mediaId)) shouldAdd = false;
              }
            }

            if (shouldAdd) {
              await isar.offlineMedias.put(media);
              existingMangaIds.add(tracked.mediaId);
              existingMangaNames.add(manga.title);
            }

            mangaLookupIds.add((
              lookupId: lookupId,
              listName: _mangaListName(tracked.status),
            ));

            processed++;
            importProgress.value = processed / total;
          }
        });

        for (final entry in mangaLookupIds) {
          await _storageController.addMediaToList(
            entry.listName,
            entry.lookupId,
            mediaType: ItemType.manga,
          );
        }
      }

      statusMessage.value = 'Done!';
      importProgress.value = 1.0;
      Logger.i('TachibkImporter: imported ${animeToImport.length} anime, ${mangaToImport.length} manga');
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

  void resetState() {
    isImporting.value = false;
    importProgress.value = 0.0;
    statusMessage.value = '';
  }
}
