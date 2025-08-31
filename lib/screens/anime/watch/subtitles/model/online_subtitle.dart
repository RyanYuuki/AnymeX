class OnlineSubtitle {
  final String id;
  final String url;
  final String flagUrl;
  final String format;
  final String encoding;
  final String label;
  final String language;
  final String media;
  final bool isHearingImpaired;
  final String source;

  OnlineSubtitle({
    required this.id,
    required this.url,
    required this.flagUrl,
    required this.format,
    required this.encoding,
    required this.label,
    required this.language,
    required this.media,
    required this.isHearingImpaired,
    required this.source,
  });

  factory OnlineSubtitle.fromJson(Map<String, dynamic> json) {
    return OnlineSubtitle(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      flagUrl: json['flagUrl'] ?? '',
      format: json['format'] ?? '',
      encoding: json['encoding'] ?? '',
      label: json['display'] ?? '',
      language: json['language'] ?? '',
      media: json['media'] ?? '',
      isHearingImpaired: json['isHearingImpaired'] ?? false,
      source: json['source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'flagUrl': flagUrl,
      'format': format,
      'encoding': encoding,
      'label': label,
      'language': language,
      'media': media,
      'isHearingImpaired': isHearingImpaired,
      'source': source,
    };
  }
}
