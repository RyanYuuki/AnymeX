import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CloudProfileService extends GetxController {
  CloudAuthService get _auth => Get.find<CloudAuthService>();

  String get _functionsUrl {
    final envBase = (dotenv.env['CLOUD_BASE_URL'] ??
            dotenv.env['COMMENTS_BASE_URL'] ??
            '')
        .trim();
    if (envBase.isEmpty) return '';
    final base =
        envBase.endsWith('/') ? envBase.substring(0, envBase.length - 1) : envBase;
    if (base.endsWith('/functions/v1')) return base;
    return '$base/functions/v1';
  }

  /// Returns true when [url] is a remote URL (http/https), false for local
  /// file paths like /data/user/... or file:// URIs.
  bool _isRemoteUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  /// Sends a request with automatic 401 retry using token refresh.
  /// Returns the response after potentially refreshing the token once.
  /// Returns null if the token is unavailable or refresh fails.
  Future<http.Response?> _sendWithAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) requestFn,
  ) async {
    if (_auth.accessToken.value.isEmpty) {
      Logger.i('CloudProfileService: no auth token available');
      return null;
    }

    var response = await requestFn(_auth.authHeaders);

    if (response.statusCode == 401) {
      Logger.i('CloudProfileService: 401 received, attempting token refresh');
      final refreshed = await _auth.refreshAuthToken();
      if (!refreshed) {
        Logger.i('CloudProfileService: token refresh failed');
        return null;
      }
      response = await requestFn(_auth.authHeaders);
    }

    return response;
  }

  /// Same as [_sendWithAuthRetry] but for MultipartRequests.
  Future<http.Response?> _sendMultipartWithAuthRetry(
    Future<http.StreamedResponse> Function(
        Map<String, String> headers) requestFn,
  ) async {
    if (_auth.accessToken.value.isEmpty) {
      Logger.i('CloudProfileService: no auth token available');
      return null;
    }

    var streamed = await requestFn(_auth.authHeaders);
    var response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      Logger.i('CloudProfileService: 401 received, attempting token refresh');
      final refreshed = await _auth.refreshAuthToken();
      if (!refreshed) {
        Logger.i('CloudProfileService: token refresh failed');
        return null;
      }
      streamed = await requestFn(_auth.authHeaders);
      response = await http.Response.fromStream(streamed);
    }

    return response;
  }

  // ---------------------------------------------------------------------------
  // Profiles CRUD
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>?> listProfiles() async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.get(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles'),
            headers: headers,
          ));

      if (response == null) return null;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['profiles'] ?? []);
      }
      Logger.i('List profiles error: ${data['error']}');
      return null;
    } catch (e) {
      Logger.i('List profiles error: $e');
      return null;
    }
  }

  /// Creates a cloud profile.
  ///
  /// [pin] is the raw 4-6 digit PIN string — the server hashes it with
  /// PBKDF2 (600k iterations). Do NOT pass a pre-hashed value.
  ///
  /// [avatarUrl] will only be included in the request body when it is a
  /// remote URL (http/https). Local file paths are silently ignored — use
  /// [uploadAvatar] after creation instead.
  Future<Map<String, dynamic>?> createProfile({
    required String localProfileId,
    required String displayName,
    String? avatarUrl,
    String? pin,
  }) async {
    try {
      final body = <String, dynamic>{
        'local_profile_id': localProfileId,
        'display_name': displayName,
      };

      // Only include avatar_url if it is a remote URL, not a local path.
      if (_isRemoteUrl(avatarUrl)) {
        body['avatar_url'] = avatarUrl;
      }

      // Send the raw PIN — server handles hashing.
      if (pin != null && pin.isNotEmpty) {
        body['pin'] = pin;
      }

      final response = await _sendWithAuthRetry((headers) => http.post(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles'),
            headers: headers,
            body: jsonEncode(body),
          ));

      if (response == null) return null;

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return Map<String, dynamic>.from(data['profile']);
      }
      Logger.i('Create profile error: ${data['error']}');
      return null;
    } catch (e) {
      Logger.i('Create profile error: $e');
      return null;
    }
  }

  /// Updates a cloud profile. [profileId] must be the cloud UUID returned by
  /// the server (NOT the local profile ID).
  Future<bool> updateProfile({
    required String profileId,
    String? displayName,
    String? avatarUrl,
    bool? anilistLinked,
    bool? malLinked,
    bool? simklLinked,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      if (anilistLinked != null) body['anilist_linked'] = anilistLinked;
      if (malLinked != null) body['mal_linked'] = malLinked;
      if (simklLinked != null) body['simkl_linked'] = simklLinked;

      final response = await _sendWithAuthRetry((headers) => http.put(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles/$profileId'),
            headers: headers,
            body: jsonEncode(body),
          ));

      if (response == null) return false;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      }
      Logger.i('Update profile error: ${data['error']}');
      return false;
    } catch (e) {
      Logger.i('Update profile error: $e');
      return false;
    }
  }

  /// Deletes a cloud profile. [profileId] must be the cloud UUID.
  Future<bool> deleteProfile(String profileId) async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.delete(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles/$profileId'),
            headers: headers,
          ));

      if (response == null) return false;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      }
      Logger.i('Delete profile error: ${data['error']}');
      return false;
    } catch (e) {
      Logger.i('Delete profile error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PIN management
  // ---------------------------------------------------------------------------

  /// Sets or replaces the PIN for a profile.
  ///
  /// [pin] is the raw 4-6 digit PIN string — the server hashes it with
  /// PBKDF2 (600k iterations). [profileId] must be the cloud UUID.
  Future<bool> setPin(String profileId, String pin) async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.put(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles/$profileId/pin'),
            headers: headers,
            body: jsonEncode({'pin': pin}),
          ));

      if (response == null) return false;

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Set pin error: $e');
      return false;
    }
  }

  /// Removes the PIN from a profile. [profileId] must be the cloud UUID.
  Future<bool> removePin(String profileId) async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.delete(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles/$profileId/pin'),
            headers: headers,
          ));

      if (response == null) return false;

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Remove pin error: $e');
      return false;
    }
  }

  /// Verifies a PIN for a locked profile.
  ///
  /// [pin] is the raw PIN string. [profileId] must be the cloud UUID.
  ///
  /// Returns a map with:
  /// - `valid` (bool): whether the PIN is correct
  /// - `remaining_attempts` (int?): remaining attempts before lockout
  /// - `locked` (bool?): whether the profile is currently locked
  /// - `locked_until` (String?): ISO timestamp of lockout expiry
  /// - `remaining_minutes` (double?): minutes remaining in lockout
  /// - `message` (String?): human-readable status message
  ///
  /// Returns null on network/auth failure.
  Future<Map<String, dynamic>?> verifyPin(String profileId, String pin) async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.post(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles/$profileId/verify-pin'),
            headers: headers,
            body: jsonEncode({'pin': pin}),
          ));

      if (response == null) return null;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'valid': data['valid'],
          if (data.containsKey('remaining_attempts'))
            'remaining_attempts': data['remaining_attempts'],
          if (data.containsKey('locked')) 'locked': data['locked'],
          if (data.containsKey('locked_until'))
            'locked_until': data['locked_until'],
          if (data.containsKey('remaining_minutes'))
            'remaining_minutes': data['remaining_minutes'],
          if (data.containsKey('lockout_level'))
            'lockout_level': data['lockout_level'],
          if (data.containsKey('message')) 'message': data['message'],
        };
      }
      Logger.i('Verify pin error: ${data['error']}');
      return null;
    } catch (e) {
      Logger.i('Verify pin error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Avatar management
  // ---------------------------------------------------------------------------

  /// Uploads an avatar image for a profile via multipart form.
  ///
  /// [profileId] must be the cloud UUID. Returns the new [avatar_url] on
  /// success, or null on failure.
  Future<String?> uploadAvatar(String profileId, File imageFile) async {
    try {
      final ext = p.extension(imageFile.path).toLowerCase();
      final fileName = '$profileId$ext';

      final response = await _sendMultipartWithAuthRetry((headers) async {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse(
              '$_functionsUrl/profiles/${_auth.username.value}/sync/$profileId/avatar'),
        );
        // Forward auth and content-type headers (MultipartRequest sets its own
        // content-type with boundary, so we only forward Authorization).
        request.headers['Authorization'] = headers['Authorization'] ?? '';
        request.files.add(
          await http.MultipartFile.fromPath('avatar', imageFile.path,
              filename: fileName),
        );
        return request.send();
      });

      if (response == null) return null;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['avatar_url'] as String?;
      }
      Logger.i('Upload avatar error: ${data['error']}');
      return null;
    } catch (e) {
      Logger.i('Upload avatar error: $e');
      return null;
    }
  }

  /// Deletes the avatar for a profile. [profileId] must be the cloud UUID.
  Future<bool> deleteAvatar(String profileId) async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.delete(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/sync/$profileId/avatar'),
            headers: headers,
          ));

      if (response == null) return false;

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Delete avatar error: $e');
      return false;
    }
  }

  /// Downloads a cloud avatar URL to a local file for caching.
  /// Returns the local file path on success, or the original URL on failure.
  Future<String> downloadAvatarToLocal(String avatarUrl) async {
    if (!_isRemoteUrl(avatarUrl)) return avatarUrl;

    try {
      final appDir = await Directory(
          p.join((await getApplicationDocumentsDirectory()).path, 'profile_avatars'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final ext = p.extension(Uri.parse(avatarUrl).path).toLowerCase();
      final allowedExts = ['.jpg', '.jpeg', '.png', '.webp'];
      final extToUse = allowedExts.contains(ext) ? ext : '.jpg';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$extToUse';
      final localPath = p.join(appDir.path, fileName);

      final response = await http.get(Uri.parse(avatarUrl));
      if (response.statusCode != 200) return avatarUrl;

      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      return localPath;
    } catch (e) {
      Logger.i('Download avatar error: $e');
      return avatarUrl; // Fallback to URL on failure
    }
  }

  // ---------------------------------------------------------------------------
  // Profile ordering & last-used
  // ---------------------------------------------------------------------------

  /// Reorders profiles on the server.
  ///
  /// [profileIds] must be a list of cloud UUIDs in the desired order.
  Future<bool> reorderProfiles(List<String> profileIds) async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.post(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles/reorder'),
            headers: headers,
            body: jsonEncode({'profile_ids': profileIds}),
          ));

      if (response == null) return false;

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Reorder profiles error: $e');
      return false;
    }
  }

  /// Marks a profile as last-used. [profileId] must be the cloud UUID.
  Future<bool> updateLastUsed(String profileId) async {
    try {
      final response = await _sendWithAuthRetry((headers) => http.put(
            Uri.parse(
                '$_functionsUrl/profiles/${_auth.username.value}/profiles/$profileId/last-used'),
            headers: headers,
          ));

      if (response == null) return false;

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Update last used error: $e');
      return false;
    }
  }
}
