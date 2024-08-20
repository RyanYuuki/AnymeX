import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

class LoginInfo {
  List login_data = [];

  final hiveLoginData = Hive.box('login-data');

  void initData() {
    if(hiveLoginData.get('login-data') == null) {
      login_data = [
        'Guest',
        'Guest',
      ];
    }
  }

  void readData() {
    log(login_data.toString());
  }

  void updateData() {
    hiveLoginData.put('userInfo', login_data);
  }
}