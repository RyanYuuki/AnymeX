import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/widgets/common/installed_extensions_gridview.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:anymex/screens/novel/search/search_page.dart';
import 'package:anymex/utils/function.dart';

class NovelHomePage extends StatefulWidget {
  const NovelHomePage({super.key});

  @override
  State<NovelHomePage> createState() => _NovelHomePageState();
}

class _NovelHomePageState extends State<NovelHomePage> {
  late ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Get.find<SourceController>().initNovelExtensions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final double bottomNavBarHeight =
        isDesktop ? 20.0 : (MediaQuery.paddingOf(context).bottom + 65.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: statusBarHeight + appBarHeight),
                const SizedBox(height: 10),
                Obx(() {
                  final sourceController = Get.find<SourceController>();
                  sourceController.installedNovelExtensions.toList();
                  return InstalledExtensionsGridView(
                    sources: sourceController.installedNovelExtensions,
                    itemType: ItemType.novel,
                  );
                }),
                SizedBox(height: bottomNavBarHeight),
              ],
            ),
          ),
          CustomAnimatedAppBar(
            isVisible: _isAppBarVisibleExternally,
            scrollController: _scrollController,
            headerContent: Header(
              title: 'Novels',
              subtitleWidget: const HeaderGreetingSubtitle(),
              actions: [
                HeaderActionButton(
                  icon: IconlyLight.search,
                  onTap: () => navigate(() => const NovelSearchPage()),
                ),
              ],
            ),
            visibleStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarBrightness: Theme.of(context).brightness,
              statusBarColor: Colors.transparent,
            ),
            hiddenStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.light
                      : Brightness.dark,
              statusBarBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
