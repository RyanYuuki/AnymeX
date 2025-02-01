import 'dart:async';
import 'dart:developer';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/core/Eval/dart/service.dart';
import 'package:anymex/core/Eval/javascript/service.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<(List<Video>, bool, List<String>)> getVideoList(
    {required MManga anime, required Source source}) async {
  List<Video> list = [];
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    list = await DartExtensionService(source).getVideoList(anime.link!);
  } else {
    list = await JsExtensionService(source).getVideoList(anime.link!);
  }
  List<Video> videos = [];
  for (var video in list) {
    final index = list.indexOf(video);
    log(index.toString());
    if (!videos.any((element) => element.quality == video.quality)) {
      videos.add(video);
    }
  }
  return (videos, false, [""]);
}
