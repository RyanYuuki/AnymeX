import 'dart:convert';
import 'dart:developer';
import 'package:anymex/utils/sources/manga/base/source_base.dart';
import 'package:anymex/utils/sources/manga/helper/jaro_helper.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'dart:async';
// import 'package:image/image.dart' as img;

class MangaFire implements SourceBase {
  final String id = "mangafire";
  final String url = "https://mangafire.to";
  final int rateLimit = 250;
  final bool needsProxy = true;
  final bool useGoogleTranslate = false;

  static const String manga = "manga";
  static const String oneShot = "one_shot";
  List<String> formats = [manga, oneShot];

  @override
  Future fetchMangaSearchResults(String query) async {
    List<Map<String, String>> results = [];

    final String formattedUrl =
        '$url/filter?keyword=${Uri.encodeComponent(query)}';
    final response = await http.get(Uri.parse(formattedUrl));
    final document = parse(response.body);

    document
        .querySelectorAll("main div.container div.original div.unit")
        .forEach((el) {
      final id = el.querySelector("a")?.attributes["href"] ?? "";
      results.add({
        "id": id,
        "image": el.querySelector("img")?.attributes["src"] ?? "",
        "title": el.querySelector("div.info a")?.text.trim() ?? "",
      });
    });

    log(results.toString());
    return results;
  }

  String extractMangaTitle(String url) {
    final parts = url.split('/');

    if (parts.length >= 3 && parts[1] == 'manga') {
      final mangaSegment = parts[2];
      final rawTitle = mangaSegment.split('.')[0];
      final title = rawTitle
          .split('-')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');

      int length = title.length;
      return title.substring(0, length - 1);
    }

    return '';
  }

  @override
  Future fetchMangaChapters(String id) async {
    final chapters = <Map<String, dynamic>>[];
    final match = RegExp(r"\.([^.]+)$").firstMatch(id);
    final mangaId = match?.group(1) ?? "";

    final response = await http.get(
      Uri.parse('$url/ajax/manga/$mangaId/chapter/en'),
      headers: {"X-Requested-With": "XMLHttpRequest", "Referer": "$url$id"},
    );
    final data = jsonDecode(response.body);

    if (data["status"] != 200) return chapters;

    final document = parse(data["result"]);

    document.querySelectorAll("ul li.item").forEach((el) {
      chapters.add({
        "id": el.querySelector("a")?.attributes["href"] ?? "",
        "number": (el.attributes["data-number"] ?? "0").toString(),
        "title": el.querySelector("span")?.text.trim() ?? "",
        "date": 'MangaFire',
      });
    });
    var finalData = {
      'id': extractMangaTitle(id),
      'title': id.split('/').last.split('.').first,
      'chapterList': chapters.reversed.toList(),
    };
    log(finalData.toString());
    return finalData;
  }

  String extractTitle(String chapterId) {
    final parts = chapterId.split('/');

    if (parts.length >= 3 && parts[1] == 'read') {
      final mangaSegment = parts[2];

      String title = mangaSegment.split('.')[0];
      int length = title.length;
      return title
          .split('-')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ')
          .substring(0, length - 1);
    }

    return '';
  }

  @override
  Future fetchChapterImages(
      {required String mangaId, required String chapterId}) async {
    final match = RegExp(r"\.([^.]+)$").firstMatch(chapterId);
    final manId = match?.group(1)?.split("/")[0] ?? "";

    final response = await http.get(
      Uri.parse('$url/ajax/read/$manId/chapter/en'),
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "Referer": "$url$chapterId"
      },
    );
    final data = jsonDecode(response.body);
    final document = parse(data["result"]["html"]);

    String chapId = "";
    double totalChapter = 0;
    document.querySelectorAll("ul li").forEach((el) {
      final url = el.querySelector("a")?.attributes["href"];
      final chapNum = el.querySelector('a')?.attributes['data-number'] ?? '0';
      if (url == chapterId) {
        chapId = el.querySelector("a")?.attributes["data-id"] ?? "";
      }
      if (double.parse(chapNum) > totalChapter) {
        totalChapter = double.parse(chapNum);
      }
    });

    if (chapId.isEmpty) return {};

    final imageDataResponse = await http.get(
      Uri.parse('$url/ajax/read/chapter/$chapId'),
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "Referer": "$url$chapterId"
      },
    );
    final imageData = jsonDecode(imageDataResponse.body);

    final List<Map<String, dynamic>> images = [];
    for (var image in imageData["result"]["images"]) {
      images.add({
        "url": image[0],
        "index": image[1],
        "isScrambled": image[2] != 0,
        "scrambledKey": image[2],
      });
    }

    final descrambledImages = await Future.wait(images.map((image) async {
      if (image["isScrambled"]) {
        final descrambled =
            await descrambleImage(image["url"], image["scrambledKey"]);
        return {"image": descrambled};
      } else {
        return {"image": image["url"]};
      }
    }));
    final assets = {
      'title': extractTitle(chapterId),
      'currentChapter':
          chapterId.split('/').last.replaceAll('-', ' ').toUpperCase(),
      'nextChapterId': getNextChapterId(chapterId, totalChapter),
      'prevChapterId': getPrevChapterId(chapterId),
      'images': descrambledImages,
      'totalImages': descrambledImages.length,
    };

    log(assets.toString());
    return assets;
  }

  String? getNextChapterId(String id, double length) {
    log(id);
    final match = RegExp(r'^(.*?/chapter-)(\d+(\.\d+)?)$').firstMatch(id);
    if (match == null) return null;

    final prefix = match.group(1)!;
    final double chapNum = double.parse(match.group(2)!);

    if (chapNum < length) {
      return '$prefix${(chapNum + 1).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}';
    } else {
      return null;
    }
  }

  String? getPrevChapterId(String id) {
    final match = RegExp(r'^(.*?/chapter-)(\d+(\.\d+)?)$').firstMatch(id);
    if (match == null) return null;

    final prefix = match.group(1)!;
    final double chapNum = double.parse(match.group(2)!);

    if (chapNum > 1) {
      return '$prefix${(chapNum - 1).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}';
    } else {
      return null;
    }
  }

  Future<String> descrambleImage(String url, int key) async {
    // final response = await http.get(Uri.parse(url));
    // final img.Image? image = img.decodeImage(response.bodyBytes);

    // if (image == null) {
    //   throw Exception('Failed to decode image');
    // }

    // final tileWidth = (image.width / 5).ceil();
    // final tileHeight = (image.height / 5).ceil();
    // final newImage = img.Image(width: image.width, height: image.height);

    // for (int y = 0; y < (image.height / tileHeight).ceil(); y++) {
    //   for (int x = 0; x < (image.width / tileWidth).ceil(); x++) {
    //     int tileX = x;
    //     int tileY = y;

    //     if (x < (image.width / tileWidth).ceil()) {
    //       tileX = ((image.width / tileWidth).ceil() - x + key) %
    //           (image.width / tileWidth).ceil();
    //     }

    //     if (y < (image.height / tileHeight).ceil()) {
    //       tileY = ((image.height / tileHeight).ceil() - y + key) %
    //           (image.height / tileHeight).ceil();
    //     }

    //     final pixel = image.getPixel(tileX * tileWidth, tileY * tileHeight);
    //     newImage.setPixel(x * tileWidth, y * tileHeight, pixel);
    //   }
    // }

    // final base64Data = base64Encode(img.encodePng(newImage));
    return url;
  }

  @override
  String get baseUrl => url;

  @override
  Future<dynamic> mapToAnilist(String id, {int page = 1}) async {
    final mangaList = await fetchMangaSearchResults(id);
    String bestMatchId = findBestMatch(id, mangaList);
    if (bestMatchId.isNotEmpty) {
      return await fetchMangaChapters(bestMatchId);
    } else {
      throw Exception('No suitable match found for the query');
    }
  }

  @override
  String get sourceName => 'MangaFire';

  @override
  String get sourceVersion => 'v1.0';
}
