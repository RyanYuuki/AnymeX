import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/pages/Android/Novel/home_page.dart';
import 'package:anymex/hiveData/themeData/theme_provider.dart';
import 'package:anymex/pages/Android/Anime/home_page.dart';
import 'package:anymex/pages/Android/Manga/home_page.dart';
import 'package:anymex/pages/home_page.dart';
import 'package:anymex/utils/sources/unified_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('login-data');
  await Hive.openBox('app-data');
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
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkAndroidVersion();
    }
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
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

  final routes = [
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
    const NovelHomePage(),
  ];

  double getProperSize(double size) {
    if (size >= 0.0 && size < 5.0) {
      return 50.0;
    } else if (size >= 5.0 && size < 10.0) {
      return 45.0;
    } else if (size >= 10.0 && size < 15.0) {
      return 40.0;
    } else if (size >= 15.0 && size < 20.0) {
      return 35.0;
    } else if (size >= 20.0 && size < 25.0) {
      return 30.0;
    } else if (size >= 25.0 && size < 30.0) {
      return 25.0;
    } else if (size >= 30.0 && size < 35.0) {
      return 20.0;
    } else if (size >= 35.0 && size < 40.0) {
      return 15.0;
    } else if (size >= 40.0 && size < 45.0) {
      return 10.0;
    } else if (size >= 45.0 && size < 50.0) {
      return 5.0;
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final box = Hive.box('app-data');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.selectedTheme,
      home: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: routes[_selectedIndex],
        bottomNavigationBar: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (BuildContext context, Box<dynamic> value, Widget? child) {
            double tabBarSizeVertical = Hive.box('app-data')
                .get('tabBarSizeVertical', defaultValue: 0.0);
            double tabBarSizeHorizontal = Hive.box('app-data')
                .get('tabBarSizeHorizontal', defaultValue: 0.0);
            return PlatformBuilder(
              androidBuilder: CrystalNavigationBar(
                borderRadius: box.get('tabBarRoundness', defaultValue: 20.0),
                currentIndex: _selectedIndex,
                paddingR: const EdgeInsets.all(0),
                height: 100 + tabBarSizeVertical,
                unselectedItemColor: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.3),
                onTap: _onItemTapped,
                marginR: EdgeInsets.symmetric(
                    horizontal: getProperSize(tabBarSizeHorizontal),
                    vertical: 15),
                items: [
                  CrystalNavigationBarItem(
                    icon: IconlyBold.home,
                    unselectedIcon: IconlyLight.home,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                  CrystalNavigationBarItem(
                    icon: Icons.movie_filter_rounded,
                    unselectedIcon: Icons.movie_filter_outlined,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                  CrystalNavigationBarItem(
                    icon: Iconsax.book,
                    unselectedIcon: Iconsax.book,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                  CrystalNavigationBarItem(
                    icon: HugeIcons.strokeRoundedBookOpen01,
                    unselectedIcon: HugeIcons.strokeRoundedBookOpen01,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                ],
              ),
              desktopBuilder: CrystalNavigationBar(
                borderRadius: box.get('tabBarRoundness', defaultValue: 20.0),
                currentIndex: _selectedIndex,
                paddingR: const EdgeInsets.all(0),
                height: 170 + tabBarSizeVertical,
                unselectedItemColor: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.3),
                onTap: _onItemTapped,
                marginR: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.40 -
                      tabBarSizeHorizontal,
                  vertical: getProperSize(tabBarSizeVertical),
                ),
                items: [
                  CrystalNavigationBarItem(
                    icon: IconlyBold.home,
                    unselectedIcon: IconlyLight.home,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                  CrystalNavigationBarItem(
                    icon: Icons.movie_filter_rounded,
                    unselectedIcon: Icons.movie_filter_outlined,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                  CrystalNavigationBarItem(
                    icon: Iconsax.book,
                    unselectedIcon: Iconsax.book,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                  CrystalNavigationBarItem(
                    icon: HugeIcons.strokeRoundedBookOpen01,
                    unselectedIcon: HugeIcons.strokeRoundedBookOpen01,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
