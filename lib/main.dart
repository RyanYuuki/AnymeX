import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/models/ui/ui_adaptor.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/offline_storage.dart';
import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/screens/anime/home_page.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/library/my_library.dart';
import 'package:anymex/screens/manga/home_page.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/utils/deeplink.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/register_protocol/register_protocol.dart';
import 'package:anymex/widgets/adaptive_wrapper.dart';
import 'package:anymex/widgets/animation/more_page_transitions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:app_links/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

late Isar isar;
WebViewEnvironment? webViewEnvironment;

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

    // TODO: For all the contributors just make a supabase account and then change this
    // await Supabase.initialize(
    //     url: dotenv.env['SUPABASE_URL']!,
    //     anonKey: dotenv.env['SUPABASE_ANON_KEY']!);

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
    if (!Platform.isAndroid && !Platform.isIOS) {
      await WindowManager.instance.ensureInitialized();
      try {
        windowManager.setTitle("AnymeX (●'◡'●)");
      } catch (e) {
        windowManager.setTitle("AnymeX");
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        try {
          final availableVersion =
              await WebViewEnvironment.getAvailableVersion();
          if (availableVersion == null) {
            snackBar(
              "Failed to find an installed WebView2 runtime or non-stable Microsoft Edge installation.\n\n"
              "Try installing WebView2 runtime from:\n"
              "https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section",
            );
          } else {
            final document = await getApplicationDocumentsDirectory();
            webViewEnvironment = await WebViewEnvironment.create(
              settings: WebViewEnvironmentSettings(
                userDataFolder: p.join(document.path, 'flutter_inappwebview'),
              ),
            );
          }
        } catch (e) {
          snackBar(
            "Error initializing WebView2: ${e.toString()}\n\n"
            "Try reinstalling WebView2 runtime from:\n"
            "https://developer.microsoft.com/en-us/microsoft-edge/webview2/#download-section",
          );
        }
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
      parent.print(zone, line);
    },
  ));
}

void initDeepLinkListener() async {
  final appLinks = AppLinks();
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
  Get.put(SourceController());
  Get.put(Settings());
  Get.put(ServiceHandler());
  Get.put(GreetingController());
  Get.lazyPut(() => CacheController());
  // DownloadManagerBinding.initializeDownloadManager();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
            windowManager.setFullScreen(!isFullScreen);
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            final isAltPressed = HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.altLeft) ||
                HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.altRight);
            if (isAltPressed) {
              bool isFullScreen = await windowManager.isFullScreen();
              windowManager.setFullScreen(!isFullScreen);
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
        home: const FilterScreen(),
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
    const ExtensionScreen(),
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
    final authService = Get.find<ServiceHandler>();
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
