import '../Eval/dart/service.dart';
import '../Eval/javascript/service.dart';
import '../Model/Source.dart';

Future<String?> getNovelWords(
    {required Source source, required String mangaId}) async {
  String? manga;
  if (source.sourceCodeLanguage == SourceCodeLanguage.dart) {
    manga = await DartExtensionService(source).getHtmlContent(mangaId);
  } else {
    manga = await JsExtensionService(source).getHtmlContent(mangaId);
  }
  return manga;
}
