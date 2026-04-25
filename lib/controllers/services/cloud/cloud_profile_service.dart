import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class CloudProfileService extends GetxController {
  CloudAuthService get _auth => Get.find<CloudAuthService>();

  String get _baseUrl {
    final envBase = (dotenv.env['COMMENTS_BASE_URL'] ?? '').trim();
    if (envBase.isEmpty) return '';
    return envBase.endsWith('/')
        ? envBase.substring(0, envBase.length - 1)
        : envBase;
  }

  String get _functionsUrl => '$_baseUrl/functions/v1';

  Future<List<Map<String, dynamic>>?> listProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('$_functionsUrl/${_auth.username.value}/profiles'),
        headers: _auth.authHeaders,
      );

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

  Future<Map<String, dynamic>?> createProfile({
    required String localProfileId,
    required String displayName,
    String? avatarUrl,
    String? pinHash,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/${_auth.username.value}/profiles'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'local_profile_id': localProfileId,
          'display_name': displayName,
          'avatar_url': avatarUrl,
          'pin_hash': pinHash,
        }),
      );

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

      final response = await http.put(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/profiles/$profileId'),
        headers: _auth.authHeaders,
        body: jsonEncode(body),
      );

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

  Future<bool> deleteProfile(String profileId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/profiles/$profileId'),
        headers: _auth.authHeaders,
      );

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

  Future<bool> setPin(String profileId, String pinHash) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/profiles/$profileId/pin'),
        headers: _auth.authHeaders,
        body: jsonEncode({'pin': pinHash}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Set pin error: $e');
      return false;
    }
  }

  Future<bool> removePin(String profileId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/profiles/$profileId/pin'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Remove pin error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyPin(
      String profileId, String pin) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/profiles/$profileId/verify-pin'),
        headers: _auth.authHeaders,
        body: jsonEncode({'pin': pin}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'valid': data['valid'],
          if (data.containsKey('remaining_attempts'))
            'remaining_attempts': data['remaining_attempts'],
          if (data.containsKey('locked')) 'locked': data['locked'],
        };
      }
      return null;
    } catch (e) {
      Logger.i('Verify pin error: $e');
      return null;
    }
  }

  Future<String?> uploadAvatar(String profileId, File imageFile) async {
    try {
      final ext = p.extension(imageFile.path).toLowerCase();
      final fileName = '$profileId$ext';

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/sync/$profileId/avatar'),
      );
      request.headers['Authorization'] = 'Bearer ${_auth.token.value}';
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path,
            filename: fileName),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
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

  Future<bool> deleteAvatar(String profileId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/sync/$profileId/avatar'),
        headers: _auth.authHeaders,
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Delete avatar error: $e');
      return false;
    }
  }

  Future<bool> reorderProfiles(List<String> profileIds) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/profiles/reorder'),
        headers: _auth.authHeaders,
        body: jsonEncode({'profile_ids': profileIds}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Reorder profiles error: $e');
      return false;
    }
  }

  Future<bool> updateLastUsed(String profileId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$_functionsUrl/${_auth.username.value}/profiles/$profileId/last-used'),
        headers: _auth.authHeaders,
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.i('Update last used error: $e');
      return false;
    }
  }
}
