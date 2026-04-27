import 'package:isar_community/isar.dart';

part 'custom_list.g.dart';

@collection
class CustomList {
  Id id = Isar.autoIncrement;

  @Index()
  String? profileId;

  @Index()
  String? listName;

  List<String>? mediaIds;

  int mediaTypeIndex;

  CustomList({
    this.profileId,
    this.listName = "Default",
    this.mediaIds,
    this.mediaTypeIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'listName': listName,
      'mediaIds': mediaIds,
      'mediaTypeIndex': mediaTypeIndex,
    };
  }

  factory CustomList.fromJson(Map<String, dynamic> json) {
    return CustomList(
      profileId: json['profileId'] as String?,
      listName: json['listName'] as String? ?? "Default",
      mediaIds: (json['mediaIds'] as List<dynamic>?)?.cast<String>(),
      mediaTypeIndex: json['mediaTypeIndex'] as int? ?? 0,
    );
  }
}
