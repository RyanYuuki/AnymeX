import '../Eval/dart/model/m_pages.dart';
import '../Model/Source.dart';
import '../lib.dart';

Future<MPages?> search({
  required Source source,
  required String query,
  required int page,
  required List<dynamic> filterList,
}) async {
  return getExtensionService(source).search(query, page, filterList);
}
