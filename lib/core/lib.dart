import 'Eval/dart/service.dart';
import 'Eval/javascript/service.dart';
import 'Model/Source.dart';
import 'interface.dart';

ExtensionService getExtensionService(Source source) {
  return switch (source.sourceCodeLanguage) {
    SourceCodeLanguage.dart => DartExtensionService(source),
    SourceCodeLanguage.javascript => JsExtensionService(source),
  };
}
