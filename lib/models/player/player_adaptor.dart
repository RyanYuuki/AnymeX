import 'package:anymex/database/data_keys/keys.dart';

class PlayerSettings {
  double speed;
  String resizeMode;
  bool showSubtitle;
  int subtitleSize;
  String subtitleColor;
  String subtitleFont;
  String subtitleBackgroundColor;
  String subtitleOutlineColor;
  int skipDuration;
  int seekDuration;
  double bottomMargin;
  bool transculentControls;
  bool defaultPortraitMode;
  int playerStyle;
  int subtitleOutlineWidth;
  bool autoSkipOP;
  bool autoSkipED;
  bool autoSkipOnce;
  bool enableSwipeControls;
  int markAsCompleted;
  bool transitionSubtitle;
  bool autoTranslate;
  String translateTo;
  bool autoSkipFiller;
  bool enableScreenshot;

  PlayerSettings({
    this.speed = 1.0,
    this.resizeMode = "Contain",
    this.subtitleSize = 16,
    this.subtitleColor = "White",
    this.subtitleFont = 'Poppins',
    this.subtitleBackgroundColor = "Black",
    this.subtitleOutlineColor = "Black",
    this.showSubtitle = true,
    this.skipDuration = 85,
    this.seekDuration = 10,
    this.bottomMargin = 5,
    this.playerStyle = 0,
    this.transculentControls = false,
    this.defaultPortraitMode = false,
    this.subtitleOutlineWidth = 1,
    this.autoSkipED = false,
    this.autoSkipOP = false,
    this.autoSkipOnce = false,
    this.enableSwipeControls = true,
    this.markAsCompleted = 90,
    this.autoTranslate = false,
    this.translateTo = 'en',
    this.transitionSubtitle = true,
    this.autoSkipFiller = false,
    this.enableScreenshot = true,
  });

  factory PlayerSettings.fromDB() {
    final defaults = PlayerSettings();

    return PlayerSettings(
      speed: PlayerSettingsKeys.speed.get<double>(defaults.speed),
      resizeMode:
          PlayerSettingsKeys.resizeMode.get<String>(defaults.resizeMode),
      showSubtitle:
          PlayerSettingsKeys.showSubtitle.get<bool>(defaults.showSubtitle),
      subtitleSize:
          PlayerSettingsKeys.subtitleSize.get<int>(defaults.subtitleSize),
      subtitleColor:
          PlayerSettingsKeys.subtitleColor.get<String>(defaults.subtitleColor),
      subtitleFont:
          PlayerSettingsKeys.subtitleFont.get<String>(defaults.subtitleFont),
      subtitleBackgroundColor: PlayerSettingsKeys.subtitleBackgroundColor
          .get<String>(defaults.subtitleBackgroundColor),
      subtitleOutlineColor: PlayerSettingsKeys.subtitleOutlineColor
          .get<String>(defaults.subtitleOutlineColor),
      skipDuration:
          PlayerSettingsKeys.skipDuration.get<int>(defaults.skipDuration),
      seekDuration:
          PlayerSettingsKeys.seekDuration.get<int>(defaults.seekDuration),
      bottomMargin:
          PlayerSettingsKeys.bottomMargin.get<double>(defaults.bottomMargin),
      transculentControls: PlayerSettingsKeys.transculentControls
          .get<bool>(defaults.transculentControls),
      defaultPortraitMode: PlayerSettingsKeys.defaultPortraitMode
          .get<bool>(defaults.defaultPortraitMode),
      playerStyle:
          PlayerSettingsKeys.playerStyle.get<int>(defaults.playerStyle),
      subtitleOutlineWidth: PlayerSettingsKeys.subtitleOutlineWidth
          .get<int>(defaults.subtitleOutlineWidth),
      autoSkipOP: PlayerSettingsKeys.autoSkipOP.get<bool>(defaults.autoSkipOP),
      autoSkipED: PlayerSettingsKeys.autoSkipED.get<bool>(defaults.autoSkipED),
      autoSkipOnce:
          PlayerSettingsKeys.autoSkipOnce.get<bool>(defaults.autoSkipOnce),
      enableSwipeControls: PlayerSettingsKeys.enableSwipeControls
          .get<bool>(defaults.enableSwipeControls),
      markAsCompleted:
          PlayerSettingsKeys.markAsCompleted.get<int>(defaults.markAsCompleted),
      transitionSubtitle: PlayerSettingsKeys.transitionSubtitle
          .get<bool>(defaults.transitionSubtitle),
      autoTranslate:
          PlayerSettingsKeys.autoTranslate.get<bool>(defaults.autoTranslate),
      translateTo:
          PlayerSettingsKeys.translateTo.get<String>(defaults.translateTo),
      autoSkipFiller:
          PlayerSettingsKeys.autoSkipFiller.get<bool>(defaults.autoSkipFiller),
      enableScreenshot: PlayerSettingsKeys.enableScreenshot
          .get<bool>(defaults.enableScreenshot),
    );
  }
}
