import '../Eval/dart/model/m_manga.dart';
import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<MManga?> getDetail({
  required String url,
  required Source source,
}) async {
  MManga? mangaDetail;
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    mangaDetail = await DartExtensionService(source).getDetail(url);
  } else {
    mangaDetail = await JsExtensionService(source).getDetail(url);
  }
  return mangaDetail;
}
