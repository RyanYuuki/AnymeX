import 'package:anymex/utils/sources/anime/handler/sources_handler.dart';
import 'package:anymex/utils/sources/manga/handlers/manga_sources_handler.dart';
import 'package:anymex/utils/sources/novel/handler/novel_sources_handler.dart';
import 'package:flutter/material.dart';

class UnifiedSourcesHandler extends ChangeNotifier {
  SourcesHandler animeHandler = SourcesHandler();
  MangaSourceHandler mangaSourceHandler = MangaSourceHandler();
  NovelSourcesHandler novelSourcesHandler = NovelSourcesHandler();

  UnifiedSourcesHandler();

  SourcesHandler getAnimeInstance() {
    return animeHandler;
  }

  MangaSourceHandler getMangaInstance() {
    return mangaSourceHandler;
  }

  NovelSourcesHandler getNovelInstance() {
    return novelSourcesHandler;
  }
}
