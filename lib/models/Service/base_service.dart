import 'package:anymex/models/Media/media.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class BaseService {
  RxList<Widget> homeWidgets(BuildContext context);
  RxList<Widget> animeWidgets(BuildContext context);
  RxList<Widget> mangaWidgets(BuildContext context);
  Future<Media> fetchDetails(dynamic id);
  Future<void> fetchHomePage();
  Future<List<Media>> search(String query,
      {bool isManga = false, Map<String, dynamic>? filters, dynamic args});
}
