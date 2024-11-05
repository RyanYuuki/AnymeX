import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

Future<dynamic> scrapeNovelsHomePage() async {
  String url = 'https://novelbuddy.com/popular?status=completed';
  var dio = Dio();

  try {
    Response response = await dio.get(url);
    if (response.statusCode == 200) {
      Document document = parse(response.data);
      List<Map<String, dynamic>> novelsData = [];

      var novelItems = document.querySelectorAll('.book-item');

      for (var novelItem in novelItems) {
        var link = novelItem.querySelector('h3 a')?.attributes['href'];
        var title = novelItem.querySelector('h3 a')?.text ?? 'No title';
        novelItem.querySelector('.rating .score i')?.remove();
        var rating =
            novelItem.querySelector('.rating .score')?.text ?? 'No rating';
        var summary =
            novelItem.querySelector('.summary p')?.text ?? 'No summary';
        var image = novelItem.querySelector('.thumb a img')?.attributes['data-src'];

        Map<String, dynamic> novelData = {
          'id': 'https://novelbuddy.com$link',
          'title': title,
          'image': 'https:$image',
          'description': summary,
          'rating': (double.parse(rating) * 2).toString(),
        };
        novelsData.add(novelData);
      }
      log(novelsData.toString());
      return novelsData;
    } else {
      log('Failed to load the page, status code: ${response.statusCode}');
    }
  } catch (e) {
    log('Error: $e');
  }
}
