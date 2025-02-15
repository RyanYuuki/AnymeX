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
