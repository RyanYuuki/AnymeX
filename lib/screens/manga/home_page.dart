import 'package:anymex/widgets/common/animated_app_bar.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MangaHomePage extends StatefulWidget {
  const MangaHomePage({
    super.key,
  });

  @override
  State<MangaHomePage> createState() => _MangaHomePageState();
}

class _MangaHomePageState extends State<MangaHomePage>
    with ScrollAwareAppBarMixin<MangaHomePage> {
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
                    children: serviceHandler.mangaWidgets(context),
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
