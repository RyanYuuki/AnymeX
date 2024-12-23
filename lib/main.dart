import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:anymex/StorageProvider.dart';
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/android/common/settings_modal.dart';
import 'package:anymex/components/common/custom_bg.dart';
import 'package:anymex/components/common/navbar.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/pages/Extensions/ExtensionScreen.dart';
import 'package:anymex/pages/Novel/home_page.dart';
import 'package:anymex/hiveData/themeData/theme_provider.dart';
import 'package:anymex/pages/Anime/home_page.dart';
import 'package:anymex/pages/Manga/home_page.dart';
import 'package:anymex/pages/home_page.dart';
import 'package:anymex/utils/sources/unified_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

late Isar isar;

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('login-data');
  await Hive.openBox('app-data');
  WidgetsFlutterBinding.ensureInitialized();
  isar = await StorageProvider().initDB(null);
  initializeDateFormatting();
  MediaKit.ensureInitialized();
  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();
    windowManager.setTitle("AnymeX");
    windowManager.maximize();
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent));
  }
  try {
    await dotenv.load(fileName: ".env");
    log('Env file loaded successfully.');
  } catch (e) {
    log('Error loading env file: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UnifiedSourcesHandler()),
        ChangeNotifierProvider(
            create: (_) => AniListProvider()..tryAutoLogin()),
      ],
      child: const ProviderScope(child: MainApp()),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  int _mobileSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkAndroidVersion();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    }
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isLight =
        PlatformDispatcher.instance.platformBrightness == Brightness.light;
    if (Hive.box('login-data').get('Theme', defaultValue: 'dark') == 'system') {
      if (isLight) {
        themeProvider.setLightModeWithoutDB();
      } else {
        themeProvider.setDarkModeWithoutDB();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAndroidVersion() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final bool isAndroid12orAbove = androidInfo.version.sdkInt >= 31;
    Hive.box('app-data').put('isAndroid12orAbove', isAndroid12orAbove);
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
    const NovelHomePage(),
    const ExtensionScreen(),
  ];

  final mobileRoutes = [
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
    const NovelHomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final box = Hive.box('app-data');

    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: "AnymeX",
      debugShowCheckedModeBanner: false,
      theme: themeProvider.selectedTheme,
      home: PlatformBuilder(
        desktopBuilder: Glow(
          child: Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Consumer<AniListProvider>(
                      builder: (context, anilistProvider, _) {
                    final avatarImagePath =
                        anilistProvider.userData?['user']?['avatar']?['large'];
                    final isLoggedIn =
                        anilistProvider.userData?['user']?['name'] != null;

                    return ResponsiveNavBar(
                      fit: true,
                      isDesktop: true,
                      currentIndex: _selectedIndex,
                      margin: const EdgeInsets.fromLTRB(20, 30, 15, 10),
                      items: [
                        NavItem(
                            unselectedIcon: IconlyBold.profile,
                            selectedIcon: IconlyBold.profile,
                            onTap: (index) {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return const SettingsModal();
                                },
                              );
                            },
                            label: 'Profile',
                            altIcon: isLoggedIn
                                ? CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          imageUrl: avatarImagePath),
                                    ))
                                : null),
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
                          unselectedIcon: Iconsax.book,
                          selectedIcon: Iconsax.book,
                          onTap: _onItemTapped,
                          label: 'Manga',
                        ),
                        NavItem(
                          unselectedIcon: HugeIcons.strokeRoundedBookOpen01,
                          selectedIcon: HugeIcons.strokeRoundedBookOpen01,
                          onTap: _onItemTapped,
                          label: 'Novel',
                        ),
                        NavItem(
                          unselectedIcon: Icons.extension_outlined,
                          selectedIcon: Icons.extension_rounded,
                          onTap: _onItemTapped,
                          label: "Extensions",
                        ),
                      ],
                    );
                  }),
                ),
                Expanded(child: routes[_selectedIndex]),
              ],
            ),
          ),
        ),
        androidBuilder: Glow(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: mobileRoutes[_mobileSelectedIndex],
            extendBody: true,
            bottomNavigationBar: ResponsiveNavBar(
              isDesktop: false,
              fit: true,
              currentIndex: _mobileSelectedIndex,
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
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
                  unselectedIcon: Iconsax.book,
                  selectedIcon: Iconsax.book,
                  onTap: _onMobileItemTapped,
                  label: 'Manga',
                ),
                NavItem(
                  unselectedIcon: HugeIcons.strokeRoundedBookOpen01,
                  selectedIcon: HugeIcons.strokeRoundedBookOpen01,
                  onTap: _onMobileItemTapped,
                  label: 'Novel',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
