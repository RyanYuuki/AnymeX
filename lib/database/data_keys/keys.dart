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
  writeLogToFile,
  customLogDirectory,
  imageCacheThresholdGb,
  libraryGridAutoMigrated,
  showCommunityRecommendations,
  hideNsfwRecommendations,
  filterByListEnabled,
  filterCompleted,
  filterWatching,
  filterDropped,
  filterPlanning,
  filterPaused,
  filterRepeating,
  communityListViewIsGrid,
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
  playerExperimentalEnabled,
  bottomControlsSettings,
  playerControlTheme,
  playerControlThemesJson,
  mediaIndicatorTheme,
  mpvCoreSettings,
  betterPlayerCoreSettings,
  mpvVisualSettings,
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
  customBrightnessEnabled,
  customBrightnessValue,
  colorFilterEnabled,
  colorFilterValue,
  colorFilterMode,
  grayscaleEnabled,
  invertColorsEnabled,
  readerTheme,
  keepScreenOn,
  alwaysShowChapterTransition,
  longPressPageActionsEnabled,
  autoWebtoonMode,
  displayRefreshEnabled,
  displayRefreshDurationMs,
  displayRefreshInterval,
  displayRefreshColor,
}

enum NovelReaderKeys {
  themeMode,
  backgroundOpacity,
  fontSize,
  lineHeight,
  letterSpacing,
  wordSpacing,
  paragraphSpacing,
  fontFamily,
  textAlign,
  paddingHorizontal,
  paddingVertical,
  autoScroll,
  autoScrollSpeed,
  volumeScrolling,
  tapToScroll,
  keepScreenOn,
  verticalSeekbar,
  swipeGestures,
  pageReader,
  showReadingProgress,
  showBatteryTime,
  ttsSpeed,
  ttsPitch,
  ttsVoice,
  ttsAutoAdvance,
  ttsEnabled,
  overscrollToChapter,
}

enum LocalSourceKeys {
  watchOfflinePath,
  watchOfflinePathHistory,
  watchOfflineDownloadPath,
  watchOfflineDownloadPathHistory,
}

enum ServiceKeys { serviceType }

enum SyncKeys {
  gistGithubToken,
  gistGithubUsername,
  gistAutoDeleteCompleted,
  gistExitSyncNotifications,
}

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
  animeExtensionOrder,
  mangaExtensionOrder,
  novelExtensionOrder,
}

enum PluginKeys {
  runtimeHostInstalledVersion,
  runtimeHostInstalledReleaseTitle,
  bridgeMode,
}

enum AuthKeys {
  authToken,
  malAuthToken,
  malRefreshToken,
  simklAuthToken,
  malSessionId,
}

enum SearchKeys { novelSearchedQueries }

enum LibraryKeys { libraryLastType }

enum TapZoneKeys {
  tapZonesPaged,
  tapZonesPagedVertical,
  tapZonesWebtoon,
  tapZonesWebtoonHorizontal,
  tapZonesEnabled,
  tapZonesActiveIsWebtoon,
  tapZonesActiveIsVertical,
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
  offlineVideoProgress,
  stickySource;

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
  autoSkipRecap,
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
  playerMenuAnimation,
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
  showContinueWatchingCard,
}

enum DownloadKeys {
  downloadPath,
  concurrentDownloads,
  saveActiveTasks,
  downloadChunks,
  hlsParallelSegments,
  enableJxlCompression,
}

