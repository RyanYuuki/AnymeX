// discord_rpc_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uriel/database/preferences.dart';
import 'package:uriel/model/episode.dart';
import 'package:uriel/model/media.dart';
import 'package:uriel/widgets/uriel_widgets/uriel_snack_bar.dart';

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
  static const String _applicationId = '1476273710183743650';
  static const String _gatewayUrl =
      'wss://gateway.discord.gg/?v=10&encoding=json';
  static const String _apiBaseUrl = 'https://discord.com/api/v10';
  static const String _downloadUrl = 'https://uriel-app.vercel.app';

  WebSocket? _gatewaySocket;
  Timer? _heartbeatTimer;
  int? _heartbeatInterval;
  int? _sequenceNumber;

  final _isConnected = false.obs;
  final _token = ''.obs;
  final Rx<DiscordProfile?> profile = Rx<DiscordProfile?>(null);
  final _isLoading = false.obs;
  final bool _isMobilePlatform = Platform.isAndroid || Platform.isIOS;

  bool get isConnected => _isConnected.value;
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
      if (profile.value == null) {
        await fetchUserProfile();
      }
      await connect();
    }
  }

  Future<void> _loadToken() async {
    _token.value = await DiscordKeys.token.get('');
  }

  Future<void> _saveToken(String token) async {
    final normalizedToken = _sanitizeToken(token);
    await DiscordKeys.token.set(normalizedToken);
    _token.value = normalizedToken;
  }

  Future<void> _loadProfile() async {
    final profileJson = await DiscordKeys.profile.get<String?>(null);
    if (profileJson != null) {
      try {
        profile.value = DiscordProfile.fromJson(jsonDecode(profileJson));
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> _saveProfile(DiscordProfile userProfile) async {
    await DiscordKeys.profile.set<String>(jsonEncode(userProfile.toJson()));
    profile.value = userProfile;
  }

  String _sanitizeToken(String token) {
    final trimmed = token.trim().replaceAll('"', '');
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  Map<String, dynamic> _buildActivityButton(String label) {
    return {
      'buttons': [label],
      'metadata': {
        'button_urls': [_downloadUrl],
      },
    };
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
        Snack.info('Session expired. Please login again.');
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
    if (_token.value.isEmpty) {
      return;
    }
    await connect();
    Snack.info(
      'Successfully logged in as ${profile.value?.displayName ?? "User"}',
    );
  }

  Future<void> connect() async {
    if (!_isMobilePlatform) {
      print('Discord mobile RPC is only available on Android/iOS');
      return;
    }

    if (_isConnected.value) {
      print('Already connected to Discord RPC');
      return;
    }

    if (_token.value.isEmpty) {
      print('No token found. Please login first.');
      return;
    }
    await _connectMobileGateway();
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
      Snack.info('Failed to connect to Discord');
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
          updateBrowsingPresence(activity: 'Browsing Stuff', details: 'Idle');
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
          '\$browser': 'Uriel',
          '\$device': 'Uriel Mobile',
        },
        'presence': {'status': 'online', 'afk': false},
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
    final payload = {'op': 1, 'd': _sequenceNumber};
    _gatewaySocket?.add(jsonEncode(payload));
  }

  Future<String> _processImageUrl(String? url) async {
    try {
      final processedUrl = await urlToDcAsset(url ?? _getAppIconUrl());
      print('Processed image URL: $processedUrl');
      return processedUrl;
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
          "urls": [url],
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

  Future<void> updateAnimePresence({
    required Media anime,
    required Episode episode,
    required String totalEpisodes,
  }) async {
    if (!_isConnected.value) {
      print('Discord not connected');
      return;
    }

    final currentSeconds = Duration(
      milliseconds: episode.watchedDuration ?? 0,
    ).inSeconds;
    final totalSeconds = Duration(
      milliseconds: episode.totalDuration ?? 0,
    ).inSeconds;
    final startTime = DateTime.now().subtract(
      Duration(seconds: currentSeconds),
    );
    final endTime = DateTime.now().add(
      Duration(seconds: totalSeconds - currentSeconds),
    );
    final episodeNumber = episode.episodeNumber.toString();
    final episodeName = episode.title ?? 'Episode $episodeNumber';
    final coverUrl = anime.cover ?? anime.poster;
    final animeTitle = anime.title;

    final presencePayload = jsonEncode({
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': _applicationId,
            'name': 'Uriel',
            'type': 3,
            'details': animeTitle,
            'state':
                'Episode $episodeNumber ${!episodeName.toLowerCase().contains('episode') ? '- $episodeName' : ''}',
            'timestamps': {
              'start': startTime.millisecondsSinceEpoch,
              'end': endTime.millisecondsSinceEpoch,
            },
            'assets': {
              'large_image': await _processImageUrl(coverUrl),
              'large_text': animeTitle,
              'small_image': await _processImageUrl(_getAppIconUrl()),
              'small_text': 'Uriel',
            },
            ..._buildActivityButton('Watch on Uriel'),
          },
        ],
        'status': 'online',
        'afk': false,
      },
    });
    _gatewaySocket?.add(presencePayload);
    print('Anime presence updated successfully (Mobile)');
  }

  Future<void> updateAnimePresencePaused({
    required Media anime,
    required Episode episode,
    required String totalEpisodes,
  }) async {
    if (!_isConnected.value) {
      print('Discord not connected');
      return;
    }

    final episodeNumber = episode.episodeNumber.toString();
    final coverUrl = anime.cover ?? anime.poster;
    final animeTitle = anime.title;

    final currentSeconds = Duration(
      milliseconds: episode.episodeNumber ?? 0,
    ).inSeconds;
    final totalSeconds = Duration(
      milliseconds: episode.totalDuration ?? 0,
    ).inSeconds;
    final timeDisplay = (currentSeconds > 0 && totalSeconds > 0)
        ? ' • ${_formatDuration(Duration(seconds: currentSeconds))} / ${_formatDuration(Duration(seconds: totalSeconds))}'
        : '';

    final presencePayload = jsonEncode({
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': _applicationId,
            'name': 'Uriel',
            'type': 3,
            'details': animeTitle,
            'state': 'Episode $episodeNumber$timeDisplay (Paused)',
            'assets': {
              'large_image': await _processImageUrl(coverUrl),
              'large_text': animeTitle,
              'small_image': await _processImageUrl(_getAppIconUrl()),
              'small_text': 'Uriel',
            },
            ..._buildActivityButton('Watch on Uriel'),
          },
        ],
        'status': 'online',
        'afk': false,
      },
    });
    _gatewaySocket?.add(presencePayload);
    print('Paused anime presence updated successfully (Mobile)');
  }

  Future<void> updateMediaPresence({required Media media}) async {
    if (!_isConnected.value) {
      print('Discord not connected');
      return;
    }

    final animeTitle = media.title;
    final type = media.type.name.capitalizeFirst ?? '';

    final presencePayload = jsonEncode({
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': _applicationId,
            'name': 'Uriel',
            'type': 0,
            'details': animeTitle,
            'state': 'Viewing $type',
            'assets': {
              'large_image': await _processImageUrl(
                media.cover ?? media.poster,
              ),
              'large_text': animeTitle,
              'small_image': await _processImageUrl(_getAppIconUrl()),
              'small_text': 'Uriel',
            },
            ..._buildActivityButton('Watch on Uriel'),
          },
        ],
        'status': 'online',
        'afk': false,
      },
    });
    _gatewaySocket?.add(presencePayload);
    print('Media presence updated successfully (Mobile)');
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
    if (!_isConnected.value) {
      print('Discord not connected');
      return;
    }

    final presencePayload = jsonEncode({
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': _applicationId,
            'name': 'Uriel',
            'type': 0,
            'details': activity ?? 'Browsing Stuff',
            'state': details ?? 'Idle',
            'assets': {
              'large_image': await _processImageUrl(_getAppIconUrl()),
              'large_text': 'Uriel - Movie, TV, Animes',
            },
            ..._buildActivityButton('Download Uriel'),
          },
        ],
        'status': 'online',
        'afk': false,
      },
    });
    _gatewaySocket?.add(presencePayload);
    print('Browsing presence updated successfully (Mobile)');
  }

  Future<void> clearPresence() async {
    if (!_isConnected.value) {
      print('Discord not connected');
      return;
    }

    final payload = {
      'op': 3,
      'd': {'since': null, 'activities': [], 'status': 'online', 'afk': false},
    };
    _gatewaySocket?.add(jsonEncode(payload));
    print('Presence cleared successfully');
  }

  String _getAppIconUrl() {
    return 'https://raw.githubusercontent.com/Uriel-App/Uriel/main/icon.png';
  }

  Future<void> pause() async {
    await clearPresence();
    await _disconnect();
  }

  Future<void> _disconnect() async {
    _heartbeatTimer?.cancel();
    await _gatewaySocket?.close();
    _gatewaySocket = null;
    _sequenceNumber = null;
    _isConnected.value = false;
  }

  Future<void> logout() async {
    await clearPresence();
    await _disconnect();

    await DiscordKeys.profile.delete();
    await DiscordKeys.token.delete();
    _token.value = '';
    profile.value = null;

    Snack.info('Logged out from Discord');
  }

  @override
  void onClose() {
    _disconnect();
    super.onClose();
  }
}
