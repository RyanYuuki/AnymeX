import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/settings/adaptors/player/player_adaptor.dart';
import 'package:anymex/controllers/settings/adaptors/ui/ui_adaptor.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/offline_storage.dart';
import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/screens/anime/home_page.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/library/anime_library.dart';
import 'package:anymex/screens/library/history.dart';
import 'package:anymex/screens/library/manga_library.dart';
import 'package:anymex/screens/manga/home_page.dart';
import 'package:anymex/utils/StorageProvider.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:uni_links_desktop/uni_links_desktop.dart';
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

void initDeepLinkListener() async {
  try {
    final initialUri = await getInitialUri();
    if (initialUri != null) {
      handleDeepLink(initialUri);
    }
  } catch (err) {
    snackBar('Error getting initial deep link: $err');
  }

  uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      handleDeepLink(uri);
    }
  }, onError: (err) {
    snackBar('Error Opening link: $err');
  });
}

void handleDeepLink(Uri uri) {
  if (uri.host == "add-repo") {
    String? repoUrl =
        uri.queryParameters["url"] ?? uri.queryParameters['anime_url'];
    String? mangaUrl = uri.queryParameters["manga_url"];
    String? novelUrl = uri.queryParameters["novel_url"];

    final settings = Get.find<SourceController>();

    if (repoUrl != null) {
      settings.activeAnimeRepo = repoUrl;
    }
    if (mangaUrl != null) {
      settings.activeMangaRepo = mangaUrl;
    }
    if (novelUrl != null) {
      settings.activeNovelRepo = novelUrl;
    }

    if (repoUrl != null || mangaUrl != null) {
      snackBar("Added Repo Links Successfully!");
    } else {
      snackBar("Missing required parameters in the link.");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS) {
    registerProtocol('anymex');
  }
  HttpOverrides.global = MyHttpoverrides();
  await dotenv.load(fileName: ".env");
  await initializeHive();
  isar = await StorageProvider().initDB(null);
  _initializeGetxController();
  initializeDateFormatting();
  MediaKit.ensureInitialized();
  if (!Platform.isAndroid && !Platform.isIOS) {
    await WindowManager.instance.ensureInitialized();
    windowManager.setTitle("AnymeX");
    if (defaultTargetPlatform == TargetPlatform.windows) {
      final availableVersion = await WebViewEnvironment.getAvailableVersion();
      if (availableVersion == null) {
        snackBar(
          "Failed to find an installed WebView2 runtime or non-stable Microsoft Edge installation.",
        );
      } else {
        final document = await getApplicationDocumentsDirectory();
        webViewEnvironment = await WebViewEnvironment.create(
            settings: WebViewEnvironmentSettings(
                userDataFolder: p.join(document.path, 'flutter_inappwebview')));
      }
    }
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent));
  }
  initDeepLinkListener();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const ProviderScope(child: MainApp()),
    ),
  );
}

Future<void> initializeHive() async {
  Hive.init((await StorageProvider().getDatabaseDirectory())!.path);
  Hive.deleteFromDisk();
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
  await Hive.openBox<UISettings>("UiSettings");
  await Hive.openBox<PlayerSettings>("PlayerSettings");
}

void _initializeGetxController() {
  Get.put(OfflineStorageController());
  Get.put(AnilistAuth());
  Get.put(AnilistData());
  Get.put(SimklService());
  Get.put(MalService());
  Get.put(SourceController()..initExtensions(refresh: false));
  Get.put(Settings());
  Get.put(ServiceHandler());
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
            if (Get.previousRoute.isNotEmpty) {
              Get.back();
            }
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
  int _selectedLibraryIndex = 1;
  bool showLibrary = false;

  void _onItemTapped(int index) {
    setState(() {
      showLibrary = false;
      _selectedIndex = index;
    });
  }

  void _onMobileItemTapped(int index) {
    setState(() {
      showLibrary = false;
      _mobileSelectedIndex = index;
    });
  }

  void _onLibraryTapped(int index) {
    if (mounted) {
      setState(() {
        showLibrary = true;
        _mobileSelectedIndex = index;
      });
    }
  }

  void _onLibraryTappedDesktop(int index) {
    if (mounted) {
      setState(() {
        showLibrary = true;
        _selectedLibraryIndex = index;
      });
    }
  }

  final routes = [
    const SizedBox.shrink(),
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
    const ExtensionScreen(),
    const MyAnimeLibrary(),
  ];

  final mobileRoutes = [
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
  ];

  final List<Widget> _libraryRoutes = [
    const SizedBox.shrink(),
    const MyAnimeLibrary(),
    const MyMangaLibrary(),
    const HistoryPage(),
  ];

  final List<Widget> _desktopLibraryRoutes = [
    const MyAnimeLibrary(),
    const MyMangaLibrary(),
    const HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<ServiceHandler>();
    final isSimkl =
        Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;
    return PlatformBuilder(
      strictMode: false,
      desktopBuilder: Glow(
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => SizedBox(
                  width: 120,
                  child: ListView(
                    children: [
                      ResponsiveNavBar(
                        fit: true,
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
                                      .surfaceContainer,
                                  child: authService.isLoggedIn.value
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(59),
                                          child: CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                          IconlyBold.profile),
                                              imageUrl: authService.profileData
                                                      .value.avatar ??
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
                            selectedIcon:
                                isSimkl ? Iconsax.monitor5 : Iconsax.book,
                            onTap: _onItemTapped,
                            label: 'Manga',
                          ),
                          NavItem(
                            unselectedIcon: Icons.extension_outlined,
                            selectedIcon: Icons.extension_rounded,
                            onTap: _onItemTapped,
                            label: "Extensions",
                          ),
                          NavItem(
                            unselectedIcon: HugeIcons.strokeRoundedLibrary,
                            selectedIcon: HugeIcons.strokeRoundedLibrary,
                            onTap: (val) {
                              _onLibraryTappedDesktop(0);
                              setState(() {
                                _selectedIndex = val;
                              });
                            },
                            label: 'Library',
                          ),
                        ],
                      ),
                      if (showLibrary) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: getResponsiveValueWithTablet(context,
                              mobileValue: 0.0,
                              tabletValue: 200.0,
                              desktopValue: 180.0),
                          child: ResponsiveNavBar(
                              fit: true,
                              isDesktop: true,
                              currentIndex: _selectedLibraryIndex,
                              margin: const EdgeInsets.fromLTRB(20, 0, 15, 0),
                              items: getResponsiveValueWithTablet(
                                context,
                                mobileValue: [],
                                tabletValue: [
                                  NavItem(
                                    unselectedIcon: Iconsax.play,
                                    selectedIcon: Iconsax.play5,
                                    onTap: _onLibraryTappedDesktop,
                                    label: 'Library',
                                  ),
                                  NavItem(
                                    unselectedIcon: isSimkl
                                        ? Iconsax.monitor
                                        : HugeIcons.strokeRoundedBookOpen01,
                                    selectedIcon: isSimkl
                                        ? Iconsax.monitor5
                                        : HugeIcons.strokeRoundedBookOpen01,
                                    onTap: _onLibraryTappedDesktop,
                                    label: 'Library',
                                  ),
                                  NavItem(
                                    unselectedIcon: Iconsax.clock,
                                    selectedIcon: Iconsax.clock5,
                                    onTap: _onLibraryTappedDesktop,
                                    label: 'Library',
                                  ),
                                ],
                                desktopValue: [
                                  NavItem(
                                    unselectedIcon: Iconsax.play,
                                    selectedIcon: Iconsax.play5,
                                    onTap: _onLibraryTappedDesktop,
                                    label: 'Library',
                                  ),
                                  NavItem(
                                    unselectedIcon: isSimkl
                                        ? Iconsax.monitor
                                        : HugeIcons.strokeRoundedBookOpen01,
                                    selectedIcon: isSimkl
                                        ? Iconsax.monitor5
                                        : HugeIcons.strokeRoundedBookOpen01,
                                    onTap: _onLibraryTappedDesktop,
                                    label: 'Library',
                                  ),
                                ],
                              )),
                        ),
                      ],
                    ],
                  ))),
              Expanded(
                  child: showLibrary
                      ? _desktopLibraryRoutes[_selectedLibraryIndex]
                      : routes[_selectedIndex]),
            ],
          ),
        ),
      ),
      androidBuilder: Glow(
          child: Scaffold(
              body: showLibrary
                  ? _libraryRoutes[_mobileSelectedIndex]
                  : mobileRoutes[_mobileSelectedIndex],
              extendBody: true,
              bottomNavigationBar: ResponsiveNavBar(
                isDesktop: false,
                fit: true,
                currentIndex: _mobileSelectedIndex,
                isShowingLibrary: showLibrary,
                margin:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
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
                    onTap: (val) {
                      _onLibraryTapped(1);
                    },
                    label: 'Library',
                  ),
                ],
                libraryItems: [
                  NavItem(
                    unselectedIcon: IconlyBold.arrow_left,
                    selectedIcon: Iconsax.arrow_left,
                    onTap: (val) => setState(() {
                      showLibrary = false;
                      _mobileSelectedIndex = 0;
                    }),
                    label: 'Back',
                  ),
                  NavItem(
                    unselectedIcon: Iconsax.play,
                    selectedIcon: Iconsax.play5,
                    onTap: _onLibraryTapped,
                    label: 'Anime',
                  ),
                  NavItem(
                    unselectedIcon: isSimkl
                        ? Iconsax.monitor
                        : HugeIcons.strokeRoundedBookOpen01,
                    selectedIcon: isSimkl
                        ? Iconsax.monitor5
                        : HugeIcons.strokeRoundedBookOpen01,
                    onTap: _onLibraryTapped,
                    label: 'Manga',
                  ),
                  NavItem(
                    unselectedIcon: Iconsax.clock,
                    selectedIcon: Iconsax.clock5,
                    onTap: _onLibraryTapped,
                    label: 'History',
                  ),
                ],
              ))),
    );
  }
}
