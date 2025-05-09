// ignore_for_file: invalid_use_of_protected_member, unused_local_variable

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeHomePage extends StatelessWidget {
  const AnimeHomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    return Scaffold(
      body: ScrollWrapper(
        children: [
          const Header(),
          const SizedBox(height: 10),
          Obx(() {
            return Column(
              children: serviceHandler.animeWidgets(context),
            );
          }),
          const SizedBox(height: 50)
        ],
      ),
    );
  }
}
