import 'package:isar_community/isar.dart';

part 'chapter.g.dart';

@embedded
class Chapter {
  String? link;
  String? title;
  String? releaseDate;
  String? scanlator;
  double? number;
  int? pageNumber;
  int? totalPages;
  int? lastReadTime;
  double? currentOffset;
  double? maxOffset;
  String? sourceName;
  String? localPath;

  List<String>? headerKeys;
  List<String>? headerValues;

  @ignore
  Map<String, String> get headers {
    if (headerKeys == null || headerValues == null) return {};
    if (headerKeys!.isEmpty || headerValues!.isEmpty) return {};
    final result = <String, String>{};
    final len = headerKeys!.length < headerValues!.length
        ? headerKeys!.length
        : headerValues!.length;
    for (int i = 0; i < len; i++) {
      final k = headerKeys![i].trim();
      final v = headerValues![i].trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        result[k] = v;
      }
    }
    return result;
  }

  set headers(Map<String, String> map) {
    headerKeys = map.keys.toList();
    headerValues = map.values.toList();
  }

  String get formattedNumber {
    if (number == null) return '-';
    if (number! % 1 == 0) return number!.toInt().toString();
    final rounded = double.parse(number!.toStringAsFixed(2));
    if (rounded == rounded.toInt()) {
      return rounded.toInt().toString();
    }
    return rounded.toString().replaceAll(RegExp(r'\.?0+$'), '');
  }

  Chapter(
      {this.link,
      this.title,
      this.releaseDate,
      this.number,
      this.scanlator,
      this.pageNumber,
      this.lastReadTime,
      this.totalPages,
      this.currentOffset,
      this.maxOffset,
      this.sourceName,
      this.localPath,
      this.headerKeys,
      this.headerValues});

  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'title': title,
      'releaseDate': releaseDate,
      'scanlator': scanlator,
      'number': number,
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'lastReadTime': lastReadTime,
      'currentOffset': currentOffset,
      'maxOffset': maxOffset,
      'sourceName': sourceName,
      'localPath': localPath,
      'headerKeys': headerKeys,
      'headerValues': headerValues
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      link: json['link'] as String?,
      title: json['title'] as String?,
      releaseDate: json['releaseDate'] as String?,
      scanlator: json['scanlator'] as String?,
      number: (json['number'] as num?)?.toDouble(),
      pageNumber: json['pageNumber'] as int?,
      totalPages: json['totalPages'] as int?,
      lastReadTime: json['lastReadTime'] as int?,
      currentOffset: (json['currentOffset'] as num?)?.toDouble(),
      maxOffset: (json['maxOffset'] as num?)?.toDouble(),
      sourceName: json['sourceName'] as String?,
      localPath: json['localPath'] as String?,
      headerKeys: (json['headerKeys'] as List<dynamic>?)?.map((e) => e as String).toList(),
      headerValues: (json['headerValues'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter &&
        other.link == link &&
        other.number == number &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(link, number, title);
}
