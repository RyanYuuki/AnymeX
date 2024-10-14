import 'package:algorithmic/algorithmic.dart'; // Import the algorithmic package
import 'package:aurora/database/scraper/scraper_search.dart';
import 'package:aurora/pages/Anime/details_page.dart';
import 'package:flutter/material.dart';

Future<void> mapMalToAniwatch(
    BuildContext context, String title, String posterUrl, String tag) async {
  // Show loading dialog
  final loadingDialog = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  try {
    final searchResults = await scrapeAnimeSearch(title);

    const double similarityThreshold = 0.85;
    String? animeId;
    String? bestMatch;
    double bestSimilarity = 0.0;

    List<String> titleChars = title.split('');

    for (var item in searchResults) {
      final currentTitle = item['name'] as String;
      List<String> currentTitleChars = currentTitle.split('');

      if (currentTitle == title) {
        animeId = item['id'];
        break;
      } else {
        final similarity = jaroWinklerSimilarity(titleChars, currentTitleChars);
        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = currentTitle;
          animeId = item['id'];
        }
      }
    }

    // Dismiss the loading dialog
    Navigator.of(context).pop(); // Dismiss loading dialog

    if (animeId == null && bestSimilarity >= similarityThreshold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Did you mean: $bestMatch?')),
      );
    } else if (animeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsPage(
            id: animeId!,
            posterUrl: posterUrl,
            tag: tag,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anime not found')),
      );
    }
  } catch (e) {
    // Dismiss loading dialog in case of error
    Navigator.of(context).pop(); // Dismiss loading dialog
    print('Error occurred while fetching anime: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('An error occurred. Please try again later.')),
    );
  }
}