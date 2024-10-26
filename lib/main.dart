import 'dart:developer';
import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/hiveData/appData/database.dart';
import 'package:aurora/pages/onboarding_screens/login_page.dart';
import 'package:aurora/pages/user/profile.dart';
import 'package:aurora/hiveData/themeData/theme_provider.dart';
import 'package:aurora/pages/Anime/home_page.dart';
import 'package:aurora/pages/Manga/home_page.dart';
import 'package:aurora/pages/home_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 1;
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
    const MangaHomePage(),
    const HomePage(),
    const AnimeHomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.selectedTheme,
      home: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: routes[_selectedIndex],
        bottomNavigationBar: CrystalNavigationBar(
          currentIndex: _selectedIndex,
          marginR: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
          unselectedItemColor: Colors.white,
          backgroundColor: Colors.black.withOpacity(0.3),
          onTap: _onItemTapped,
          items: [
            CrystalNavigationBarItem(
              icon: Iconsax.book,
              unselectedIcon: Iconsax.book,
              selectedColor: themeProvider.selectedTheme.colorScheme.primary,
            ),
            CrystalNavigationBarItem(
              icon: IconlyBold.home,
              unselectedIcon: IconlyLight.home,
              selectedColor: themeProvider.selectedTheme.colorScheme.primary,
            ),
            CrystalNavigationBarItem(
              icon: Icons.movie_filter_rounded,
              unselectedIcon: Icons.movie_filter_outlined,
              selectedColor: themeProvider.selectedTheme.colorScheme.primary,
            ),
          ],
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
            return MaterialPageRoute(
              builder: (context) => ReadingPage(
                id: id,
                mangaId: mangaId,
                posterUrl: posterUrl,
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            );
          case '/login-page':
            return MaterialPageRoute(
              builder: (context) => const LoginPage(),
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
