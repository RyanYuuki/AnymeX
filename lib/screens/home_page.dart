// ignore_for_file: invalid_use_of_protected_member, deprecated_member_use

import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/history/tap_history_cards.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<Settings>().checkForUpdates(context);
      Get.find<Settings>().showWelcomeDialog(context);
    });
    _scrollController = ScrollController();
  }

  ScrollController get scrollController => _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheController = Get.find<CacheController>();
    final serviceHandler = Get.find<ServiceHandler>();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const appBarHeight = kToolbarHeight + 20;
    final double bottomNavBarHeight = MediaQuery.of(context).padding.bottom;

    bool isMobile =
        getResponsiveValue(context, desktopValue: false, mobileValue: true);

    final TextAlign textAlignment =
        isMobile ? TextAlign.center : TextAlign.left;

    return RefreshIndicator(
      onRefresh: () {
        if (!serviceHandler.isLoggedIn.value) {
          snackBar(
              "W-what are you doing step-bro, login before you do that (●´⌓`●)",
              duration: 1200);
        }
        return serviceHandler.refresh();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: isDesktop ? 10 : statusBarHeight + appBarHeight,
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: AnymexTextSpans(
                        fontSize: 27,
                        spans: [
                          const AnymexTextSpan(
                              text: 'Hey ',
                              size: 30,
                              variant: TextVariant.bold),
                          AnymexTextSpan(
                              text:
                                  '${serviceHandler.isLoggedIn.value ? serviceHandler.profileData.value.name : 'Guest'}',
                              size: 30,
                              color: Theme.of(context).colorScheme.primary,
                              variant: TextVariant.bold),
                          const AnymexTextSpan(
                              text: ', what are we doing today?',
                              size: 30,
                              variant: TextVariant.bold),
                        ],
                        textAlign: textAlignment,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: isMobile
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Find your favourite anime or manga, manhwa or whatever you like!',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .inverseSurface
                                .withOpacity(0.8),
                          ),
                          textAlign: textAlignment,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Obx(() {
                        final children = List<Widget>.from(
                            serviceHandler.homeWidgets(context));
                        final data = cacheController.getStoredAnime();
                        if (data.isNotEmpty && children.length > 2) {
                          children.insert(
                            2,
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      cacheController.getStoredAnime().length,
                                  itemBuilder: (context, i) {
                                    final media =
                                        cacheController.getStoredAnime()[i];
                                    return RecentlyOpenedAnimeCard(
                                        media: media);
                                  },
                                ),
                              ),
                            ),
                          );
                        } else if (data.isNotEmpty) {
                          children.insert(
                            0,
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      cacheController.getStoredAnime().length,
                                  itemBuilder: (context, i) {
                                    final media =
                                        cacheController.getStoredAnime()[i];
                                    return RecentlyOpenedAnimeCard(
                                        media: media);
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(children: children);
                      }),
                    ],
                  ),
                  if (!isDesktop)
                    SizedBox(height: bottomNavBarHeight)
                  else
                    const SizedBox(height: 50),
                ],
              ),
            ),
            if (!isDesktop)
              CustomAnimatedAppBar(
                isVisible: _isAppBarVisibleExternally,
                scrollController: _scrollController,
                headerContent: const Header(type: PageType.home),
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
      ),
    );
  }
}

class ImageButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final String backgroundImage;
  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final double margin;

  const ImageButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    required this.backgroundImage,
    this.width = 160,
    this.height = 60,
    this.borderRadius = 18,
    this.textStyle,
    this.margin = 0,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).brightness == Brightness.dark
        ? [
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.5),
          ]
        : [Colors.transparent, Colors.transparent];
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.symmetric(vertical: margin),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius.multiplyRadius()),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.3),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(borderRadius.multiplyRadius()),
              child: CachedNetworkImage(
                height: height,
                width: width,
                imageUrl: backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          Positioned.fill(
            child: AnymexButton(
              onTap: onPressed,
              padding: EdgeInsets.zero,
              color: Colors.transparent,
              border: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              radius: borderRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText.toUpperCase(),
                    style: textStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    color: Theme.of(context).colorScheme.primary,
                    height: 2,
                    width: 6 * buttonText.length.toDouble(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
