import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class KitsuAuth extends GetxController {
  static KitsuAuth get instance => Get.find<KitsuAuth>();

  final RxBool isLoggedIn = false.obs;
  final Rx<Profile> profileData = Profile().obs;
  static const String CLIENT_ID = "dd031b32d2f56c990b1425efe6c42ad847e7fe3ab46bf1299f05ecd856bdb7dd";
  static const String CLIENT_SECRET = "54d7307928f63414defd96399fc31ba847961ceaecef3a5fd93144e960c0e151";
  static const String AUTH_URL = "https://kitsu.app/api/oauth/authorize";
  static const String TOKEN_URL = "https://kitsu.app/api/oauth/token";

  Future<void> login() async {
    try {
      final state = _generateRandomString(32);
      
      final authUrl = Uri.parse(AUTH_URL).replace(queryParameters: {
        'client_id': CLIENT_ID,
        'redirect_uri': '${dotenv.env['CALLBACK_SCHEME']}://callback',
        'response_type': 'code',
        'state': state,
      }).toString();

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: dotenv.env['CALLBACK_SCHEME']!.replaceAll('://', ''),
      );

      final callbackUri = Uri.parse(result);
      final code = callbackUri.queryParameters['code'];
      final returnedState = callbackUri.queryParameters['state'];

      if (code == null) {
        throw Exception('No authorization code received');
      }

      if (returnedState != state) {
        throw Exception('State mismatch - possible CSRF attack');
      }
      
      await _exchangeCodeForToken(code);
    } catch (e, stack) {
      Logger.i('Kitsu login error: $e\n$stack');
      snackBar('Failed to login to Kitsu: $e');
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(TOKEN_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': '${dotenv.env['CALLBACK_SCHEME']}://callback',
          'client_id': CLIENT_ID,
          'client_secret': CLIENT_SECRET,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final createdAt = data['created_at'];
        final expiresIn = data['expires_in'];
        
        AuthKeys.kitsuAuthToken.set(accessToken);
        AuthKeys.kitsuRefreshToken.set(refreshToken);
        AuthKeys.kitsuTokenCreatedAt.set(createdAt.toString());
        AuthKeys.kitsuTokenExpiresIn.set(expiresIn.toString());

        isLoggedIn.value = true;
        await fetchUserProfile();
        snackBar('Successfully logged in to Kitsu!');
      } else {
        throw Exception('Failed to exchange code: ${response.body}');
      }
    } catch (e) {
      Logger.i('Token exchange error: $e');
      rethrow;
    }
  }

  Future<void> refreshToken() async {
    final refreshToken = AuthKeys.kitsuRefreshToken.get<String?>();
    if (refreshToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(TOKEN_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': CLIENT_ID,
          'client_secret': CLIENT_SECRET,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];
        final createdAt = data['created_at'];
        final expiresIn = data['expires_in'];

        AuthKeys.kitsuAuthToken.set(accessToken);
        if (newRefreshToken != null) {
          AuthKeys.kitsuRefreshToken.set(newRefreshToken);
        }
        AuthKeys.kitsuTokenCreatedAt.set(createdAt.toString());
        AuthKeys.kitsuTokenExpiresIn.set(expiresIn.toString());

        isLoggedIn.value = true;
      }
    } catch (e) {
      Logger.i('Token refresh error: $e');
      logout();
    }
  }

  Future<void> fetchUserProfile() async {
    final token = AuthKeys.kitsuAuthToken.get<String?>();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://kitsu.app/api/edge/users?filter[self]=true'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.api+json',
          'Content-Type': 'application/vnd.api+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'][0];
        final attributes = userData['attributes'];

        profileData.value = Profile(
          id: userData['id'],
          name: attributes['name'] ?? attributes['slug'] ?? 'Kitsu User',
          avatar: attributes['avatar']?['original'],
        );
      }
    } catch (e) {
      Logger.i('Failed to fetch Kitsu profile: $e');
    }
  }

  Future<bool> isTokenValid() async {
    final token = AuthKeys.kitsuAuthToken.get<String?>();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('https://kitsu.app/api/edge/users?filter[self]=true'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> autoLogin() async {
    final token = AuthKeys.kitsuAuthToken.get<String?>();
    if (token != null) {
      final isValid = await isTokenValid();
      if (isValid) {
        isLoggedIn.value = true;
        await fetchUserProfile();
      } else {
        await refreshToken();
      }
    }
  }

  void logout() {
    AuthKeys.kitsuAuthToken.delete();
    AuthKeys.kitsuRefreshToken.delete();
    AuthKeys.kitsuTokenCreatedAt.delete();
    AuthKeys.kitsuTokenExpiresIn.delete();
    isLoggedIn.value = false;
    profileData.value = Profile();
    snackBar('Logged out from Kitsu');
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random % chars.length)),
    );
  }
}
