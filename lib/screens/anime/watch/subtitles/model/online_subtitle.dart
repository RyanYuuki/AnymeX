class OnlineSubtitle {
  final String id;
  final String url;
  final String flagUrl;
  final String format;
  final String encoding;
  final String label;
  final String language;
  final String languageCode;
  final String media;
  final bool isHearingImpaired;
  final String source;
  final String provider;
  final int downloads;
  final double rating;
  final bool isSeasonPack;
  final String? uploadDate;
  final String? uploader;

  OnlineSubtitle({
    required this.id,
    required this.url,
    required this.flagUrl,
    required this.format,
    required this.encoding,
    required this.label,
    required this.language,
    required this.languageCode,
    required this.media,
    required this.isHearingImpaired,
    required this.source,
    required this.provider,
    this.downloads = 0,
    this.rating = 0.0,
    this.isSeasonPack = false,
    this.uploadDate,
    this.uploader,
  });

  factory OnlineSubtitle.fromJson(Map<String, dynamic> json) {
    return OnlineSubtitle(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      flagUrl: json['flagUrl'] ?? '',
      format: json['format'] ?? '',
      encoding: json['encoding'] ?? '',
      label: json['display'] ?? json['label'] ?? '',
      language: json['language'] ?? '',
      languageCode: json['languageCode'] ?? json['lang'] ?? '',
      media: json['media'] ?? '',
      isHearingImpaired: json['isHearingImpaired'] ?? json['hearingImpaired'] ?? false,
      source: json['source'] ?? '',
      provider: json['provider'] ?? '',
      downloads: json['downloads'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      isSeasonPack: json['isSeasonPack'] ?? false,
      uploadDate: json['uploadDate'],
      uploader: json['uploader'],
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
      'languageCode': languageCode,
      'media': media,
      'isHearingImpaired': isHearingImpaired,
      'source': source,
      'provider': provider,
      'downloads': downloads,
      'rating': rating,
      'isSeasonPack': isSeasonPack,
      'uploadDate': uploadDate,
      'uploader': uploader,
    };
  }
}
