import 'package:anymex/database/kv_helper.dart';
export 'package:anymex/database/kv_helper.dart';
export 'watchium_keys.dart';

enum General {
  shouldAskForTrack,
  hideAdultContent,
  searchIsAdult,
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
  hasJoinedNewDiscord,
  discordRpcEnabled,
  useHighRefreshRate,
  preferredDisplayMode,
  navigationTabOrder,
  useAlternateTitle,
  unifiedLibrary,
  joinDialogShowCount,
  wrongTitleIsCardView,
  showHomeContinueWatching,
  incognitoMode,
  dontShowDonationDialog,
  hasShownHomeDonationDialog,
  watchedAdsCount,
  appLanguageCode,
  appCountryCode,
}

enum ThemeKeys {
  isLightMode,
  isSystemMode,
  isOled,
  selectedVariantIndex,
  themeMode,
  customColorIndex,
  logoAnimationType,
  customHexColor,
  customLogos,
  selectedCustomLogoId,
}

enum PlayerKeys { useLibass, useMediaKit, useExternalPlayer, audioChannelLayout }

enum PlayerUiKeys {
  playerExperimentalEnabled,
  bottomControlsSettings,
  playerControlTheme,
  playerControlThemesJson,
  mediaIndicatorTheme,
  episodeStyle,
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
  useMpvConf,
  brightnessGestureWidth,
  volumeGestureWidth,
  progressSliderStyle,
  overrideSliderTheme,
}

enum ReaderKeys {
  readerControlTheme,
  chapterStyle,
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
  enhanceColorsEnabled,
  enhanceColorsProfile,
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
  imageFilterQuality,
  fitToScreen,
  navigateByNumber,
  upscalingEnabled,
  upscalerShader,
  upscalerProfile,
  upscalerSharpness,
  upscalerDenoise,
  customGlslShaders,
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

/// Namespaces novel reader preferences so they cannot collide with manga
/// reader keys or other settings that share the same enum value name.
extension NovelReaderKeyStorage on NovelReaderKeys {
  String get storageKey => 'novel_$name';

  T get<T>([T? defaultValue]) =>
      KvHelper.get<T>(storageKey, defaultVal: defaultValue);

  void set<T>(T value) => KvHelper.set(storageKey, value);

  Future<void> setAsync<T>(T value) => KvHelper.setAsync(storageKey, value);

  void delete() => KvHelper.remove(storageKey);

  Future<void> deleteAsync() => KvHelper.removeAsync(storageKey);
}

/// Moves novel reader preferences from the legacy unprefixed keys to the
/// novel-prefixed keys. Legacy values are only copied while the prefixed key
/// is still absent, so user changes made after the upgrade are preserved.
Future<void> migrateNovelReaderKeys() async {
  for (final key in NovelReaderKeys.values) {
    // Novel theme mode has always used its own prefixed key.
    if (key == NovelReaderKeys.themeMode) continue;
    if (KvHelper.containsKey(key.storageKey)) continue;
    if (!KvHelper.containsKey(key.name)) continue;

    final value = KvHelper.get<dynamic>(key.name);
    if (value == null) continue;
    await KvHelper.setAsync<dynamic>(key.storageKey, value);
  }
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
  extensionsEnabled,
}

enum PluginKeys {
  runtimeHostInstalledVersion,
  runtimeHostInstalledReleaseTitle,
  bridgeMode,
  useInternalExtensionLoading,
}

enum AuthKeys {
  authToken,
  malAuthToken,
  malRefreshToken,
  simklAuthToken,
  malSessionId,
  mangaBakaAuthToken,
}

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
  stickySource,
  stickyServer,
  trackBindings;

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
  defaultOrientation,
  playerStyle,
  subtitleOutlineWidth,
  autoSkipOP,
  autoSkipED,
  autoSkipOnce,
  autoSkipRecap,
  enableAniSkip,
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
  hardwareDecoder,
  preferredSubtitleLanguage,
  videoOutput,
  audioOutput,
  enableHoldToSeek,
  enableSlideToSeek,
  useMediaSession,
  subtitleBackgroundOpacity,
  relativeHoldSpeed,
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
  homePageCardsSimkl,
  cardStyle,
  historyCardStyle,
  liquidMode,
  liquidBackgroundPath,
  retainOriginalColor,
  usePosterColor,
  enablePosterKenBurns,
  carouselStyle,
  showContinueWatchingCard,
  useLegacyHeader,
  useGrainTexture,
  grainIntensity,
  enableImmersiveMode,
  navBarStyle,
  tileStyle,
  tileIconShape,
  appFontFamily,
  appFontScale,
  bottomNavBarMargin,
  useLegacyNavbar,
  useComputedBlur,
  fullScreenBlur,
  tintBlur,
  usePosterForBlur,
  detailsBlurAmount,
  detailsBackdropBrightness,
  detailsFadeAdjuster,
  detailsBlurStyle,
  detailsBlurScope,
  detailsOledMode,
  customCardStyleJson,
  episodeMetaOrder,
  episodeMetaDisabled,
  selectedEpisodeMetaSource,
  enableSeekPreview,
  seekPreviewFirstBootDetected,
}

enum DownloadKeys {
  downloadPath,
  concurrentDownloads,
  saveActiveTasks,
  downloadChunks,
  hlsParallelSegments,
  enableJxlCompression,
  hasSeenDownloadGuide,
}

enum DiscordRpcKeys {
  hideNsfw,
  showTimestamps,
  animeWatchingFormat,
  animeDetailsFormat,
  mangaReadingFormat,
  mangaDetailsFormat,
  novelReadingFormat,
  novelDetailsFormat,
  idleFormat,
}

enum CommentKeys {
  renderAvatarDecorations,
  renderNameplates,
  renderProfileEffects,
  renderBanners,
}

enum NetworkKeys {
  enableDoh,
  customDnsUrl,
  proxyUrl,
  verifyTls,
  customUserAgent,
  fetchedUserAgent,
}

