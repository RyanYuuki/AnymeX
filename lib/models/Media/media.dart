import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';

class Media {
  final int id;
  final String title;
  final String romajiTitle;
  final String description;
  final String poster;
  final String? cover;
  final String totalEpisodes;
  final String type;
  final String season;
  final String premiered;
  final String duration;
  final String status;
  final String rating;
  final String popularity;
  final String format;
  final String aired;

  final String? totalChapters;
  final List<String> genres;
  final List<String>? studios;
  final List<Character>? characters;
  final List<Relation>? relations;
  final List<Recommendation> recommendations;
  final NextAiringEpisode? nextAiringEpisode;
  final List<Ranking> rankings;

  Media({
    required this.id,
    required this.title,
    required this.romajiTitle,
    required this.description,
    required this.poster,
    this.cover,
    required this.totalEpisodes,
    required this.type,
    required this.season,
    required this.premiered,
    required this.duration,
    required this.status,
    required this.rating,
    required this.popularity,
    required this.format,
    required this.aired,
    required this.totalChapters,
    required this.genres,
    required this.studios,
    required this.characters,
    required this.relations,
    required this.recommendations,
    this.nextAiringEpisode,
    required this.rankings,
  });

  factory Media.fromManga(MManga manga) {
    return Media(
      id: 0,
      title: manga.name ?? "Unknown Title",
      romajiTitle: manga.name ?? "Unknown Title",
      description: manga.description ?? "No description available.",
      poster: manga.imageUrl ?? "",
      cover: null,
      totalEpisodes: "0",
      type: "MANGA",
      season: "Unknown",
      premiered: "Unknown",
      duration: "0",
      status: manga.status.toString(),
      rating: "0",
      popularity: "0",
      format: "MANGA",
      aired: "Unknown",
      totalChapters: manga.chapters?.length.toString(),
      genres: manga.genre ?? [],
      studios: null,
      characters: [],
      relations: [],
      recommendations: [],
      nextAiringEpisode: null,
      rankings: [],
    );
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int,
      romajiTitle: json['title']['romaji'] ?? '?',
      title: json['title']['english'] ?? json['title']['romaji'] ?? '?',
      description: json['description'] ?? '?',
      poster: json['coverImage']['large'] ?? '?',
      cover: json['bannerImage'],
      totalEpisodes: (json['episodes'] as int?)?.toString() ?? '?',
      type: json['type'] ?? '?',
      season: json['season'] ?? '?',
      premiered: '${json['season'] ?? '?'} ${json['seasonYear'] ?? '?'}',
      duration: '${json['duration'] ?? '?'}m',
      status: json['status'] ?? '?',
      rating: ((json['averageScore'] ?? 0) / 10).toString(),
      popularity: json['popularity']?.toString() ?? '6900',
      format: json['format'] ?? '?',
      aired: _parseDateRange(json['startDate'], json['endDate']),
      totalChapters: json['chapters']?.toString() ?? '?',
      genres: List<String>.from(json['genres'] ?? []),
      studios: (json['studios']['nodes'] as List)
          .map((el) => el['name'].toString())
          .toList(),
      characters: (json['characters']['edges'] as List)
          .map((character) => Character.fromJson(character))
          .toList(),
      relations: (json['relations']['edges'] as List)
          .map((relation) => Relation.fromJson(relation))
          .toList(),
      recommendations: (json['recommendations']['edges'] as List)
          .map((recommendation) => Recommendation.fromJson(recommendation))
          .toList(),
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? NextAiringEpisode.fromJson(json['nextAiringEpisode'])
          : null,
      rankings: (json['rankings'] as List)
          .map((ranking) => Ranking.fromJson(ranking))
          .toList(),
    );
  }

  static String _parseDateRange(
      Map<String, dynamic>? start, Map<String, dynamic>? end) {
    if (start == null && end == null) return 'Unknown';
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);
    return '$startDate to $endDate';
  }

  static String _formatDate(Map<String, dynamic>? date) {
    if (date == null) return '?';
    return '${date['year'] ?? '?'}-${date['month']?.toString().padLeft(2, '0') ?? '?'}-${date['day']?.toString().padLeft(2, '0') ?? '?'}';
  }
}

class Character {
  final String? name;
  final int? favourites;
  final String? image;
  final List<VoiceActor> voiceActors;

  Character({
    required this.name,
    required this.favourites,
    required this.image,
    required this.voiceActors,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['node']['name']['full'],
      favourites: json['node']['favourites'] ?? 0,
      image: json['node']['image']['large'],
      voiceActors: (json['voiceActors'] as List)
          .map((actor) => VoiceActor.fromJson(actor))
          .toList(),
    );
  }
}

class VoiceActor {
  final String? name;
  final String? image;

  VoiceActor({required this.name, required this.image});

  factory VoiceActor.fromJson(Map<String, dynamic> json) {
    return VoiceActor(
      name: json['name']['full'],
      image: json['image']['large'],
    );
  }
}

class Relation {
  final int id;
  final String title;
  final String poster;
  final String type;
  final String averageScore;

  Relation({
    required this.id,
    required this.title,
    required this.poster,
    required this.type,
    required this.averageScore,
  });

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
      id: json['node']['id'],
      title:
          json['node']['title']['romaji'] ?? json['node']['title']['english'],
      poster: json['node']['coverImage']['large'],
      type: json['node']['type'],
      averageScore: (json['node']['averageScore'] ?? 0).toString(),
    );
  }
}

class Recommendation {
  final int? id;
  final String? title;
  final String? poster;
  final String? averageScore;

  Recommendation({
    required this.id,
    required this.title,
    required this.poster,
    required this.averageScore,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['node']['mediaRecommendation']['id'],
      title: json['node']['mediaRecommendation']['title']['romaji'] ??
          json['node']['mediaRecommendation']['title']['english'],
      poster: json['node']['mediaRecommendation']['coverImage']['large'],
      averageScore:
          ((json['node']['mediaRecommendation']['averageScore'] ?? 0) / 10 ?? 0)
              .toString(),
    );
  }
}

class NextAiringEpisode {
  final int airingAt;
  final int timeUntilAiring;

  NextAiringEpisode({required this.airingAt, required this.timeUntilAiring});

  factory NextAiringEpisode.fromJson(Map<String, dynamic> json) {
    return NextAiringEpisode(
      airingAt: json['airingAt'],
      timeUntilAiring: json['timeUntilAiring'],
    );
  }
}

class Ranking {
  final int rank;
  final String type;
  final int year;

  Ranking({required this.rank, required this.type, required this.year});

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      rank: json['rank'] ?? 0,
      type: json['type'] ?? '?',
      year: json['year'] ?? 0,
    );
  }
}
