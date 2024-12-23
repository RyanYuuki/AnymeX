import 'package:hive/hive.dart';

part 'ShowResponse.g.dart';

@HiveType(typeId: 0)
class ShowResponse {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String link;

  @HiveField(2)
  final String coverUrl;

  @HiveField(3)
  final List<String> otherNames;

  @HiveField(4)
  final int? total;

  @HiveField(5)
  final Map<String, String>? extra;

  ShowResponse({
    required this.name,
    required this.link,
    required this.coverUrl,
    this.otherNames = const [],
    this.total,
    this.extra,
  });
}
