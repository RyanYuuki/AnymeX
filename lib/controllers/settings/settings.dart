import 'dart:convert';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/models/ui/ui_adaptor.dart';
import 'package:anymex/screens/onboarding/welcome_dialog.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/updater.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final settingsController = Get.put(Settings());

class Settings extends GetxController {
  late Rx<UISettings> uiSettings;
  late Rx<PlayerSettings> playerSettings;
  final canShowUpdate = true.obs;
  final playerControlThemeRx = 'default'.obs;
  final mediaIndicatorThemeRx = 'default'.obs;
  final readerControlThemeRx = 'default'.obs;

  RxBool enableBetaUpdates = false.obs;

  RxBool isTV = false.obs;
  final _selectedShader = ''.obs;
  final _selectedProfile = 'MID-END'.obs;
  final mpvPath = ''.obs;

  String get selectedShader => _selectedShader.value;

  set selectedShader(String value) {
    _selectedShader.value = value;
    PlayerUiKeys.selectedShaderLegacy.set(value);
  }

  String get selectedProfile => _selectedProfile.value;

  set selectedProfile(String value) {
    _selectedProfile.value = value;
    PlayerUiKeys.selectedProfile.set(value);
  }

  @override
  void onInit() {
    super.onInit();

    playerSettings = Rx<PlayerSettings>(PlayerSettings.fromDB());
    uiSettings = Rx<UISettings>(UISettings.fromDB());
    uiSettings.value.normalizeMaps();

    selectedShader = PlayerUiKeys.selectedShaderLegacy.get<String>("");
    selectedProfile = PlayerUiKeys.selectedProfile.get<String>("MID-END");
    playerControlThemeRx.value =
        PlayerUiKeys.playerControlTheme.get<String>('default');
    mediaIndicatorThemeRx.value =
        PlayerUiKeys.mediaIndicatorTheme.get<String>('default');
    readerControlThemeRx.value =
        ReaderKeys.readerControlTheme.get<String>('default');

    enableBetaUpdates.value = General.enableBetaUpdates.get<bool>(false);

    isTv().then((e) {
      isTV.value = e;
    });
    PlayerShaders.createMpvConfigFolder();
    PlayerShaders.getMpvPath().then((e) {
      mpvPath.value = e;
    });
  }

  void checkForUpdates(BuildContext context) {
    UpdateManager().checkForUpdates(
      context,
      RxBool(true),
      isBeta: enableBetaUpdates.value,
    );
  }

  void saveBetaUpdateToggle(bool value) {
    enableBetaUpdates.value = value;
    General.enableBetaUpdates.set(value);
  }

  void showWelcomeDialog(BuildContext context) {
    if (General.isFirstTime.get<bool>(true)) {
      showWelcomeDialogg(context);
    }
  }

  T _getUISetting<T>(T Function(UISettings settings) getter) {
    return getter(uiSettings.value);
  }

  T _getPlayerSetting<T>(T Function(PlayerSettings settings) getter) {
    return getter(playerSettings.value);
  }

  bool get usePosterColor => _getUISetting((s) => s.usePosterColor);
  set usePosterColor(bool value) {
    uiSettings.update((s) => s?.usePosterColor = value);
    UISettingsKeys.usePosterColor.set(value);
  }

  bool get liquidMode => _getUISetting((s) => s.liquidMode);
  set liquidMode(bool value) {
    uiSettings.update((s) => s?.liquidMode = value);
    UISettingsKeys.liquidMode.set(value);
  }

  bool get retainOriginalColor => _getUISetting((s) => s.retainOriginalColor);
  set retainOriginalColor(bool value) {
    uiSettings.update((s) => s?.retainOriginalColor = value);
    UISettingsKeys.retainOriginalColor.set(value);
  }

  String get liquidBackgroundPath =>
      _getUISetting((s) => s.liquidBackgroundPath);
  set liquidBackgroundPath(String value) {
    uiSettings.update((s) => s?.liquidBackgroundPath = value);
    UISettingsKeys.liquidBackgroundPath.set(value);
  }

  bool get transculentBar => _getUISetting((s) => s.translucentTabBar);
  set transculentBar(bool value) {
    uiSettings.update((s) => s?.translucentTabBar = value);
    UISettingsKeys.translucentTabBar.set(value);
  }

  int get cardStyle => _getUISetting((s) => s.cardStyle);
  set cardStyle(int value) {
    uiSettings.update((s) => s?.cardStyle = value);
    UISettingsKeys.cardStyle.set(value);
  }

  int get historyCardStyle => _getUISetting((s) => s.historyCardStyle);
  set historyCardStyle(int value) {
    uiSettings.update((s) => s?.historyCardStyle = value);
    UISettingsKeys.historyCardStyle.set(value);
  }

  int get carouselStyle => _getUISetting((s) => s.carouselStyle);
  set carouselStyle(int value) {
    uiSettings.update((s) => s?.carouselStyle = value);
    UISettingsKeys.carouselStyle.set(value);
  }

  int get episodeListLayout => _getUISetting((s) => s.episodeListLayout);
  set episodeListLayout(int value) {
    final clamped = value.clamp(0, 2).toInt();
    uiSettings.update((s) => s?.episodeListLayout = clamped);
    UISettingsKeys.episodeListLayout.set(clamped);
  }

  double get glowDensity => _getUISetting((s) => s.glowDensity);
  set glowDensity(double value) {
    uiSettings.update((s) => s?.glowDensity = value);
    UISettingsKeys.glowDensity.set(value);
  }

  bool get enableAnimation => _getUISetting((s) => s.enableAnimation);
  set enableAnimation(bool value) {
    uiSettings.update((s) => s?.enableAnimation = value);
    UISettingsKeys.enableAnimation.set(value);
  }

  bool get disableGradient => _getUISetting((s) => s.disableGradient);
  set disableGradient(bool value) {
    uiSettings.update((s) => s?.disableGradient = value);
    UISettingsKeys.disableGradient.set(value);
  }

  Map<String, bool> get homePageCards => _getUISetting((s) => s.homePageCards);
  Map<String, bool> get homePageCardsMal =>
      _getUISetting((s) => s.homePageCardsMal);

  double get glowMultiplier => _getUISetting((s) => s.glowMultiplier);
  set glowMultiplier(double value) {
    uiSettings.update((s) => s?.glowMultiplier = value);
    UISettingsKeys.glowMultiplier.set(value);
  }

  double get radiusMultiplier => _getUISetting((s) => s.radiusMultiplier);
  set radiusMultiplier(double value) {
    uiSettings.update((s) => s?.radiusMultiplier = value);
    UISettingsKeys.radiusMultiplier.set(value);
  }

  double get blurMultiplier => _getUISetting((s) => s.blurMultipler);
  set blurMultiplier(double value) {
    uiSettings.update((s) => s?.blurMultipler = value);
    UISettingsKeys.blurMultipler.set(value);
  }

  double get cardRoundness => _getUISetting((s) => s.cardRoundness);
  set cardRoundness(double value) {
    uiSettings.update((s) => s?.cardRoundness = value);
    UISettingsKeys.cardRoundness.set(value);
  }

  bool get saikouLayout => _getUISetting((s) => s.saikouLayout);
  set saikouLayout(bool value) {
    uiSettings.update((s) => s?.saikouLayout = value);
    UISettingsKeys.saikouLayout.set(value);
  }

  bool get enablePosterKenBurns => _getUISetting((s) => s.enablePosterKenBurns);
  set enablePosterKenBurns(bool value) {
    uiSettings.update((s) => s?.enablePosterKenBurns = value);
    UISettingsKeys.enablePosterKenBurns.set(value);
  }

  double get tabBarHeight => _getUISetting((s) => s.tabBarHeight);
  set tabBarHeight(double value) {
    uiSettings.update((s) => s?.tabBarHeight = value);
    UISettingsKeys.tabBarHeight.set(value);
  }

  double get tabBarWidth => _getUISetting((s) => s.tabBarWidth);
  set tabBarWidth(double value) {
    uiSettings.update((s) => s?.tabBarWidth = value);
    UISettingsKeys.tabBarWidth.set(value);
  }

  double get tabBarRoundness => _getUISetting((s) => s.tabBarRoundness);
  set tabBarRoundness(double value) {
    uiSettings.update((s) => s?.tabBarRoundness = value);
    UISettingsKeys.tabBarRoundness.set(value);
  }

  bool get compactCards => _getUISetting((s) => s.compactCards);
  set compactCards(bool value) {
    uiSettings.update((s) => s?.compactCards = value);
    UISettingsKeys.compactCards.set(value);
  }

  int get animationDuration => _getUISetting((s) => s.animationDuration);
  set animationDuration(int value) {
    uiSettings.update((s) => s?.animationDuration = value);
    UISettingsKeys.animationDuration.set(value);
  }

  bool get defaultPortraitMode =>
      _getPlayerSetting((s) => s.defaultPortraitMode);
  set defaultPortraitMode(bool value) {
    playerSettings.update((s) => s?.defaultPortraitMode = value);
    PlayerSettingsKeys.defaultPortraitMode.set(value);
  }

  double get speed => _getPlayerSetting((s) => s.speed);
  set speed(double value) {
    playerSettings.update((s) => s?.speed = value);
    PlayerSettingsKeys.speed.set(value);
  }

  String get resizeMode => _getPlayerSetting((s) => s.resizeMode);
  set resizeMode(String value) {
    playerSettings.update((s) => s?.resizeMode = value);
    PlayerSettingsKeys.resizeMode.set(value);
  }

  bool get showSubtitle => _getPlayerSetting((s) => s.showSubtitle);
  set showSubtitle(bool value) {
    playerSettings.update((s) => s?.showSubtitle = value);
    PlayerSettingsKeys.showSubtitle.set(value);
  }

  int get subtitleSize => _getPlayerSetting((s) => s.subtitleSize);
  set subtitleSize(int value) {
    playerSettings.update((s) => s?.subtitleSize = value);
    PlayerSettingsKeys.subtitleSize.set(value);
  }

  String get subtitleColor => _getPlayerSetting((s) => s.subtitleColor);
  set subtitleColor(String value) {
    playerSettings.update((s) => s?.subtitleColor = value);
    PlayerSettingsKeys.subtitleColor.set(value);
  }

  String get subtitleFont => _getPlayerSetting((s) => s.subtitleFont);
  set subtitleFont(String value) {
    playerSettings.update((s) => s?.subtitleFont = value);
    PlayerSettingsKeys.subtitleFont.set(value);
  }

  String get subtitleBackgroundColor =>
      _getPlayerSetting((s) => s.subtitleBackgroundColor);
  set subtitleBackgroundColor(String value) {
    playerSettings.update((s) => s?.subtitleBackgroundColor = value);
    PlayerSettingsKeys.subtitleBackgroundColor.set(value);
  }

  String get subtitleOutlineColor =>
      _getPlayerSetting((s) => s.subtitleOutlineColor);
  set subtitleOutlineColor(String value) {
    playerSettings.update((s) => s?.subtitleOutlineColor = value);
    PlayerSettingsKeys.subtitleOutlineColor.set(value);
  }

  int get skipDuration => _getPlayerSetting((s) => s.skipDuration);
  set skipDuration(int value) {
    playerSettings.update((s) => s?.skipDuration = value);
    PlayerSettingsKeys.skipDuration.set(value);
  }

  int get seekDuration => _getPlayerSetting((s) => s.seekDuration);
  set seekDuration(int value) {
    playerSettings.update((s) => s?.seekDuration = value);
    PlayerSettingsKeys.seekDuration.set(value);
  }

  bool get transitionSubtitle => _getPlayerSetting((s) => s.transitionSubtitle);
  set transitionSubtitle(bool value) {
    playerSettings.update((s) => s?.transitionSubtitle = value);
    PlayerSettingsKeys.transitionSubtitle.set(value);
  }

  double get bottomMargin => _getPlayerSetting((s) => s.bottomMargin);
  set bottomMargin(double value) {
    playerSettings.update((s) => s?.bottomMargin = value);
    PlayerSettingsKeys.bottomMargin.set(value);
  }

  int get playerStyle => _getPlayerSetting((s) => s.playerStyle);
  set playerStyle(int value) {
    playerSettings.update((s) => s?.playerStyle = value);
    PlayerSettingsKeys.playerStyle.set(value);
  }

  String get playerControlTheme => playerControlThemeRx.value;
  set playerControlTheme(String value) {
    playerControlThemeRx.value = value;
    PlayerUiKeys.playerControlTheme.set(value);
  }

  String get mediaIndicatorTheme => mediaIndicatorThemeRx.value;
  set mediaIndicatorTheme(String value) {
    mediaIndicatorThemeRx.value = value;
    PlayerUiKeys.mediaIndicatorTheme.set(value);
  }

  String get readerControlTheme => readerControlThemeRx.value;
  set readerControlTheme(String value) {
    readerControlThemeRx.value = value;
    ReaderKeys.readerControlTheme.set(value);
  }

  int get subtitleOutlineWidth =>
      _getPlayerSetting((s) => s.subtitleOutlineWidth);
  set subtitleOutlineWidth(int value) {
    playerSettings.update((s) => s?.subtitleOutlineWidth = value);
    PlayerSettingsKeys.subtitleOutlineWidth.set(value);
  }

  bool get autoSkipOP => _getPlayerSetting((s) => s.autoSkipOP);
  set autoSkipOP(bool value) {
    playerSettings.update((s) => s?.autoSkipOP = value);
    PlayerSettingsKeys.autoSkipOP.set(value);
  }

  bool get autoSkipED => _getPlayerSetting((s) => s.autoSkipED);
  set autoSkipED(bool value) {
    playerSettings.update((s) => s?.autoSkipED = value);
    PlayerSettingsKeys.autoSkipED.set(value);
  }

  bool get autoSkipOnce => _getPlayerSetting((s) => s.autoSkipOnce);
  set autoSkipOnce(bool value) {
    playerSettings.update((s) => s?.autoSkipOnce = value);
    PlayerSettingsKeys.autoSkipOnce.set(value);
  }

  bool get autoSkipFiller => _getPlayerSetting((s) => s.autoSkipFiller);
  set autoSkipFiller(bool value) {
    playerSettings.update((s) => s?.autoSkipFiller = value);
    PlayerSettingsKeys.autoSkipFiller.set(value);
  }

  bool get enableScreenshot => _getPlayerSetting((s) => s.enableScreenshot);
  set enableScreenshot(bool value) {
    playerSettings.update((s) => s?.enableScreenshot = value);
    PlayerSettingsKeys.enableScreenshot.set(value);
  }

  bool get enableSwipeControls =>
      _getPlayerSetting((s) => s.enableSwipeControls);
  set enableSwipeControls(bool value) {
    playerSettings.update((s) => s?.enableSwipeControls = value);
    PlayerSettingsKeys.enableSwipeControls.set(value);
  }

  int get markAsCompleted => _getPlayerSetting((s) => s.markAsCompleted);
  set markAsCompleted(int value) {
    playerSettings.update((s) => s?.markAsCompleted = value);
    PlayerSettingsKeys.markAsCompleted.set(value);
  }

  void updateHomePageCard(String key, bool value) {
    final currentCards = Map<String, bool>.from(uiSettings.value.homePageCards);
    currentCards[key] = value;
    uiSettings.update((s) => s?.homePageCards = currentCards);
    UISettingsKeys.homePageCards.set(jsonEncode(currentCards));
  }

  void updateHomePageCardMal(String key, bool value) {
    final currentCards =
        Map<String, bool>.from(uiSettings.value.homePageCardsMal);
    currentCards[key] = value;
    uiSettings.update((s) => s?.homePageCardsMal = currentCards);
    UISettingsKeys.homePageCardsMal.set(jsonEncode(currentCards));
  }
}
