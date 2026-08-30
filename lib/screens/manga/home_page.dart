// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/common/installed_extensions_gridview.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';

import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/utils/function.dart';

class MangaHomePage extends StatefulWidget {
  const MangaHomePage({
    super.key,
  });

  @override
  State<MangaHomePage> createState() => _MangaHomePageState();
}

class _MangaHomePageState extends State<MangaHomePage> {
  late ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final sourceController = Get.find<SourceController>();
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
                  if (serviceHandler.serviceType.value ==
                      ServicesType.extensions) {
                    return InstalledExtensionsGridView(
                      sources: sourceController.installedMangaExtensions.value,
                      itemType: ItemType.manga,
                    );
                  }
                  return Column(
                    children: serviceHandler.mangaWidgets(context),
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
              title: serviceHandler.serviceType.value == ServicesType.simkl
                  ? 'Series'
                  : 'Manga',
              subtitleWidget: const HeaderGreetingSubtitle(),
              actions: [
                HeaderActionButton(
                  icon: IconlyLight.search,
                  onTap: () {
                    if (serviceHandler.serviceType.value ==
                        ServicesType.extensions) {
                      navigateWithAnimation(() => const SourceSearchPage(
                            initialTerm: '',
                            type: ItemType.manga,
                          ));
                    } else {
                      final hasNovelExts = Get.find<SourceController>()
                          .installedNovelExtensions
                          .isNotEmpty;
                      if (hasNovelExts) {
                        searchTypeSheet(context);
                      } else {
                        navigate(() =>
                            const SearchPage(searchTerm: '', isManga: true));
                      }
                    }
                  },
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
