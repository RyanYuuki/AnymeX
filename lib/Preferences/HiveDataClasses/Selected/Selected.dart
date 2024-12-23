import 'package:hive/hive.dart';

part 'Selected.g.dart';

@HiveType(typeId: 1)
class Selected {
  @HiveField(0)
  int window;
  @HiveField(1)
  int? recyclerStyle;
  @HiveField(2)
  bool recyclerReversed;
  @HiveField(3)
  int chip;
  @HiveField(4)
  int sourceIndex;
  @HiveField(5)
  int langIndex;
  @HiveField(6)
  bool preferDub;
  @HiveField(7)
  String? server;
  @HiveField(8)
  int video;
  @HiveField(9)
  double latest;
  @HiveField(10)
  List<String>? scanlators;

  Selected({
    this.window = 0,
    this.recyclerStyle,
    this.recyclerReversed = false,
    this.chip = 0,
    this.sourceIndex = 0,
    this.langIndex = 0,
    this.preferDub = false,
    this.server,
    this.video = 0,
    this.latest = 0.0,
    this.scanlators,
  });
}
