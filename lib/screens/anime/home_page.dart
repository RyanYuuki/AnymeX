// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/widgets/common/installed_extensions_gridview.dart';
import 'package:anymex/widgets/common/lazy_indexed_stack.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:anymex/controllers/media_mode_controller.dart';
import 'package:anymex/widgets/common/media_mode_selector.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/screens/novel/search/search_page.dart';
import 'package:anymex/utils/function.dart';

class AnimeHomePage extends StatefulWidget {
  final ItemType? type;
  const AnimeHomePage({
    super.key,
    this.type,
  });

  @override
  State<AnimeHomePage> createState() => _AnimeHomePageState();
}

class _AnimeHomePageState extends State<AnimeHomePage> {
  late ScrollController _animeScrollController;
  late ScrollController _mangaScrollController;
  late ScrollController _novelScrollController;
  late ScrollController _extensionsScrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _animeScrollController = ScrollController();
    _mangaScrollController = ScrollController();
    _novelScrollController = ScrollController();
    _extensionsScrollController = ScrollController();
  }

  ScrollController _getActiveScrollController(bool isExtensions, int index) {
    if (isExtensions) {
      return _extensionsScrollController;
    }
    switch (index) {
      case 1:
        return _mangaScrollController;
      case 2:
        return _novelScrollController;
      default:
        return _animeScrollController;
    }
  }

  ScrollController get scrollController {
    final serviceHandler = Get.find<ServiceHandler>();
    final mediaModeController = Get.find<MediaModeController>();
    final isExtensions =
        serviceHandler.serviceType.value == ServicesType.extensions;
    final index = widget.type != null
        ? _typeToIndex(widget.type!)
        : _typeToIndex(mediaModeController.mode);
    return _getActiveScrollController(isExtensions, index);
  }

  @override
  void dispose() {
    _animeScrollController.dispose();
    _mangaScrollController.dispose();
    _novelScrollController.dispose();
    _extensionsScrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  int _typeToIndex(ItemType type) {
    switch (type) {
      case ItemType.manga:
        return 1;
      case ItemType.novel:
        return 2;
      default:
        return 0;
    }
  }

  void _openSearch(BuildContext context, ItemType currentType,
      ServiceHandler serviceHandler) {
    if (serviceHandler.serviceType.value == ServicesType.extensions) {
      navigateWithAnimation(() => SourceSearchPage(
            initialTerm: '',
            type: currentType,
          ));
    } else if (currentType == ItemType.manga) {
      final hasNovelExts =
          Get.find<SourceController>().installedNovelExtensions.isNotEmpty;
      if (hasNovelExts) {
        searchTypeSheet(context);
      } else {
        navigate(() => const SearchPage(searchTerm: '', isManga: true));
      }
    } else if (currentType == ItemType.novel) {
      navigate(() => const NovelSearchPage());
    } else {
      navigate(() => const SearchPage(searchTerm: '', isManga: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final mediaModeController = Get.put(MediaModeController());
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final double bottomNavBarHeight =
        isDesktop ? 20.0 : (MediaQuery.paddingOf(context).bottom + 65.0);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Obx(() {
            final isExtensions =
                serviceHandler.serviceType.value == ServicesType.extensions;
            final currentType = widget.type ?? mediaModeController.mode;

            if (isExtensions) {
              final sourceController = Get.find<SourceController>();
              final sources = switch (currentType) {
                ItemType.manga => sourceController.installedMangaExtensions,
                ItemType.novel => sourceController.installedNovelExtensions,
                _ => sourceController.installedExtensions,
              };
              return SingleChildScrollView(
                controller: _extensionsScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: statusBarHeight + appBarHeight),
                    const SizedBox(height: 10),
                    Obx(() => InstalledExtensionsGridView(
                          key: ValueKey(currentType),
                          sources: sources.value,
                          itemType: currentType,
                        )),
                    SizedBox(height: bottomNavBarHeight + 60),
                  ],
                ),
              );
            }

            final index = widget.type != null
                ? _typeToIndex(widget.type!)
                : _typeToIndex(mediaModeController.mode);

            return LazyIndexedStack(
              index: index,
              children: [
                _ContentPage(
                  scrollController: _animeScrollController,
                  statusBarHeight: statusBarHeight,
                  appBarHeight: appBarHeight,
                  bottomNavBarHeight: bottomNavBarHeight,
                  widgetsBuilder: () => serviceHandler.animeWidgets(context),
                ),
                _ContentPage(
                  scrollController: _mangaScrollController,
                  statusBarHeight: statusBarHeight,
                  appBarHeight: appBarHeight,
                  bottomNavBarHeight: bottomNavBarHeight,
                  widgetsBuilder: () => serviceHandler.mangaWidgets(context),
                ),
                _ContentPage(
                  scrollController: _novelScrollController,
                  statusBarHeight: statusBarHeight,
                  appBarHeight: appBarHeight,
                  bottomNavBarHeight: bottomNavBarHeight,
                  widgetsBuilder: () => serviceHandler.novelWidgets(context),
                ),
              ],
            );
          }),
          Obx(() {
            final isExtensions =
                serviceHandler.serviceType.value == ServicesType.extensions;
            final currentType = widget.type ?? mediaModeController.mode;
            final index = widget.type != null
                ? _typeToIndex(widget.type!)
                : _typeToIndex(mediaModeController.mode);
            final activeScrollController =
                _getActiveScrollController(isExtensions, index);

            final String title = currentType == ItemType.novel
                ? 'Novels'
                : (serviceHandler.serviceType.value == ServicesType.simkl
                    ? (currentType == ItemType.anime ? 'Movies' : 'Series')
                    : (currentType == ItemType.anime ? 'Anime' : 'Manga'));

            return CustomAnimatedAppBar(
              isVisible: _isAppBarVisibleExternally,
              scrollController: activeScrollController,
              headerContent: Header(
                title: title,
                subtitleWidget: const HeaderGreetingSubtitle(),
                actions: [
                  HeaderActionButton(
                    icon: IconlyLight.search,
                    onTap: () =>
                        _openSearch(context, currentType, serviceHandler),
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
            );
          })
        ]));
  }
}

class _ContentPage extends StatelessWidget {
  final ScrollController scrollController;
  final double statusBarHeight;
  final double appBarHeight;
  final double bottomNavBarHeight;
  final List<Widget> Function() widgetsBuilder;

  const _ContentPage({
    required this.scrollController,
    required this.statusBarHeight,
    required this.appBarHeight,
    required this.bottomNavBarHeight,
    required this.widgetsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = widgetsBuilder();
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: statusBarHeight + appBarHeight),
          const SizedBox(height: 10),
          ...widgets,
          SizedBox(height: bottomNavBarHeight + 60),
        ],
      ),
    );
  }
}
