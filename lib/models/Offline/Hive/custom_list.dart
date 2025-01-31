import 'package:hive/hive.dart';

part 'custom_list.g.dart';

@HiveType(typeId: 9)
class CustomList extends HiveObject {
  @HiveField(0)
  String? listName;

  @HiveField(1)
  List<String>? mediaIds;

  CustomList({
    this.listName = "Default",
    this.mediaIds = const ['0'],
  });
}
