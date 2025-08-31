class ImdbItem {
  final String id;
  final String title;
  final String originalTitle;
  final String type;
  final int? startYear;
  final String? image;
  final ImdbRating? rating;

  ImdbItem({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.type,
    this.startYear,
    this.image,
    this.rating,
  });

  factory ImdbItem.fromJson(Map<String, dynamic> json) {
    return ImdbItem(
      id: json['id'] ?? '',
      title: json['primaryTitle'] ?? '',
      originalTitle: json['originalTitle'] ?? '',
      type: json['type'] ?? '',
      startYear: json['startYear'],
      image:
          json['primaryImage'] != null ? (json['primaryImage']['url']) : null,
      rating:
          json['rating'] != null ? ImdbRating.fromJson(json['rating']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryTitle': title,
      'originalTitle': originalTitle,
      'type': type,
      'startYear': startYear,
      'primaryImage': image,
      'rating': rating?.toJson(),
    };
  }
}

class ImdbRating {
  final double aggregateRating;
  final int voteCount;

  ImdbRating({required this.aggregateRating, required this.voteCount});

  factory ImdbRating.fromJson(Map<String, dynamic> json) {
    return ImdbRating(
      aggregateRating: (json['aggregateRating'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['voteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aggregateRating': aggregateRating,
      'voteCount': voteCount,
    };
  }
}

class ImdbEpisode {
  final String id;
  final String title;
  final String? image;
  final int? season;
  final int? episodeNumber;
  final int? runtimeSeconds;
  final String? plot;
  final double? aggregateRating;
  final int? voteCount;
  final DateTime? releaseDate;

  ImdbEpisode({
    required this.id,
    required this.title,
    this.image,
    this.season,
    this.episodeNumber,
    this.runtimeSeconds,
    this.plot,
    this.aggregateRating,
    this.voteCount,
    this.releaseDate,
  });

  factory ImdbEpisode.fromJson(Map<String, dynamic> json) {
    return ImdbEpisode(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      image: json['primaryImage']?['url'],
      season: int.tryParse(json['season']?.toString() ?? ''),
      episodeNumber: int.tryParse(json['episodeNumber']?.toString() ?? ''),
      runtimeSeconds: json['runtimeSeconds'],
      plot: json['plot'],
      aggregateRating: (json['rating']?['aggregateRating'] as num?)?.toDouble(),
      voteCount: json['rating']?['voteCount'],
      releaseDate: (json['releaseDate'] != null)
          ? DateTime(
              json['releaseDate']['year'] ?? 0,
              json['releaseDate']['month'] ?? 1,
              json['releaseDate']['day'] ?? 1,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'primaryImage': image,
      'season': season,
      'episodeNumber': episodeNumber,
      'runtimeSeconds': runtimeSeconds,
      'plot': plot,
      'rating': {
        'aggregateRating': aggregateRating,
        'voteCount': voteCount,
      },
      'releaseDate': releaseDate != null
          ? {
              'year': releaseDate!.year,
              'month': releaseDate!.month,
              'day': releaseDate!.day,
            }
          : null,
    };
  }
}
