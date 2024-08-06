// ignore_for_file: unused_import

import 'dart:developer';
import 'package:aurora/components/carousel.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Your API key and proxy configuration
const String API_KEY =
    "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJlMmYxZmIxMmNhYTg4MzIyNGE4MzYzZGMwMzI5YjNiYyIsIm5iZiI6MTcyMjUzMzMxNS4xNDMxOTYsInN1YiI6IjY2OTc5YjJlOGE4ZDI0OTk1MTk4ZDBjMCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.aU0LaiXEoOMHop7gUT7rhCOa--IfwnzitSncuSqb3Lo";
const String BASE_MOVIE_URL = "https://api.themoviedb.org/3";

// Helper function to fetch data
Future<List<dynamic>?> fetchTopRatedMovies() async {
  final url = '$BASE_MOVIE_URL/movie/top_rated';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $API_KEY',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      log('Data: ${jsonEncode(data['results'])}'); // Convert Map to JSON string for logging
      return data['results'] as List<dynamic>?; // Extract the results
    } else {
      log('Failed to load top-rated movies. Status code: ${response.statusCode}');
      return null;
    }
  } catch (error) {
    log('Error fetching top-rated movies: $error');
    return null;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromRGBO(45, 45, 55, 0.6), // Dark background color
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: ListView(
          children: const [
            Header(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CategoryItem(
                  emoji: '😍',
                  name: 'Romance',
                ),
                CategoryItem(
                  emoji: '😂',
                  name: 'Comedy',
                ),
                CategoryItem(
                  emoji: '😱',
                  name: 'Horror',
                ),
                CategoryItem(
                  emoji: '😚',
                  name: 'Drama',
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              'Showing This Month',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Carousel(),
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Ryan 👋',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Let's relax and watch a movie !",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 24, // Avatar size
                backgroundImage:
                    AssetImage('assets/images/avatar.png'), // Image asset
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromRGBO(
                  52, 52, 67, 1), // Dark color for the search bar
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String emoji;
  final String name;
  final VoidCallback? onTap;

  const CategoryItem({
    required this.emoji,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: GestureDetector(
        onTap: onTap, // Handle tap
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, // Set width to control the size of the emoji container
              height:
                  60, // Set height to control the size of the emoji container
              decoration: BoxDecoration(
                color:
                    Colors.grey[800], // Background color of the emoji container
                borderRadius: BorderRadius.circular(15), // Border radius
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 30, // Adjust emoji size as needed
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
