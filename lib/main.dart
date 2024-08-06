import 'package:aurora/pages/profile_page.dart';
import 'package:aurora/pages/search_page.dart';
import 'package:aurora/pages/trending_page.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:aurora/pages/home_page.dart';
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

  final List<Widget> routes = [
    const HomePage(),
    const SearchPage(),
    const TrendingPage(),
    const ProfilePage(),
    // Add corresponding pages for Favourite, Add, and Profile if needed
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
        final brightness = MediaQuery.of(context).platformBrightness;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Poppins',
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black54),
              headlineSmall: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          darkTheme: ThemeData(
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            primarySwatch: Colors.blueGrey,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.grey),
              headlineSmall: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            extendBody: true,
            body: routes[_selectedIndex],
            bottomNavigationBar: CrystalNavigationBar(
              currentIndex: _selectedIndex,
              unselectedItemColor: Colors.white70,
              backgroundColor: Colors.black.withOpacity(0.1),
              onTap: _onItemTapped,
              items: [
                /// Home
                CrystalNavigationBarItem(
                  icon: IconlyBold.home,
                  unselectedIcon: IconlyLight.home,
                  selectedColor: Colors.white,
                ),

                CrystalNavigationBarItem(
                  icon: IconlyBold.search,
                  unselectedIcon: IconlyLight.search,
                  selectedColor: Colors.white,
                ),

                /// Add
                CrystalNavigationBarItem(
                  icon: IconlyBold.plus,
                  unselectedIcon: IconlyLight.plus,
                  selectedColor: Colors.white,
                ),

                /// Profile
                CrystalNavigationBarItem(
                  icon: IconlyBold.user_2,
                  unselectedIcon: IconlyLight.user,
                  selectedColor: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
