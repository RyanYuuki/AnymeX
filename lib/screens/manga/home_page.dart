// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MangaHomePage extends StatelessWidget {
  const MangaHomePage({
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
              children: serviceHandler.mangaWidgets(context),
            );
          }),
          const SizedBox(height: 50)
        ],
      ),
    );
  }
}
