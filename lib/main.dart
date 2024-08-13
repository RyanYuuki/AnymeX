import 'package:aurora/pages/streaming_page.dart';
import 'package:flutter/material.dart';
import 'package:aurora/pages/home_page.dart';
import 'package:aurora/pages/details_page.dart';
import 'package:aurora/pages/profile_page.dart';
import 'package:aurora/pages/search_page.dart';
import 'package:aurora/pages/trending_page.dart';
import 'package:aurora/theme/theme.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  final routes = [
    const HomePage(),
    const SearchPage(),
    const TrendingPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightMode,
          darkTheme: darkMode,
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
              unselectedItemColor: Colors.white70,
              backgroundColor: Colors.black.withOpacity(0.1),
              onTap: _onItemTapped,
              items: [
                CrystalNavigationBarItem(
                  icon: IconlyBold.home,
                  unselectedIcon: IconlyLight.home,
                  selectedColor: Colors.indigo,
                ),
                CrystalNavigationBarItem(
                  icon: IconlyBold.search,
                  unselectedIcon: IconlyLight.search,
                  selectedColor: Colors.indigo,
                ),
                CrystalNavigationBarItem(
                  icon: IconlyBold.plus,
                  unselectedIcon: IconlyLight.plus,
                  selectedColor: Colors.indigo,
                ),
                CrystalNavigationBarItem(
                  icon: IconlyBold.user_2,
                  unselectedIcon: IconlyLight.user,
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
