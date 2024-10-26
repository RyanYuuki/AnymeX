// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:algorithmic/algorithmic.dart';
import 'package:aurora/utils/scrapers/anime/aniwatch/scraper_search.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future mapMalToAniwatch(
    BuildContext context, String title, String posterUrl, String tag) async {
  final loadingDialog = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final searchResults = await scrapeAnimeSearch(title);

    const double similarityThreshold = 0.85;
    String? animeId;
    String? bestMatch;
    double bestSimilarity = 0.0;

    List titleChars = title.split('');

    for (var item in searchResults) {
      final currentTitle = item['name'] as String;
      final currentJTitle = item['jname'] as String? ?? '';

      List currentTitleChars = currentTitle.split('');
      List currentJTitleChars = currentJTitle.split('');

      String? matchId;
      double matchSimilarity = 0.0;
      String? matchTitle;

      // First check with English title
      if (currentTitle == title) {
        animeId = item['id'];
        break;
      } else {
        final similarity = jaroWinklerSimilarity(titleChars, currentTitleChars);
        if (similarity > matchSimilarity) {
          matchSimilarity = similarity;
          matchTitle = currentTitle;
          matchId = item['id'];
        }
      }

      // If no perfect match with English title, check with Japanese title
      if (currentJTitle == title) {
        animeId = item['id'];
        break;
      } else {
        final jSimilarity =
            jaroWinklerSimilarity(titleChars, currentJTitleChars);
        if (jSimilarity > matchSimilarity) {
          matchSimilarity = jSimilarity;
          matchTitle = currentJTitle;
          matchId = item['id'];
        }
      }

      // Update best match if found
      if (matchSimilarity > bestSimilarity) {
        bestSimilarity = matchSimilarity;
        bestMatch = matchTitle;
        animeId = matchId;
      }
    }

    Navigator.of(context).pop();

    if (animeId == null && bestSimilarity >= similarityThreshold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Did you mean: $bestMatch?')),
      );
    } else if (animeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsPage(
            id: int.parse(animeId!),
            posterUrl: posterUrl,
            tag: tag,
            fromAnilist: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anime not found')),
      );
    }
  } catch (e) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('An error occurred. Please try again later.')),
    );
  }
}

Future<String> fetchAnilistToAniwatch(String animeId) async {
  final url =
      'https://proxy-ryan.vercel.app/cors?url=https://raw.githubusercontent.com/bal-mackup/mal-backup/master/anilist/anime/$animeId.json';

  final response = await http.get(
    Uri.parse(url),
    // headers: {
    //   'Authorization': 'token $githubToken',
    // },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    var aniwatchData = data['Sites']['Zoro'];
    aniwatchData.forEach((key, value) {
      if (value is Map && value.containsKey('identifier')) {
        return (value['url'].toString().split('/').last);
      }
    });
  } else {
    return '';
  }
  return '';
}
