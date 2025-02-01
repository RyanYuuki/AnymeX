import '../Eval/dart/model/m_manga.dart';
import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<List<MManga>?> getPopular({
  int page = 1,
  required Source source,
}) async {
  List<MManga>? mangaDetail;
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    mangaDetail = (await DartExtensionService(source).getPopular(1)).list;
  } else {
    mangaDetail = (await JsExtensionService(source).getPopular(1)).list;
  }
  return mangaDetail;
}
