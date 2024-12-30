class Episode {
  String number;
  String? link;
  String? title;
  String? videoUrl;
  String? desc;
  String? thumb;
  bool? filler;
  String? date;

  Episode({
    required this.number,
    this.link,
    this.title,
    this.videoUrl,
    this.desc,
    this.thumb,
    this.filler,
    this.date,
  });
}
