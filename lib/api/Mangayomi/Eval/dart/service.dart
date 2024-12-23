import 'package:anymex/api/Mangayomi/Eval/dart/runtime/runtime.dart';
import 'package:anymex/api/Mangayomi/Eval/javascript/http.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

import '../../Model/Source.dart';
import 'bridge/m_source.dart';
import 'compiler/compiler.dart';
import 'model/filter.dart';
import 'model/m_manga.dart';
import 'model/m_pages.dart';
import 'model/m_provider.dart';
import 'model/page.dart';
import 'model/source_preference.dart';
import 'model/video.dart';

class DartExtensionService {
  late Source? source;

  DartExtensionService(this.source);

  MProvider _executeLib() {
    final bytecode = compilerEval(source!.sourceCode!);

    final runtime = runtimeEval(bytecode);

    return runtime.executeLib('package:anymex/main.dart', 'main',
        [$MSource.wrap(source!.toMSource())]) as MProvider;
  }

  Map<String, String> getHeaders() {
    Map<String, String> headers = {};
    try {
      final bytecode = compilerEval(source!.sourceCode!);
      final runtime = runtimeEval(bytecode);
      runtime.args = [$String(source!.baseUrl!)];
      var res = runtime.executeLib(
        'package:anymex/main.dart',
        'getHeader',
      );
      if (res is $Map) {
        headers = (res.$reified).toMapStringString!;
      } else if (res is Map) {
        headers = res.toMapStringString!;
      } else {
        throw "";
      }
    } catch (_) {
      try {
        headers = _executeLib().headers;
      } catch (_) {
        return {};
      }
    }
    return headers;
  }

  String get sourceBaseUrl {
    String? baseUrl;
    try {
      baseUrl = _executeLib().baseUrl;
    } catch (e) {
      baseUrl = source!.baseUrl;
    }
    return baseUrl!;
  }

  bool get supportsLatest {
    bool? supportsLatest;
    try {
      supportsLatest = _executeLib().supportsLatest;
    } catch (e) {
      supportsLatest = true;
    }
    return supportsLatest;
  }

  Future<MPages> getPopular(int page) async {
    return await _executeLib().getPopular(page);
  }

  Future<MPages> getLatestUpdates(int page) async {
    return await _executeLib().getLatestUpdates(page);
  }

  Future<MPages> search(
      String query, int page, List<dynamic> filterList) async {
    return await _executeLib().search(query, page, FilterList(filterList));
  }

  Future<MManga> getDetail(String url) async {
    return await _executeLib().getDetail(url);
  }

  Future<List<PageUrl>> getPageList(String url) async {
    return (await _executeLib().getPageList(url))
        .map((e) => e is String
            ? PageUrl(e.toString().trim())
            : PageUrl.fromJson((e as Map).toMapStringDynamic!))
        .toList();
  }

  Future<List<Video>> getVideoList(String url) async {
    return await _executeLib().getVideoList(url);
  }

  List<dynamic> getFilterList() {
    return _executeLib()
        .getFilterList()
        .map((e) => e is $Value ? e.$reified : e)
        .toList();
  }

  List<SourcePreference> getSourcePreferences() {
    try {
      return _executeLib()
          .getSourcePreferences()
          .map((e) => (e is $Value ? e.$reified : e) as SourcePreference)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
