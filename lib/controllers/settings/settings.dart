import 'package:anymex/controllers/settings/adaptors/player/player_adaptor.dart';
import 'package:anymex/controllers/settings/adaptors/ui/ui_adaptor.dart';
import 'package:anymex/screens/onboarding/welcome_dialog.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/updater.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class Settings extends GetxController {
  late Rx<UISettings> uiSettings;
  late Rx<PlayerSettings> playerSettings;
  final canShowUpdate = true.obs;
  RxBool isTV = false.obs;

  @override
  void onInit() {
    super.onInit();
    var uiBox = Hive.box<UISettings>("UiSettings");
    var playerBox = Hive.box<PlayerSettings>("PlayerSettings");
    uiSettings = Rx<UISettings>(uiBox.get('settings') ?? UISettings());
    playerSettings =
        Rx<PlayerSettings>(playerBox.get('settings') ?? PlayerSettings());
    isTv().then((e) {
      isTV.value = e;
    });
  }

  void checkForUpdates(BuildContext context) {
    canShowUpdate.value
        ? UpdateChecker().checkForUpdates(context, canShowUpdate)
        : null;
  }

  void showWelcomeDialog(BuildContext context) {
    if (Hive.box('themeData').get('isFirstTime', defaultValue: true)) {
      showWelcomeDialogg(context);
    }
  }

  bool get transculentBar => uiSettings.value.translucentTabBar;
  set transculentBar(bool value) {
    uiSettings.update((settings) {
      settings?.translucentTabBar = value;
    });
    saveUISettings();
  }

  double get glowDensity => uiSettings.value.glowDensity;
  set glowDensity(double value) {
    uiSettings.update((settings) {
      settings?.glowDensity = value;
    });
    saveUISettings();
  }

  bool get enableAnimation => uiSettings.value.enableAnimation;
  set enableAnimation(bool value) {
    uiSettings.update((settings) {
      settings?.enableAnimation = value;
    });
    saveUISettings();
  }

  bool get defaultPortraitMode => playerSettings.value.defaultPortraitMode;
  set defaultPortraitMode(bool value) {
    playerSettings.update((settings) {
      settings?.defaultPortraitMode = value;
    });
    savePlayerSettings();
  }

  bool get disableGradient => uiSettings.value.disableGradient;
  set disableGradient(bool value) {
    uiSettings.update((settings) {
      settings?.disableGradient = value;
    });
    saveUISettings();
  }

  Map<String, bool> get homePageCards => uiSettings.value.homePageCards;

  void updateHomePageCard(String key, bool value) {
    final currentCards = Map<String, bool>.from(uiSettings.value.homePageCards);
    currentCards[key] = value;
    uiSettings.update((settings) {
      settings?.homePageCards = currentCards;
    });
    saveUISettings();
  }

  double get glowMultiplier => uiSettings.value.glowMultiplier;
  set glowMultiplier(double value) {
    uiSettings.update((settings) {
      settings?.glowMultiplier = value;
    });
    saveUISettings();
  }

  double get radiusMultiplier => uiSettings.value.radiusMultiplier;
  set radiusMultiplier(double value) {
    uiSettings.update((settings) {
      settings?.radiusMultiplier = value;
    });
    saveUISettings();
  }

  double get blurMultiplier => uiSettings.value.blurMultipler;
  set blurMultiplier(double value) {
    uiSettings.update((settings) {
      settings?.blurMultipler = value;
    });
    saveUISettings();
  }

  double get cardRoundness => uiSettings.value.cardRoundness;
  set cardRoundness(double value) {
    uiSettings.update((settings) {
      settings?.cardRoundness = value;
    });
    saveUISettings();
  }

  bool get saikouLayout => uiSettings.value.saikouLayout;
  set saikouLayout(bool value) {
    uiSettings.update((settings) {
      settings?.saikouLayout = value;
    });
    saveUISettings();
  }

  double get tabBarHeight => uiSettings.value.tabBarHeight;
  set tabBarHeight(double value) {
    uiSettings.update((settings) {
      settings?.tabBarHeight = value;
    });
    saveUISettings();
  }

  double get tabBarWidth => uiSettings.value.tabBarWidth;
  set tabBarWidth(double value) {
    uiSettings.update((settings) {
      settings?.tabBarWidth = value;
    });
    saveUISettings();
  }

  double get tabBarRoundness => uiSettings.value.tabBarRoundness;
  set tabBarRoundness(double value) {
    uiSettings.update((settings) {
      settings?.tabBarRoundness = value;
    });
    saveUISettings();
  }

  bool get compactCards => uiSettings.value.compactCards;
  set compactCards(bool value) {
    uiSettings.update((settings) {
      settings?.compactCards = value;
    });
    saveUISettings();
  }

  int get animationDuration => uiSettings.value.animationDuration;
  set animationDuration(int value) {
    uiSettings.update((settings) {
      settings?.animationDuration = value;
    });
    saveUISettings();
  }

  double get speed => playerSettings.value.speed;
  set speed(double value) {
    playerSettings.update((settings) {
      settings?.speed = value;
    });
    savePlayerSettings();
  }

  String get resizeMode => playerSettings.value.resizeMode;
  set resizeMode(String value) {
    playerSettings.update((settings) {
      settings?.resizeMode = value;
    });
    savePlayerSettings();
  }

  bool get showSubtitle => playerSettings.value.showSubtitle;
  set showSubtitle(bool value) {
    playerSettings.update((settings) {
      settings?.showSubtitle = value;
    });
    savePlayerSettings();
  }

  int get subtitleSize => playerSettings.value.subtitleSize;
  set subtitleSize(int value) {
    playerSettings.update((settings) {
      settings?.subtitleSize = value;
    });
    savePlayerSettings();
  }

  String get subtitleColor => playerSettings.value.subtitleColor;
  set subtitleColor(String value) {
    playerSettings.update((settings) {
      settings?.subtitleColor = value;
    });
    savePlayerSettings();
  }

  String get subtitleFont => playerSettings.value.subtitleFont;
  set subtitleFont(String value) {
    playerSettings.update((settings) {
      settings?.subtitleFont = value;
    });
    savePlayerSettings();
  }

  String get subtitleBackgroundColor =>
      playerSettings.value.subtitleBackgroundColor;
  set subtitleBackgroundColor(String value) {
    playerSettings.update((settings) {
      settings?.subtitleBackgroundColor = value;
    });
    savePlayerSettings();
  }

  String get subtitleOutlineColor => playerSettings.value.subtitleOutlineColor;
  set subtitleOutlineColor(String value) {
    playerSettings.update((settings) {
      settings?.subtitleOutlineColor = value;
    });
    savePlayerSettings();
  }

  int get skipDuration => playerSettings.value.skipDuration;
  set skipDuration(int value) {
    playerSettings.update((settings) {
      settings?.skipDuration = value;
    });
    savePlayerSettings();
  }

  int get seekDuration => playerSettings.value.seekDuration;
  set seekDuration(int value) {
    playerSettings.update((settings) {
      settings?.seekDuration = value;
    });
    savePlayerSettings();
  }

  double get bottomMargin => playerSettings.value.bottomMargin;
  set bottomMargin(double value) {
    playerSettings.update((settings) {
      settings?.bottomMargin = value;
    });
    savePlayerSettings();
  }

  bool get transculentControls => playerSettings.value.transculentControls;
  set transculentControls(bool value) {
    playerSettings.update((settings) {
      settings?.transculentControls = value;
    });
    savePlayerSettings();
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
