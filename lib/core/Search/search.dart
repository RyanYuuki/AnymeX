import 'dart:convert';

import 'package:anymex/core/Eval/dart/model/m_manga.dart';

import '../Eval/dart/model/filter.dart';
import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<List<MManga?>>? search(
    {required Source source,
    required String query,
    required int page,
    required List<dynamic> filterList}) async {
  List<MManga>? manga;
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    manga = (await DartExtensionService(source).search(query, page, filterList))
        .list;
  } else {
    manga = (await JsExtensionService(source).search(
            query, page, jsonEncode(filterValuesListToJson(filterList))))
        .list;
  }
  return manga;
}
