import 'package:aurora/pages/onboarding_screens/login_page.dart';
import 'package:aurora/pages/onboarding_screens/onboarding_screens.dart';
import 'package:aurora/pages/Anime/home_page.dart';
import 'package:aurora/pages/Manga/home_page.dart';
import 'package:aurora/pages/home_page.dart';
import 'package:aurora/pages/user/profile.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:aurora/pages/Anime/search_page.dart';
import 'package:aurora/pages/Anime/streaming_page.dart';
import 'package:aurora/pages/Manga/details_page.dart';
import 'package:aurora/pages/Manga/read_page.dart';
import 'package:aurora/pages/Manga/search_page.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('login-data');
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final box = await Hive.openBox('login-data');
    setState(() {
      _isFirstTime = box.get('isFirstTime', defaultValue: true);
    });
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
      home: _isFirstTime
          ? const OnboardingScreens()
          : Scaffold(
              extendBody: true,
              body: routes[_selectedIndex],
              bottomNavigationBar: CrystalNavigationBar(
                currentIndex: _selectedIndex,
                marginR:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                unselectedItemColor:
                    themeProvider.selectedTheme.colorScheme.inverseSurface,
                backgroundColor: themeProvider
                    .selectedTheme.colorScheme.inverseSurface
                    .withOpacity(0.1),
                onTap: _onItemTapped,
                items: [
                  CrystalNavigationBarItem(
                    icon: Iconsax.book,
                    unselectedIcon: Iconsax.book,
                    selectedColor:
                        themeProvider.selectedTheme.colorScheme.primary,
                  ),
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
                ],
              ),
            ),
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/details':
            final posterUrl = args?['posterUrl'] ?? '';
            final id = args?['id'] ?? '';
            final tag = args?['tag'] ?? '';
            return MaterialPageRoute(
              builder: (context) =>
                  DetailsPage(id: id, posterUrl: posterUrl, tag: tag),
            );
          case '/watch':
            final id = args?['id'] ?? '';
            return MaterialPageRoute(
              builder: (context) => StreamingPage(id: id),
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
            return MaterialPageRoute(
              builder: (context) => ReadingPage(id: id, mangaId: mangaId),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            );
          case '/login-page' :
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
