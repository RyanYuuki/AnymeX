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
  Rx<CloudMode> cloudMode = CloudMode.uninitialized.obs;

  static const String _kSkippedKey = '__cloud_skipped__';

  String get _baseUrl {
    final envBase = (dotenv.env['COMMENTS_BASE_URL'] ?? '').trim();
    if (envBase.isEmpty) return '';
    return envBase.endsWith('/')
        ? envBase.substring(0, envBase.length - 1)
        : envBase;
  }

  String get _functionsUrl => '$_baseUrl/functions/v1';

  RxString username = ''.obs;
  RxString email = ''.obs;
  RxString token = ''.obs;
  RxBool isLoggedIn = false.obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

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
        token.value = data['token']?.toString() ?? '';
        this.username.value = data['user']?['username']?.toString() ?? '';
        this.email.value = data['user']?['email']?.toString() ?? '';
        isLoggedIn.value = true;
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
        token.value = data['token']?.toString() ?? '';
        this.username.value = data['user']?['username']?.toString() ?? '';
        this.email.value = data['user']?['email']?.toString() ?? '';
        isLoggedIn.value = true;
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

  Future<bool> refreshToken() async {
    if (token.value.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.value}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        token.value = data['token'];
        _saveAuth();
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Cloud token refresh error: $e');
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isLoggedIn.value) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.value}',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          token.value = data['token'];
          _saveAuth();
        }
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

  Future<bool> deleteAccount({required String password}) async {
    if (!isLoggedIn.value) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsUrl/auth/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.value}',
        },
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

  void logout() {
    token.value = '';
    username.value = '';
    email.value = '';
    isLoggedIn.value = false;
    cloudMode.value = CloudMode.guest;
    skipCloud();
    _clearAuth();
  }

  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      if (token.value.isNotEmpty) 'Authorization': 'Bearer ${token.value}',
    };
  }

  void _saveAuth() {
    try {
      final kvData = jsonEncode({
        'token': token.value,
        'username': username.value,
        'email': email.value,
      });
      final kvJson = jsonEncode({'val': kvData});
      _writeGlobalKV('__cloud_auth__', kvJson);
    } catch (e) {
      Logger.i('Error saving cloud auth: $e');
    }
  }

  void _loadAuth() {
    try {
      final col = isar.collection<KeyValue>();
      final result = col.filter().keyEqualTo('__cloud_auth__').findFirstSync();
      if (result?.value == null) return;

      final data = jsonDecode(result!.value!)['val'] as String;
      final inner = jsonDecode(data) as Map<String, dynamic>;
      token.value = inner['token'] as String? ?? '';
      username.value = inner['username'] as String? ?? '';
      email.value = inner['email'] as String? ?? '';
      isLoggedIn.value = token.value.isNotEmpty;
    } catch (e) {
      Logger.i('Error loading cloud auth: $e');
    }
  }

  void _clearAuth() {
    try {
      final col = isar.collection<KeyValue>();
      final result = col.filter().keyEqualTo('__cloud_auth__').findFirstSync();
      if (result != null) {
        isar.writeTxnSync(() => col.deleteSync(result.id));
      }
    } catch (e) {
      Logger.i('Error clearing cloud auth: $e');
    }
  }

  void _writeGlobalKV(String key, String value) {
    try {
      final kv = KeyValue()..key = key..value = value;
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error writing global KV $key: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadAuth();
    _loadCloudMode();
  }

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

  void skipCloud() {
    ProfileManager.writeGlobal(_kSkippedKey, 'true');
    cloudMode.value = CloudMode.guest;
  }

  void unskipCloud() {
    ProfileManager.writeGlobal(_kSkippedKey, 'false');
  }

  bool get isGuestMode => cloudMode.value == CloudMode.guest;

  bool get isCloudMode => cloudMode.value == CloudMode.cloud;
}
