import 'package:anymex/core/Eval/dart/model/page.dart';
import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<List<PageUrl>?> getPagesList(
    {required Source source, required String mangaId}) async {
  List<PageUrl>? manga;
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    manga = await DartExtensionService(source).getPageList(mangaId);
  } else {
    manga = await JsExtensionService(source).getPageList(mangaId);
  }
  return manga;
}
