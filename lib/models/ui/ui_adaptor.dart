import 'package:hive/hive.dart';

part 'ui_adaptor.g.dart';

@HiveType(typeId: 4)
class UISettings extends HiveObject {
  @HiveField(0)
  double glowMultiplier;

  @HiveField(1)
  double radiusMultiplier;

  @HiveField(2)
  bool saikouLayout;

  @HiveField(3)
  double tabBarHeight;

  @HiveField(4)
  double tabBarWidth;

  @HiveField(5)
  double tabBarRoundness;

  @HiveField(6)
  bool compactCards;

  @HiveField(7)
  double cardRoundness;

  @HiveField(8)
  double blurMultipler;

  @HiveField(9)
  int animationDuration;

  @HiveField(10)
  bool translucentTabBar;

  @HiveField(11)
  double glowDensity;

  @HiveField(12)
  Map<String, bool> homePageCards;

  @HiveField(13)
  bool enableAnimation;

  @HiveField(14)
  bool disableGradient;

  @HiveField(15)
  Map<String, bool> homePageCardsMal;

  @HiveField(16)
  int cardStyle;

  @HiveField(17)
  int historyCardStyle;

  @HiveField(18)
  bool liquidMode;

  @HiveField(19)
  String liquidBackgroundPath;

  @HiveField(20)
  bool retainOriginalColor;

  @HiveField(21)
  bool usePosterColor;

  UISettings(
      {this.glowMultiplier = 1.0,
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
      this.homePageCards = const {
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
      this.homePageCardsMal = const {
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
      this.enableAnimation = true,
      this.disableGradient = false,
      this.cardStyle = 2,
      this.historyCardStyle = 0,
      this.liquidMode = true,
      this.retainOriginalColor = false,
      this.liquidBackgroundPath = '',
      this.usePosterColor = false});
}
