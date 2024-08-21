import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';

class LoginInfo {
  static final Box<List<String>> hiveLoginData = Hive.box('login-data');

  static List<String> getLoginData() {
    final List<String>? data = hiveLoginData.get('userInfo');
    if (data != null) {
      return data;
    } else {
      return ['Guest', 'Guest'];
    }
  }

  static void updateLoginData(List<String> newData) {
    hiveLoginData.put('userInfo', newData);
    log('Login data updated: $newData');
  }

  static void clearLoginData() {
    hiveLoginData.delete('userInfo');
    log('Login data cleared.');
  }
}
