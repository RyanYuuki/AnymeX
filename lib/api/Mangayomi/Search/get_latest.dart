import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<List<MManga>?> getLatest({required Source source, int page = 1}) async {
  List<MManga>? manga;
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    manga = (await DartExtensionService(source).getLatestUpdates(page)).list;
  } else {
    manga = (await JsExtensionService(source).getLatestUpdates(page)).list;
  }
  return manga;
}
