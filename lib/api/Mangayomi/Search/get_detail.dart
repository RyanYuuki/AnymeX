import '../Eval/dart/model/m_manga.dart';
import '../Model/Source.dart';
import '../lib.dart';

Future<MManga> getDetail({
  required String url,
  required Source source,
}) async {
  return getExtensionService(source).getDetail(url);
}
