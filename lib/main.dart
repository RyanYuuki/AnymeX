import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/firebase_options.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/models/Offline/Hive/offline_storage.dart';
import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/models/ui/ui_adaptor.dart';
import 'package:anymex/screens/anime/home_page.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/my_library.dart';
import 'package:anymex/screens/manga/home_page.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/deeplink.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/register_protocol/register_protocol.dart';
import 'package:anymex/widgets/adaptive_wrapper.dart';
import 'package:anymex/widgets/animation/more_page_transitions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_splash_screen.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/utils/notification_service.dart';
import 'package:anymex/utils/background_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:anymex/controllers/notification/notification_controller.dart';
import 'package:app_links/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar_community/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:window_manager/window_manager.dart';

WebViewEnvironment? webViewEnvironment;
late Isar isar;
final appLinks = AppLinks();

FirebaseAnalytics analytics = FirebaseAnalytics.instance;

class MyHttpoverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, String host, int port) => true;
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus
      };
}

void main(List<String> args) async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Logger.init();
    await dotenv.load(fileName: ".env");

    if (!Platform.isLinux) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (Platform.isWindows) {
      ['dar', 'anymex', 'sugoireads', 'mangayomi']
          .forEach(registerProtocolHandler);
    }
    initDeepLinkListener();
    HttpOverrides.global = MyHttpoverrides();
    await initializeHive();
    _initializeGetxController();
    initializeDateFormatting();
    MediaKit.ensureInitialized();
    await NotificationService.init();
    
    // Initialize Workmanager for background tasks
    if (Platform.isAndroid) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging frequency
      );
      await Workmanager().registerPeriodicTask(
        "fetchEpisodeTask", 
        fetchBackgroundEpisodeTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected, 
        ),
      );
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      await windowManager.ensureInitialized();
      if (Platform.isWindows) {
        await AnymexTitleBar.initialize();
      }
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark));
    }

    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      Logger.e("FLUTTER ERROR: ${details.exceptionAsString()}");
      Logger.e("STACK: ${details.stack}");
    };

    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyAdaptiveWrapper(child: MainApp()),
      ),
    );
  }, (error, stackTrace) async {
    Logger.e("CRASH: $error");
    if (error.toString().contains('PathAccessException: lock failed')) {
      Hive.deleteFromDisk();
      await Hive.initFlutter('AnymeX');
      Hive.deleteFromDisk();
    }
    Logger.e("STACK: $stackTrace");
  }, zoneSpecification: ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      Logger.i(line);
    },
  ));
}

void initDeepLinkListener() async {
  if (Platform.isLinux) return;

  try {
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) Deeplink.handleDeepLink(initialUri);
  } catch (err) {
    errorSnackBar('Error getting initial deep link: $err');
  }

  appLinks.uriLinkStream.listen(
    (uri) => Deeplink.handleDeepLink(uri),
    onError: (err) => errorSnackBar('Error Opening link: $err'),
  );
}

Future<void> initializeHive() async {
  await Hive.initFlutter('AnymeX');
  Hive.registerAdapter(VideoAdapter());
  Hive.registerAdapter(TrackAdapter());
  Hive.registerAdapter(UISettingsAdapter());
  Hive.registerAdapter(PlayerSettingsAdapter());
  Hive.registerAdapter(OfflineStorageAdapter());
  Hive.registerAdapter(OfflineMediaAdapter());
  Hive.registerAdapter(CustomListAdapter());
  Hive.registerAdapter(ChapterAdapter());
  Hive.registerAdapter(EpisodeAdapter());
  await Hive.openBox('themeData');
  await Hive.openBox('loginData');
  await Hive.openBox('auth');
  await Hive.openBox('preferences');
  await Hive.openBox<UISettings>("UiSettings");
  await Hive.openBox<PlayerSettings>("PlayerSettings");
}

void _initializeGetxController() async {
  Get.put(OfflineStorageController());
  Get.put(AnilistAuth());
  Get.put(AnilistData());
  Get.put(SimklService());
  Get.put(MalService());
  Get.put(DiscordRPCController());
  Get.put(SourceController());
  Get.put(Settings());
  Get.put(ServiceHandler());
  Get.put(GreetingController());
  Get.put(CommentumService());
  Get.put(CommentPreloader());
  Get.put(NotificationController());
  Get.lazyPut(() => CacheController());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showMainApp = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMainApp = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) async {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(Get.context!);
          } else if (event.logicalKey == LogicalKeyboardKey.f11) {
            bool isFullScreen = await windowManager.isFullScreen();
            AnymexTitleBar.setFullScreen(!isFullScreen);
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            final isAltPressed = HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.altLeft) ||
                HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.altRight);
            if (isAltPressed) {
              bool isFullScreen = await windowManager.isFullScreen();
              AnymexTitleBar.setFullScreen(!isFullScreen);
            }
          }
        }
      },
      child: GetMaterialApp(
        scrollBehavior: MyCustomScrollBehavior(),
        debugShowCheckedModeBanner: false,
        title: "AnymeX",
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.isSystemMode
            ? ThemeMode.system
            : theme.isLightMode
                ? ThemeMode.light
                : ThemeMode.dark,
        home: _showMainApp ? const FilterScreen() : const AnymeXSplashScreen(),
        builder: (context, child) {
          if (PlatformDispatcher.instance.views.length > 1) {
            return child!;
          }
          final isDesktop = Platform.isWindows;

          if (isDesktop) {
            return Stack(
              children: [
                child!,
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    child: AnymexTitleBar.titleBar(),
                  ),
                ),
              ],
            );
          }
          return child!;
        },
        enableLog: true,
        logWriterCallback: (text, {isError = false}) async {
          Logger.d(text);
        },
      ),
    );
  }
}

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int _selectedIndex = 1;
  int _mobileSelectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Get.find<Settings>();
      settings.checkForUpdates(context);
      settings.showWelcomeDialog(context);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onMobileItemTapped(int index) {
    setState(() {
      _mobileSelectedIndex = index;
    });
  }

  final routes = [
    const SizedBox.shrink(),
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
    const MyLibrary(),
    const ExtensionScreen(disableGlow: true),
  ];

  final mobileRoutes = [
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
    const MyLibrary()
  ];

  @override
  void dispose() {
    Logger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.put(ServiceHandler());
    final isSimkl =
        Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;
    return Glow(
      child: PlatformBuilder(
        strictMode: false,
        desktopBuilder: _buildDesktopLayout(context, authService, isSimkl),
        androidBuilder: _buildAndroidLayout(isSimkl),
      ),
    );
  }

  Scaffold _buildDesktopLayout(
      BuildContext context, ServiceHandler authService, bool isSimkl) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Provider.of<ThemeProvider>(context).isOled
          ? Colors.black
          : Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => SizedBox(
              width: 120,
              child: SuperListView(
                children: [
                  ResponsiveNavBar(
                    isDesktop: true,
                    currentIndex: _selectedIndex,
                    margin: const EdgeInsets.fromLTRB(20, 30, 15, 10),
                    items: [
                      NavItem(
                          unselectedIcon: IconlyBold.profile,
                          selectedIcon: IconlyBold.profile,
                          onTap: (index) {
                            return SettingsSheet.show(context);
                          },
                          label: 'Profile',
                          altIcon: CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer
                                  .withValues(alpha: 0.3),
                              child: authService.isLoggedIn.value
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(59),
                                      child: CachedNetworkImage(
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              const Icon(IconlyBold.profile),
                                          imageUrl: authService
                                                  .profileData.value.avatar ??
                                              ''),
                                    )
                                  : const Icon((IconlyBold.profile)))),
                      NavItem(
                        unselectedIcon: IconlyLight.home,
                        selectedIcon: IconlyBold.home,
                        onTap: _onItemTapped,
                        label: 'Home',
                      ),
                      NavItem(
                        unselectedIcon: Icons.movie_filter_outlined,
                        selectedIcon: Icons.movie_filter_rounded,
                        onTap: _onItemTapped,
                        label: 'Anime',
                      ),
                      NavItem(
                        unselectedIcon:
                            isSimkl ? Iconsax.monitor : Iconsax.book,
                        selectedIcon: isSimkl ? Iconsax.monitor5 : Iconsax.book,
                        onTap: _onItemTapped,
                        label: 'Manga',
                      ),
                      NavItem(
                        unselectedIcon: HugeIcons.strokeRoundedLibrary,
                        selectedIcon: HugeIcons.strokeRoundedLibrary,
                        onTap: _onItemTapped,
                        label: 'Library',
                      ),
                      if (sourceController.shouldShowExtensions.value)
                        NavItem(
                          unselectedIcon: Icons.extension_outlined,
                          selectedIcon: Icons.extension_rounded,
                          onTap: _onItemTapped,
                          label: "Extensions",
                        ),
                    ],
                  ),
                ],
              ))),
          Expanded(
              child: SmoothPageEntrance(
                  style: PageEntranceStyle.slideUpGentle,
                  key: Key(_selectedIndex.toString()),
                  child: routes[_selectedIndex])),
        ],
      ),
    );
  }

  Scaffold _buildAndroidLayout(bool isSimkl) {
    return Scaffold(
        body: SmoothPageEntrance(
            style: PageEntranceStyle.slideUpGentle,
            key: Key(_mobileSelectedIndex.toString()),
            child: mobileRoutes[_mobileSelectedIndex]),
        extendBody: true,
        bottomNavigationBar: ResponsiveNavBar(
          isDesktop: false,
          currentIndex: _mobileSelectedIndex,
          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
          items: [
            NavItem(
              unselectedIcon: IconlyBold.home,
              selectedIcon: IconlyBold.home,
              onTap: _onMobileItemTapped,
              label: 'Home',
            ),
            NavItem(
              unselectedIcon: Icons.movie_filter_rounded,
              selectedIcon: Icons.movie_filter_rounded,
              onTap: _onMobileItemTapped,
              label: 'Anime',
            ),
            NavItem(
              unselectedIcon: isSimkl ? Iconsax.monitor : Iconsax.book,
              selectedIcon: isSimkl ? Iconsax.monitor5 : Iconsax.book,
              onTap: _onMobileItemTapped,
              label: 'Manga',
            ),
            NavItem(
              unselectedIcon: HugeIcons.strokeRoundedLibrary,
              selectedIcon: HugeIcons.strokeRoundedLibrary,
              onTap: _onMobileItemTapped,
              label: 'Library',
            ),
          ],
        ));
  }
}
