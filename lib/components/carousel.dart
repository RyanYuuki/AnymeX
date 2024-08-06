import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';

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
      log('Data: ${jsonEncode(data)}'); // Convert Map to JSON string for logging
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

class Carousel extends StatefulWidget {
  const Carousel({super.key});

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  Future<List<dynamic>?>? _futureMovies;

  @override
  void initState() {
    super.initState();
    _futureMovies =
        fetchTopRatedMovies(); // Fetch movies on widget initialization
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>?>(
      future: _futureMovies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No data available'));
        } else {
          final movies = snapshot.data!;
          return CarouselSlider(
            options: CarouselOptions(
              height: 400,
              aspectRatio: 2 / 3,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              enlargeFactor: 0.3,
              scrollDirection: Axis.horizontal,
            ),
            items: movies.map((movie) {
              final posterPath = movie['poster_path'];
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          25), // Adjust the radius as needed
                      child: Image.network(
                        'https://image.tmdb.org/t/p/original/${posterPath}',
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        }
      },
    );
  }
}
