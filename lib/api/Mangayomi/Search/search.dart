import 'dart:convert';

import '../Eval/dart/model/filter.dart';
import '../Eval/dart/model/m_pages.dart';
import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<MPages?> search(
    {required Source source,
    required String query,
    required int page,
    required List<dynamic> filterList}) async {
  MPages? manga;
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    manga = await DartExtensionService(source).search(query, page, filterList);
  } else {
    manga = await JsExtensionService(source)
        .search(query, page, jsonEncode(filterValuesListToJson(filterList)));
  }
  return manga;
}
