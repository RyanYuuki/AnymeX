import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/models/ui/ui_adaptor.dart';
import 'package:anymex/screens/onboarding/welcome_dialog.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/updater.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

final settingsController = Get.put(Settings());

class Settings extends GetxController {
  late Rx<UISettings> uiSettings;
  late Rx<PlayerSettings> playerSettings;
  late Box preferences;
  final canShowUpdate = true.obs;
  RxBool isTV = false.obs;
  final _selectedShader = ''.obs;
  final _selectedProfile = 'MID-END'.obs;
  final mpvPath = ''.obs;

  String get selectedShader => _selectedShader.value;

  set selectedShader(String value) {
    _selectedShader.value = value;
    preferences.put('selected_shader', value);
  }

  String get selectedProfile => _selectedProfile.value;

  set selectedProfile(String value) {
    _selectedProfile.value = value;
    preferences.put('selected_profile', value);
  }

  @override
  void onInit() {
    super.onInit();
    var uiBox = Hive.box<UISettings>("UiSettings");
    var playerBox = Hive.box<PlayerSettings>("PlayerSettings");
    uiSettings = Rx<UISettings>(uiBox.get('settings') ?? UISettings());
    playerSettings =
        Rx<PlayerSettings>(playerBox.get('settings') ?? PlayerSettings());
    preferences = Hive.box('preferences');
    selectedShader = preferences.get('selected_shader', defaultValue: '');
    selectedProfile =
        preferences.get('selected_profile', defaultValue: 'MID-END');
    isTv().then((e) {
      isTV.value = e;
    });
    PlayerShaders.createMpvConfigFolder();
    PlayerShaders.getMpvPath().then((e) {
      mpvPath.value = e;
    });
  }

  void checkForUpdates(BuildContext context) {
    canShowUpdate.value
        ? UpdateManager().checkForUpdates(context, canShowUpdate)
        : null;
  }

  void showWelcomeDialog(BuildContext context) {
    if (Hive.box('themeData').get('isFirstTime', defaultValue: true)) {
      showWelcomeDialogg(context);
    }
  }

  T _getUISetting<T>(T Function(UISettings settings) getter) {
    return getter(uiSettings.value);
  }

  void _setUISetting<T>(void Function(UISettings? settings) setter) {
    uiSettings.update(setter);
    saveUISettings();
  }

  T _getPlayerSetting<T>(T Function(PlayerSettings settings) getter) {
    return getter(playerSettings.value);
  }

  void _setPlayerSetting<T>(void Function(PlayerSettings? settings) setter) {
    playerSettings.update(setter);
    savePlayerSettings();
  }

  bool get usePosterColor => _getUISetting((s) => s.usePosterColor);
  set usePosterColor(bool value) =>
      _setUISetting((s) => s?.usePosterColor = value);

  bool get liquidMode => _getUISetting((s) => s.liquidMode);
  set liquidMode(bool value) => _setUISetting((s) => s?.liquidMode = value);

  bool get retainOriginalColor => _getUISetting((s) => s.retainOriginalColor);
  set retainOriginalColor(bool value) =>
      _setUISetting((s) => s?.retainOriginalColor = value);

  String get liquidBackgroundPath =>
      _getUISetting((s) => s.liquidBackgroundPath);
  set liquidBackgroundPath(String value) =>
      _setUISetting((s) => s?.liquidBackgroundPath = value);

  bool get transculentBar => _getUISetting((s) => s.translucentTabBar);
  set transculentBar(bool value) =>
      _setUISetting((s) => s?.translucentTabBar = value);

  int get cardStyle => _getUISetting((s) => s.cardStyle);
  set cardStyle(int value) => _setUISetting((s) => s?.cardStyle = value);

  int get historyCardStyle => _getUISetting((s) => s.historyCardStyle);
  set historyCardStyle(int value) =>
      _setUISetting((s) => s?.historyCardStyle = value);

  double get glowDensity => _getUISetting((s) => s.glowDensity);
  set glowDensity(double value) => _setUISetting((s) => s?.glowDensity = value);

  bool get enableAnimation => _getUISetting((s) => s.enableAnimation);
  set enableAnimation(bool value) =>
      _setUISetting((s) => s?.enableAnimation = value);

  bool get disableGradient => _getUISetting((s) => s.disableGradient);
  set disableGradient(bool value) =>
      _setUISetting((s) => s?.disableGradient = value);

  Map<String, bool> get homePageCards => _getUISetting((s) => s.homePageCards);
  Map<String, bool> get homePageCardsMal =>
      _getUISetting((s) => s.homePageCardsMal);

  double get glowMultiplier => _getUISetting((s) => s.glowMultiplier);
  set glowMultiplier(double value) =>
      _setUISetting((s) => s?.glowMultiplier = value);

  double get radiusMultiplier => _getUISetting((s) => s.radiusMultiplier);
  set radiusMultiplier(double value) =>
      _setUISetting((s) => s?.radiusMultiplier = value);

  double get blurMultiplier => _getUISetting((s) => s.blurMultipler);
  set blurMultiplier(double value) =>
      _setUISetting((s) => s?.blurMultipler = value);

  double get cardRoundness => _getUISetting((s) => s.cardRoundness);
  set cardRoundness(double value) =>
      _setUISetting((s) => s?.cardRoundness = value);

  bool get saikouLayout => _getUISetting((s) => s.saikouLayout);
  set saikouLayout(bool value) => _setUISetting((s) => s?.saikouLayout = value);

  double get tabBarHeight => _getUISetting((s) => s.tabBarHeight);
  set tabBarHeight(double value) =>
      _setUISetting((s) => s?.tabBarHeight = value);

  double get tabBarWidth => _getUISetting((s) => s.tabBarWidth);
  set tabBarWidth(double value) => _setUISetting((s) => s?.tabBarWidth = value);

  double get tabBarRoundness => _getUISetting((s) => s.tabBarRoundness);
  set tabBarRoundness(double value) =>
      _setUISetting((s) => s?.tabBarRoundness = value);

  bool get compactCards => _getUISetting((s) => s.compactCards);
  set compactCards(bool value) => _setUISetting((s) => s?.compactCards = value);

  int get animationDuration => _getUISetting((s) => s.animationDuration);
  set animationDuration(int value) =>
      _setUISetting((s) => s?.animationDuration = value);

  // Player Settings
  bool get defaultPortraitMode =>
      _getPlayerSetting((s) => s.defaultPortraitMode);
  set defaultPortraitMode(bool value) =>
      _setPlayerSetting((s) => s?.defaultPortraitMode = value);

  double get speed => _getPlayerSetting((s) => s.speed);
  set speed(double value) => _setPlayerSetting((s) => s?.speed = value);

  String get resizeMode => _getPlayerSetting((s) => s.resizeMode);
  set resizeMode(String value) =>
      _setPlayerSetting((s) => s?.resizeMode = value);

  bool get showSubtitle => _getPlayerSetting((s) => s.showSubtitle);
  set showSubtitle(bool value) =>
      _setPlayerSetting((s) => s?.showSubtitle = value);

  int get subtitleSize => _getPlayerSetting((s) => s.subtitleSize);
  set subtitleSize(int value) =>
      _setPlayerSetting((s) => s?.subtitleSize = value);

  String get subtitleColor => _getPlayerSetting((s) => s.subtitleColor);
  set subtitleColor(String value) =>
      _setPlayerSetting((s) => s?.subtitleColor = value);

  String get subtitleFont => _getPlayerSetting((s) => s.subtitleFont);
  set subtitleFont(String value) =>
      _setPlayerSetting((s) => s?.subtitleFont = value);

  String get subtitleBackgroundColor =>
      _getPlayerSetting((s) => s.subtitleBackgroundColor);
  set subtitleBackgroundColor(String value) =>
      _setPlayerSetting((s) => s?.subtitleBackgroundColor = value);

  String get subtitleOutlineColor =>
      _getPlayerSetting((s) => s.subtitleOutlineColor);
  set subtitleOutlineColor(String value) =>
      _setPlayerSetting((s) => s?.subtitleOutlineColor = value);

  int get skipDuration => _getPlayerSetting((s) => s.skipDuration);
  set skipDuration(int value) =>
      _setPlayerSetting((s) => s?.skipDuration = value);

  int get seekDuration => _getPlayerSetting((s) => s.seekDuration);
  set seekDuration(int value) =>
      _setPlayerSetting((s) => s?.seekDuration = value);

  double get bottomMargin => _getPlayerSetting((s) => s.bottomMargin);
  set bottomMargin(double value) =>
      _setPlayerSetting((s) => s?.bottomMargin = value);

  int get playerStyle => _getPlayerSetting((s) => s.playerStyle);
  set playerStyle(int value) =>
      _setPlayerSetting((s) => s?.playerStyle = value);

  int get subtitleOutlineWidth =>
      _getPlayerSetting((s) => s.subtitleOutlineWidth);
  set subtitleOutlineWidth(int value) =>
      _setPlayerSetting((s) => s?.subtitleOutlineWidth = value);

  bool get autoSkipOP => _getPlayerSetting((s) => s.autoSkipOP);
  set autoSkipOP(bool value) => _setPlayerSetting((s) => s?.autoSkipOP = value);

  bool get autoSkipED => _getPlayerSetting((s) => s.autoSkipED);
  set autoSkipED(bool value) => _setPlayerSetting((s) => s?.autoSkipED = value);

  bool get autoSkipOnce => _getPlayerSetting((s) => s.autoSkipOnce);
  set autoSkipOnce(bool value) =>
      _setPlayerSetting((s) => s?.autoSkipOnce = value);

  bool get enableSwipeControls =>
      _getPlayerSetting((s) => s.enableSwipeControls);
  set enableSwipeControls(bool value) =>
      _setPlayerSetting((s) => s?.enableSwipeControls = value);

  int get markAsCompleted => _getPlayerSetting((s) => s.markAsCompleted);
  set markAsCompleted(int value) =>
      _getPlayerSetting((s) => s.markAsCompleted = value);

  void updateHomePageCard(String key, bool value) {
    final currentCards = Map<String, bool>.from(uiSettings.value.homePageCards);
    currentCards[key] = value;
    _setUISetting((s) => s?.homePageCards = currentCards);
  }

  void updateHomePageCardMal(String key, bool value) {
    final currentCards =
        Map<String, bool>.from(uiSettings.value.homePageCardsMal);
    currentCards[key] = value;
    _setUISetting((s) => s?.homePageCardsMal = currentCards);
  }

  void savePlayerSettings() {
    var playerBox = Hive.box<PlayerSettings>("PlayerSettings");
    playerBox.put('settings', playerSettings.value);
  }

  void saveUISettings() {
    var uiBox = Hive.box<UISettings>("UiSettings");
    uiBox.put('settings', uiSettings.value);
    update();
  }
}
