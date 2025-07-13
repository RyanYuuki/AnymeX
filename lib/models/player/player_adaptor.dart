import 'package:hive/hive.dart';

part 'player_adaptor.g.dart';

@HiveType(typeId: 3)
class PlayerSettings {
  @HiveField(0)
  double speed;
  @HiveField(1)
  String resizeMode;
  @HiveField(2)
  bool showSubtitle;
  @HiveField(3)
  int subtitleSize;
  @HiveField(4)
  String subtitleColor;
  @HiveField(5)
  String subtitleFont;
  @HiveField(6)
  String subtitleBackgroundColor;
  @HiveField(7)
  String subtitleOutlineColor;
  @HiveField(8)
  int skipDuration;
  @HiveField(9)
  int seekDuration;
  @HiveField(10)
  double bottomMargin;
  @HiveField(11)
  bool transculentControls;
  @HiveField(12)
  bool defaultPortraitMode;
  @HiveField(13)
  int playerStyle;
  @HiveField(14)
  int subtitleOutlineWidth;
  @HiveField(15)
  bool autoSkipOP;
  @HiveField(16)
  bool autoSkipED;
  @HiveField(17)
  bool autoSkipOnce;
  @HiveField(18)
  bool enableSwipeControls;
  @HiveField(19)
  int markAsCompleted;

  PlayerSettings(
      {this.speed = 1.0,
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
      this.markAsCompleted = 90});
}
