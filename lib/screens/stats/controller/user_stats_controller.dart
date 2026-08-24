import 'package:anymex/database/isar_models/daily_activity.dart';
import 'package:anymex/database/isar_models/media_stats.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/main.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart' hide isar;
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

class UserStatsController extends GetxController {
  final dailyActivities = <DailyActivity>[].obs;
  final mediaStats = <MediaStats>[].obs;

  @override
  void onInit() {
    super.onInit();
    dailyActivities.bindStream(
      isar.dailyActivitys.where().sortByDateDesc().watch(fireImmediately: true),
    );
    mediaStats.bindStream(
      isar.mediaStats.where().sortByLastInteractedDesc().watch(fireImmediately: true),
    );
    syncLibraryStats();
  }

  Future<void> syncLibraryStats() async {
    try {
      final existingStats = await isar.mediaStats.where().findAll();
      final existingMediaIds = existingStats.map((s) => s.mediaId).toSet();

      final libraryItems = await isar.offlineMedias.where().findAll();
      final List<MediaStats> newStatsList = [];

      for (final media in libraryItems) {
        final mediaId = media.mediaId;
        if (mediaId == null || existingMediaIds.contains(mediaId)) {
          continue;
        }

        final stats = MediaStats()
          ..mediaId = mediaId
          ..title = media.displayTitle
          ..poster = media.poster
          ..cover = media.cover
          ..lastInteracted = DateTime.now()
          ..interactionCount = 1;

        if (media.itemType == ItemType.anime) {
          if (mediaId.contains('*MOVIE')) {
            stats.type = 'movie';
          } else if (mediaId.contains('*SERIES')) {
            stats.type = 'series';
          } else {
            stats.type = 'anime';
          }

          int units = media.watchedEpisodes?.length ?? 0;
          if (units == 0 && media.currentEpisode != null) {
            final epNum = media.currentEpisode!.number;
            final cleanNum = epNum.replaceAll(RegExp(r'[^0-9]'), '');
            units = int.tryParse(cleanNum) ?? 0;
          }
          stats.totalUnitsConsumed = units;
          stats.totalTimeMinutes = units * 24;
        } else {
          stats.type = media.itemType == ItemType.manga ? 'manga' : 'novel';
          int units = media.readChapters?.length ?? 0;
          if (units == 0 && media.currentChapter != null) {
            final chNum = media.currentChapter!.number;
            if (chNum != null) {
              units = chNum.toInt();
            }
          }
          stats.totalUnitsConsumed = units;
          stats.totalTimeMinutes = units * 10;
        }

        newStatsList.add(stats);
      }

      if (newStatsList.isNotEmpty) {
        await isar.writeTxn(() async {
          for (final stats in newStatsList) {
            await isar.mediaStats.put(stats);
          }
        });
      }
    } catch (_) {}
  }

  int get todayWatchTime {
    final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return dailyActivities.firstWhereOrNull((a) => a.date.isAtSameMomentAs(today))?.watchTimeMinutes ?? 0;
  }

  int get todayReadTime {
    final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return dailyActivities.firstWhereOrNull((a) => a.date.isAtSameMomentAs(today))?.readTimeMinutes ?? 0;
  }

  int get totalWatchTimeMinutes {
    return mediaStats
        .where((s) => s.type == 'anime' || s.type == 'movie' || s.type == 'series')
        .fold(0, (sum, s) => sum + s.totalTimeMinutes);
  }

  int get totalReadTimeMinutes {
    return mediaStats
        .where((s) => s.type == 'manga' || s.type == 'novel')
        .fold(0, (sum, s) => sum + s.totalTimeMinutes);
  }

  Map<String, int> get streaks {
    if (dailyActivities.isEmpty) return {'current': 0, 'longest': 0};

    int current = 0;
    int longest = 0;
    int temp = 0;

    final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime lastDate = today;
    bool hasTodayOrYesterday = false;

    for (int i = 0; i < dailyActivities.length; i++) {
      final actDate = dailyActivities[i].date;
      if (actDate.isAtSameMomentAs(today) || actDate.isAtSameMomentAs(yesterday)) {
        hasTodayOrYesterday = true;
      }
      
      if (i == 0) {
        temp = 1;
      } else {
        final diff = lastDate.difference(actDate).inDays;
        if (diff == 1) {
          temp++;
        } else if (diff > 1) {
          if (temp > longest) longest = temp;
          temp = 1;
        }
      }
      lastDate = actDate;
    }
    if (temp > longest) longest = temp;

    current = hasTodayOrYesterday ? temp : 0;

    return {'current': current, 'longest': longest};
  }

  double get averageUnitsPerDay {
    if (dailyActivities.isEmpty) return 0.0;
    int totalUnits = dailyActivities.fold(0, (sum, a) => sum + a.episodesWatched + a.chaptersRead);
    return totalUnits / dailyActivities.length;
  }

  MediaStats? get favoriteTitle {
    if (mediaStats.isEmpty) return null;
    final list = List<MediaStats>.from(mediaStats);
    list.sort((a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
    return list.first;
  }

  int get totalDaysActive {
    return dailyActivities.where((a) => a.watchTimeMinutes > 0 || a.readTimeMinutes > 0).length;
  }

  int get totalTitlesAdded {
    return mediaStats.length;
  }

  int get totalUnitsConsumed {
    return mediaStats.fold(0, (sum, s) => sum + s.totalUnitsConsumed);
  }

  List<MediaStats> get frequentlyRevisited {
    final list = List<MediaStats>.from(mediaStats);
    list.sort((a, b) => b.interactionCount.compareTo(a.interactionCount));
    return list.take(5).toList();
  }
}
