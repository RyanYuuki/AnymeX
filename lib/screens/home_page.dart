import 'dart:math' as math;

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/missing_sequel/missing_sequel_service.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/continue_watching_cards.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/history/tap_history_cards.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Widget _buildRecentlyOpenedSection(CacheController cacheController) {
    final data = cacheController.getStoredAnime();
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        height: 100,
        child: RepaintBoundary(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            itemBuilder: (context, i) =>
                RecentlyOpenedAnimeCard(media: data[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueWatchingSection(
      OfflineStorageController offlineStorageController) {
    return StreamBuilder<List<OfflineMedia>>(
      stream: offlineStorageController.watchAnimeLibrary(),
      builder: (context, snapshot) {
        final historyData = (snapshot.data ?? const <OfflineMedia>[])
            .where((e) => e.currentEpisode?.currentTrack != null)
            .toList()
          ..sort((a, b) => (b.currentEpisode?.lastWatchedTime ?? 0)
              .compareTo(a.currentEpisode?.lastWatchedTime ?? 0));
        final visibleHistory = historyData.take(20).toList(growable: false);

        if (visibleHistory.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                "Local History",
                style: TextStyle(
                  fontFamily: "Poppins-SemiBold",
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 228,
              child: RepaintBoundary(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleHistory.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 0,
                    mainAxisExtent: 300,
                  ),
                  itemBuilder: (context, i) => ContinueWatchingCard(
                    media: HistoryModel.fromOfflineMedia(
                        visibleHistory[i], ItemType.anime),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildHomeWidgets({
    required BuildContext context,
    required ServiceHandler serviceHandler,
    required CacheController cacheController,
    required OfflineStorageController offlineStorageController,
    required Settings settings,
  }) {
    final baseWidgets = serviceHandler.homeWidgets(context);
    final hasRecentSection = cacheController.getStoredAnime().isNotEmpty;
    final shouldShowContinueSection = settings.showContinueWatchingCard;

    if (!hasRecentSection && !shouldShowContinueSection) {
      return List<Widget>.from(baseWidgets);
    }
    final localSections = <Widget>[
      const SizedBox(height: 12),
      if (hasRecentSection) _buildRecentlyOpenedSection(cacheController),
      const SizedBox(height: 12),
      if (shouldShowContinueSection)
        _buildContinueWatchingSection(offlineStorageController),
    ];

    int insertionIndex;
    if (serviceHandler.serviceType.value == ServicesType.simkl) {
      insertionIndex = serviceHandler.isLoggedIn.value ? 3 : 2;
    } else if (!serviceHandler.isLoggedIn.value ||
        serviceHandler.serviceType.value == ServicesType.extensions) {
      insertionIndex = 0;
    } else {
      insertionIndex = 2;
    }
    insertionIndex = math.min(insertionIndex, baseWidgets.length);

    return [
      ...baseWidgets.take(insertionIndex),
      ...localSections,
      ...baseWidgets.skip(insertionIndex),
    ];
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDiscordDialog();
    });
  }

  void _showDiscordDialog() {
    if (General.hasJoinedNewDiscord.get(false)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AnymexDialog(
            title: 'Important Announcement',
            showCancelButton: false,
            confirmText: 'Join Discord',
            onConfirm: () async {
              General.hasJoinedNewDiscord.set(true);
              final url = Uri.parse('https://discord.gg/C9abCZjC8K');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            contentWidget: const Text(
              'Our previous Discord server with over 2,100 members was unfortunately taken down due to copyright infringement.\n\n'
              'We are trying to rebuild! Please join our new Discord server to help us gain our wonderful community back. '
              'You must join to continue using the app.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),
          ),
        );
      },
    );
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
    final offlineStorageController = Get.find<OfflineStorageController>();
    final serviceHandler = Get.find<ServiceHandler>();
    final settings = Get.find<Settings>();
    final sourceController = Get.find<SourceController>();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const appBarHeight = kToolbarHeight + 20;
    final double bottomNavBarHeight = MediaQuery.of(context).padding.bottom;

    bool isMobile =
        getResponsiveValue(context, desktopValue: false, mobileValue: true);

    final TextAlign textAlignment =
        isMobile ? TextAlign.center : TextAlign.left;

    final List<dynamic> novelData = [];

    return RefreshIndicator(
      onRefresh: () async {
        if (!serviceHandler.isLoggedIn.value) {
          snackBar(
              "W-what are you doing step-bro, login before you do that (●´⌓`●)",
              duration: 1200);
          return;
        }
        final missingSequelService = Get.find<MissingSequelService>();
        await Future.wait([
          serviceHandler.refresh(),
          missingSequelService.fetchAll(),
        ]);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
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
                              color: context.colors.primary,
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
                        cacheController.currentPool.length;
                        final children = _buildHomeWidgets(
                          context: context,
                          serviceHandler: serviceHandler,
                          cacheController: cacheController,
                          offlineStorageController: offlineStorageController,
                          settings: settings,
                        );
                        return Column(children: children);
                      }),
                      if (novelData.isNotEmpty)
                        ReusableCarousel(
                          title: "Recommended Novels",
                          data: novelData,
                          type: ItemType.novel,
                          source: sourceController.activeNovelSource.value,
                        ),
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
  final VoidCallback? onLongPress;
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
    this.onLongPress,
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
          color: context.colors.inverseSurface.withOpacity(0.3),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(borderRadius.multiplyRadius()),
              child: AnymeXImage(
                height: height,
                width: width,
                imageUrl: backgroundImage,
                fit: BoxFit.cover,
                radius: 0,
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
              onLongPress: onLongPress,
              padding: EdgeInsets.zero,
              color: Colors.transparent,
              border: BorderSide(
                color: context.colors.primary.withOpacity(0.7),
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
                    color: context.colors.primary,
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
