import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart';
import 'package:anymex/models/mangaupdates/news_item.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class MangaAnimeUtil {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1';
  static Future<String?> _fetchWithWebView(String url) async {
    HeadlessInAppWebView? headlessWebView;
    String? html;

    try {
      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          userAgentString: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:135.0) Gecko/20100101 Firefox/135.0",
        ),
        onLoadStop: (controller, url) async {
          await Future.delayed(const Duration(milliseconds: 3500));
          
          final renderedHtml = await controller.evaluateJavascript(
            source: "document.documentElement.outerHTML"
          );

          if (renderedHtml != null && 
              !renderedHtml.contains("BAILOUT_TO_CLIENT_SIDE_RENDERING") &&
              renderedHtml.contains("col-2 text")) {
            html = renderedHtml;
          }
        },
      );

      await headlessWebView.run();
      
      for (int i = 0; i < 10; i++) {
        if (html != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print("WebView Scraping Error: $e");
    } finally {
      await headlessWebView?.dispose();
    }
    return html;
  }

  static Future<List<NewsItem>> getMangaNovelNews(Media media) async {
    try {
      final seriesData = await _getSeriesFromId(media);
      if (seriesData == null || seriesData.isEmpty) return [];
      final int bakaId = seriesData[0]['id'];
      final response = await http.get(Uri.parse('$_baseUrl/series/$bakaId/news'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? newsData = data['data'];
        if (newsData == null) return [];
        return newsData.map((json) => NewsItem.fromMangaBaka(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<NewsItem>> getAnimeNews(Media media) async {
    try {
      final malId = media.idMal.isEmpty ? media.id : media.idMal;
      final response = await http.get(Uri.parse('https://kuroiru.co/api/anime/$malId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? newsData = data['news'];
        if (newsData == null) return [];
        final newsList = newsData.map((json) => NewsItem.fromKuroiru(json)).toList();
        newsList.sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
        return newsList;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<AnimeAdaptation> getAnimeAdaptation(Media media) async {
    try {
      final seriesData = await _getSeriesFromId(media);
      if (seriesData == null || seriesData.isEmpty) {
        return AnimeAdaptation(hasAdaptation: false, error: 'No series found');
      }
      final series = seriesData[0];
      if (series['has_anime'] == true && series['anime'] != null) {
        final animeData = series['anime'];
        return AnimeAdaptation(
          animeStart: animeData['start'],
          animeEnd: animeData['end'],
          hasAdaptation: true,
        );
      }
      return AnimeAdaptation(hasAdaptation: false);
    } catch (e) {
      return AnimeAdaptation(hasAdaptation: false, error: e.toString());
    }
  }

  static Future<NextRelease> getNextChapterPrediction(Media media) async {
    if (media.status.toUpperCase() != 'RELEASING') {
      return NextRelease(error: 'Series is not releasing');
    }

    try {
      final seriesData = await _getSeriesFromId(media);
      final String? muId = seriesData?[0]['source']?['manga_updates']?['id']?.toString();
      if (muId == null) return NextRelease(error: 'MU ID missing');

      final archiveUrl = "https://www.mangaupdates.com/releases/archive?search=$muId&search_type=series";
      final archiveHtml = await _fetchWithWebView(archiveUrl);

      if (archiveHtml == null) return NextRelease(error: 'Failed to render MU Archive');

      final RegExp rowRegExp = RegExp(
        r'class="col-2 text">\s*(\d{4}-\d{2}-\d{2})\s*</div>.*?class="col-1 text text-center">.*?</div>\s*<div class="col-1 text text-center">\s*(.*?)\s*</div>',
        caseSensitive: false,
        dotAll: true,
      );

      final matches = rowRegExp.allMatches(archiveHtml);
      List<DateTime> releaseDates = [];
      String? latestChapterStr;

      for (final match in matches) {
        final dateStr = match.group(1);
        final chapterStr = match.group(2);
        if (dateStr != null) {
          try {
            releaseDates.add(DateTime.parse(dateStr));
            if (latestChapterStr == null && chapterStr != null && chapterStr.trim().contains(RegExp(r'\d'))) {
              latestChapterStr = chapterStr.trim();
            }
          } catch (e) {}
        }
      }

      if (releaseDates.length < 2) return NextRelease(error: 'Insufficient data');

      int sampleSize = releaseDates.length > 10 ? 10 : releaseDates.length;
      List<int> intervals = [];
      for (int i = 0; i < sampleSize - 1; i++) {
        final diff = releaseDates[i].difference(releaseDates[i + 1]).inDays;
        if (diff > 0 && diff < 365) intervals.add(diff);
      }

      if (intervals.isEmpty) return NextRelease(error: 'Irregular schedule');

      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      int roundedInterval = avgInterval.round();

      DateTime predictedDate = releaseDates[0].add(Duration(days: roundedInterval));
      DateTime now = DateTime.now();
      int chaptersToAdd = 1;

      while (predictedDate.isBefore(now)) {
        predictedDate = predictedDate.add(Duration(days: roundedInterval));
        chaptersToAdd++;
      }

      String nextChapterName = "Next Chapter";
      if (latestChapterStr != null) {
        final numericMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(latestChapterStr);
        if (numericMatch != null) {
          double chNum = double.parse(numericMatch.group(1)!);
          double nextChNum = chNum + chaptersToAdd;
          nextChapterName = "Chapter ${nextChNum % 1 == 0 ? nextChNum.toInt() : nextChNum.toStringAsFixed(1)}";
        }
      }

      return NextRelease(
        nextReleaseDate: predictedDate,
        averageIntervalDays: roundedInterval,
        nextChapter: nextChapterName,
      );
    } catch (e) {
      return NextRelease(error: e.toString());
    }
  }

  static Future<List<dynamic>?> _getSeriesFromId(Media media) async {
    final endpoint = media.serviceType == ServicesType.mal
        ? '$_baseUrl/source/my-anime-list/${media.idMal}'
        : '$_baseUrl/source/anilist/${media.id}';

    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['series'] as List<dynamic>?;
      }
    } catch (_) {}
    return [];
  }
}
