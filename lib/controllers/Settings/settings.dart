import 'package:anymex/controllers/Settings/adaptors/player/player_adaptor.dart';
import 'package:anymex/controllers/Settings/adaptors/ui/ui_adaptor.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class Settings extends GetxController {
  late Rx<UISettings> uiSettings;
  late Rx<PlayerSettings> playerSettings;

  @override
  void onInit() {
    super.onInit();

    var uiBox = Hive.box<UISettings>("UiSettings");
    var playerBox = Hive.box<PlayerSettings>("PlayerSettings");

    uiSettings = Rx<UISettings>(uiBox.get('settings') ?? UISettings());
    playerSettings =
        Rx<PlayerSettings>(playerBox.get('settings') ?? PlayerSettings());
  }

  double get glowMultiplier => uiSettings.value.glowMultiplier;
  double get radiusMultiplier => uiSettings.value.radiusMultiplier;
  double get blurMultiplier => uiSettings.value.blurMultipler;

  set glowMultiplier(double value) {
    uiSettings.update((settings) {
      settings?.glowMultiplier = value;
    });
    saveUISettings();
  }

  set radiusMultiplier(double value) {
    uiSettings.update((settings) {
      settings?.radiusMultiplier = value;
    });
    saveUISettings();
  }

  set blurMultiplier(double value) {
    uiSettings.update((settings) {
      settings?.blurMultipler = value;
    });
    saveUISettings();
  }

  bool get saikouLayout => uiSettings.value.saikouLayout;
  set saikouLayout(bool value) {
    uiSettings.value.saikouLayout = value;
    saveUISettings();
  }

  double get tabBarHeight => uiSettings.value.tabBarHeight;
  set tabBarHeight(double value) {
    uiSettings.value.tabBarHeight = value;
    saveUISettings();
  }

  double get tabBarWidth => uiSettings.value.tabBarWidth;
  set tabBarWidth(double value) {
    uiSettings.value.tabBarWidth = value;
    saveUISettings();
  }

  double get tabBarRoundness => uiSettings.value.tabBarRoundness;
  set tabBarRoundness(double value) {
    uiSettings.value.tabBarRoundness = value;
    saveUISettings();
  }

  bool get compactCards => uiSettings.value.compactCards;
  set compactCards(bool value) {
    uiSettings.value.compactCards = value;
    saveUISettings();
  }

  double get cardRoundness => uiSettings.value.cardRoundness;
  set cardRoundness(double value) {
    uiSettings.value.cardRoundness = value;
    saveUISettings();
  }

  int get animationDuration => uiSettings.value.animationDuration;
  set animationDuration(int value) {
    uiSettings.value.animationDuration = value;
    saveUISettings();
  }

  String get speed => playerSettings.value.speed;
  set speed(String value) {
    playerSettings.value.speed = value;
    savePlayerSettings();
  }

  String get resizeMode => playerSettings.value.resizeMode;
  set resizeMode(String value) {
    playerSettings.value.resizeMode = value;
    savePlayerSettings();
  }

  bool get showSubtitle => playerSettings.value.showSubtitle;
  set showSubtitle(bool value) {
    playerSettings.value.showSubtitle = value;
    savePlayerSettings();
  }

  int get subtitleSize => playerSettings.value.subtitleSize;
  set subtitleSize(int value) {
    playerSettings.value.subtitleSize = value;
    savePlayerSettings();
  }

  int get subtitleColor => playerSettings.value.subtitleColor;
  set subtitleColor(int value) {
    playerSettings.value.subtitleColor = value;
    savePlayerSettings();
  }

  String get subtitleFont => playerSettings.value.subtitleFont;
  set subtitleFont(String value) {
    playerSettings.value.subtitleFont = value;
    savePlayerSettings();
  }

  int get subtitleBackgroundColor =>
      playerSettings.value.subtitleBackgroundColor;
  set subtitleBackgroundColor(int value) {
    playerSettings.value.subtitleBackgroundColor = value;
    savePlayerSettings();
  }

  int get subtitleOutlineColor => playerSettings.value.subtitleOutlineColor;
  set subtitleOutlineColor(int value) {
    playerSettings.value.subtitleOutlineColor = value;
    savePlayerSettings();
  }

  int get skipDuration => playerSettings.value.skipDuration;
  set skipDuration(int value) {
    playerSettings.value.skipDuration = value;
    savePlayerSettings();
  }

  Future<void> savePlayerSettings() async {
    var playerBox = await Hive.openBox<PlayerSettings>("PlayerSettings");
    await playerBox.put('settings', playerSettings.value);
  }

  Future<void> saveUISettings() async {
    var uiBox = await Hive.openBox<UISettings>("UiSettings");
    await uiBox.put('settings', uiSettings.value);
  }
}
