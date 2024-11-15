import 'dart:developer';
import 'dart:io';
import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/hiveData/appData/database.dart';
import 'package:aurora/pages/Novel/home_page.dart';
import 'package:aurora/pages/user/profile.dart';
import 'package:aurora/hiveData/themeData/theme_provider.dart';
import 'package:aurora/pages/Anime/home_page.dart';
import 'package:aurora/pages/Manga/home_page.dart';
import 'package:aurora/pages/home_page.dart';
import 'package:aurora/utils/sources/anime/handler/sources_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:aurora/pages/Anime/search_page.dart';
import 'package:aurora/pages/Manga/details_page.dart';
import 'package:aurora/pages/Manga/read_page.dart';
import 'package:aurora/pages/Manga/search_page.dart';
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
        ChangeNotifierProvider(create: (_) => SourcesHandler()),
        ChangeNotifierProvider(
            create: (_) => AniListProvider()..tryAutoLogin()),
      ],
      child: const MainApp(),
    ),
  );
}

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final os = await DeviceInfoPlugin().androidInfo;
    if (os.version.sdkInt >= 33) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        print("Notification permission not granted");
      }
    }
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _checkAndroidVersion();
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
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
                .get('tabBarSizeVertical', defaultValue: 30.0);
            double tabBarSizeHorizontal = Hive.box('app-data')
                .get('tabBarSizeHorizontal', defaultValue: 0.0);
            return CrystalNavigationBar(
              borderRadius: box.get('tabBarRoundness', defaultValue: 30.0),
              currentIndex: _selectedIndex,
              paddingR: const EdgeInsets.all(0),
              marginR: EdgeInsets.symmetric(
                horizontal: getProperSize(tabBarSizeHorizontal),
                vertical: getProperSize(tabBarSizeVertical),
              ),
              unselectedItemColor: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.3),
              onTap: _onItemTapped,
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
            );
          },
        ),
      ),
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/details':
            final posterUrl = args?['posterUrl'] ?? '';
            final id = args?['id'] ?? 0;
            final tag = args?['tag'] ?? '';
            return MaterialPageRoute(
              builder: (context) => DetailsPage(
                id: id,
                posterUrl: posterUrl,
                tag: tag,
              ),
            );
          case '/anime/search':
            final id = args?['term'] ?? '';
            return MaterialPageRoute(
              builder: (context) => SearchPage(searchTerm: id),
            );
          case '/manga/search':
            final id = args?['term'] ?? '';
            return MaterialPageRoute(
              builder: (context) => MangaSearchPage(searchTerm: id),
            );
          case '/manga/details':
            final posterUrl = args?['posterUrl'] ?? '';
            final id = args?['id'] ?? '';
            final tag = args?['tag'] ?? '';
            return MaterialPageRoute(
              builder: (context) =>
                  MangaDetailsPage(id: id, posterUrl: posterUrl, tag: tag),
            );
          case '/manga/read':
            final id = args?['id'] ?? '';
            final mangaId = args?['mangaId'] ?? '';
            final posterUrl = args?['posterUrl'] ?? '';
            final currentSource = args?['currentSource'] ?? '';
            final anilistId = args?['anilistId'] ?? '';
            return MaterialPageRoute(
              builder: (context) => ReadingPage(
                id: id,
                mangaId: mangaId,
                posterUrl: posterUrl,
                currentSource: currentSource,
                anilistId: anilistId,
                chapterList: null,
                description: '',
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                    child: Text('No route defined for ${settings.name}')),
              ),
            );
        }
      },
    );
  }
}
