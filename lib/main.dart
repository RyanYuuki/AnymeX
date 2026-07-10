import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/services/storage/storage_manager_service.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/database/database.dart';
import 'package:anymex/firebase_options.dart';
import 'package:anymex/screens/anime/home_page.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/my_library.dart';
import 'package:anymex/screens/manga/home_page.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/external_font_loader.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/deeplink.dart';
import 'package:anymex/utils/register_protocol/register_protocol.dart';
import 'package:anymex/widgets/animation/more_page_transitions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/fps_meter.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_splash_screen.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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

void initDeepLinkListener(List<String> args) async {
  if (args.isNotEmpty) {
    for (final arg in args) {
      try {
        final uri = Uri.parse(arg);
        final schemes = {
          'dar',
          'anymex',
          'sugoireads',
          'mangayomi',
          'cloudstreamrepo',
          'sora',
          'tachiyomi',
          'aniyomi'
        };
        if (uri.hasScheme && schemes.contains(uri.scheme.toLowerCase())) {
          Deeplink.handleDeepLink(uri);
          break;
        }
      } catch (_) {}
    }
  }

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

Future<void> safeCall(FutureOr<void> Function() function,
    {String? errorMessage}) async {
  try {
    await function();
  } catch (e) {
    if (errorMessage != null) {
      Logger.e("$errorMessage: $e");
    } else {
      debugPrint("Error: $e");
    }
  }
}

void main(List<String> args) async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await safeCall(() async {
      if (!Platform.isLinux) {
        if (Platform.isWindows || Platform.isMacOS) {
          webViewEnvironment = await WebViewEnvironment.create();
        }
        await InAppWebViewController.setWebContentsDebuggingEnabled(
          !const bool.fromEnvironment('dart.vm.product'),
        );
      }
    }, errorMessage: 'Failed to initialize WebViewEnvironment');

    await safeCall(() => ExternalFontLoader.loadAllFonts(),
        errorMessage: 'Failed to load external fonts');

    await Logger.init();

    await safeCall(() => dotenv.load(fileName: ".env"),
        errorMessage: 'Failed to load .env file');

    if (!Platform.isLinux) {
      await safeCall(
          () => Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform,
              ),
          errorMessage: 'Failed to initialize Firebase');
    }

    if (Platform.isWindows) {
      await safeCall(() {
        [
          'dar',
          'anymex',
          'sugoireads',
          'mangayomi',
          'cloudstreamrepo',
          'sora',
          'tachiyomi',
          'aniyomi'
        ].forEach(registerProtocolHandler);
      }, errorMessage: 'Failed to register protocol handlers');
    }

    await safeCall(() => Database().init(),
        errorMessage: 'CRITICAL: Database initialization failed');

    HttpOverrides.global = MyHttpoverrides();

    _initializeGetxController();

    await safeCall(() => initDeepLinkListener(args),
        errorMessage: 'Failed to initialize deep link listener');

    await safeCall(() => initializeDateFormatting(),
        errorMessage: 'Failed to initialize date formatting');

    await safeCall(() => MediaKit.ensureInitialized(),
        errorMessage: 'Failed to initialize MediaKit');

    await safeCall(() async {
      if (!Platform.isAndroid && !Platform.isIOS) {
        await windowManager.ensureInitialized();
        await AnymexTitleBar.initialize();
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark));
      }
    }, errorMessage: 'Failed to initialize window manager or system UI');

    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      Logger.e("FLUTTER ERROR: ${details.exceptionAsString()}");
      Logger.e("STACK: ${details.stack}");
    };

    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MainApp(),
      ),
    );
  }, (error, stackTrace) async {
    Logger.e("CRASH: $error");
    Logger.e("STACK: $stackTrace");
  }, zoneSpecification: ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      if (Logger.isInitialized) {
        Logger.i(line);
      } else {
        parent.print(zone, line);
      }
    },
  ));
}

void _initializeGetxController() async {
  await safeCall(() {
    Get.put(Settings());
    Get.put(OfflineStorageController());
    Get.put(AnilistAuth());
    Get.put(CommunityService());
    Get.put(AnilistData());
    Get.put(SimklService());
    Get.put(MalService());
    Get.put(DiscordRPCController());
    if (!Get.isRegistered<SourceController>()) {
      Get.put(SourceController());
    }
    Get.put(ServiceHandler());
    Get.put(GreetingController());
    Get.put(CommentumService());
    Get.put(CommentPreloader());
    Get.put(GistSyncController(), permanent: true);
    Get.put(DownloadController(), permanent: true);
    Get.lazyPut(() => CacheController());
  }, errorMessage: 'Failed to register GetX controllers');

  await safeCall(() => StorageManagerService().enforceImageCacheLimit(),
      errorMessage: 'Failed to enforce image cache limit');
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showMainApp = false;
  bool _isFullScreen = false;

  late FocusNode focusNode;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isFullScreen) {
        AnymexTitleBar.setFullScreen(false);
      } else {
        BuildContext escapeContext = Get.context!;
        if (Navigator.of(escapeContext).canPop()) {
          Navigator.pop(escapeContext);
        }
      }
      return KeyEventResult.handled;
    } else if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f11) {
      AnymexTitleBar.toggleFullScreen();
      return KeyEventResult.handled;
    } else if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      final isAltPressed = HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.altLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.altRight);
      if (isAltPressed) {
        AnymexTitleBar.toggleFullScreen();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();

    AnymexTitleBar.isFullScreen
        .addListener(() => _isFullScreen = AnymexTitleBar.isFullScreen.value);

    focusNode = FocusNode();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMainApp = true;
        });
      }
    });
  }

  @override
  void dispose() {
    Logger.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
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
                RepaintBoundary(child: child!),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    child: AnymexTitleBar.titleBar(),
                  ),
                ),
                const FpsMeter(),
              ],
            );
          }
          return Stack(
            children: [
              child!,
              const FpsMeter(),
            ],
          );
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
    return Glow(
      child: PlatformBuilder(
        strictMode: false,
        desktopBuilder: _buildDesktopLayout(context, authService),
        androidBuilder: _buildAndroidLayout(authService),
      ),
    );
  }

  Scaffold _buildDesktopLayout(
      BuildContext context, ServiceHandler authService) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Provider.of<ThemeProvider>(context).isOled
          ? Colors.black
          : Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final isSimkl = authService.serviceType.value == ServicesType.simkl;
            return SizedBox(
              width: 120,
              child: SuperListView(
                children: [
                  ResponsiveNavBar(
                    isDesktop: true,
                    currentIndex: _selectedIndex,
                    margin: const EdgeInsets.fromLTRB(20, 18, 15, 10),
                    borderRadius: BorderRadius.circular(50),
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
                                      child: AnymeXImage(
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          radius: 0,
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
                        label: isSimkl ? 'Movies' : 'Anime',
                      ),
                      NavItem(
                        unselectedIcon:
                            isSimkl ? Iconsax.monitor : Iconsax.book,
                        selectedIcon: isSimkl ? Iconsax.monitor5 : Iconsax.book,
                        onTap: _onItemTapped,
                        label: isSimkl ? 'Series' : 'Manga',
                      ),
                      NavItem(
                        unselectedIcon: HugeIcons.strokeRoundedLibrary,
                        selectedIcon: HugeIcons.strokeRoundedLibrary,
                        onTap: _onItemTapped,
                        label: 'Library',
                      ),
                      NavItem(
                        unselectedIcon: Icons.extension_outlined,
                        selectedIcon: Icons.extension_rounded,
                        onTap: _onItemTapped,
                        label: "Extensions",
                      ),
                    ],
                  ),
                ],
              ));
          }),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: routes,
            ),
          ),
        ],
      ),
    );
  }

  Scaffold _buildAndroidLayout(ServiceHandler authService) {
    return Scaffold(
        body: IndexedStack(
          index: _mobileSelectedIndex,
          children: mobileRoutes,
        ),
        extendBody: true,
        bottomNavigationBar: Obx(() {
          final isSimkl = authService.serviceType.value == ServicesType.simkl;
          return ResponsiveNavBar(
            isDesktop: false,
            currentIndex: _mobileSelectedIndex,
            margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 32),
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
                label: isSimkl ? 'Movies' : 'Anime',
              ),
              NavItem(
                unselectedIcon: isSimkl ? Iconsax.monitor : Iconsax.book,
                selectedIcon: isSimkl ? Iconsax.monitor5 : Iconsax.book,
                onTap: _onMobileItemTapped,
                label: isSimkl ? 'Series' : 'Manga',
              ),
              NavItem(
                unselectedIcon: HugeIcons.strokeRoundedLibrary,
                selectedIcon: HugeIcons.strokeRoundedLibrary,
                onTap: _onMobileItemTapped,
                label: 'Library',
              ),
            ],
          );
        }));
  }
}
