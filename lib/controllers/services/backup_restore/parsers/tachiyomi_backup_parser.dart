import 'dart:io';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:archive/archive.dart';
import '../proto/BackupAnime.pb.dart';
import '../proto/BackupAniyomi.pb.dart';
import '../proto/BackupCategory.pb.dart';
import '../proto/BackupManga.pb.dart';
import '../proto/BackupMihon.pb.dart';

class TachiyomiParseResult {
  final List<OfflineMedia> mangas;
  final List<OfflineMedia> animes;
  final List<CustomList> mangaCustomLists;
  final List<CustomList> animeCustomLists;
  final bool isAniyomi;

  const TachiyomiParseResult({
    required this.mangas,
    required this.animes,
    required this.mangaCustomLists,
    required this.animeCustomLists,
    required this.isAniyomi,
  });
}

class TachiyomiBackupParser {
  static TachiyomiParseResult parseBytes(List<int> bytes) {
    final decompressed = const GZipDecoder().decodeBytes(bytes);

    BackupAniyomi? aniyomi;
    try {
      aniyomi = BackupAniyomi.fromBuffer(decompressed);
    } catch (_) {}

    BackupMihon? mihon;
    try {
      mihon = BackupMihon.fromBuffer(decompressed);
    } catch (_) {}

    final mangaCategoriesRaw = aniyomi?.backupCategories.isNotEmpty == true
        ? aniyomi!.backupCategories
        : (mihon?.backupCategories ?? <BackupCategory>[]);

    final mangaEntriesRaw = aniyomi?.backupManga.isNotEmpty == true
        ? aniyomi!.backupManga
        : (mihon?.backupManga ?? <BackupManga>[]);

    final animeCategoriesRaw = aniyomi != null
        ? (aniyomi.backupAnimeCategories.isNotEmpty
            ? aniyomi.backupAnimeCategories
            : (aniyomi.legacyBackupAnimeCategories.isNotEmpty
                ? aniyomi.legacyBackupAnimeCategories
                : aniyomi.backupCategories))
        : <BackupCategory>[];

    final animeEntriesRaw = aniyomi != null
        ? (aniyomi.backupAnime.isNotEmpty
            ? aniyomi.backupAnime
            : aniyomi.legacyBackupAnime)
        : <BackupAnime>[];

    final mangaCatOrderToTitle = <int, String>{};
    final mangaCatOrderToMediaIds = <int, List<String>>{};
    for (var i = 0; i < mangaCategoriesRaw.length; i++) {
      final cat = mangaCategoriesRaw[i];
      final order = cat.order.toInt();
      final id = cat.id.toInt();
      final title = cat.name.trim().isNotEmpty ? cat.name.trim() : 'Manga Category ${i + 1}';
      final mediaIds = <String>[];
      mangaCatOrderToTitle[order] = title;
      mangaCatOrderToMediaIds[order] = mediaIds;
      if (id != order) {
        mangaCatOrderToTitle[id] = title;
        mangaCatOrderToMediaIds[id] = mediaIds;
      }
      if (i != order && i != id) {
        mangaCatOrderToTitle[i] = title;
        mangaCatOrderToMediaIds[i] = mediaIds;
      }
    }

    final defaultMangaMediaIds = <String>[];
    final mangas = <OfflineMedia>[];
    for (final m in mangaEntriesRaw) {
      final title = m.title.trim().isNotEmpty ? m.title.trim() : 'Unknown Manga';
      final url = m.url.trim();
      final mediaId = url.isNotEmpty ? url : title;

      final allChapters = <Chapter>[];
      final readChaptersList = <Chapter>[];
      Chapter? currentChapter;

      for (final c in m.chapters) {
        final chTitle = c.name.trim().isNotEmpty ? c.name.trim() : 'Chapter ${c.chapterNumber}';
        final chapter = Chapter(
          title: chTitle,
          number: c.chapterNumber > 0 ? c.chapterNumber : 1.0,
          link: c.url,
          scanlator: c.scanlator.isNotEmpty ? c.scanlator : null,
          pageNumber: c.lastPageRead.toInt() > 0 ? c.lastPageRead.toInt() : null,
          lastReadTime: c.lastModifiedAt.toInt() > 0 ? c.lastModifiedAt.toInt() : null,
        );
        allChapters.add(chapter);
        if (c.read) {
          readChaptersList.add(chapter);
        }
      }

      for (final h in m.history) {
        Chapter? ch;
        for (final c in allChapters) {
          if (c.link == h.url) {
            ch = c;
            break;
          }
        }
        if (ch != null) {
          if (h.lastRead.toInt() > 0) {
            ch.lastReadTime = h.lastRead.toInt();
          }
          if (!readChaptersList.contains(ch)) {
            readChaptersList.add(ch);
          }
        }
      }

      if (readChaptersList.isNotEmpty) {
        final sortedRead = List<Chapter>.from(readChaptersList)
          ..sort((a, b) => (b.lastReadTime ?? 0).compareTo(a.lastReadTime ?? 0));
        currentChapter = sortedRead.first;
      } else if (allChapters.isNotEmpty && allChapters.any((c) => (c.pageNumber ?? 0) > 0)) {
        currentChapter = allChapters.firstWhere((c) => (c.pageNumber ?? 0) > 0);
      }

      final media = OfflineMedia(
        mediaId: mediaId,
        name: title,
        english: title,
        poster: m.thumbnailUrl.isNotEmpty ? m.thumbnailUrl : null,
        cover: m.thumbnailUrl.isNotEmpty ? m.thumbnailUrl : null,
        description: m.description.isNotEmpty ? m.description : null,
        genres: m.genre.toList(),
        status: _convertStatus(m.status),
        chapters: allChapters,
        readChapters: readChaptersList,
        currentChapter: currentChapter,
        totalChapters: allChapters.isNotEmpty ? allChapters.length.toString() : null,
        mediaTypeIndex: 0,
      );
      mangas.add(media);

      bool assignedToCategory = false;
      for (final order in m.categories) {
        final orderInt = order.toInt();
        if (mangaCatOrderToMediaIds.containsKey(orderInt)) {
          if (!mangaCatOrderToMediaIds[orderInt]!.contains(mediaId)) {
            mangaCatOrderToMediaIds[orderInt]!.add(mediaId);
          }
          assignedToCategory = true;
        }
      }
      if (!assignedToCategory) {
        defaultMangaMediaIds.add(mediaId);
      }
    }

    final mangaCustomLists = <CustomList>[];
    final seenMangaTitles = <String>{};
    for (var i = 0; i < mangaCategoriesRaw.length; i++) {
      final cat = mangaCategoriesRaw[i];
      final title = cat.name.trim().isNotEmpty ? cat.name.trim() : 'Manga Category ${i + 1}';
      if (seenMangaTitles.contains(title.toLowerCase())) continue;
      seenMangaTitles.add(title.toLowerCase());
      final mediaIds = mangaCatOrderToMediaIds[cat.order.toInt()] ?? mangaCatOrderToMediaIds[cat.id.toInt()] ?? mangaCatOrderToMediaIds[i] ?? [];
      final list = CustomList()
        ..listName = title
        ..mediaTypeIndex = 0
        ..mediaIds = mediaIds;
      mangaCustomLists.add(list);
    }

    final defaultMangaIndex = mangaCustomLists.indexWhere((l) => l.listName?.toLowerCase() == 'default');
    if (defaultMangaIndex != -1) {
      final existing = mangaCustomLists[defaultMangaIndex];
      final combined = {...?existing.mediaIds, ...defaultMangaMediaIds}.toList();
      existing.mediaIds = combined;
    } else if (defaultMangaMediaIds.isNotEmpty || mangaCustomLists.isEmpty) {
      mangaCustomLists.insert(
        0,
        CustomList()
          ..listName = 'Default'
          ..mediaTypeIndex = 0
          ..mediaIds = defaultMangaMediaIds,
      );
    }

    final animeCatOrderToTitle = <int, String>{};
    final animeCatOrderToMediaIds = <int, List<String>>{};
    for (var i = 0; i < animeCategoriesRaw.length; i++) {
      final cat = animeCategoriesRaw[i];
      final order = cat.order.toInt();
      final id = cat.id.toInt();
      final title = cat.name.trim().isNotEmpty ? cat.name.trim() : 'Anime Category ${i + 1}';
      final mediaIds = <String>[];
      animeCatOrderToTitle[order] = title;
      animeCatOrderToMediaIds[order] = mediaIds;
      if (id != order) {
        animeCatOrderToTitle[id] = title;
        animeCatOrderToMediaIds[id] = mediaIds;
      }
      if (i != order && i != id) {
        animeCatOrderToTitle[i] = title;
        animeCatOrderToMediaIds[i] = mediaIds;
      }
    }

    final defaultAnimeMediaIds = <String>[];
    final animes = <OfflineMedia>[];
    for (final a in animeEntriesRaw) {
      final title = a.title.trim().isNotEmpty ? a.title.trim() : 'Unknown Anime';
      final url = a.url.trim();
      final mediaId = url.isNotEmpty ? url : title;

      final allEpisodes = <Episode>[];
      final watchedEpisodesList = <Episode>[];
      Episode? currentEpisode;

      for (final e in a.episodes) {
        final epNumberStr = e.episodeNumber > 0
            ? (e.episodeNumber % 1 == 0
                ? e.episodeNumber.toInt().toString()
                : e.episodeNumber.toString())
            : '1';
        final epTitle = e.name.trim().isNotEmpty ? e.name.trim() : 'Episode $epNumberStr';
        final ep = Episode(
          title: epTitle,
          number: epNumberStr,
          link: e.url,
          timeStampInMilliseconds: e.lastSecondSeen.toInt() > 0 ? e.lastSecondSeen.toInt() * 1000 : null,
          durationInMilliseconds: e.totalSeconds.toInt() > 0 ? e.totalSeconds.toInt() * 1000 : null,
          lastWatchedTime: e.lastModifiedAt.toInt() > 0
              ? e.lastModifiedAt.toInt()
              : (e.seen ? DateTime.now().millisecondsSinceEpoch : null),
        );
        allEpisodes.add(ep);
        if (e.seen) {
          watchedEpisodesList.add(ep);
        }
      }

      for (final h in a.history) {
        Episode? ep;
        for (final e in allEpisodes) {
          if (e.link == h.url) {
            ep = e;
            break;
          }
        }
        if (ep != null) {
          if (h.lastRead.toInt() > 0) {
            ep.lastWatchedTime = h.lastRead.toInt();
          }
          if (!watchedEpisodesList.contains(ep)) {
            watchedEpisodesList.add(ep);
          }
        }
      }

      if (watchedEpisodesList.isNotEmpty) {
        final sortedWatched = List<Episode>.from(watchedEpisodesList)
          ..sort((a, b) => (b.lastWatchedTime ?? 0).compareTo(a.lastWatchedTime ?? 0));
        currentEpisode = sortedWatched.first;
      } else if (allEpisodes.isNotEmpty && allEpisodes.any((e) => (e.timeStampInMilliseconds ?? 0) > 0)) {
        currentEpisode = allEpisodes.firstWhere((e) => (e.timeStampInMilliseconds ?? 0) > 0);
      }

      if (currentEpisode != null) {
        currentEpisode.currentTrack ??= Video(
          url: currentEpisode.link,
          originalUrl: currentEpisode.link,
          quality: 'default',
        );
      }

      final media = OfflineMedia(
        mediaId: mediaId,
        name: title,
        english: title,
        poster: a.thumbnailUrl.isNotEmpty ? a.thumbnailUrl : null,
        cover: a.thumbnailUrl.isNotEmpty ? a.thumbnailUrl : null,
        description: a.description.isNotEmpty ? a.description : null,
        genres: a.genre.toList(),
        status: _convertStatus(a.status),
        episodes: allEpisodes,
        watchedEpisodes: watchedEpisodesList,
        currentEpisode: currentEpisode,
        totalEpisodes: allEpisodes.isNotEmpty ? allEpisodes.length.toString() : null,
        mediaTypeIndex: 1,
      );
      animes.add(media);

      bool assignedToCategory = false;
      for (final order in a.categories) {
        final orderInt = order.toInt();
        if (animeCatOrderToMediaIds.containsKey(orderInt)) {
          if (!animeCatOrderToMediaIds[orderInt]!.contains(mediaId)) {
            animeCatOrderToMediaIds[orderInt]!.add(mediaId);
          }
          assignedToCategory = true;
        }
      }
      if (!assignedToCategory) {
        defaultAnimeMediaIds.add(mediaId);
      }
    }

    final animeCustomLists = <CustomList>[];
    final seenAnimeTitles = <String>{};
    for (var i = 0; i < animeCategoriesRaw.length; i++) {
      final cat = animeCategoriesRaw[i];
      final title = cat.name.trim().isNotEmpty ? cat.name.trim() : 'Anime Category ${i + 1}';
      if (seenAnimeTitles.contains(title.toLowerCase())) continue;
      seenAnimeTitles.add(title.toLowerCase());
      final mediaIds = animeCatOrderToMediaIds[cat.order.toInt()] ?? animeCatOrderToMediaIds[cat.id.toInt()] ?? animeCatOrderToMediaIds[i] ?? [];
      final list = CustomList()
        ..listName = title
        ..mediaTypeIndex = 1
        ..mediaIds = mediaIds;
      animeCustomLists.add(list);
    }

    final defaultAnimeIndex = animeCustomLists.indexWhere((l) => l.listName?.toLowerCase() == 'default');
    if (defaultAnimeIndex != -1) {
      final existing = animeCustomLists[defaultAnimeIndex];
      final combined = {...?existing.mediaIds, ...defaultAnimeMediaIds}.toList();
      existing.mediaIds = combined;
    } else if (defaultAnimeMediaIds.isNotEmpty || animeCustomLists.isEmpty) {
      animeCustomLists.insert(
        0,
        CustomList()
          ..listName = 'Default'
          ..mediaTypeIndex = 1
          ..mediaIds = defaultAnimeMediaIds,
      );
    }

    return TachiyomiParseResult(
      mangas: mangas,
      animes: animes,
      mangaCustomLists: mangaCustomLists,
      animeCustomLists: animeCustomLists,
      isAniyomi: animes.isNotEmpty || animeCustomLists.isNotEmpty,
    );
  }

  static Future<TachiyomiParseResult> parseFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return parseBytes(bytes);
  }

  static String _convertStatus(int status) {
    switch (status) {
      case 1:
        return 'Ongoing';
      case 2:
        return 'Completed';
      case 3:
        return 'Licensed';
      case 4:
        return 'Publishing finished';
      case 5:
        return 'Cancelled';
      case 6:
        return 'On hiatus';
      default:
        return 'Unknown';
    }
  }
}
