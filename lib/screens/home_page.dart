import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/history/tap_history_cards.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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

    final historyData = Get.find<OfflineStorageController>()
        .animeLibrary
        .where((e) => e.currentEpisode?.currentTrack != null)
        .toList();

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
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                "Continue Watching (Literally)",
                                style: TextStyle(
                                  fontFamily: "Poppins-SemiBold",
                                  fontSize: 17,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            10.height(),
                            SizedBox(
                              height: 228,
                              child: GridView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                scrollDirection: Axis.horizontal,
                                itemCount: historyData.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 1,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 0,
                                        mainAxisExtent: 300),
                                itemBuilder: (context, i) {
                                  final historyModel =
                                      HistoryModel.fromOfflineMedia(
                                          historyData[i], ItemType.anime);
                                  return UnifiedHistoryCardV3(
                                      media: historyModel);
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      10.height(),
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

class UnifiedHistoryCardV3 extends StatelessWidget {
  final HistoryModel media;

  const UnifiedHistoryCardV3({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnymexCard(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12.multiplyRadius()),
      ),
      color: colorScheme.surfaceContainer.withValues(alpha: 0.4),
      child: AnymexOnTap(
        onTap: media.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.multiplyRadius()),
                      topRight: Radius.circular(12.multiplyRadius()),
                    ),
                    child: AnymeXImage(
                      imageUrl:
                          media.cover.isEmpty ? media.poster : media.cover,
                      width: double.infinity,
                      radius: 0,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.multiplyRadius()),
                        topRight: Radius.circular(12.multiplyRadius()),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timelapse_rounded,
                            size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        AnymexText(
                          text: media.date ?? '',
                          size: 10,
                          variant: TextVariant.bold,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: AnymexText(
                          text: media.formattedEpisodeTitle ?? '',
                          size: 11,
                          maxLines: 1,
                          variant: TextVariant.bold,
                          color: colorScheme.onPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    year2023: false,
                    value: media.calculatedProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    color: colorScheme.primary,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexText(
                          text: media.progressTitle ?? media.title!,
                          size: 13,
                          maxLines: 1,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (media.title != null &&
                            media.title != media.progressTitle)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: AnymexText(
                              text: media.title!,
                              size: 11,
                              maxLines: 1,
                              variant: TextVariant.regular,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AnymexText(
                      text: media.progressText!,
                      size: 11,
                      color: colorScheme.primary,
                      variant: TextVariant.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
