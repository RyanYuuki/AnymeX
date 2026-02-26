import 'package:anymex/database/kv_helper.dart';

export 'package:anymex/database/kv_helper.dart';

enum General {
  shouldAskForTrack,
  hideAdultContent,
  uiScaler,
  isFirstTime,
  hasAcceptedCommentRules,
  universalScrapper,
  enableBetaUpdates,
  imageCacheThresholdGb,
}

enum ThemeKeys {
  isLightMode,
  isSystemMode,
  isOled,
  selectedVariantIndex,
  themeMode,
  customColorIndex,
  logoAnimationType,
}

enum PlayerKeys { useLibass, useMediaKit }

enum PlayerUiKeys {
  bottomControlsSettings,
  playerControlTheme,
  playerControlThemesJson,
  mediaIndicatorTheme,
  currentVisualProfile,
  currentVisualSettings,
  selectedShader,
  selectedShaderLegacy,
  selectedProfile,
  shadersEnabled,
  cacheDays,
}

enum ReaderKeys {
  readerControlTheme,
  readingLayout,
  readingDirection,
  imageWidth,
  scrollSpeed,
  spacedPages,
  overscrollToChapter,
  preloadPages,
  showPageIndicator,
  cropImages,
  volumeKeysEnabled,
  invertVolumeKeys,
  dualPageMode,
  autoScrollEnabled,
  autoScrollSpeed,
}

enum LocalSourceKeys {
  watchOfflinePath,
  watchOfflinePathHistory,
  watchOfflineDownloadPath,
  watchOfflineDownloadPathHistory,
}

enum ServiceKeys { serviceType }

enum SourceKeys {
  activeAnimeRepo,
  activeMangaRepo,
  activeNovelRepo,
  activeAniyomiAnimeRepo,
  activeAniyomiMangaRepo,
  extensionsServiceAllowed,
  activeSourceId,
  activeMangaSourceId,
  activeNovelSourceId,
}

enum AuthKeys {
  authToken,
  malAuthToken,
  malRefreshToken,
  simklAuthToken,
  malSessionId,
  // Kitsu Auth Keys
  kitsuAuthToken,
  kitsuRefreshToken,
  kitsuTokenCreatedAt,
  kitsuTokenExpiresIn,
}

enum SearchKeys { novelSearchedQueries }

enum LibraryKeys { libraryLastType }

enum TapZoneKeys {
  tapZonesPaged,
  tapZonesPagedVertical,
  tapZonesWebtoon,
  tapZonesWebtoonHorizontal,
  tapZonesEnabled,
}

enum DynamicKeys {
  trackingPermission,
  watchProgress,
  customSetting,
  searchHistory,
  libraryLastListIndex,
  librarySortType,
  librarySortOrder,
  libraryGridSize,
  mappedMediaTitle,
  offlineVideoProgress;

  T get<T>(dynamic id, [T? defaultValue]) {
    return KvHelper.get<T>('${name}_$id', defaultVal: defaultValue);
  }

  void set<T>(dynamic id, T value) {
    KvHelper.set('${name}_$id', value);
  }

  void delete(dynamic id) {
    KvHelper.remove('${name}_$id');
  }
}

enum PlayerSettingsKeys {
  speed,
  resizeMode,
  showSubtitle,
  subtitleSize,
  subtitleColor,
  subtitleFont,
  subtitleBackgroundColor,
  subtitleOutlineColor,
  skipDuration,
  seekDuration,
  bottomMargin,
  transculentControls,
  defaultPortraitMode,
  playerStyle,
  subtitleOutlineWidth,
  autoSkipOP,
  autoSkipED,
  autoSkipOnce,
  enableSwipeControls,
  markAsCompleted,
  transitionSubtitle,
  autoTranslate,
  translateTo,
  autoSkipFiller,
  enableScreenshot,
  subtitleOpacity,
  subtitleBottomMargin,
  subtitleOutlineType,
}

enum UISettingsKeys {
  glowMultiplier,
  radiusMultiplier,
  saikouLayout,
  tabBarHeight,
  tabBarWidth,
  tabBarRoundness,
  compactCards,
  cardRoundness,
  blurMultipler,
  animationDuration,
  translucentTabBar,
  glowDensity,
  homePageCards,
  enableAnimation,
  disableGradient,
  homePageCardsMal,
  cardStyle,
  historyCardStyle,
  liquidMode,
  liquidBackgroundPath,
  retainOriginalColor,
  usePosterColor,
  enablePosterKenBurns,
  carouselStyle,
}
