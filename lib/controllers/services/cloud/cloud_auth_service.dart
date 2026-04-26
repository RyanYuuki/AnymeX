import 'dart:convert';

import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/main.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';

enum CloudMode { guest, uninitialized, cloud }

class CloudAuthService extends GetxController {
  // ──────────────────────────────────────────────────────────
  // Reactive state
  // ──────────────────────────────────────────────────────────

  Rx<CloudMode> cloudMode = CloudMode.uninitialized.obs;
  RxString username = ''.obs;
  RxString email = ''.obs;
  RxString accessToken = ''.obs;
  final refreshToken = ''.obs;
  RxBool isLoggedIn = false.obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxBool isTokenRefreshing = false.obs;

  static const String _kSkippedKey = '__cloud_skipped__';

  // ──────────────────────────────────────────────────────────
  // Token expiry tracking
  // ──────────────────────────────────────────────────────────

  /// Absolute epoch-millis timestamp when the current access token expires.
  int _tokenExpiresAt = 0;

  /// Returns true when the access token has passed its expiry window
  /// (with a 60-second safety buffer so we refresh *before* it truly dies).
  bool _isTokenExpired() {
    final bufferMs = 60 * 1000;
    return accessToken.value.isEmpty ||
        DateTime.now().millisecondsSinceEpoch + bufferMs >= _tokenExpiresAt;
  }

  // ──────────────────────────────────────────────────────────
  // Functions URL — CLOUD_BASE_URL with COMMENTS_BASE_URL fallback
  // ──────────────────────────────────────────────────────────

  String get _functionsUrl {
    final envBase =
        (dotenv.env['CLOUD_BASE_URL'] ?? dotenv.env['COMMENTS_BASE_URL'] ?? '')
            .trim();
    if (envBase.isEmpty) return '';
    final base =
        envBase.endsWith('/') ? envBase.substring(0, envBase.length - 1) : envBase;
    if (base.endsWith('/functions/v1')) return base;
    return '$base/functions/v1';
  }

  // ──────────────────────────────────────────────────────────
  // Auth headers for API calls
  // ──────────────────────────────────────────────────────────

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (accessToken.value.isNotEmpty)
          'Authorization': 'Bearer ${accessToken.value}',
      };

  // ══════════════════════════════════════════════════════════
  // Token management
  // ══════════════════════════════════════════════════════════

  /// Ensures the current access token is valid (not expired / about to expire).
  /// If expired, attempts a single refresh.  Returns `true` when the token is
  /// usable, `false` when it cannot be recovered (caller should force re-login).
  Future<bool> ensureValidToken() async {
    if (accessToken.value.isEmpty) return false;
    if (!_isTokenExpired()) return true;

    // Prevent concurrent refresh storms
    if (isTokenRefreshing.value) {
      // Wait for the in-flight refresh to finish (up to 10 s)
      for (var i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!isTokenRefreshing.value) break;
      }
      // Check if the concurrent refresh succeeded
      return !_isTokenExpired();
    }

    final refreshed = await refreshAuthToken();
    if (!refreshed) {
      Logger.i('Cloud: token unrefreshable, forcing logout');
      logout();
      return false;
    }
    return true;
  }

  /// Wraps any HTTP call with automatic 401-retry logic.
  ///
  /// 1. Makes the request with the current `accessToken`.
  /// 2. If the server returns **401**, attempts to refresh the token once.
  /// 3. On successful refresh, retries the *exact same* request.
  /// 4. Returns `null` on network error or when auth recovery fails.
  Future<http.Response?> authedRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    http.Response response;

    // ── First attempt ──
    try {
      response = await _rawRequest(method, url, headers: headers, body: body);
    } catch (e) {
      Logger.i('Cloud authedRequest network error: $e');
      return null;
    }

    // ── 401 → refresh → retry ──
    if (response.statusCode == 401) {
      Logger.i('Cloud: 401 received, attempting token refresh before retry…');
      final refreshed = await refreshAuthToken();
      if (refreshed) {
        try {
          response =
              await _rawRequest(method, url, headers: headers, body: body);
        } catch (e) {
          Logger.i('Cloud authedRequest retry network error: $e');
          return null;
        }
      } else {
        // Refresh itself failed — session is dead
        logout();
        return null;
      }
    }

    return response;
  }

  /// Low-level request helper that always injects the current Bearer token.
  Future<http.Response> _rawRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final effectiveHeaders = <String, String>{
      if (headers != null) ...headers,
      if (accessToken.value.isNotEmpty)
        'Authorization': 'Bearer ${accessToken.value}',
    };

    final m = method.toUpperCase();
    final uri = Uri.parse(url);

    switch (m) {
      case 'GET':
        return http.get(uri, headers: effectiveHeaders);
      case 'POST':
        return http.post(uri, headers: effectiveHeaders, body: body);
      case 'PUT':
        return http.put(uri, headers: effectiveHeaders, body: body);
      case 'DELETE':
        return http.delete(uri, headers: effectiveHeaders, body: body);
      case 'PATCH':
        return http.patch(uri, headers: effectiveHeaders, body: body);
      default:
        return http.get(uri, headers: effectiveHeaders);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Auth API methods
  // ══════════════════════════════════════════════════════════

  /// POST /auth/register
  ///
  /// Returns `{ success, access_token, refresh_token, expires_in, device_id, user }`.
  Future<bool> register({
    required String username,
    required String password,
    String? email,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _applyAuthResponse(data);
        unskipCloud();
        cloudMode.value = CloudMode.cloud;
        _saveAuth();
        return true;
      } else {
        errorMessage.value = data['error'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      Logger.i('Cloud register error: $e');
      errorMessage.value = 'Network error. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// POST /auth/login
  ///
  /// Returns `{ success, access_token, refresh_token, expires_in, device_id, user }`.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _applyAuthResponse(data);
        unskipCloud();
        cloudMode.value = CloudMode.cloud;
        _saveAuth();
        return true;
      } else {
        errorMessage.value = data['error'] ?? 'Login failed';
        return false;
      }
    } catch (e) {
      Logger.i('Cloud login error: $e');
      errorMessage.value = 'Network error. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// POST /auth/refresh
  ///
  /// Sends `{ refresh_token }` in the **body** (no Authorization header).
  /// Returns `{ success, access_token, refresh_token, expires_in }`.
  Future<bool> refreshAuthToken() async {
    if (refreshToken.value.isEmpty) return false;

    isTokenRefreshing.value = true;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        // refresh_token goes in the body — NOT in the Authorization header
        body: jsonEncode({'refresh_token': refreshToken.value}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        accessToken.value = data['access_token']?.toString() ?? '';
        // Server may rotate the refresh token on each refresh
        refreshToken.value =
            data['refresh_token']?.toString() ?? refreshToken.value;
        final expiresIn = data['expires_in'] as int? ?? 900;
        _tokenExpiresAt =
            DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
        _saveAuth();
        Logger.i(
            'Cloud: token refreshed successfully, expires in ${expiresIn}s');
        return true;
      }

      // Refresh token itself is dead — cannot recover without re-login
      Logger.i(
          'Cloud: token refresh failed (status ${response.statusCode})');
      return false;
    } catch (e) {
      Logger.i('Cloud token refresh error: $e');
      return false;
    } finally {
      isTokenRefreshing.value = false;
    }
  }

  /// POST /auth/change-password
  ///
  /// Sends `{ current_password, new_password }`.
  /// Returns `{ success, access_token, refresh_token, expires_in, message }`.
  /// Server issues new tokens so the session stays valid.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isLoggedIn.value) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/change-password'),
        headers: authHeaders,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Server rotates tokens on password change
        accessToken.value =
            data['access_token']?.toString() ?? accessToken.value;
        refreshToken.value =
            data['refresh_token']?.toString() ?? refreshToken.value;
        final expiresIn = data['expires_in'] as int? ?? 900;
        _tokenExpiresAt =
            DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
        _saveAuth();
        return true;
      } else {
        errorMessage.value = data['error'] ?? 'Password change failed';
        return false;
      }
    } catch (e) {
      Logger.i('Cloud change password error: $e');
      errorMessage.value = 'Network error';
      return false;
    }
  }

  /// POST /auth/delete-account
  ///
  /// Sends `{ password }`.  On success the local session is cleared.
  Future<bool> deleteAccount({required String password}) async {
    if (!isLoggedIn.value) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/delete-account'),
        headers: authHeaders,
        body: jsonEncode({'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        logout();
        return true;
      } else {
        errorMessage.value = data['error'] ?? 'Account deletion failed';
        return false;
      }
    } catch (e) {
      Logger.i('Cloud delete account error: $e');
      errorMessage.value = 'Network error';
      return false;
    }
  }

  /// POST /auth/logout-all
  ///
  /// Revokes ALL active sessions for this user (except current if desired).
  /// Returns `true` on success.
  Future<bool> logoutAllDevices() async {
    if (!isLoggedIn.value) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/logout-all'),
        headers: authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        errorMessage.value = data['error'] ?? 'Failed to logout other devices';
        return false;
      }
    } catch (e) {
      Logger.i('Cloud logout-all error: $e');
      errorMessage.value = 'Network error';
      return false;
    }
  }

  /// GET /auth/sessions
  ///
  /// Returns a list of active sessions for the current user.
  /// Each session includes: `device_id`, `device_name`, `device_type`,
  /// `ip_address`, `user_agent`, `created_at`, `last_active_at`, `is_current`.
  Future<List<Map<String, dynamic>>?> getSessions() async {
    if (!isLoggedIn.value) return null;

    try {
      final response = await http.get(
        Uri.parse('$_functionsUrl/auth/sessions'),
        headers: authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      }
      return null;
    } catch (e) {
      Logger.i('Cloud get sessions error: $e');
      return null;
    }
  }

  /// POST /auth/forgot-password
  ///
  /// Sends `{ email }`. Always returns true (prevents email enumeration).
  Future<bool> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Cloud forgot password error: $e');
      return false;
    }
  }

  /// POST /auth/reset-password
  ///
  /// Sends `{ token, new_password }`.
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Cloud reset password error: $e');
      return false;
    }
  }

  /// POST /auth/logout  (revoke a specific device/session)
  ///
  /// Sends `{ device_id }` to revoke a specific session.
  Future<bool> logoutDevice(String deviceId) async {
    if (!isLoggedIn.value) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/logout'),
        headers: authHeaders,
        body: jsonEncode({'device_id': deviceId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Cloud logout device error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // Session management
  // ══════════════════════════════════════════════════════════

  /// Wipes all auth state and persisted credentials.
  void logout() {
    accessToken.value = '';
    refreshToken.value = '';
    username.value = '';
    email.value = '';
    _tokenExpiresAt = 0;
    isLoggedIn.value = false;
    cloudMode.value = CloudMode.guest;
    skipCloud();
    _clearAuth();
  }

  // ══════════════════════════════════════════════════════════
  // Internal helpers
  // ══════════════════════════════════════════════════════════

  /// Extracts token + user fields from a successful login / register payload
  /// and applies them to the reactive state.
  void _applyAuthResponse(Map<String, dynamic> data) {
    accessToken.value = data['access_token']?.toString() ?? '';
    refreshToken.value = data['refresh_token']?.toString() ?? '';
    final expiresIn = data['expires_in'] as int? ?? 900;
    _tokenExpiresAt =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    final user = data['user'];
    if (user is Map<String, dynamic>) {
      username.value = user['username']?.toString() ?? '';
      email.value = user['email']?.toString() ?? '';
    }

    isLoggedIn.value = accessToken.value.isNotEmpty;
  }

  /// Persists the current auth state to Isar (key-value store).
  ///
  /// Stored keys: `access_token`, `refresh_token`, `token_expires_at`,
  /// `username`, `email`.  **No password** is ever stored.
  void _saveAuth() {
    try {
      final inner = jsonEncode({
        'access_token': accessToken.value,
        'refresh_token': refreshToken.value,
        'token_expires_at': _tokenExpiresAt,
        'username': username.value,
        'email': email.value,
      });
      final kvJson = jsonEncode({'val': inner});
      _writeGlobalKV('__cloud_auth__', kvJson);
    } catch (e) {
      Logger.i('Error saving cloud auth: $e');
    }
  }

  /// Restores auth state from Isar on startup.
  ///
  /// Supports graceful migration from the old schema where the access token
  /// was stored under the key `token` and `token_expires_at` was absent.
  void _loadAuth() {
    try {
      final col = isar.collection<KeyValue>();
      final result =
          col.filter().keyEqualTo('__cloud_auth__').findFirstSync();
      if (result?.value == null) return;

      final raw = jsonDecode(result!.value!);
      final inner = (raw['val'] ?? raw) as dynamic;
      final data = inner is String
          ? jsonDecode(inner) as Map<String, dynamic>
          : inner as Map<String, dynamic>;

      // Migrate old `token` key → `access_token`
      accessToken.value = (data['access_token'] as String?) ??
          (data['token'] as String?) ??
          '';
      refreshToken.value = data['refresh_token'] as String? ?? '';
      _tokenExpiresAt = data['token_expires_at'] as int? ?? 0;
      username.value = data['username'] as String? ?? '';
      email.value = data['email'] as String? ?? '';

      // Ignore any legacy `password` / `cloudPassword` — we never store it

      isLoggedIn.value = accessToken.value.isNotEmpty;
    } catch (e) {
      Logger.i('Error loading cloud auth: $e');
    }
  }

  /// Deletes the persisted auth record from Isar.
  void _clearAuth() {
    try {
      final col = isar.collection<KeyValue>();
      final result =
          col.filter().keyEqualTo('__cloud_auth__').findFirstSync();
      if (result != null) {
        isar.writeTxnSync(() => col.deleteSync(result.id));
      }
    } catch (e) {
      Logger.i('Error clearing cloud auth: $e');
    }
  }

  /// Low-level Isar key-value write.
  void _writeGlobalKV(String key, String value) {
    try {
      final kv = KeyValue()..key = key..value = value;
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error writing global KV $key: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // Controller lifecycle
  // ══════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    _loadAuth();
    _loadCloudMode();
    _initTokenCheck();
  }

  /// After loading persisted auth, verify the token hasn't expired.
  /// If it has, attempt a silent refresh.  If the refresh fails, force logout.
  Future<void> _initTokenCheck() async {
    if (!isLoggedIn.value || accessToken.value.isEmpty) return;

    if (_isTokenExpired()) {
      Logger.i('Cloud: saved token expired on startup, attempting auto-refresh…');
      final refreshed = await refreshAuthToken();
      if (!refreshed) {
        Logger.i('Cloud: auto-refresh on startup failed, logging out');
        logout();
      } else {
        Logger.i('Cloud: auto-refresh on startup succeeded');
      }
    } else {
      Logger.i('Cloud: saved token still valid');
    }
  }

  /// Determines the initial [CloudMode] from persisted preferences.
  void _loadCloudMode() {
    final skipped = ProfileManager.readGlobal(_kSkippedKey);
    if (skipped == 'true') {
      cloudMode.value = CloudMode.guest;
    } else if (isLoggedIn.value) {
      cloudMode.value = CloudMode.cloud;
    } else {
      cloudMode.value = CloudMode.uninitialized;
    }
  }

  // ══════════════════════════════════════════════════════════
  // Guest / skip mode
  // ══════════════════════════════════════════════════════════

  /// Marks the cloud onboarding as permanently skipped until the user
  /// explicitly logs in or resets the preference.
  void skipCloud() {
    ProfileManager.writeGlobal(_kSkippedKey, 'true');
    cloudMode.value = CloudMode.guest;
  }

  /// Clears the skip flag so cloud mode can activate on next login.
  void unskipCloud() {
    ProfileManager.writeGlobal(_kSkippedKey, 'false');
  }

  // ══════════════════════════════════════════════════════════
  // Convenience getters
  // ══════════════════════════════════════════════════════════

  bool get isGuestMode => cloudMode.value == CloudMode.guest;
  bool get isCloudMode => cloudMode.value == CloudMode.cloud;
}
