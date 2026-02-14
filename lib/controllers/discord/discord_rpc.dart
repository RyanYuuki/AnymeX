// discord_rpc_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_discord_rpc_fork/flutter_discord_rpc.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

enum DiscordKeys { token, profile }

class DiscordProfile {
  final String id;
  final String username;
  final String discriminator;
  final String? avatar;
  final String? banner;
  final String? email;
  final bool verified;
  final int? premiumType;

  DiscordProfile({
    required this.id,
    required this.username,
    required this.discriminator,
    this.avatar,
    this.banner,
    this.email,
    required this.verified,
    this.premiumType,
  });

  String get displayName =>
      discriminator == '0' ? username : '$username#$discriminator';

  String get avatarUrl {
    if (avatar != null) {
      return 'https://cdn.discordapp.com/avatars/$id/$avatar.png?size=256';
    }
    final defaultAvatarNum = discriminator == '0'
        ? (int.parse(id) >> 22) % 6
        : int.parse(discriminator) % 5;
    return 'https://cdn.discordapp.com/embed/avatars/$defaultAvatarNum.png';
  }

  String? get bannerUrl {
    if (banner != null) {
      return 'https://cdn.discordapp.com/banners/$id/$banner.png?size=600';
    }
    return null;
  }

  String get premiumTypeName {
    switch (premiumType) {
      case 1:
        return 'Nitro Classic';
      case 2:
        return 'Nitro';
      case 3:
        return 'Nitro Basic';
      default:
        return 'None';
    }
  }

  factory DiscordProfile.fromJson(Map<String, dynamic> json) {
    return DiscordProfile(
      id: json['id'],
      username: json['username'],
      discriminator: json['discriminator'] ?? '0',
      avatar: json['avatar'],
      banner: json['banner'],
      email: json['email'],
      verified: json['verified'] ?? false,
      premiumType: json['premium_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'discriminator': discriminator,
      'avatar': avatar,
      'banner': banner,
      'email': email,
      'verified': verified,
      'premium_type': premiumType,
    };
  }
}

class DiscordRPCController extends GetxController {
  static const String _applicationId = '1435544312296505394';
  static const String _gatewayUrl =
      'wss://gateway.discord.gg/?v=10&encoding=json';
  static const String _apiBaseUrl = 'https://discord.com/api/v10';

  FlutterDiscordRPC? _discordRPC;
  StreamSubscription<bool>? _desktopConnectionSub;

  WebSocket? _gatewaySocket;
  Timer? _heartbeatTimer;
  int? _heartbeatInterval;
  int? _sequenceNumber;

  final _isConnected = false.obs;
  final _isMobile = (Platform.isAndroid || Platform.isIOS).obs;
  final _token = ''.obs;
  final Rx<DiscordProfile?> profile = Rx<DiscordProfile?>(null);
  final _isLoading = false.obs;

  bool get isConnected => _isConnected.value;
  bool get isMobile => _isMobile.value;
  bool get isLoggedIn => _token.value.isNotEmpty;
  bool get isLoading => _isLoading.value;
  DiscordProfile? get userProfile => profile.value;

  static DiscordRPCController get instance => Get.find<DiscordRPCController>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadToken();
    if (_token.value.isNotEmpty) {
      await _loadProfile();
      await connect();
    }
  }

  Future<void> _loadToken() async {
    _token.value = DiscordKeys.token.get('');
    if (!isMobile) {
      _token.value = 'DESKTOP';
    }
  }

  Future<void> _saveToken(String token) async {
    DiscordKeys.token.set(token);
    _token.value = token;
  }

  Future<void> _loadProfile() async {
    final profileJson = DiscordKeys.profile.get<String?>(null);
    if (profileJson != null) {
      try {
        profile.value = DiscordProfile.fromJson(jsonDecode(profileJson));
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> _saveProfile(DiscordProfile userProfile) async {
    DiscordKeys.profile.set<String>(jsonEncode(userProfile.toJson()));
    profile.value = userProfile;
  }

  Future<void> fetchUserProfile() async {
    if (_token.value.isEmpty) {
      print('No token available');
      return;
    }

    _isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users/@me'),
        headers: {
          'Authorization': _token.value,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userProfile = DiscordProfile.fromJson(data);
        await _saveProfile(userProfile);
        print('Profile fetched: ${userProfile.displayName}');
      } else if (response.statusCode == 401) {
        print('Invalid token, logging out');
        await logout();
        snackBar('Session expired. Please login again.');
      } else {
        print('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> onLoginSuccess(String token) async {
    await _saveToken(token);
    await fetchUserProfile();
    await connect();
    snackBar(
        'Successfully logged in as ${profile.value?.displayName ?? "User"}');
  }

  Future<void> connect() async {
    if (_isConnected.value) {
      print('Already connected to Discord RPC');
      return;
    }

    if (isMobile) {
      if (_token.value.isEmpty) {
        print('No token found. Please login first.');
        return;
      }
      await _connectMobileGateway();
    } else {
      await _initializeDesktopRPC();
    }
  }

  Future<void> _initializeDesktopRPC() async {
    try {
      await FlutterDiscordRPC.initialize(_applicationId);
      _discordRPC = FlutterDiscordRPC.instance;
      _desktopConnectionSub?.cancel();
      _desktopConnectionSub =
          _discordRPC!.isConnectedStream.listen((connected) {
        _isConnected.value = connected;
      });

      await _discordRPC!.connect(autoRetry: true);
      _isConnected.value = _discordRPC!.isConnected;
      if (!_isConnected.value) {
        print('Discord RPC connect requested (Desktop), but not connected yet');
        return;
      }
      print('Connected to Discord RPC (Desktop)');

      await updateBrowsingPresence(
        activity: 'Browsing Stuff',
        details: 'Idle',
      );
    } catch (e) {
      print('Failed to connect to Discord RPC: $e');
      _isConnected.value = false;
      snackBar('Failed to connect to Discord RPC');
    }
  }

  bool _canUseDesktopRpc(String action) {
    if (isMobile) {
      return true;
    }
    final connected = _discordRPC != null && _discordRPC!.isConnected;
    if (!connected) {
      _isConnected.value = false;
      print('Skipping $action: Discord RPC is not connected (Desktop)');
      return false;
    }
    return true;
  }

  Future<void> _connectMobileGateway() async {
    try {
      _gatewaySocket = await WebSocket.connect(_gatewayUrl);

      _gatewaySocket!.listen(
        _handleGatewayMessage,
        onError: (error) {
          print('Gateway error: $error');
          _isConnected.value = false;
        },
        onDone: () {
          print('Gateway connection closed');
          _isConnected.value = false;
          _heartbeatTimer?.cancel();
        },
      );

      print('Connected to Discord Gateway (Mobile)');
    } catch (e) {
      print('Failed to connect to Discord Gateway: $e');
      _isConnected.value = false;
      snackBar('Failed to connect to Discord');
    }
  }

  void _handleGatewayMessage(dynamic message) {
    final data = jsonDecode(message);
    final op = data['op'];

    _sequenceNumber = data['s'];

    switch (op) {
      case 10: // Hello
        _heartbeatInterval = data['d']['heartbeat_interval'];
        _identify();
        _startHeartbeat();
        break;
      case 0: // Dispatch
        final event = data['t'];
        if (event == 'READY') {
          _isConnected.value = true;
          print('Discord Gateway Ready (Mobile)');
          updateBrowsingPresence(
            activity: 'Browsing Stuff',
            details: 'Idle',
          );
        }
        break;
      case 11: // Heartbeat ACK
        print('Heartbeat acknowledged');
        break;
    }
  }

  void _identify() {
    final payload = {
      'op': 2,
      'd': {
        'token': _token.value,
        'properties': {
          '\$os': Platform.operatingSystem,
          '\$browser': 'AnymeX',
          '\$device': 'AnymeX Mobile',
        },
        'presence': {
          'status': 'online',
          'afk': false,
        },
      },
    };

    _gatewaySocket?.add(jsonEncode(payload));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (_heartbeatInterval != null) {
      _heartbeatTimer = Timer.periodic(
        Duration(milliseconds: _heartbeatInterval!),
        (_) => _sendHeartbeat(),
      );
    }
  }

  void _sendHeartbeat() {
    final payload = {
      'op': 1,
      'd': _sequenceNumber,
    };
    _gatewaySocket?.add(jsonEncode(payload));
  }

  Future<String> _processImageUrl(String? url) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final processedUrl = await urlToDcAsset(url ?? _getAppIconUrl());
        print('Processed image URL: $processedUrl');
        return processedUrl;
      }

      if (url == null || url.isEmpty) {
        return _getAppIconUrl();
      }

      return url;
    } catch (e) {
      print('Error processing image URL: $e');
      return _getAppIconUrl();
    }
  }

  Future<String> urlToDcAsset(String url) async {
    try {
      print('Converting URL to Discord asset: $url');

      final resp = await Dio().post(
        "https://discord.com/api/v9/applications/$_applicationId/external-assets",
        options: Options(
          headers: {
            'Authorization': _token.value,
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          "urls": [url]
        }),
      );

      print('Discord asset conversion response: ${resp.statusCode}');

      if (resp.statusCode == 200 && resp.data != null && resp.data.isNotEmpty) {
        final assetPath = "mp:${resp.data[0]['external_asset_path']}";
        print('Successfully converted to asset: $assetPath');
        return assetPath;
      } else {
        print('Failed to convert asset: ${resp.statusCode} - ${resp.data}');
        return url;
      }
    } catch (e) {
      print('Error converting URL to Discord asset: $e');
      return url;
    }
  }

// Fixed updateAnimePresence method
  Future<void> updateAnimePresence({
    required Media anime,
    required Episode episode,
    required String totalEpisodes,
  }) async {
    if (!_isConnected.value || !_canUseDesktopRpc('updateAnimePresence')) {
      print('Discord not connected');
      return;
    }

    final currentSeconds =
        Duration(milliseconds: episode.timeStampInMilliseconds ?? 0).inSeconds;
    final totalSeconds =
        Duration(milliseconds: episode.durationInMilliseconds ?? 0).inSeconds;
    final startTime =
        DateTime.now().subtract(Duration(seconds: currentSeconds));
    final endTime =
        DateTime.now().add(Duration(seconds: totalSeconds - currentSeconds));
    final episodeNumber = episode.number.toString();
    final episodeName = episode.title ?? 'Episode $episodeNumber';
    final coverUrl = anime.cover ?? anime.poster;
    final anilistUrl = 'https://anilist.co/anime/${anime.id}';
    final animeTitle = anime.title;

    if (isMobile) {
      final presencePayload = jsonEncode({
        'op': 3,
        'd': {
          'since': null,
          'activities': [
            {
              'name': 'AnymeX',
              'type': 3, // Watching
              'details': animeTitle,
              'state':
                  'Episode $episodeNumber ${!episodeName.toLowerCase().contains('episode') ? '– $episodeName' : ''}',
              'timestamps': {
                'start': startTime.millisecondsSinceEpoch,
                'end': endTime.millisecondsSinceEpoch,
              },
              'assets': {
                'large_image': await _processImageUrl(coverUrl),
                'large_text': animeTitle,
                'small_image': await _processImageUrl(_getAppIconUrl()),
                'small_text': 'AnymeX',
              },
              'buttons': [
                'View Anime',
                'Watch on AnymeX',
              ],
              'metadata': {
                'button_urls': [
                  anilistUrl,
                  'https://github.com/RyanYuuki/AnymeX/',
                ],
              }
            }
          ],
          'status': 'online',
          'afk': false,
        },
      });
      _gatewaySocket?.add(presencePayload);
      print('Anime presence updated successfully (Mobile)');
    } else {
      try {
        await _discordRPC!.setActivity(
          activity: RPCActivity(
            details: animeTitle,
            state:
                'Episode $episodeNumber ${!episodeName.toLowerCase().contains('episode') ? '– $episodeName' : ''} - $totalEpisodes',
            activityType: ActivityType.watching,
            timestamps: RPCTimestamps(
              start: startTime.millisecondsSinceEpoch,
              end: endTime.millisecondsSinceEpoch,
            ),
            assets: RPCAssets(
              largeImage: await _processImageUrl(coverUrl),
              largeText: animeTitle,
              smallImage: await _processImageUrl(_getAppIconUrl()),
              smallText: 'AnymeX',
            ),
            buttons: [
              RPCButton(label: 'View Anime', url: anilistUrl),
              const RPCButton(
                label: 'Watch on AnymeX',
                url: 'https://github.com/RyanYuuki/AnymeX/',
              ),
            ],
          ),
        );
        print('Anime presence updated successfully');
      } catch (e) {
        print('Error updating anime presence: $e');
      }
    }
  }

// Fixed updateAnimePresencePaused method
  Future<void> updateAnimePresencePaused({
    required Media anime,
    required Episode episode,
    required String totalEpisodes,
  }) async {
    if (!_isConnected.value ||
        !_canUseDesktopRpc('updateAnimePresencePaused')) {
      print('Discord not connected');
      return;
    }

    final episodeNumber = episode.number.toString();
    final coverUrl = anime.cover ?? anime.poster;
    final anilistUrl = 'https://anilist.co/anime/${anime.id}';
    final animeTitle = anime.title;

    final currentSeconds =
        Duration(milliseconds: episode.timeStampInMilliseconds ?? 0).inSeconds;
    final totalSeconds =
        Duration(milliseconds: episode.durationInMilliseconds ?? 0).inSeconds;
    final timeDisplay = (currentSeconds > 0 && totalSeconds > 0)
        ? ' • ${_formatDuration(Duration(seconds: currentSeconds))} / ${_formatDuration(Duration(seconds: totalSeconds))}'
        : '';

    if (isMobile) {
      final presencePayload = jsonEncode({
        'op': 3,
        'd': {
          'since': null,
          'activities': [
            {
              'name': 'AnymeX',
              'type': 3, // Watching
              'details': animeTitle,
              'state': 'Episode $episodeNumber$timeDisplay (Paused)',
              'assets': {
                'large_image': await _processImageUrl(coverUrl),
                'large_text': animeTitle,
                'small_image': await _processImageUrl(_getAppIconUrl()),
                'small_text': 'AnymeX',
              },
              'buttons': [
                'View Anime',
                'Watch on AnymeX',
              ],
              'metadata': {
                'button_urls': [
                  anilistUrl,
                  'https://github.com/RyanYuuki/AnymeX/',
                ],
              }
            }
          ],
          'status': 'online',
          'afk': false,
        },
      });
      _gatewaySocket?.add(presencePayload);
      print('Paused anime presence updated successfully (Mobile)');
    } else {
      try {
        await _discordRPC!.setActivity(
          activity: RPCActivity(
            details: animeTitle,
            state: 'Episode $episodeNumber$timeDisplay (Paused)',
            activityType: ActivityType.watching,
            assets: RPCAssets(
              largeImage: await _processImageUrl(coverUrl),
              largeText: animeTitle,
              smallImage: await _processImageUrl(_getAppIconUrl()),
              smallText: 'AnymeX',
            ),
            buttons: [
              RPCButton(label: 'View Anime', url: anilistUrl),
              const RPCButton(
                label: 'Watch on AnymeX',
                url: 'https://github.com/RyanYuuki/AnymeX/',
              ),
            ],
          ),
        );
        print('Paused anime presence updated successfully');
      } catch (e) {
        print('Error updating paused anime presence: $e');
      }
    }
  }

// Fixed updateMangaPresence method
  Future<void> updateMangaPresence({
    required Media manga,
    required Chapter chapter,
    required String totalChapters,
    int currentPage = 1,
  }) async {
    if (!_isConnected.value || !_canUseDesktopRpc('updateMangaPresence')) {
      print('Discord not connected');
      return;
    }

    final coverUrl = manga.cover ?? manga.poster;
    final anilistUrl = 'https://anilist.co/manga/${manga.id}';
    final mangaTitle = manga.title;
    final chapterNumber = chapter.number?.toString() ?? 'Unknown';
    final totalPages = chapter.totalPages ?? 1;

    if (isMobile) {
      final presencePayload = jsonEncode({
        'op': 3,
        'd': {
          'since': null,
          'activities': [
            {
              'name': 'AnymeX',
              'type': 0, // Playing
              'details': mangaTitle,
              'state':
                  'Chapter: $chapterNumber/$totalChapters • Page: $currentPage/$totalPages',
              'assets': {
                'large_image': await _processImageUrl(coverUrl),
                'large_text': mangaTitle,
                'small_image': await _processImageUrl(_getAppIconUrl()),
                'small_text': 'AnymeX',
              },
              'buttons': [
                'View Manga',
                'Read on AnymeX',
              ],
              'metadata': {
                'button_urls': [
                  anilistUrl,
                  'https://github.com/RyanYuuki/AnymeX/',
                ],
              }
            }
          ],
          'status': 'online',
          'afk': false,
        },
      });
      _gatewaySocket?.add(presencePayload);
      print('Manga presence updated successfully (Mobile)');
    } else {
      try {
        await _discordRPC!.setActivity(
          activity: RPCActivity(
            details: mangaTitle,
            state:
                'Chapter: $chapterNumber/$totalChapters • Page: $currentPage/$totalPages',
            activityType: ActivityType.playing,
            assets: RPCAssets(
              largeImage: await _processImageUrl(coverUrl),
              largeText: mangaTitle,
              smallImage: await _processImageUrl(_getAppIconUrl()),
              smallText: 'AnymeX',
            ),
            buttons: [
              RPCButton(label: 'View Manga', url: anilistUrl),
              const RPCButton(
                label: 'Read on AnymeX',
                url: 'https://github.com/RyanYuuki/AnymeX/',
              ),
            ],
          ),
        );
        print('Manga presence updated successfully');
      } catch (e) {
        print('Error updating manga presence: $e');
      }
    }
  }

  Future<void> updateMediaPresence({required Media media}) async {
    if (!_isConnected.value || !_canUseDesktopRpc('updateMediaPresence')) {
      print('Discord not connected');
      return;
    }

    final anilistUrl =
        'https://anilist.co/${media.mediaType.isAnime ? 'anime' : 'manga'}/${media.id}';
    final animeTitle = media.title;
    final type = media.mediaType.name.capitalizeFirst ?? '';

    if (isMobile) {
      final presencePayload = jsonEncode({
        'op': 3,
        'd': {
          'since': null,
          'activities': [
            {
              'name': 'AnymeX',
              'type': 0,
              'details': animeTitle,
              'state': 'Viewing $type',
              'assets': {
                'large_image':
                    await _processImageUrl(media.cover ?? media.poster),
                'large_text': animeTitle,
                'small_image': await _processImageUrl(_getAppIconUrl()),
                'small_text': 'AnymeX',
              },
              'buttons': [
                'View $type',
                '${media.mediaType.isAnime ? 'Watch' : 'Read'} on AnymeX',
              ],
              'metadata': {
                'button_urls': [
                  anilistUrl,
                  'https://github.com/RyanYuuki/AnymeX',
                ],
              }
            }
          ],
          'status': 'online',
          'afk': false,
        },
      });
      _gatewaySocket?.add(presencePayload);
      print('Media presence updated successfully (Mobile)');
    } else {
      try {
        await _discordRPC!.setActivity(
          activity: RPCActivity(
            details: animeTitle,
            state: 'Viewing $type',
            activityType: ActivityType.watching,
            assets: RPCAssets(
              largeImage: await _processImageUrl(media.cover ?? media.poster),
              largeText: animeTitle,
              smallImage: await _processImageUrl(_getAppIconUrl()),
              smallText: 'AnymeX',
            ),
            buttons: [
              RPCButton(label: 'View $type', url: anilistUrl),
              const RPCButton(
                label: 'Watch on AnymeX',
                url: 'https://github.com/RyanYuuki/AnymeX/',
              ),
            ],
          ),
        );
        print('Media presence updated successfully');
      } catch (e) {
        print('Error updating media presence: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> updateBrowsingPresence({
    String? activity,
    String? details,
  }) async {
    if (!_isConnected.value || !_canUseDesktopRpc('updateBrowsingPresence')) {
      print('Discord not connected');
      return;
    }

    if (isMobile) {
      final presencePayload = jsonEncode({
        'op': 3,
        'd': {
          'since': null,
          'activities': [
            {
              'name': 'AnymeX',
              'type': 0,
              'details': activity ?? 'Browsing Stuff',
              'state': details ?? 'Idle',
              'assets': {
                'large_image': await _processImageUrl(_getAppIconUrl()),
                'large_text': 'AnymeX - Anime & Manga',
              },
              'buttons': [
                'Download AnymeX',
              ],
              'metadata': {
                'button_urls': [
                  'https://github.com/RyanYuuki/AnymeX/',
                ],
              }
            }
          ],
          'status': 'online',
          'afk': false,
        },
      });
      _gatewaySocket?.add(presencePayload);
      print('Browsing presence updated successfully (Mobile)');
    } else {
      try {
        await _discordRPC!.setActivity(
          activity: RPCActivity(
            details: activity ?? 'Browsing Stuff',
            state: details ?? 'Idle',
            activityType: ActivityType.playing,
            assets: RPCAssets(
              largeImage: await _processImageUrl(_getAppIconUrl()),
              largeText: 'AnymeX - Anime & Manga',
            ),
          ),
        );
        print('Browsing presence updated successfully');
      } catch (e) {
        print('Error updating browsing presence: $e');
      }
    }
  }

  Future<void> clearPresence() async {
    if (!_isConnected.value || !_canUseDesktopRpc('clearPresence')) {
      print('Discord not connected');
      return;
    }

    if (isMobile) {
      final payload = {
        'op': 3,
        'd': {
          'since': null,
          'activities': [],
          'status': 'online',
          'afk': false,
        },
      };
      _gatewaySocket?.add(jsonEncode(payload));
      print('Presence cleared successfully');
    } else {
      try {
        await _discordRPC!.clearActivity();
        print('Presence cleared successfully');
      } catch (e) {
        print('Error clearing presence: $e');
      }
    }
  }

  String _getAppIconUrl() {
    return 'https://raw.githubusercontent.com/RyanYuuki/AnymeX/main/assets/images/logo.png';
  }

  Future<void> pause() async {
    await clearPresence();
    await _disconnect();
  }

  Future<void> _disconnect() async {
    if (isMobile) {
      _heartbeatTimer?.cancel();
      await _gatewaySocket?.close();
      _gatewaySocket = null;
      _sequenceNumber = null;
    } else {
      await _desktopConnectionSub?.cancel();
      _desktopConnectionSub = null;
      if (_discordRPC != null) {
        try {
          await _discordRPC!.disconnect();
        } catch (e) {
          print('Error disconnecting from Discord RPC: $e');
        }
        _discordRPC = null;
      }
    }
    _isConnected.value = false;
  }

  Future<void> logout() async {
    await clearPresence();
    await _disconnect();

    DiscordKeys.profile.delete();
    DiscordKeys.token.delete();
    _token.value = '';
    profile.value = null;

    snackBar('Logged out from Discord');
  }

  @override
  void onClose() {
    _disconnect();
    super.onClose();
  }
}
