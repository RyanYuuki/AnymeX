import 'dart:convert';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:archive/archive.dart';

class KotatsuParseResult {
  final List<OfflineMedia> mangas;
  final List<CustomList> customLists;

  const KotatsuParseResult({
    required this.mangas,
    required this.customLists,
  });
}

class KotatsuBackupParser {
  static KotatsuParseResult parse(Archive archive) {
    final categoriesData = _readJsonSection(archive, 'categories');
    final favouritesData = _readJsonSection(archive, 'favourites');
    final chaptersData = _readJsonSection(archive, 'chapters');
    final historyData = _readJsonSection(archive, 'history');

    final categoryIdToTitle = <int, String>{};
    final categoryIdToMediaIds = <int, List<String>>{};

    for (var index = 0; index < categoriesData.length; index++) {
      final item = categoriesData[index];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final catId = _parseInt(map['category_id'] ?? map['id']);
      final title = map['title'] as String? ?? 'Category ${index + 1}';
      if (catId != null) {
        categoryIdToTitle[catId] = title;
        categoryIdToMediaIds[catId] = <String>[];
      }
    }

    final mangasByKey = <String, OfflineMedia>{};
    final mangaIdToMediaId = <int, String>{};

    OfflineMedia getOrCreateManga(Map<String, dynamic> manga, {int? mangaIdNum}) {
      final title = (manga['title'] as String?)?.trim() ?? 'Unknown Manga';
      final url = (manga['url'] as String?)?.trim() ?? '';
      final idNum = mangaIdNum ?? _parseInt(manga['id']);
      final mediaId = url.isNotEmpty ? url : (idNum != null ? 'kotatsu_$idNum' : title);

      if (idNum != null) {
        mangaIdToMediaId[idNum] = mediaId;
      }

      if (mangasByKey.containsKey(mediaId)) {
        return mangasByKey[mediaId]!;
      }

      final cover = (manga['large_cover_url'] ?? manga['cover_url']) as String?;
      final author = manga['author'] as String?;
      final state = manga['state'] as String?;

      final tags = <String>[];
      final rawTags = manga['tags'];
      if (rawTags is List) {
        for (final t in rawTags) {
          if (t is Map && t['title'] != null) {
            tags.add(t['title'].toString());
          } else if (t is String) {
            tags.add(t);
          }
        }
      }

      final media = OfflineMedia(
        mediaId: mediaId,
        name: title,
        english: title,
        cover: cover,
        poster: cover,
        description: author != null && author.isNotEmpty ? 'Author: $author' : null,
        genres: tags,
        status: state,
        mediaTypeIndex: 0,
      );
      mangasByKey[mediaId] = media;
      return media;
    }

    for (final item in favouritesData) {
      if (item is! Map) continue;
      final fav = Map<String, dynamic>.from(item);
      final mangaRaw = fav['manga'];
      if (mangaRaw is! Map) continue;
      final mangaJson = Map<String, dynamic>.from(mangaRaw);
      final mangaIdNum = _parseInt(fav['manga_id'] ?? mangaJson['id']);

      final media = getOrCreateManga(mangaJson, mangaIdNum: mangaIdNum);

      if (mangaJson['chapters'] is List) {
        final chList = _parseChapterList(mangaJson['chapters'] as List);
        if (chList.isNotEmpty) {
          media.chapters = chList;
          media.totalChapters = chList.length.toString();
        }
      }

      final catId = _parseInt(fav['category_id']);
      if (catId != null && categoryIdToMediaIds.containsKey(catId)) {
        if (!categoryIdToMediaIds[catId]!.contains(media.mediaId)) {
          categoryIdToMediaIds[catId]!.add(media.mediaId!);
        }
      }
    }

    for (final item in chaptersData) {
      if (item is! Map) continue;
      final chMap = Map<String, dynamic>.from(item);
      final mangaRaw = chMap['manga'];
      if (mangaRaw is! Map) continue;
      final mangaJson = Map<String, dynamic>.from(mangaRaw);
      final mangaIdNum = _parseInt(mangaJson['id']);
      final media = getOrCreateManga(mangaJson, mangaIdNum: mangaIdNum);

      final rawChapters = chMap['chapters'];
      if (rawChapters is List) {
        final chList = _parseChapterList(rawChapters);
        if (chList.isNotEmpty) {
          media.chapters = chList;
          media.totalChapters = chList.length.toString();
        }
      }
    }

    for (final item in historyData) {
      if (item is! Map) continue;
      final h = Map<String, dynamic>.from(item);
      final mangaIdNum = _parseInt(h['manga_id']);
      OfflineMedia? media;
      if (mangaIdNum != null && mangaIdToMediaId.containsKey(mangaIdNum)) {
        media = mangasByKey[mangaIdToMediaId[mangaIdNum]];
      }
      if (media == null && h['manga'] is Map) {
        media = getOrCreateManga(Map<String, dynamic>.from(h['manga'] as Map), mangaIdNum: mangaIdNum);
      }
      if (media == null) continue;

      final chapterIdNum = _parseInt(h['chapter_id']);
      final page = _parseInt(h['page']) ?? 0;
      final updatedAt = _parseInt(h['updated_at']);

      media.readChapters ??= [];
      Chapter? targetChapter;
      if (media.chapters != null && media.chapters!.isNotEmpty) {
        if (chapterIdNum != null) {
          for (final c in media.chapters!) {
            if (c.link?.contains('$chapterIdNum') == true) {
              targetChapter = c;
              break;
            }
          }
        }
        targetChapter ??= media.chapters!.first;
      } else {
        targetChapter = Chapter(
          title: 'Chapter 1',
          number: 1.0,
          pageNumber: page > 0 ? page : null,
          lastReadTime: updatedAt,
        );
        media.chapters = [targetChapter];
        media.totalChapters = '1';
      }

      targetChapter.pageNumber = page > 0 ? page : targetChapter.pageNumber;
      targetChapter.lastReadTime = updatedAt ?? targetChapter.lastReadTime;
      media.currentChapter = targetChapter;

      if (!media.readChapters!.contains(targetChapter)) {
        media.readChapters!.add(targetChapter);
      }
    }

    final assignedMediaIds = <String>{};
    for (final ids in categoryIdToMediaIds.values) {
      assignedMediaIds.addAll(ids);
    }

    final uncategorizedMediaIds = <String>[];
    for (final media in mangasByKey.values) {
      if (media.mediaId != null && !assignedMediaIds.contains(media.mediaId)) {
        uncategorizedMediaIds.add(media.mediaId!);
      }
    }

    final customLists = <CustomList>[];
    for (final entry in categoryIdToTitle.entries) {
      final mediaIds = categoryIdToMediaIds[entry.key] ?? [];
      final list = CustomList()
        ..listName = entry.value
        ..mediaTypeIndex = 0
        ..mediaIds = mediaIds;
      customLists.add(list);
    }

    final defaultIndex = customLists.indexWhere((l) => l.listName?.toLowerCase() == 'default');
    if (defaultIndex != -1) {
      final existing = customLists[defaultIndex];
      final combined = {...?existing.mediaIds, ...uncategorizedMediaIds}.toList();
      existing.mediaIds = combined;
    } else if (uncategorizedMediaIds.isNotEmpty || customLists.isEmpty) {
      customLists.insert(
        0,
        CustomList()
          ..listName = 'Default'
          ..mediaTypeIndex = 0
          ..mediaIds = uncategorizedMediaIds,
      );
    }

    return KotatsuParseResult(
      mangas: mangasByKey.values.toList(),
      customLists: customLists,
    );
  }

  static List<Chapter> _parseChapterList(List rawChapters) {
    final list = <Chapter>[];
    for (final c in rawChapters) {
      if (c is! Map) continue;
      final m = Map<String, dynamic>.from(c);
      final title = (m['name'] ?? m['title']) as String? ?? 'Chapter';
      final number = (m['number'] as num?)?.toDouble() ?? 1.0;
      final url = (m['url'] ?? m['link']) as String?;
      final scanlator = m['scanlator'] as String?;
      final uploadDate = m['upload_date']?.toString();
      list.add(
        Chapter(
          title: title,
          number: number,
          link: url,
          scanlator: scanlator,
          releaseDate: uploadDate,
        ),
      );
    }
    return list;
  }

  static List<dynamic> _readJsonSection(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.name == name) {
        try {
          final content = utf8.decode(file.content as List<int>);
          final decoded = jsonDecode(content);
          return decoded is List ? decoded : const [];
        } catch (_) {
          return const [];
        }
      }
    }
    return const [];
  }

  static int? _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
