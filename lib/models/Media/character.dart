import 'package:anymex/models/Media/voice_actor.dart';

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
