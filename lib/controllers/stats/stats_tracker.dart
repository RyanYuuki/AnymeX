import 'package:anymex/main.dart';
import 'package:anymex/database/isar_models/daily_activity.dart';
import 'package:anymex/database/isar_models/media_stats.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

class StatsTracker extends GetxService {
  DateTime _normalizeDate(DateTime dt) {
    return DateTime.utc(dt.year, dt.month, dt.day);
  }

  Future<void> logWatch(
    String mediaId, 
    String title, 
    int minutes, {
    bool episodeCompleted = false,
    String? poster,
    String? cover,
  }) async {
    final today = _normalizeDate(DateTime.now());
    
    await isar.writeTxn(() async {
      var activity = await isar.dailyActivitys.where().dateEqualTo(today).findFirst();
      activity ??= DailyActivity()..date = today;
      
      activity.watchTimeMinutes += minutes;
      if (episodeCompleted) {
        activity.episodesWatched += 1;
      }
      if (!activity.activeMediaIds.contains(mediaId)) {
        activity.activeMediaIds.add(mediaId);
      }
      await isar.dailyActivitys.put(activity);

      var stats = await isar.mediaStats.where().mediaIdEqualTo(mediaId).findFirst();
      stats ??= MediaStats()
        ..mediaId = mediaId
        ..title = title;
      
      if (mediaId.contains('*MOVIE')) {
        stats.type = 'movie';
      } else if (mediaId.contains('*SERIES')) {
        stats.type = 'series';
      } else {
        stats.type = 'anime';
      }
      
      if (poster != null) stats.poster = poster;
      if (cover != null) stats.cover = cover;
      stats.totalTimeMinutes += minutes;
      if (episodeCompleted) stats.totalUnitsConsumed += 1;
      stats.lastInteracted = DateTime.now();
      stats.interactionCount += 1;
      await isar.mediaStats.put(stats);
    });
  }

  Future<void> logRead(
    String mediaId, 
    String title, 
    int minutes, {
    int chaptersCompleted = 1, 
    String type = 'manga',
    String? poster,
    String? cover,
  }) async {
    final today = _normalizeDate(DateTime.now());

    await isar.writeTxn(() async {
      var activity = await isar.dailyActivitys.where().dateEqualTo(today).findFirst();
      activity ??= DailyActivity()..date = today;

      activity.readTimeMinutes += minutes;
      activity.chaptersRead += chaptersCompleted;
      if (!activity.activeMediaIds.contains(mediaId)) {
        activity.activeMediaIds.add(mediaId);
      }
      await isar.dailyActivitys.put(activity);

      var stats = await isar.mediaStats.where().mediaIdEqualTo(mediaId).findFirst();
      stats ??= MediaStats()
        ..mediaId = mediaId
        ..title = title
        ..type = type;

      if (poster != null) stats.poster = poster;
      if (cover != null) stats.cover = cover;
      stats.totalTimeMinutes += minutes;
      stats.totalUnitsConsumed += chaptersCompleted;
      stats.lastInteracted = DateTime.now();
      stats.interactionCount += 1;
      await isar.mediaStats.put(stats);
    });
  }
}
