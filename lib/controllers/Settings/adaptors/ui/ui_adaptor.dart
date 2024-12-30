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

  UISettings(
      {this.glowMultiplier = 1.0,
      this.radiusMultiplier = 1.0,
      this.saikouLayout = false,
      this.tabBarHeight = 50.0,
      this.tabBarWidth = 180.0,
      this.tabBarRoundness = 10.0,
      this.compactCards = false,
      this.cardRoundness = 0.0,
      this.blurMultipler = 1.0,
      this.animationDuration = 200});

  factory UISettings.from(UISettings other) {
    return UISettings(
      glowMultiplier: other.glowMultiplier,
      radiusMultiplier: other.radiusMultiplier,
      blurMultipler: other.blurMultipler,
      saikouLayout: other.saikouLayout,
      tabBarHeight: other.tabBarHeight,
      tabBarWidth: other.tabBarWidth,
      tabBarRoundness: other.tabBarRoundness,
      compactCards: other.compactCards,
      cardRoundness: other.cardRoundness,
    );
  }
}
