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
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _kBaseApi = 'https://api.mangabaka.dev';
const _kBaseAuth = 'https://mangabaka.org/auth/oauth2';
const _kClientId = 'TpsJLfZWOXJgqTlzYRFMQJHeZXXFnCyq';
const _kRedirectUri = 'anymex://mangabaka-auth';
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

  RxList<Media> trendingManga = <Media>[].obs;

  String? _codeVerifier;

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
    if (_isUnauthorized(response)) {
      if (await _tryRefreshToken()) {
        response = await http.get(uri, headers: _authHeaders);
      }
    }
    return response;
  }

  Future<http.Response> _send(String method, String path,
      Map<String, dynamic> body) async {
    final uri = Uri.parse('$_kBaseApi$path');
    Future<http.Response> doRequest() async {
      final req = http.Request(method, uri)
        ..headers.addAll(_authHeaders)
        ..body = jsonEncode(body);
      return http.Response.fromStream(await req.send());
    }

    var response = await doRequest();
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

    final authUri = Uri.parse('$_kBaseAuth/authorize').replace(
      queryParameters: {
        'client_id': _kClientId,
        'redirect_uri': _kRedirectUri,
        'response_type': 'code',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'scope': 'library.read library.write profile offline_access',
      },
    );

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: _kCallbackScheme,
      );
      final code = Uri.parse(result).queryParameters['code'];
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
      final resp = await _get('/v1/my/profile');
      if (resp.statusCode != 200) return;
      final data =
          (jsonDecode(resp.body) as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      if (data != null) {
        profileData.value = Profile(
          id: data['id']?.toString(),
          name: data['username'] as String? ?? 'MangaBaka User',
          avatar: data['avatar'] as String?,
        );
      }
    } catch (e) {
      Logger.i('[MangaBaka] profile fetch error: $e');
    }
  }

  Future<void> fetchUserMangaList() async {
    try {
      final resp = await _get('/v1/my/library');
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
          .map((e) => TrackedMedia(
                id: e.seriesId?.toString() ?? '',
                episodeCount: e.progressChapter?.toString(),
                chapterCount: e.progressChapter?.toString(),
                watchingStatus: e.state?.toAnilistStatus(),
                score: e.rating?.toDouble().toString(),
              ))
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
      final resp = await _get('/v1/my/library/$seriesId');
      if (resp.statusCode == 404 || resp.statusCode != 200) return null;
      final envelope = MangaBakaResponse<MangaBakaLibraryEntry>.fromJson(
        jsonDecode(resp.body) as Map<String, dynamic>,
        (d) => MangaBakaLibraryEntry.fromJson(d as Map<String, dynamic>),
      );
      return envelope.data;
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

  Future<List<MangaBakaSeries>> searchSeries(String query,
      {bool nsfw = false}) async {
    try {
      final parts = ['q=${Uri.encodeComponent(query)}'];
      if (!nsfw) {
        parts.addAll([
          'not_content_rating=erotica',
          'not_content_rating=pornographic',
        ]);
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
      Logger.i('[MangaBaka] searchSeries error: $e');
      return [];
    }
  }

  Future<bool> _writeLibraryEntry({
    required int seriesId,
    required MangaBakaLibraryEntry entry,
    required bool create,
  }) async {
    try {
      final resp = await _send(
        create ? 'POST' : 'PATCH',
        '/v1/my/library/$seriesId',
        entry.toJson(),
      );
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
    if (seriesId == null) return;

    final existing = await fetchLibraryEntry(seriesId);
    final create = existing == null;

    final state = params.status != null
        ? MangaBakaLibraryState.fromAnilistStatus(params.status)
        : null;

    String? isoDate(DateTime? d) => d?.toUtc().toIso8601String();

    final entry = MangaBakaLibraryEntry(
      state: state,
      rating: params.score?.toInt(),
      progressChapter: params.progress,
      startDate: isoDate(params.startedAt),
      finishDate: isoDate(params.completedAt),
    );

    final ok = await _writeLibraryEntry(
        seriesId: seriesId, entry: entry, create: create);

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
    try {
      final results = await searchSeries('', nsfw: false);
      trendingManga.value = results.take(15).map((s) => s.toMedia()).toList();
    } catch (e) {
      Logger.i('[MangaBaka] fetchHomePage error: $e');
    }
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
            .map((e) => Media(
                  id: e.id ?? '',
                  title: e.title ?? '',
                  cover: e.coverImage,
                  serviceType: ServicesType.mangabaka,
                  mediaType: ItemType.manga,
                ))
            .toList();
        if (continueReading.isEmpty) return const SizedBox.shrink();
        return ReusableCarousel(
          data: continueReading,
          title: 'Continue Reading',
          variant: DataVariant.anilist,
          type: ItemType.manga,
        );
      }),
      Obx(() => trendingManga.isEmpty
          ? const Center(child: AnymexProgressIndicator())
          : ReusableCarousel(
              data: trendingManga.value,
              title: 'Trending on MangaBaka',
              type: ItemType.manga,
            )),
    ].obs;
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) => <Widget>[].obs;

  @override
  RxList<Widget> mangaWidgets(BuildContext context) {
    return [
      Obx(() => trendingManga.isEmpty
          ? const Center(child: AnymexProgressIndicator())
          : Column(children: [
              buildBigCarousel(trendingManga, true),
              ReusableCarousel(
                data: trendingManga.value,
                title: 'Trending on MangaBaka',
                type: ItemType.manga,
              ),
            ])),
    ].obs;
  }
}
