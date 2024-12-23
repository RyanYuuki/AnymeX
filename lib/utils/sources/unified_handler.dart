import 'package:anymex/utils/sources/novel/handler/novel_sources_handler.dart';
import 'package:flutter/material.dart';

class UnifiedSourcesHandler extends ChangeNotifier {
  NovelSourcesHandler novelSourcesHandler = NovelSourcesHandler();
  UnifiedSourcesHandler();

  NovelSourcesHandler getNovelInstance() {
    return novelSourcesHandler;
  }
}
