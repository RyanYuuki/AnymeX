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

  PlayerSettings(
      {this.speed = 1.0,
      this.resizeMode = "Cover",
      this.subtitleSize = 16,
      this.subtitleColor = "White",
      this.subtitleFont = 'Poppins',
      this.subtitleBackgroundColor = "Black",
      this.subtitleOutlineColor = "Black",
      this.showSubtitle = true,
      this.skipDuration = 85,
      this.seekDuration = 10});
}
