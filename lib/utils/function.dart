import 'dart:io';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/models/models_convertor/carousel_mapper.dart';
import 'package:device_info_plus/device_info_plus.dart';
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

String convertAniListStatus(String? status, {bool isManga = false}) {
  switch (status?.toUpperCase()) {
    case 'CURRENT':
      return isManga ? "CURRENTLY READING" : 'CURRENTLY WATCHING';
    case 'PLANNING':
      return 'PLANNING TO ${isManga ? 'READ' : 'WATCH'}';
    case 'COMPLETED':
      return 'COMPLETED';
    case 'DROPPED':
      return 'DROPPED';
    case 'PAUSED':
      return 'PAUSED';
    case 'REPEATING':
      return isManga ? "REREADING" : 'REWATCHING';
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

    final episodeMatch = RegExp(r"e(\d+)").firstMatch(name);
    if (episodeMatch != null) {
      return int.parse(episodeMatch.group(1)!);
    }

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

Episode DEpisodeToEpisode(DEpisode chapter) {
  // var episodeNumber = ChapterRecognition.parseChapterNumber(
  //     selectedMedia?.title ?? '', chapter.name ?? '');
  return Episode(
    number: chapter.episodeNumber,
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

List<Chapter> DEpisodeToChapter(List<DEpisode> chapters, String title) {
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

enum DataVariant {
  regular,
  recommendation,
  relation,
  anilist,
  extension,
  offline,
  library
}

List<CarouselData> convertData(List<dynamic> data,
    {DataVariant variant = DataVariant.regular, bool isManga = false}) {
  return data.map<CarouselData>((e) {
    switch (variant) {
      case DataVariant.extension:
        return (e as DMedia).toCarouselData(variant: variant, isManga: isManga);
      case DataVariant.offline:
        return (e as OfflineMedia)
            .toCarouselData(variant: variant, isManga: isManga);
      case DataVariant.relation:
        return (e as Relation)
            .toCarouselData(variant: variant, isManga: isManga);
      case DataVariant.anilist:
        return (e as TrackedMedia)
            .toCarouselData(variant: variant, isManga: isManga);
      default:
        return (e as Media).toCarouselData(variant: variant, isManga: isManga);
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

Media convertOfflineToMedia(OfflineMedia offlineMedia) {
  return Media(
      id: offlineMedia.id ?? '0',
      romajiTitle: offlineMedia.jname ?? '',
      title: offlineMedia.english ?? offlineMedia.name ?? '',
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
      serviceType: ServicesType.values[offlineMedia.serviceIndex ?? 0]);
}

List<TrackedMedia> filterListByStatus(
    List<TrackedMedia> animeList, String status,
    {bool isMAL = false}) {
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
              ((anime.watchingStatus == 'COMPLETED') && anime.format == 'TV'))
          .toList();
    case 'COMPLETED':
      return animeList
          .where((anime) => ((anime.watchingStatus == 'COMPLETED')))
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

List<TrackedMedia> filterListByLabel(
    List<TrackedMedia> animeList, String label) {
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

int getResponsiveCrossAxisVal(double screenWidth, {int itemWidth = 150}) {
  return (screenWidth / itemWidth).floor().clamp(1, 12);
}

Future<bool> isTv() async {
  if (!Platform.isAndroid) return false;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  bool isTV = androidInfo.systemFeatures.contains('android.software.leanback');
  return isTV;
}

void navigate(dynamic page) {
  Navigator.push(Get.context!, MaterialPageRoute(builder: (c) => page()));
}

extension SizedBoxExt on num {
  SizedBox width() {
    return SizedBox(width: toDouble());
  }

  SizedBox height() {
    return SizedBox(height: toDouble());
  }
}

String getRandomTag({String? addition}) {
  if (addition != null) {
    return '$addition-${DateTime.now().millisecond}';
  }
  return DateTime.now().millisecond.toString();
}
