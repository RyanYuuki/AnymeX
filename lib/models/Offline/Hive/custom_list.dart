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

  Map<String, dynamic> toJson() {
    return {
      'listName': listName,
      'mediaIds': mediaIds,
    };
  }

  factory CustomList.fromJson(Map<String, dynamic> json) {
    return CustomList(
      listName: json['listName'] as String? ?? "Default",
      mediaIds: (json['mediaIds'] as List<dynamic>?)?.cast<String>() ?? ['0'],
    );
  }
}
