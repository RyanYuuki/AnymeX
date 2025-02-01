import 'package:anymex/models/Media/media.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class BaseService {
  RxList<Widget> get homeWidgets;
  RxList<Widget> get animeWidgets;
  RxList<Widget> get mangaWidgets;
  Future<Media> fetchDetails(dynamic id);
  Future<void> fetchHomePage();
  Future<List<Media>> search(String query,
      {bool isManga = false, Map<String, dynamic>? filters});
}
