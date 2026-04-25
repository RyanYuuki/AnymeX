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
const int _kServiceExtensions = 3;
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

String _syntheticId(int source, String url) {
  final hash = (source.toString() + url).hashCode.abs();
  return 'ext_${source}_$hash';
}

class _TachiCategory {
  String name = '';
  int order = 0;

  static _TachiCategory decode(Uint8List bytes) {
    final r = _ProtoReader(bytes);
    final obj = _TachiCategory();
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag == null) break;
      switch (tag.fieldNumber) {
        case 1:
          obj.name = utf8.decode(r.readBytes());
          break;
        case 2:
          obj.order = r.readVarint();
          break;
        default:
          r.skip(tag.wireType);
      }
    }
    return obj;
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
  List<int> categoryOrders = [];

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
        case 17:
          if (tag.wireType == 2) {
            final bytes = r.readBytes();
            final pr = _ProtoReader(bytes);
            while (pr.hasMore) {
              obj.categoryOrders.add(pr.readVarint());
            }
          } else {
            obj.categoryOrders.add(r.readVarint());
          }
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

  ({String mediaId, int serviceIndex, int status, bool isSynthetic}) get resolvedTracking {
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
          isSynthetic: false,
        );
      }
    }
    return (
      mediaId: _syntheticId(source, url),
      serviceIndex: _kServiceExtensions,
      status: _kStatusCurrent,
      isSynthetic: true,
    );
  }
}

class _TachiManga {
  int source = 0;
  String url = '';
  String title = '';
  String? thumbnailUrl;
  bool favorite = true;
  List<_TachiTracking> tracking = [];
  List<int> categoryOrders = [];

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
        case 17:
          if (tag.wireType == 2) {
            final bytes = r.readBytes();
            final pr = _ProtoReader(bytes);
            while (pr.hasMore) {
              obj.categoryOrders.add(pr.readVarint());
            }
          } else {
            obj.categoryOrders.add(r.readVarint());
          }
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

  ({String mediaId, int serviceIndex, int status, bool isSynthetic}) get resolvedTracking {
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
          isSynthetic: false,
        );
      }
    }
    return (
      mediaId: _syntheticId(source, url),
      serviceIndex: _kServiceExtensions,
      status: _kStatusCurrent,
      isSynthetic: true,
    );
  }
}

class _TachiBackup {
  List<_TachiManga> backupManga = [];
  List<_TachiAnime> backupAnime = [];
  Map<int, String> mangaCategories = {};
  Map<int, String> animeCategories = {};

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
        case 2:
          final cat = _TachiCategory.decode(r.readBytes());
          obj.mangaCategories[cat.order] = cat.name;
          break;
        case 3:
          obj.backupAnime.add(_TachiAnime.decode(r.readBytes()));
          break;
        case 4:
          final cat = _TachiCategory.decode(r.readBytes());
          if (!obj.animeCategories.containsKey(cat.order)) {
            obj.animeCategories[cat.order] = cat.name;
          }
          break;
        case 501:
          obj.backupAnime.add(_TachiAnime.decode(r.readBytes()));
          break;
        case 502:
          final cat = _TachiCategory.decode(r.readBytes());
          obj.animeCategories[cat.order] = cat.name;
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

      final animeTracked = favoriteAnime.where((a) => !a.resolvedTracking.isSynthetic).length;
      final mangaTracked = favoriteManga.where((m) => !m.resolvedTracking.isSynthetic).length;

      return {
        'animeCount': favoriteAnime.length,
        'mangaCount': favoriteManga.length,
        'animeTracked': animeTracked,
        'mangaTracked': mangaTracked,
        'animeUntracked': favoriteAnime.length - animeTracked,
        'mangaUntracked': favoriteManga.length - mangaTracked,
        'animeCategoryCount': backup.animeCategories.length,
        'mangaCategoryCount': backup.mangaCategories.length,
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

        for (final listName in [
          'Watching', 'Completed', 'On Hold', 'Dropped', 'Plan to Watch', 'Rewatching'
        ]) {
          await _storageController.addCustomList(listName, mediaType: ItemType.anime);
        }
        for (final catName in backup.animeCategories.values) {
          await _storageController.addCustomList(catName, mediaType: ItemType.anime);
        }

        final existingAnimeItems = await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(1)
            .findAll();
        final existingIds = existingAnimeItems.map((e) => e.mediaId).toSet();

        final animeLookupIds = <({String lookupId, List<String> listNames})>[];

        await isar.writeTxn(() async {
          for (final anime in animeToImport) {
            final tracked = anime.resolvedTracking;

            bool shouldAdd = true;
            if (merge && existingIds.contains(tracked.mediaId)) {
              shouldAdd = false;
            }

            if (shouldAdd) {
              final media = OfflineMedia()
                ..mediaId = tracked.mediaId
                ..name = anime.title
                ..poster = anime.thumbnailUrl
                ..mediaTypeIndex = 1
                ..serviceIndex = tracked.serviceIndex;
              await isar.offlineMedias.put(media);
              existingIds.add(tracked.mediaId);
            }

            final lists = <String>[_animeListName(tracked.status)];
            for (final order in anime.categoryOrders) {
              final catName = backup.animeCategories[order];
              if (catName != null) lists.add(catName);
            }

            animeLookupIds.add((
              lookupId: tracked.mediaId,
              listNames: lists,
            ));

            processed++;
            importProgress.value = processed / total;
          }
        });

        for (final entry in animeLookupIds) {
          for (final listName in entry.listNames) {
            await _storageController.addMediaToList(
              listName,
              entry.lookupId,
              mediaType: ItemType.anime,
            );
          }
        }
      }

      if (mangaToImport.isNotEmpty) {
        statusMessage.value = 'Importing manga (${mangaToImport.length})...';

        for (final listName in [
          'Reading', 'Completed', 'On Hold', 'Dropped', 'Plan to Read', 'Rereading'
        ]) {
          await _storageController.addCustomList(listName, mediaType: ItemType.manga);
        }
        for (final catName in backup.mangaCategories.values) {
          await _storageController.addCustomList(catName, mediaType: ItemType.manga);
        }

        final existingMangaItems = await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(0)
            .findAll();
        final existingMangaIds = existingMangaItems.map((e) => e.mediaId).toSet();

        final mangaLookupIds = <({String lookupId, List<String> listNames})>[];

        await isar.writeTxn(() async {
          for (final manga in mangaToImport) {
            final tracked = manga.resolvedTracking;

            bool shouldAdd = true;
            if (merge && existingMangaIds.contains(tracked.mediaId)) {
              shouldAdd = false;
            }

            if (shouldAdd) {
              final media = OfflineMedia()
                ..mediaId = tracked.mediaId
                ..name = manga.title
                ..poster = manga.thumbnailUrl
                ..mediaTypeIndex = 0
                ..serviceIndex = tracked.serviceIndex;
              await isar.offlineMedias.put(media);
              existingMangaIds.add(tracked.mediaId);
            }

            final lists = <String>[_mangaListName(tracked.status)];
            for (final order in manga.categoryOrders) {
              final catName = backup.mangaCategories[order];
              if (catName != null) lists.add(catName);
            }

            mangaLookupIds.add((
              lookupId: tracked.mediaId,
              listNames: lists,
            ));

            processed++;
            importProgress.value = processed / total;
          }
        });

        for (final entry in mangaLookupIds) {
          for (final listName in entry.listNames) {
            await _storageController.addMediaToList(
              listName,
              entry.lookupId,
              mediaType: ItemType.manga,
            );
          }
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
