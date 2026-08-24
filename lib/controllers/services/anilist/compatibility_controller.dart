import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/compatibility/compatibility_models.dart';
import 'package:anymex/utils/compatibility/matchmaker.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

class CompatibilityController extends GetxController {
  final AnilistAuth _auth = Get.find<AnilistAuth>();

  final Rx<Profile?> user1 = Rx<Profile?>(null);
  final Rx<Profile?> user2 = Rx<Profile?>(null);
  final Rx<CompatibilityResult?> result = Rx<CompatibilityResult?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  void initWithLoggedInUser() {
    if (_auth.isLoggedIn.value) {
      user1.value = _auth.profileData.value;
    }
  }

  void initForOtherUser(String otherUserName) {
    if (_auth.isLoggedIn.value) {
      user1.value = _auth.profileData.value;
    }
  }

  Future<void> runMatch({
    String? userName1,
    String? userName2,
    Profile? profile1,
    Profile? profile2,
    bool useLoggedInUser = true,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    result.value = null;

    try {
      Profile? p1 = profile1;
      Profile? p2 = profile2;
      List<TrackedMedia> u1Anime = [];
      List<TrackedMedia> u2Anime = [];
      List<TrackedMedia> u1Manga = [];
      List<TrackedMedia> u2Manga = [];

      final u1Name = p1?.name ?? userName1?.trim() ?? '';
      final u2Name = p2?.name ?? userName2?.trim() ?? '';

      if (p1 == null && useLoggedInUser && _auth.isLoggedIn.value) {
        p1 = _auth.profileData.value;
        u1Anime = _auth.animeList.toList();
        u1Manga = _auth.mangaList.toList();

        if (p2 == null && u2Name.isNotEmpty) {
          p2 = await _auth.fetchUserByName(u2Name);
        }
      } else {
        final res = await Future.wait([
          if (p1 == null && u1Name.isNotEmpty) _auth.fetchUserByName(u1Name) else Future.value(p1),
          if (p2 == null && u2Name.isNotEmpty) _auth.fetchUserByName(u2Name) else Future.value(p2),
        ]);
        p1 = res[0];
        p2 = res[1];
      }

      if (p1 == null) {
        errorMessage.value = 'Could not load first user.';
        isLoading.value = false;
        return;
      }

      if (p2 == null) {
        errorMessage.value = 'User not found or profile is private.';
        isLoading.value = false;
        return;
      }

      final id1 = p1.id?.toString().trim() ?? '';
      final id2 = p2.id?.toString().trim() ?? '';
      final n1 = p1.name?.trim().toLowerCase() ?? '';
      final n2 = p2.name?.trim().toLowerCase() ?? '';

      if ((id1.isNotEmpty && id2.isNotEmpty && id1 == id2) ||
          (n1.isNotEmpty && n2.isNotEmpty && n1 == n2)) {
        errorMessage.value =
            'Cannot compare a user with themselves! Please select two different AniList profiles.';
        isLoading.value = false;
        return;
      }

      _executeMatch(
        p1,
        p2,
        u1Anime: u1Anime,
        u2Anime: u2Anime,
        u1Manga: u1Manga,
        u2Manga: u2Manga,
      );
      isLoading.value = false;

      final bgUser1Media = (u1Anime.isEmpty && u1Name.isNotEmpty)
          ? _fetchUserMedia(u1Name)
          : Future.value((u1Anime, u1Manga));
      final bgUser2Media = (u2Anime.isEmpty && u2Name.isNotEmpty)
          ? _fetchUserMedia(u2Name)
          : Future.value((u2Anime, u2Manga));

      Future.wait([bgUser1Media, bgUser2Media]).then((mediaResults) {
        final m1 = mediaResults[0];
        final m2 = mediaResults[1];
        if (m1.$1.isNotEmpty || m2.$1.isNotEmpty || m1.$2.isNotEmpty || m2.$2.isNotEmpty) {
          _executeMatch(
            p1!,
            p2!,
            u1Anime: m1.$1,
            u2Anime: m2.$1,
            u1Manga: m1.$2,
            u2Manga: m2.$2,
          );
        }
      }).catchError((e) {
        Logger.w('Background media list fetch failed: $e');
      });

      _fetchMutualSocial(p1, p2).then((socialData) {
        if (socialData != null && result.value != null) {
          result.update((val) => val?.socialData = socialData);
        }
      }).catchError((e) {
        Logger.w('Background mutual social fetch failed: $e');
      });
    } catch (e) {
      Logger.e('Compatibility error: $e');
      errorMessage.value = 'Something went wrong. Please try again.';
      isLoading.value = false;
    }
  }

  Future<(List<TrackedMedia>, List<TrackedMedia>)> _fetchUserMedia(String username) async {
    final u = username.trim();
    if (u.isEmpty) return (const <TrackedMedia>[], const <TrackedMedia>[]);
    try {
      final res = await Future.wait([
        _auth.fetchUserMediaListFlat(u, 'ANIME'),
        _auth.fetchUserMediaListFlat(u, 'MANGA'),
      ]);
      return ((res[0] as List).cast<TrackedMedia>(), (res[1] as List).cast<TrackedMedia>());
    } catch (e) {
      Logger.w('Failed to fetch user media for $username: $e');
      return (const <TrackedMedia>[], const <TrackedMedia>[]);
    }
  }

  void _executeMatch(
    Profile p1,
    Profile p2, {
    List<TrackedMedia> u1Anime = const [],
    List<TrackedMedia> u2Anime = const [],
    List<TrackedMedia> u1Manga = const [],
    List<TrackedMedia> u2Manga = const [],
  }) {
    final perfA1 = u1Anime.where((e) => _isPerfectScore(e.score)).toList();
    final perfA2 = u2Anime.where((e) => _isPerfectScore(e.score)).toList();
    final perfM1 = u1Manga.where((e) => _isPerfectScore(e.score)).toList();
    final perfM2 = u2Manga.where((e) => _isPerfectScore(e.score)).toList();

    if (perfA1.isNotEmpty) {
      p1.perfectAnimeIds = _mapToIds(perfA1);
      p1.perfectAnimeList = _mapToFavMedia(perfA1);
    }
    if (perfA2.isNotEmpty) {
      p2.perfectAnimeIds = _mapToIds(perfA2);
      p2.perfectAnimeList = _mapToFavMedia(perfA2);
    }

    if (perfM1.isNotEmpty) {
      p1.perfectMangaIds = _mapToIds(perfM1);
      p1.perfectMangaList = _mapToFavMedia(perfM1);
    }
    if (perfM2.isNotEmpty) {
      p2.perfectMangaIds = _mapToIds(perfM2);
      p2.perfectMangaList = _mapToFavMedia(perfM2);
    }

    final commonAnimeList = _intersectMediaLists(u1Anime, u2Anime);
    final commonMangaList = _intersectMediaLists(u1Manga, u2Manga);

    user1.value = p1;
    user2.value = p2;

    final compatResult = Matchmaker.compute(
      p1,
      p2,
      user1PerfectAnimeIds: p1.perfectAnimeIds,
      user2PerfectAnimeIds: p2.perfectAnimeIds,
      user1PerfectMangaIds: p1.perfectMangaIds,
      user2PerfectMangaIds: p2.perfectMangaIds,
      sharedAnimeList: commonAnimeList,
      sharedMangaList: commonMangaList,
    );

    if (result.value?.socialData != null) {
      compatResult.socialData = result.value!.socialData;
    }

    result.value = compatResult;

    Logger.i(
        'Compatibility: ${p1.name} vs ${p2.name} = ${compatResult.percentage.toStringAsFixed(1)}% (${compatResult.rank}) [${commonAnimeList.length} shared anime, ${commonMangaList.length} shared manga]');
  }

  static bool _isPerfectScore(String? score) {
    final s = double.tryParse(score ?? '') ?? 0.0;
    return s >= 100 || s == 10;
  }

  static List<int> _mapToIds(List<TrackedMedia> media) {
    return media
        .map((e) => int.tryParse(e.id ?? '') ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  static List<FavouriteMedia> _mapToFavMedia(List<TrackedMedia> media) {
    return media
        .map((e) => FavouriteMedia(
              id: e.id,
              title: e.title,
              cover: e.poster,
              genres: e.genres,
              tags: e.tags,
            ))
        .toList();
  }

  static List<FavouriteMedia> _intersectMediaLists(
    List<TrackedMedia> list1,
    List<TrackedMedia> list2,
  ) {
    final map1 = <String, TrackedMedia>{
      for (var m in list1)
        if (m.id != null && m.id!.isNotEmpty) m.id!: m
    };
    final map2 = <String, TrackedMedia>{
      for (var m in list2)
        if (m.id != null && m.id!.isNotEmpty) m.id!: m
    };
    final commonIds = map1.keys.toSet().intersection(map2.keys.toSet());
    return commonIds.map((id) {
      final m1 = map1[id]!;
      final m2 = map2[id]!;
      return FavouriteMedia(
        id: id,
        title: m1.title ?? m2.title,
        cover: m1.poster ?? m2.poster,
        genres: <String>{...m1.genres, ...m2.genres}.toList(),
        tags: <String>{...m1.tags, ...m2.tags}.toList(),
      );
    }).toList();
  }

  Future<MutualSocialData?> _fetchMutualSocial(Profile p1, Profile p2) async {
    final id1 = int.tryParse(p1.id ?? '0') ?? 0;
    final id2 = int.tryParse(p2.id ?? '0') ?? 0;
    if (id1 <= 0 || id2 <= 0) return null;

    try {
      final results = await Future.wait([
        _auth.fetchFollowingPage(id1, page: 1),
        _auth.fetchFollowingPage(id2, page: 1),
        _auth.fetchFollowersPage(id1, page: 1),
        _auth.fetchFollowersPage(id2, page: 1),
      ]);

      final following1 = results[0].$1;
      final following2 = results[1].$1;
      final followers1 = results[2].$1;
      final followers2 = results[3].$1;

      final u1FollowsU2 = following1.any((u) => u.id == id2) || followers2.any((u) => u.id == id1);
      final u2FollowsU1 = following2.any((u) => u.id == id1) || followers1.any((u) => u.id == id2);

      final mutualFollowing = following1
          .where((u1) => following2.any((u2) => u2.id == u1.id))
          .toList();

      final mutualFollowers = followers1
          .where((u1) => followers2.any((u2) => u2.id == u1.id))
          .toList();

      return MutualSocialData(
        user1FollowsUser2: u1FollowsU2,
        user2FollowsUser1: u2FollowsU1,
        mutualFollowing: mutualFollowing,
        mutualFollowers: mutualFollowers,
      );
    } catch (e) {
      Logger.w('Could not fetch mutual social connections: $e');
      return null;
    }
  }

  void clear() {
    result.value = null;
    user2.value = null;
    errorMessage.value = '';
  }
}
