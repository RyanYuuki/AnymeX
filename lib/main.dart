import 'package:aurora/pages/Anime/search_page.dart';
import 'package:aurora/pages/Anime/streaming_page.dart';
import 'package:aurora/pages/Manga/details_page.dart';
import 'package:aurora/pages/Manga/home_page.dart';
import 'package:aurora/pages/Manga/read_page.dart';
import 'package:aurora/pages/Manga/search_page.dart';
import 'package:aurora/pages/home_page.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:aurora/pages/Anime/home_page.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

void main() {
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

  final routes = [
    const MangaHomePage(),
    const HomePage(),
    const AnimeHomePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Builder(
      builder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.selectedTheme,
          onGenerateRoute: (settings) {
            final args = settings.arguments as Map<String, dynamic>?;

            switch (settings.name) {
              case '/details':
                final id = args?['id'] ?? '';
                return MaterialPageRoute(
                  builder: (context) => DetailsPage(id: id),
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
                final id = args?['id'] ?? '';
                return MaterialPageRoute(
                  builder: (context) => MangaDetailsPage(id: id),
                );
              case '/manga/read':
                final id = args?['id'] ?? '';
                final mangaId = args?['mangaId'] ?? '';
                return MaterialPageRoute(
                  builder: (context) => ReadingPage(id: id, mangaId: mangaId),
                );
              default:
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(child: Text('Page not found')),
                  ),
                );
            }
          },
          home: Scaffold(
            extendBody: true,
            body: routes[_selectedIndex],
            bottomNavigationBar: CrystalNavigationBar(
              currentIndex: _selectedIndex,
              marginR: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
              unselectedItemColor: Colors.white70,
              backgroundColor: Colors.black.withOpacity(0.1),
              onTap: _onItemTapped,
              items: [
                CrystalNavigationBarItem(
                  icon: Iconsax.book,
                  unselectedIcon: Iconsax.book,
                  selectedColor: Colors.indigo,
                ),
                CrystalNavigationBarItem(
                  icon: IconlyBold.home,
                  unselectedIcon: IconlyLight.home,
                  selectedColor: Colors.indigo,
                ),
                CrystalNavigationBarItem(
                  icon: Icons.movie_filter_rounded,
                  unselectedIcon: Icons.movie_filter_outlined,
                  selectedColor: Colors.indigo,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
