import 'dart:convert';

import 'package:anymex/database/data_keys/keys.dart';

class UISettings {
  double glowMultiplier;
  double radiusMultiplier;
  bool saikouLayout;
  double tabBarHeight;
  double tabBarWidth;
  double tabBarRoundness;
  bool compactCards;
  double cardRoundness;
  double blurMultipler;
  int animationDuration;
  bool translucentTabBar;
  double glowDensity;
  Map<String, bool> homePageCards;
  bool enableAnimation;
  bool disableGradient;
  Map<String, bool> homePageCardsMal;
  Map<String, bool> homePageCardsSimkl;
  int cardStyle;
  int historyCardStyle;
  bool liquidMode;
  String liquidBackgroundPath;
  bool retainOriginalColor;
  bool usePosterColor;
  bool enablePosterKenBurns;
  int carouselStyle;
  bool useLegacyHeader;
  bool useGrainTexture;
  double grainIntensity;
  bool enableImmersiveMode;
  int navBarStyle;
  String appFontFamily;
  double bottomNavBarMargin;
  bool useLegacyNavbar;

  UISettings({
    this.glowMultiplier = 1.0,
    this.radiusMultiplier = 1.0,
    this.saikouLayout = false,
    this.tabBarHeight = 50.0,
    this.tabBarWidth = 180.0,
    this.tabBarRoundness = 10.0,
    this.compactCards = false,
    this.cardRoundness = 1.0,
    this.blurMultipler = 1.0,
    this.animationDuration = 200,
    this.glowDensity = 0.3,
    this.translucentTabBar = true,
    Map<String, bool>? homePageCards,
    Map<String, bool>? homePageCardsMal,
    Map<String, bool>? homePageCardsSimkl,
    this.enableAnimation = true,
    this.disableGradient = false,
    this.cardStyle = 0,
    this.historyCardStyle = 0,
    this.liquidMode = true,
    this.retainOriginalColor = false,
    this.liquidBackgroundPath = '',
    this.usePosterColor = false,
    this.enablePosterKenBurns = true,
    this.carouselStyle = 0,
    this.useLegacyHeader = false,
    this.useGrainTexture = false,
    this.grainIntensity = 0.05,
    this.enableImmersiveMode = false,
    this.navBarStyle = 1,
    this.appFontFamily = '',
    this.bottomNavBarMargin = 32.0,
    this.useLegacyNavbar = true,
  })  : homePageCards = homePageCards ??
            {
              "Continue Watching": true,
              "Continue Reading": true,
              "Completed TV": false,
              "Completed Manga": false,
              "Completed Movie": false,
              "Paused Animes": false,
              "Paused Manga": false,
              "Dropped Animes": false,
              "Dropped Manga": false,
              "Planning Animes": false,
              "Planning Manga": false,
              "Rewatching Animes": false,
              "Rewatching Manga": false,
            },
        homePageCardsMal = homePageCardsMal ??
            {
              "Continue Watching": true,
              "Continue Reading": true,
              "Completed TV": false,
              "Completed Manga": false,
              "Paused Animes": false,
              "Paused Manga": false,
              "Dropped Animes": false,
              "Dropped Manga": false,
              "Planning Animes": false,
              "Planning Manga": false,
            },
        homePageCardsSimkl = homePageCardsSimkl ??
            {
              "Continue Watching (Movies)": true,
              "Continue Watching (Shows)": true,
              "Completed Movies": false,
              "Completed Shows": false,
              "Paused Movies": false,
              "Paused Shows": false,
              "Dropped Movies": false,
              "Dropped Shows": false,
              "Planning Movies": false,
              "Planning Shows": false,
            };

  void normalizeMaps() {
    homePageCards = Map<String, bool>.from(homePageCards);
    homePageCards.putIfAbsent('Recommended Animes', () => true);
    homePageCards.putIfAbsent('Recommended Mangas', () => true);
    if (!homePageCards.values.any((v) => v)) {
      homePageCards['Recommended Animes'] = true;
      homePageCards['Recommended Mangas'] = true;
    }

    homePageCardsMal = Map<String, bool>.from(homePageCardsMal);
    homePageCardsMal.putIfAbsent('Recommended Animes', () => true);
    homePageCardsMal.putIfAbsent('Recommended Mangas', () => true);
    if (!homePageCardsMal.values.any((v) => v)) {
      homePageCardsMal['Recommended Animes'] = true;
      homePageCardsMal['Recommended Mangas'] = true;
    }

    homePageCardsSimkl = Map<String, bool>.from(homePageCardsSimkl);
    if (homePageCardsSimkl.isNotEmpty && !homePageCardsSimkl.values.any((v) => v)) {
      homePageCardsSimkl[homePageCardsSimkl.keys.first] = true;
    }
  }

  factory UISettings.fromDB() {
    final uiDefaults = UISettings();
    final homeCardsRaw = UISettingsKeys.homePageCards.get<String?>(null);
    final homeCardsMalRaw = UISettingsKeys.homePageCardsMal.get<String?>(null);
    final homeCardsSimklRaw =
        UISettingsKeys.homePageCardsSimkl.get<String?>(null);
    return UISettings(
      glowMultiplier:
          UISettingsKeys.glowMultiplier.get<double>(uiDefaults.glowMultiplier),
      radiusMultiplier: UISettingsKeys.radiusMultiplier
          .get<double>(uiDefaults.radiusMultiplier),
      saikouLayout:
          UISettingsKeys.saikouLayout.get<bool>(uiDefaults.saikouLayout),
      tabBarHeight:
          UISettingsKeys.tabBarHeight.get<double>(uiDefaults.tabBarHeight),
      tabBarWidth:
          UISettingsKeys.tabBarWidth.get<double>(uiDefaults.tabBarWidth),
      tabBarRoundness: UISettingsKeys.tabBarRoundness
          .get<double>(uiDefaults.tabBarRoundness),
      compactCards:
          UISettingsKeys.compactCards.get<bool>(uiDefaults.compactCards),
      cardRoundness:
          UISettingsKeys.cardRoundness.get<double>(uiDefaults.cardRoundness),
      blurMultipler:
          UISettingsKeys.blurMultipler.get<double>(uiDefaults.blurMultipler),
      animationDuration: UISettingsKeys.animationDuration
          .get<int>(uiDefaults.animationDuration),
      translucentTabBar: UISettingsKeys.translucentTabBar
          .get<bool>(uiDefaults.translucentTabBar),
      glowDensity:
          UISettingsKeys.glowDensity.get<double>(uiDefaults.glowDensity),
      homePageCards: homeCardsRaw != null
          ? Map<String, bool>.from(jsonDecode(homeCardsRaw))
          : null,
      enableAnimation:
          UISettingsKeys.enableAnimation.get<bool>(uiDefaults.enableAnimation),
      disableGradient:
          UISettingsKeys.disableGradient.get<bool>(uiDefaults.disableGradient),
      homePageCardsMal: homeCardsMalRaw != null
          ? Map<String, bool>.from(jsonDecode(homeCardsMalRaw))
          : null,
      homePageCardsSimkl: homeCardsSimklRaw != null
          ? Map<String, bool>.from(jsonDecode(homeCardsSimklRaw))
          : null,
      cardStyle: UISettingsKeys.cardStyle.get<int>(uiDefaults.cardStyle),
      historyCardStyle:
          UISettingsKeys.historyCardStyle.get<int>(uiDefaults.historyCardStyle),
      liquidMode: UISettingsKeys.liquidMode.get<bool>(uiDefaults.liquidMode),
      retainOriginalColor: UISettingsKeys.retainOriginalColor
          .get<bool>(uiDefaults.retainOriginalColor),
      liquidBackgroundPath: UISettingsKeys.liquidBackgroundPath
          .get<String>(uiDefaults.liquidBackgroundPath),
      usePosterColor:
          UISettingsKeys.usePosterColor.get<bool>(uiDefaults.usePosterColor),
      enablePosterKenBurns: UISettingsKeys.enablePosterKenBurns
          .get<bool>(uiDefaults.enablePosterKenBurns),
      carouselStyle:
          UISettingsKeys.carouselStyle.get<int>(uiDefaults.carouselStyle),
      useLegacyHeader:
          UISettingsKeys.useLegacyHeader.get<bool>(uiDefaults.useLegacyHeader),
      useGrainTexture:
          UISettingsKeys.useGrainTexture.get<bool>(uiDefaults.useGrainTexture),
      grainIntensity:
          UISettingsKeys.grainIntensity.get<double>(uiDefaults.grainIntensity),
      enableImmersiveMode: UISettingsKeys.enableImmersiveMode
          .get<bool>(uiDefaults.enableImmersiveMode),
      navBarStyle: UISettingsKeys.navBarStyle.get<int>(uiDefaults.navBarStyle),
      appFontFamily:
          UISettingsKeys.appFontFamily.get<String>(uiDefaults.appFontFamily),
      bottomNavBarMargin: UISettingsKeys.bottomNavBarMargin
          .get<double>(uiDefaults.bottomNavBarMargin),
      useLegacyNavbar: UISettingsKeys.useLegacyNavbar
          .get<bool>(uiDefaults.useLegacyNavbar),
    );
  }
}
