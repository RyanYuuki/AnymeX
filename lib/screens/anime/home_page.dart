// ignore_for_file: invalid_use_of_protected_member, unused_local_variable

import 'package:anymex/widgets/common/animated_app_bar.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeHomePage extends StatefulWidget {
  const AnimeHomePage({
    super.key,
  });

  @override
  State<AnimeHomePage> createState() => _AnimeHomePageState();
}

class _AnimeHomePageState extends State<AnimeHomePage>
    with ScrollAwareAppBarMixin<AnimeHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final double appBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...(!isDesktop
                    ? [
                        SizedBox(
                            height: appBarHeight +
                                MediaQuery.of(context).padding.top),
                        const SizedBox(height: 30),
                      ]
                    : [
                        const SizedBox(height: 30),
                        const Header(),
                      ]),
                Obx(() {
                  return Column(
                    children: serviceHandler.animeWidgets(context),
                  );
                }),
                const SizedBox(height: 50),
              ],
            ),
          ),
          if (!isDesktop)
            AnimatedScrollAppBar(
              isVisible: isAppBarVisible,
              isHomePage: false,
            ),
        ],
      ),
    );
  }
}
