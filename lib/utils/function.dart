import 'package:anymex/api/Mangayomi/Eval/dart/model/m_chapter.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anime_media_small.dart';
import 'package:anymex/models/Carousel/carousel.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get getUrlWithoutDomain {
    final uri = Uri.parse(replaceAll(' ', '%20'));
    String out = uri.path;
    if (uri.query.isNotEmpty) {
      out += '?${uri.query}';
    }
    if (uri.fragment.isNotEmpty) {
      out += '#${uri.fragment}';
    }
    return out;
  }
}

String convertAniListStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'CURRENT':
      return 'CURRENTLY WATCHING';
    case 'PLANNING':
      return 'PLANNING TO WATCH';
    case 'COMPLETED':
      return 'COMPLETED';
    case 'DROPPED':
      return 'DROPPED';
    case 'PAUSED':
      return 'PAUSED';
    case 'REPEATING':
      return 'REWATCHING';
    default:
      return 'ADD TO LIST';
  }
}

Future<void> snackString(
  String? s, {
  String? clipboard,
}) async {
  var context = Get.context;

  if (context != null && s != null && s.isNotEmpty) {
    var theme = Theme.of(context).colorScheme;

    try {
      final snackBar = SnackBar(
        content: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          child: Text(
            s,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
            ),
          ),
        ),
        backgroundColor: theme.surface,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 32,
          right: 32,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e, stackTrace) {
      debugPrint('Error showing SnackBar: $e');
      debugPrint(stackTrace.toString());
    }
  } else {
    debugPrint('No valid context or string provided.');
  }
}

class ChapterRecognition {
  static const _numberPattern = r"([0-9]+)(\.[0-9]+)?(\.?[a-z]+)?";

  static final _unwanted =
      RegExp(r"\b(?:v|ver|vol|version|volume|season|s)[^a-z]?[0-9]+");

  static final _unwantedWhiteSpace = RegExp(r"\s(?=extra|special|omake)");

  static dynamic parseChapterNumber(String mangaTitle, String chapterName) {
    var name = chapterName.toLowerCase();

    name = name.replaceAll(mangaTitle.toLowerCase(), "").trim();

    name = name.replaceAll(',', '.').replaceAll('-', '.');

    name = name.replaceAll(_unwantedWhiteSpace, "");

    name = name.replaceAll(_unwanted, "");
    const numberPat = "*$_numberPattern";
    const ch = r"(?<=ch\.)";
    var match = RegExp("$ch $numberPat").firstMatch(name);
    if (match != null) {
      return _convertToIntIfWhole(_getChapterNumberFromMatch(match));
    }

    match = RegExp(_numberPattern).firstMatch(name);
    if (match != null) {
      return _convertToIntIfWhole(_getChapterNumberFromMatch(match));
    }

    return 0;
  }

  static dynamic _convertToIntIfWhole(double value) {
    return value % 1 == 0 ? value.toInt() : value;
  }

  static double _getChapterNumberFromMatch(Match match) {
    final initial = double.parse(match.group(1)!);
    final subChapterDecimal = match.group(2);
    final subChapterAlpha = match.group(3);
    final addition = _checkForDecimal(subChapterDecimal, subChapterAlpha);
    return initial + addition;
  }

  static double _checkForDecimal(String? decimal, String? alpha) {
    if (decimal != null && decimal.isNotEmpty) {
      return double.parse(decimal);
    }

    if (alpha != null && alpha.isNotEmpty) {
      if (alpha.contains("extra")) {
        return 0.99;
      }
      if (alpha.contains("omake")) {
        return 0.98;
      }
      if (alpha.contains("special")) {
        return 0.97;
      }
      final trimmedAlpha = alpha.replaceFirst('.', '');
      if (trimmedAlpha.length == 1) {
        return _parseAlphaPostFix(trimmedAlpha[0]);
      }
    }

    return 0.0;
  }

  static double _parseAlphaPostFix(String alpha) {
    final number = alpha.codeUnitAt(0) - ('a'.codeUnitAt(0) - 1);
    if (number >= 10) return 0.0;
    return number / 10.0;
  }
}

Episode mChapterToEpisode(MChapter chapter, MManga? selectedMedia) {
  var episodeNumber = ChapterRecognition.parseChapterNumber(
      selectedMedia?.name ?? '', chapter.name ?? '');
  return Episode(
    number: episodeNumber != -1 ? episodeNumber.toString() : chapter.name ?? '',
    link: chapter.url,
    title: chapter.name,
    thumbnail: null,
    desc: null,
    filler: false,
  );
}

String calcTime(String timestamp, {String format = "dd-MM-yyyy"}) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays <= 14) {
    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return "${difference.inMinutes} minutes ago";
      }
      return "${difference.inHours} hours ago";
    }
    return "${difference.inDays} days ago";
  }

  return DateFormat(format).format(dateTime);
}

String dateFormatHour(String timestamp) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  return DateFormat.Hm().format(dateTime);
}

List<Chapter> mChapterToChapter(List<MChapter> chapters, String title) {
  return chapters.map((e) {
    return Chapter(
        title: e.name,
        link: e.url,
        scanlator: e.scanlator,
        number:
            ChapterRecognition.parseChapterNumber(title, e.name!).toDouble(),
        releaseDate: calcTime(e.dateUpload ?? ''));
  }).toList();
}

int calculateChunkSize(List<Episode> episodes) {
  final total = episodes.length;
  if (total <= 12) {
    return total;
  } else if (total <= 50) {
    return 12;
  } else if (total <= 250) {
    return 25;
  } else if (total <= 500) {
    return 50;
  } else {
    return 75;
  }
}

List<List<Episode>> chunkEpisodes(List<Episode> episodes, int chunkSize) {
  if (episodes.isEmpty) {
    return [];
  }

  final chunks = List.generate(
    (episodes.length / chunkSize).ceil(),
    (index) => episodes.sublist(
      index * chunkSize,
      (index + 1) * chunkSize > episodes.length
          ? episodes.length
          : (index + 1) * chunkSize,
    ),
  );

  return [
    episodes,
    ...chunks,
  ];
}

int calculateChapterChunkSize(List<Chapter> chapters) {
  final total = chapters.length;
  if (total <= 12) {
    return total;
  } else if (total <= 50) {
    return 12;
  } else if (total <= 250) {
    return 25;
  } else if (total <= 500) {
    return 50;
  } else {
    return 75;
  }
}

List<List<Chapter>> chunkChapter(List<Chapter> chapters, int chunkSize) {
  if (chapters.isEmpty) {
    return [];
  }

  final chunks = List.generate(
    (chapters.length / chunkSize).ceil(),
    (index) => chapters.sublist(
      index * chunkSize,
      (index + 1) * chunkSize > chapters.length
          ? chapters.length
          : (index + 1) * chunkSize,
    ),
  );

  return [
    chapters,
    ...chunks,
  ];
}

enum DataVariant { regular, recommendation, relation, anilist, extension }

List<CarouselData> convertData(List<dynamic> data,
    {DataVariant variant = DataVariant.regular}) {
  return data.map((e) {
    String extra = "";
    switch (variant) {
      case DataVariant.regular:
        final data = e as AnilistMediaSmall;
        extra = data.averageScore?.toString() ?? "??";
        break;
      case DataVariant.recommendation:
        final data = e as Recommendation;
        extra = data.averageScore?.toString() ?? "??";
        break;
      case DataVariant.relation:
        final data = e as Relation;
        extra = data.type ?? "??";
        break;
      case DataVariant.anilist:
        final data = e as AnilistMediaUser;
        final ext = data.episodeCount;
        extra = ext ?? "??";
        break;
      case DataVariant.extension:
      // TODO: Handle this case.
    }
    if (variant == DataVariant.extension) {
      final data = e as MManga;
      return CarouselData(
        id: data.link,
        title: data.name,
        poster: data.imageUrl,
        extraData: data.author?.toUpperCase() ?? 'NOVEL',
      );
    } else {
      return CarouselData(
        id: e.id.toString(),
        title: e.title,
        poster: e.poster,
        extraData: extra,
      );
    }
  }).toList();
}

String formatTimeAgo(int millisecondsSinceEpoch) {
  final now = DateTime.now();
  final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);

  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return "${difference.inSeconds} seconds ago";
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes} minutes ago";
  } else if (difference.inHours < 24) {
    return "${difference.inHours} hours ago";
  } else if (difference.inDays < 7) {
    return "${difference.inDays} days ago";
  } else {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}

AnilistMediaData convertOfflineToAnilistMediaData(OfflineMedia offlineMedia) {
  return AnilistMediaData(
    id: offlineMedia.id ?? 0,
    jname: offlineMedia.jname ?? '',
    name: offlineMedia.name ?? '',
    english: offlineMedia.english ?? '',
    japanese: offlineMedia.japanese ?? '',
    description: offlineMedia.description ?? '',
    poster: offlineMedia.poster ?? '',
    cover: offlineMedia.cover,
    totalEpisodes: offlineMedia.totalEpisodes ?? '',
    type: offlineMedia.type ?? '',
    season: offlineMedia.season ?? '',
    premiered: offlineMedia.premiered ?? '',
    duration: offlineMedia.duration ?? '',
    status: offlineMedia.status ?? '',
    rating: offlineMedia.rating ?? '',
    popularity: offlineMedia.popularity ?? '',
    format: offlineMedia.format ?? '',
    aired: offlineMedia.aired ?? '',
    totalChapters: offlineMedia.totalChapters ?? '',
    genres: offlineMedia.genres ?? [],
    studios: offlineMedia.studios ?? [],
    characters: [],
    relations: [],
    recommendations: [],
    nextAiringEpisode: null,
    rankings: [],
  );
}

List<AnilistMediaUser> filterListByStatus(
    List<AnilistMediaUser> animeList, String status) {
  switch (status.toUpperCase()) {
    case 'WATCHING':
      return animeList
          .where((anime) => anime.watchingStatus == 'CURRENT')
          .toList();
    case 'READING':
      return animeList
          .where((anime) => anime.watchingStatus == 'CURRENT')
          .toList();
    case 'COMPLETED TV':
      return animeList
          .where((anime) =>
              anime.watchingStatus == 'COMPLETED' && anime.format == 'TV')
          .toList();
    case 'COMPLETED MOVIE':
      return animeList
          .where((anime) =>
              anime.watchingStatus == 'COMPLETED' && anime.format == 'MOVIE')
          .toList();
    case 'COMPLETED OVA':
      return animeList
          .where((anime) =>
              anime.watchingStatus == 'COMPLETED' && anime.format == 'OVA')
          .toList();
    case 'COMPLETED SPECIAL':
      return animeList
          .where((anime) =>
              anime.watchingStatus == 'COMPLETED' && anime.format == 'SPECIAL')
          .toList();
    case 'PAUSED':
      return animeList
          .where((anime) => anime.watchingStatus == 'PAUSED')
          .toList();
    case 'DROPPED':
      return animeList
          .where((anime) => anime.watchingStatus == 'DROPPED')
          .toList();
    case 'PLANNING':
      return animeList
          .where((anime) => anime.watchingStatus == 'PLANNING')
          .toList();
    case 'REWATCHING':
      return animeList
          .where((anime) => anime.watchingStatus == "REPEATING")
          .toList();

    case 'CURRENTLY WATCHING':
      return animeList
          .where((anime) => anime.watchingStatus == 'CURRENT')
          .toList();
    case 'CURRENTLY READING':
      return animeList
          .where((anime) => anime.watchingStatus == 'CURRENT')
          .toList();
    case 'ALL':
      return animeList;
    default:
      return [];
  }
}

List<AnilistMediaUser> filterListByLabel(
    List<AnilistMediaUser> animeList, String label) {
  return animeList.where((anime) {
    if (label == "Continue Watching" && anime.watchingStatus == 'CURRENT') {
      return true;
    }
    if (label == "Continue Reading" && anime.watchingStatus == 'CURRENT') {
      return true;
    }
    if (label == "Completed TV" && anime.watchingStatus == 'COMPLETED') {
      return true;
    }
    if (label == "Completed Manga" && anime.watchingStatus == 'COMPLETED') {
      return true;
    }
    if (label == "Completed Movie" && anime.watchingStatus == 'COMPLETED') {
      return true;
    }
    if (label == "Paused Animes" && anime.watchingStatus == 'PAUSED') {
      return true;
    }
    if (label == "Paused Manga" && anime.watchingStatus == 'PAUSED') {
      return true;
    }
    if (label == "Dropped Animes" && anime.watchingStatus == 'DROPPED') {
      return true;
    }
    if (label == "Dropped Manga" && anime.watchingStatus == 'DROPPED') {
      return true;
    }
    if (label == "Planning Animes" && anime.watchingStatus == 'PLANNING') {
      return true;
    }
    if (label == "Planning Manga" && anime.watchingStatus == 'PLANNING') {
      return true;
    }
    if (label == "Rewatching Animes" && anime.watchingStatus == 'REPEATING') {
      return true;
    }
    if (label == "Rewatching Manga" && anime.watchingStatus == 'REPEATING') {
      return true;
    }

    return false;
  }).toList();
}
