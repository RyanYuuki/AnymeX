import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/models/Anilist/anilist_activity.dart';
import 'package:anymex/models/Anilist/social_user.dart';

class StorySeenManager {
  static const String _key = 'stories_seen_ids';
  static Set<String>? _cachedSeen;

  static Set<String> get seenIds {
    if (_cachedSeen != null) return _cachedSeen!;
    final stored = KvHelper.get<List<String>>(_key, defaultVal: <String>[]);
    _cachedSeen = stored.toSet();
    return _cachedSeen!;
  }

  static bool isSeen(int activityId) {
    return seenIds.contains(activityId.toString());
  }

  static void markSeen(int activityId) {
    final strId = activityId.toString();
    if (seenIds.contains(strId)) return;
    _cachedSeen!.add(strId);
    final list = _cachedSeen!.toList();
    final kept = list.length > 500 ? list.sublist(list.length - 500) : list;
    KvHelper.set(_key, kept);
  }
}

class StoryGroup {
  final SocialUser user;
  final List<AnilistActivity> activities;

  const StoryGroup({
    required this.user,
    required this.activities,
  });

  bool get hasUnseen =>
      activities.any((a) => !StorySeenManager.isSeen(a.id));

  int get latestTimestamp =>
      activities.isEmpty ? 0 : activities.last.createdAt;
}
