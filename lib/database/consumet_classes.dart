class Anime {
  final String id;
  final List<String> title;
  final int malId;
  final Trailer trailer;
  final String image;
  final double popularity;
  final String color;
  final String description;
  final String status;
  final int releaseDate;
  final StartEndDate startDate;
  final StartEndDate endDate;
  final int rating;
  final List<String> genres;
  final String season;
  final List<String> studios;
  final String type;
  final Recommendation recommendations;
  final Character characters;
  final Relation relations;
  final Episode episodes;

  Anime({
    required this.id,
    required this.title,
    required this.malId,
    required this.trailer,
    required this.image,
    required this.popularity,
    required this.color,
    required this.description,
    required this.status,
    required this.releaseDate,
    required this.startDate,
    required this.endDate,
    required this.rating,
    required this.genres,
    required this.season,
    required this.studios,
    required this.type,
    required this.recommendations,
    required this.characters,
    required this.relations,
    required this.episodes,
  });
}

class Trailer {
  final String id;
  final String site;
  final String thumbnail;

  Trailer({
    required this.id,
    required this.site,
    required this.thumbnail,
  });
}

class StartEndDate {
  final int year;
  final int month;
  final int day;

  StartEndDate({
    required this.year,
    required this.month,
    required this.day,
  });
}

class Recommendation {
  final String id;
  final String malId;
  final List<String> title;
  final String status;
  final double episodes;
  final String image;
  final String cover;
  final double rating;
  final String type;

  Recommendation({
    required this.id,
    required this.malId,
    required this.title,
    required this.status,
    required this.episodes,
    required this.image,
    required this.cover,
    required this.rating,
    required this.type,
  });
}

class Character {
  final String id;
  final String role;
  final List<String> name;
  final String image;

  Character({
    required this.id,
    required this.role,
    required this.name,
    required this.image,
  });
}

class Relation {
  final int id;
  final String relationType;
  final int malId;
  final List<String> title;
  final String status;
  final int episodes;
  final String image;
  final String color;
  final String type;
  final String cover;
  final int rating;

  Relation({
    required this.id,
    required this.relationType,
    required this.malId,
    required this.title,
    required this.status,
    required this.episodes,
    required this.image,
    required this.color,
    required this.type,
    required this.cover,
    required this.rating,
  });
}

class Episode {
  final String id;
  final String title;
  final String episode;

  Episode({
    required this.id,
    required this.title,
    required this.episode,
  });
}
