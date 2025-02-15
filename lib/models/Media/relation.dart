class Relation {
  final int id;
  final String title;
  final String poster;
  final String type;
  final String averageScore;
  final String relationType;

  Relation({
    required this.id,
    required this.title,
    required this.poster,
    required this.type,
    required this.averageScore,
    required this.relationType,
  });

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
      relationType: json['relationType'],
      id: json['node']['id'],
      title:
          json['node']['title']['romaji'] ?? json['node']['title']['english'],
      poster: json['node']['coverImage']['large'],
      type: json['node']['type'],
      averageScore: (json['node']['averageScore'] ?? 0).toString(),
    );
  }
}
