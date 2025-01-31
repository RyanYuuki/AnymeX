import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/string_extensions.dart';

import '../../../Model/Manga.dart';
import 'm_chapter.dart';

class MManga {
  String? name;

  String? link;

  String? imageUrl;

  String? description;

  String? author;

  String? artist;

  Status? status;

  List<String>? genre;

  List<MChapter>? chapters;

  MManga(
      {this.author,
      this.artist,
      this.genre,
      this.imageUrl,
      this.link,
      this.name,
      this.status = Status.unknown,
      this.description,
      this.chapters});

  factory MManga.fromJson(Map<String, dynamic> json) {
    return MManga(
        name: json['name'],
        link: json['link'],
        imageUrl: json['imageUrl'],
        description: json['description'],
        author: json['author'],
        artist: json['artist'],
        status: switch (json['status'] as int?) {
          0 => Status.ongoing,
          1 => Status.completed,
          2 => Status.onHiatus,
          3 => Status.canceled,
          4 => Status.publishingFinished,
          _ => Status.unknown,
        },
        genre:
            (json['genre'] as List?)?.map((e) => e.toString()).toList() ?? [],
        chapters: json['chapters'] != null
            ? (json['chapters'] as List)
                .map((e) => MChapter.fromJson(e))
                .toList()
            : json['episodes'] != null
                ? (json['episodes'] as List)
                    .map((e) => MChapter.fromJson(e))
                    .toList()
                : []);
  }

  factory MManga.fromMedia(Media media) {
    return MManga(
        name: media.title,
        imageUrl: media.poster,
        description: media.description,
        status: switch (media.status) {
          "ONGOING" => Status.ongoing,
          "COMPLETED" => Status.completed,
          "ON_HIATUS" => Status.onHiatus,
          "CANCELED" => Status.canceled,
          "PUBLISHING_FINISHED" => Status.publishingFinished,
          _ => Status.unknown,
        },
        genre: media.genres,
        chapters: media.mediaContent);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'link': link,
        'imageUrl': imageUrl,
        'description': description,
        'author': author,
        'artist': artist,
        'status': status.toString().substringAfter("."),
        'genre': genre,
        'chapters': chapters!.map((e) => e.toJson()).toList()
      };
}
