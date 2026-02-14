class VoiceActor {
  final String? id;
  final String? name;
  final String? image;
  final String? language;

  final bool isFavourite;

  VoiceActor({
    this.id,
    required this.name,
    required this.image,
    this.language,
    this.isFavourite = false,
  });

  factory VoiceActor.fromJson(Map<String, dynamic> json) {
    return VoiceActor(
      id: json['id']?.toString(),
      name: json['name']['userPreferred'] ?? json['name']['full'],
      image: json['image']['large'],
      language: json['languageV2'],
      isFavourite: (json['isFavourite'] as bool?) ?? false,
    );
  }
}
