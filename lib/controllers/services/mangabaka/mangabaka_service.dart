import 'dart:convert';
import 'dart:math' show Random;

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/mangabaka/mangabaka_models.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _kBaseApi = 'https://api.mangabaka.dev';
const _kBaseAuth = 'https://mangabaka.org/auth/oauth2';
const _kClientId = 'TpsJLfZWOXJgqTlzYRFMQJHeZXXFnCyq';
const _kRedirectUri = 'anymex://callback';
const _kCallbackScheme = 'anymex';

class MangaBakaService extends GetxController
    implements BaseService, OnlineService {
  @override
  RxBool isLoggedIn = false.obs;
  @override
  Rx<Profile> profileData = Profile().obs;
  @override
  RxList<TrackedMedia> animeList = <TrackedMedia>[].obs;
  @override
  RxList<TrackedMedia> mangaList = <TrackedMedia>[].obs;
  @override
  Rx<TrackedMedia> currentMedia = TrackedMedia().obs;
  RxList<Media> recentlyAddedManga = <Media>[].obs;
  RxList<Media> popularManga = <Media>[].obs;
  RxList<Media> popularManhwa = <Media>[].obs;
  RxList<Media> popularManhua = <Media>[].obs;
  RxList<Media> popularOel = <Media>[].obs;
  RxList<Media> popularOther = <Media>[].obs;
  RxList<Media> recentlyAddedNovels = <Media>[].obs;
  RxList<Media> popularNovels = <Media>[].obs;

  String? _codeVerifier;
  String? _authState;

  String _generateCodeVerifier() {
    final rng = Random.secure();
    final bytes = List<int>.generate(64, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  String _generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(length, (_) => charset[rng.nextInt(charset.length)])
        .join();
  }

  MangaBakaOAuthToken? get _storedToken {
    final raw = AuthKeys.mangaBakaAuthToken.get<String?>();
    if (raw == null) return null;
    try {
      return MangaBakaOAuthToken.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void _saveToken(MangaBakaOAuthToken token) {
    AuthKeys.mangaBakaAuthToken.set(jsonEncode(token.toJson()));
  }

  String? get _accessToken => _storedToken?.accessToken;
  String? get _refreshToken => _storedToken?.refreshToken;

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${_accessToken ?? ''}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  bool _isUnauthorized(http.Response r) =>
      r.statusCode == 400 || r.statusCode == 401 || r.statusCode == 403;

  Future<bool> _tryRefreshToken() async {
    final refresh = _refreshToken;
    if (refresh == null) {
      isLoggedIn.value = false;
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse('$_kBaseAuth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _kClientId,
          'refresh_token': refresh,
          'grant_type': 'refresh_token',
          'redirect_uri': _kRedirectUri,
        },
      );
      if (response.statusCode == 200) {
        _saveToken(MangaBakaOAuthToken.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>));
        return true;
      }
    } catch (e) {
      Logger.i('[MangaBaka] refresh failed: $e');
    }
    isLoggedIn.value = false;
    return false;
  }

  Future<http.Response> _get(String path, {String? rawQuery}) async {
    var uri = Uri.parse('$_kBaseApi$path');
    if (rawQuery != null) {
      uri = uri.replace(query: rawQuery);
    }
    var response = await http.get(uri, headers: _authHeaders);
    if (response.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 5));
      return _get(path, rawQuery: rawQuery);
    }
    if (_isUnauthorized(response)) {
      if (await _tryRefreshToken()) {
        response = await http.get(uri, headers: _authHeaders);
      }
    }
    return response;
  }

  Future<http.Response> _send(
      String method, String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_kBaseApi$path');
    Future<http.Response> doRequest() async {
      final req = http.Request(method, uri)
        ..headers.addAll(_authHeaders)
        ..body = jsonEncode(body);
      return http.Response.fromStream(await req.send());
    }

    var response = await doRequest();
    if (response.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 5));
      return _send(method, path, body);
    }
    if (_isUnauthorized(response)) {
      if (await _tryRefreshToken()) {
        response = await doRequest();
      }
    }
    return response;
  }

  @override
  Future<void> login(BuildContext context) async {
    _codeVerifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(_codeVerifier!);

    _authState = _generateRandomString(16);
    final authUri = Uri.parse('$_kBaseAuth/authorize').replace(
      queryParameters: {
        'client_id': _kClientId,
        'redirect_uri': _kRedirectUri,
        'response_type': 'code',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'scope': 'openid profile library.read library.write offline_access',
        'state': _authState!,
        'prompt': 'consent',
      },
    );

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: _kCallbackScheme,
      );
      final resultUri = Uri.parse(result);
      final code = resultUri.queryParameters['code'];
      final returnedState = resultUri.queryParameters['state'];
      if (returnedState != _authState) {
        Logger.i('[MangaBaka] OAuth state mismatch — possible CSRF');
        errorSnackBar('Login failed: security check failed');
        return;
      }
      if (code != null && _codeVerifier != null) {
        await _exchangeCode(code);
      }
    } catch (e) {
      Logger.i('[MangaBaka] login error: $e');
      errorSnackBar('MangaBaka login failed');
    }
  }

  Future<void> _exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse('$_kBaseAuth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _kClientId,
        'code': code,
        'code_verifier': _codeVerifier!,
        'grant_type': 'authorization_code',
        'redirect_uri': _kRedirectUri,
      },
    );
    if (response.statusCode == 200) {
      _saveToken(MangaBakaOAuthToken.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>));
      isLoggedIn.value = true;
      snackBar('Logged in to MangaBaka!');
      await _fetchUserProfile();
      await fetchUserMangaList();
    } else {
      Logger.i('[MangaBaka] token exchange failed: ${response.body}');
      errorSnackBar('MangaBaka login failed');
    }
  }

  @override
  Future<void> autoLogin() async {
    final token = _storedToken;
    if (token == null) return;
    if (token.isExpired) {
      if (!await _tryRefreshToken()) return;
    }
    isLoggedIn.value = true;
    await _fetchUserProfile();
    await fetchUserMangaList();
  }

  @override
  Future<void> logout() async {
    AuthKeys.mangaBakaAuthToken.delete();
    isLoggedIn.value = false;
    profileData.value = Profile();
    mangaList.value = [];
    currentMedia.value = TrackedMedia();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final resp = await http.get(
        Uri.parse('$_kBaseAuth/userinfo'),
        headers: {
          'Authorization': 'Bearer ${_accessToken ?? ''}',
          'Accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        profileData.value = Profile(
          id: body['sub']?.toString(),
          name: body['preferred_username'] as String? ??
              body['nickname'] as String? ??
              'MangaBaka User',
          avatar: null,
        );
        return;
      }
      final meResp = await _get('/v1/my/profile');
      if (meResp.statusCode != 200) return;
      final data = (jsonDecode(meResp.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>?;
      if (data != null) {
        profileData.value = Profile(
          id: data['id']?.toString(),
          name: data['preferred_username'] as String? ??
              data['nickname'] as String? ??
              'MangaBaka User',
          avatar: null,
        );
      }
    } catch (e) {
      Logger.i('[MangaBaka] profile fetch error: $e');
    }
  }

  Future<void> fetchUserMangaList() async {
    try {
      final resp = await _get('/v1/my/library', rawQuery: 'page=1&limit=100&sort_by=updated_at_desc');
      if (resp.statusCode != 200) return;
      final envelope =
          MangaBakaResponse<List<MangaBakaLibraryEntry>>.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
        (d) => (d as List<dynamic>)
            .map((e) =>
                MangaBakaLibraryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (envelope.data == null) return;
      mangaList.value = envelope.data!
          .map((e) {
            final series = e.series;
            return TrackedMedia(
              id: series?.id.toString() ?? e.seriesId?.toString() ?? '',
              title: series?.title ?? '',
              poster: series?.coverUrl,
              episodeCount: e.progressChapter?.toString(),
              chapterCount: e.progressChapter?.toString(),
              watchingStatus: e.state?.toAnilistStatus(),
              score: e.rating?.toDouble().toString(),
              servicesType: ServicesType.mangabaka,
              mediaListId: e.id?.toString(),
            );
          })
          .toList();
    } catch (e) {
      Logger.i('[MangaBaka] fetchUserMangaList error: $e');
    }
  }

  @override
  void setCurrentMedia(String id, {bool isManga = false}) {
    currentMedia.value = mangaList.firstWhere(
      (e) => e.id == id,
      orElse: () => TrackedMedia(),
    );
  }

  Future<MangaBakaSeries?> fetchSeriesById(int id) async {
    try {
      final resp = await _get('/v1/series/$id');
      if (resp.statusCode != 200) return null;
      final envelope = MangaBakaResponse<MangaBakaSeries>.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
        (d) => MangaBakaSeries.fromJson(d as Map<String, dynamic>),
      );
      return envelope.data;
    } catch (e) {
      Logger.i('[MangaBaka] fetchSeriesById error: $e');
      return null;
    }
  }

  Future<MangaBakaLibraryEntry?> fetchLibraryEntry(int seriesId) async {
    try {
      final resp =
          await _get('/v1/my/library/batch', rawQuery: 'series_id=$seriesId');
      if (resp.statusCode != 200) return null;
      final envelope =
          MangaBakaResponse<List<MangaBakaLibraryEntry>>.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
        (d) => (d as List<dynamic>)
            .map((e) =>
                MangaBakaLibraryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      final entries = envelope.data;
      return (entries != null && entries.isNotEmpty) ? entries.first : null;
    } catch (e) {
      Logger.i('[MangaBaka] fetchLibraryEntry error: $e');
      return null;
    }
  }

  Future<List<MangaBakaLibraryEntry>> fetchLibraryEntries(
      List<int> seriesIds) async {
    if (seriesIds.isEmpty) return [];
    try {
      final query = seriesIds.map((id) => 'series_id=$id').join('&');
      final resp = await _get('/v1/my/library/batch', rawQuery: query);
      if (resp.statusCode != 200) return [];
      final envelope =
          MangaBakaResponse<List<MangaBakaLibraryEntry>>.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
        (d) => (d as List<dynamic>)
            .map((e) =>
                MangaBakaLibraryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return envelope.data ?? [];
    } catch (e) {
      Logger.i('[MangaBaka] fetchLibraryEntries error: $e');
      return [];
    }
  }

  Future<List<MangaBakaSeries>> _fetchSeries({
    String? query,
    List<MangaBakaType> types = const [],
    String sortBy = 'popularity_desc',
    bool nsfw = false,
    int limit = 15,
  }) async {
    try {
      if (isLoggedIn.value && (_storedToken?.isExpired ?? false)) {
        await _tryRefreshToken();
      }
      final parts = <String>[];
      if (query != null && query.isNotEmpty) {
        parts.add('q=${Uri.encodeComponent(query)}');
      }
      for (final t in types) {
        parts.add('type=${t.apiValue}');
      }
      parts.add('sort_by=$sortBy');
      parts.add('limit=$limit');
      if (!nsfw) {
        parts.add('not_content_rating=erotica');
        parts.add('not_content_rating=pornographic');
      }
      final resp =
          await _get('/v1/series/search', rawQuery: parts.join('&'));
      if (resp.statusCode != 200) return [];
      final envelope = MangaBakaResponse<List<MangaBakaSeries>>.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
        (d) => (d as List<dynamic>)
            .map((e) => MangaBakaSeries.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return envelope.data ?? [];
    } catch (e) {
      Logger.i('[MangaBaka] _fetchSeries error: $e');
      return [];
    }
  }

  Future<List<MangaBakaSeries>> searchSeries(String query,
      {bool nsfw = false}) async {
    return _fetchSeries(query: query, nsfw: nsfw, limit: 25);
  }

  Future<bool> _writeLibraryEntry({
    required int seriesId,
    required Map<String, dynamic> body,
    required bool create,
  }) async {
    try {
      var resp = await _send(
        create ? 'POST' : 'PUT',
        '/v1/my/library/$seriesId',
        body,
      );
      if (create && resp.statusCode == 409) {
        resp = await _send('PUT', '/v1/my/library/$seriesId', body);
      }
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      Logger.i('[MangaBaka] _writeLibraryEntry error: $e');
      return false;
    }
  }

  @override
  Future<void> updateListEntry(UpdateListEntryParams params) async {
    if (!isLoggedIn.value) return;
    final seriesId = int.tryParse(params.listId);
    if (seriesId == null) {
      Logger.i('[MangaBaka] Invalid series ID: ${params.listId}');
      errorSnackBar('Invalid series ID');
      return;
    }

    final existing = await fetchLibraryEntry(seriesId);
    final create = existing == null;

    final state = params.status != null
        ? MangaBakaLibraryState.fromAnilistStatus(params.status)
        : null;

    String? isoDate(DateTime? d) => d?.toUtc().toIso8601String();

    final body = <String, dynamic>{};
    if (state != null) body['state'] = state.value;
    if (params.score != null) body['rating'] = params.score!.toInt();
    if (params.progress != null) body['progress_chapter'] = params.progress;
    if (params.startedAt != null) body['start_date'] = isoDate(params.startedAt);
    if (params.completedAt != null) body['finish_date'] = isoDate(params.completedAt);
    if (create && state == null) body['state'] = 'reading';

    final ok = await _writeLibraryEntry(
        seriesId: seriesId, body: body, create: create);

    if (ok) {
      final updatedMedia = currentMedia.value
        ..chapterCount = params.progress?.toString()
        ..episodeCount = params.progress?.toString()
        ..watchingStatus = params.status
        ..score = params.score?.toString();
      currentMedia.value = updatedMedia;
      await _crossSync(seriesId: seriesId, params: params, mbState: state);
      await fetchUserMangaList();
    } else {
      errorSnackBar('Failed to update MangaBaka entry');
    }
  }

  Future<void> _crossSync({
    required int seriesId,
    required UpdateListEntryParams params,
    required MangaBakaLibraryState? mbState,
  }) async {
    try {
      final series = await fetchSeriesById(seriesId);
      if (series == null) return;

      final handler = Get.find<ServiceHandler>();

      if (series.anilistId != null &&
          handler.anilistService.isLoggedIn.value) {
        await handler.anilistService.updateListEntry(UpdateListEntryParams(
          listId: series.anilistId.toString(),
          score: params.score,
          status: mbState?.toAnilistStatus() ?? params.status,
          progress: params.progress,
          isAnime: false,
          startedAt: params.startedAt,
          completedAt: params.completedAt,
        ));
        Logger.i('[MangaBaka] synced AniList id=${series.anilistId}');
      }

      if (series.malId != null && handler.malService.isLoggedIn.value) {
        await handler.malService.updateListEntry(UpdateListEntryParams(
          listId: series.malId.toString(),
          score: params.score,
          status: mbState?.toMalStatus() ?? params.status ?? '',
          progress: params.progress,
          isAnime: false,
          startedAt: params.startedAt,
          completedAt: params.completedAt,
        ));
        Logger.i('[MangaBaka] synced MAL id=${series.malId}');
      }
    } catch (e) {
      Logger.i('[MangaBaka] _crossSync error: $e');
    }
  }

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async {
    final seriesId = int.tryParse(listId);
    if (seriesId == null) return;
    try {
      final uri = Uri.parse('$_kBaseApi/v1/my/library/$seriesId');
      final req = http.Request('DELETE', uri)..headers.addAll(_authHeaders);
      final resp = await http.Response.fromStream(await req.send());
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        currentMedia.value = TrackedMedia();
        snackBar('Manga removed from MangaBaka library');
        await fetchUserMangaList();
      } else {
        errorSnackBar('Failed to remove from MangaBaka');
      }
    } catch (e) {
      Logger.i('[MangaBaka] deleteListEntry error: $e');
    }
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final results =
        await searchSeries(params.query, nsfw: params.args == true);
    return results.map((s) => s.toMedia()).toList();
  }

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    final id = int.tryParse(params.id.toString());
    if (id == null) throw Exception('Invalid MangaBaka series id');
    final series = await fetchSeriesById(id);
    if (series == null) throw Exception('Series not found on MangaBaka');
    return series.toMedia();
  }

  @override
  Future<void> fetchHomePage() async {
    await Future.wait([
      _loadMangaPageSections(),
      _loadNovelPageSections(),
    ]);
  }

  Future<void> _loadMangaPageSections() async {
    final mangaTypes = [
      MangaBakaType.manga,
      MangaBakaType.manhwa,
      MangaBakaType.manhua,
      MangaBakaType.oel,
      MangaBakaType.other,
    ];

    final results = await Future.wait([
      _fetchSeries(types: mangaTypes, sortBy: 'latest', limit: 15),
      _fetchSeries(
          types: [MangaBakaType.manga], sortBy: 'popularity_desc', limit: 15),
      _fetchSeries(
          types: [MangaBakaType.manhwa], sortBy: 'popularity_desc', limit: 15),
      _fetchSeries(
          types: [MangaBakaType.manhua], sortBy: 'popularity_desc', limit: 15),
      _fetchSeries(
          types: [MangaBakaType.oel], sortBy: 'popularity_desc', limit: 15),
      _fetchSeries(
          types: [MangaBakaType.other], sortBy: 'popularity_desc', limit: 15),
    ]);

    recentlyAddedManga.assignAll(results[0].map((s) => s.toMedia()).toList());
    popularManga.assignAll(results[1].map((s) => s.toMedia()).toList());
    popularManhwa.assignAll(results[2].map((s) => s.toMedia()).toList());
    popularManhua.assignAll(results[3].map((s) => s.toMedia()).toList());
    popularOel.assignAll(results[4].map((s) => s.toMedia()).toList());
    popularOther.assignAll(results[5].map((s) => s.toMedia()).toList());
  }

  Future<void> _loadNovelPageSections() async {
    final results = await Future.wait([
      _fetchSeries(
          types: [MangaBakaType.novel], sortBy: 'latest', limit: 15),
      _fetchSeries(
          types: [MangaBakaType.novel], sortBy: 'popularity_desc', limit: 15),
    ]);

    recentlyAddedNovels.assignAll(results[0].map((s) => s.toMedia()).toList());
    popularNovels.assignAll(results[1].map((s) => s.toMedia()).toList());
  }

  @override
  Future<void> refresh() async {
    await fetchUserMangaList();
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    return [
      Obx(() {
        if (!isLoggedIn.value) return const SizedBox.shrink();
        final continueReading = mangaList
            .where((e) => e.watchingStatus == 'CURRENT')
            .toList();
        if (continueReading.isEmpty) return const SizedBox.shrink();
        return ReusableCarousel(
          data: continueReading,
          title: 'Continue Reading',
          variant: DataVariant.anilist,
          type: ItemType.manga,
        );
      }),
      Obx(() => recentlyAddedManga.isEmpty
          ? const Center(child: AnymexProgressIndicator())
          : ReusableCarousel(
              data: recentlyAddedManga,
              title: 'Popular on MangaBaka',
              type: ItemType.manga,
            )),
      Obx(() => popularNovels.isEmpty
          ? const SizedBox.shrink()
          : ReusableCarousel(
              data: popularNovels,
              title: 'Popular Novels',
              type: ItemType.novel,
            )),
    ].obs;
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) {
    return [
      Obx(() {
        if (recentlyAddedManga.isEmpty) {
          return const Center(child: AnymexProgressIndicator());
        }
        return Column(children: [
          buildBigCarousel(recentlyAddedManga, false),
          ReusableCarousel(
            data: recentlyAddedManga,
            title: 'Recently Added',
            type: ItemType.manga,
          ),
          if (popularManga.isNotEmpty)
            ReusableCarousel(
              data: popularManga,
              title: 'Popular Manga',
              type: ItemType.manga,
            ),
          if (popularManhwa.isNotEmpty)
            ReusableCarousel(
              data: popularManhwa,
              title: 'Popular Manhwa',
              type: ItemType.manga,
            ),
          if (popularManhua.isNotEmpty)
            ReusableCarousel(
              data: popularManhua,
              title: 'Popular Manhua',
              type: ItemType.manga,
            ),
          if (popularOel.isNotEmpty)
            ReusableCarousel(
              data: popularOel,
              title: 'OEL Comics',
              type: ItemType.manga,
            ),
          if (popularOther.isNotEmpty)
            ReusableCarousel(
              data: popularOther,
              title: 'Other',
              type: ItemType.manga,
            ),
        ]);
      }),
    ].obs;
  }

  @override
  RxList<Widget> mangaWidgets(BuildContext context) {
    return [
      Obx(() {
        if (recentlyAddedNovels.isEmpty) {
          return const Center(child: AnymexProgressIndicator());
        }
        return Column(children: [
          buildBigCarousel(recentlyAddedNovels, true),
          ReusableCarousel(
            data: recentlyAddedNovels,
            title: 'Recently Added Novels',
            type: ItemType.novel,
          ),
          if (popularNovels.isNotEmpty)
            ReusableCarousel(
              data: popularNovels,
              title: 'Popular Novels',
              type: ItemType.novel,
            ),
        ]);
      }),
    ].obs;
  }
}
