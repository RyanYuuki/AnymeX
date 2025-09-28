class Relation {
  final int id;
  final String title;
  final String poster;
  final String cover;
  final String type;
  final String averageScore;
  final String relationType;
  final String status;

  Relation({
    required this.id,
    required this.title,
    required this.poster,
    required this.cover,
    required this.type,
    required this.averageScore,
    required this.relationType,
    required this.status,
  });

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
      relationType: json['relationType'],
      id: json['node']['id'],
      cover: json['node']['bannerImage'] ?? '',
      title:
          json['node']['title']['english'] ?? json['node']['title']['romaji'],
      poster: json['node']['coverImage']['large'],
      type: json['node']['type'],
      averageScore: (json['node']['averageScore'] ?? 0).toString(),
      status: json['node']['status'] ?? '',
    );
  }
}
