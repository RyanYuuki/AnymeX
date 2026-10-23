import 'package:isar_community/isar.dart';

part 'custom_list.g.dart';

@collection
class CustomList {
  Id id = Isar.autoIncrement;

  @Index()
  String? listName;

  List<String>? mediaIds;

  int mediaTypeIndex;

  CustomList({
    this.listName = "Default",
    this.mediaIds,
    this.mediaTypeIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'listName': listName,
      'mediaIds': mediaIds,
      'mediaTypeIndex': mediaTypeIndex,
    };
  }

  factory CustomList.fromJson(Map<String, dynamic> json) {
    return CustomList(
      listName: json['listName'] as String? ?? "Default",
      mediaIds: (json['mediaIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      mediaTypeIndex: (json['mediaTypeIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
