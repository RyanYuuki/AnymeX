import 'package:hive/hive.dart';

part 'player_adaptor.g.dart';

@HiveType(typeId: 3)
class PlayerSettings {
  @HiveField(0)
  String speed;
  @HiveField(1)
  String resizeMode;
  @HiveField(2)
  bool showSubtitle;
  @HiveField(3)
  int subtitleSize;
  @HiveField(4)
  int subtitleColor;
  @HiveField(5)
  String subtitleFont;
  @HiveField(6)
  int subtitleBackgroundColor;
  @HiveField(7)
  int subtitleOutlineColor;
  @HiveField(8)
  int skipDuration;

  PlayerSettings({
    this.speed = '1x',
    this.resizeMode = "Cover",
    this.subtitleSize = 16,
    this.subtitleColor = 0xFFFFFFFF,
    this.subtitleFont = 'Poppins',
    this.subtitleBackgroundColor = 0x80000000,
    this.subtitleOutlineColor = 0x00000000,
    this.showSubtitle = true,
    this.skipDuration = 85,
  });
}
