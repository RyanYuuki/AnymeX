import 'dart:io';
import 'dart:ui';

import 'package:anymex/controllers/Settings/settings.dart';
import 'package:anymex/controllers/source_controller.dart';
import 'package:anymex/controllers/anilist/anilist_auth.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/Settings/adaptors/player/player_adaptor.dart';
import 'package:anymex/controllers/Settings/adaptors/ui/ui_adaptor.dart';
import 'package:anymex/screens/anime/home_page.dart';
import 'package:anymex/screens/extemsions/ExtensionScreen.dart';
import 'package:anymex/screens/manga/home_page.dart';
import 'package:anymex/screens/novel/home_page.dart';
import 'package:anymex/utils/StorageProvider.dart';
import 'package:anymex/controllers/anilist/anilist_data.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:window_manager/window_manager.dart';

late Isar isar;

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeHive();
  isar = await StorageProvider().initDB(null);
  _initializeGetxController();
  initializeDateFormatting();
  MediaKit.ensureInitialized();
  if (!Platform.isAndroid && !Platform.isIOS) {
    await WindowManager.instance.ensureInitialized();
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ProviderScope(child: MainApp()),
    ),
  );
}

Future<void> initializeHive() async {
  await Hive.initFlutter();
  await Hive.openBox('themeData');
  await Hive.openBox('loginData');
  await Hive.openBox('settingsData');
  Hive.registerAdapter(UISettingsAdapter());
  Hive.registerAdapter(PlayerSettingsAdapter());
  await Hive.openBox<UISettings>("UiSettings");
  await Hive.openBox<PlayerSettings>("PlayerSettings");
}

void _initializeGetxController() {
  Get.put(AnilistData());
  Get.put(AnilistAuth()..tryAutoLogin());
  Get.put(SourceController()..initExtensions());
  Get.put(Settings());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Get.back();
        }
      },
      child: GetMaterialApp(
        scrollBehavior: MyCustomScrollBehavior(),
        debugShowCheckedModeBanner: false,
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
    final authService = Get.find<AnilistAuth>();
    return PlatformBuilder(
      desktopBuilder: Glow(
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => SizedBox(
                  width: 120,
                  child: ResponsiveNavBar(
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
                                      borderRadius: BorderRadius.circular(59),
                                      child: CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          imageUrl: authService
                                                  .profileData.value?.avatar ??
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
                  ))),
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
                margin:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
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
              ))),
    );
  }
}
