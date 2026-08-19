import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Media/voice_actor.dart';

class Character {
  final String? id;
  final String? name;
  final int? favourites;
  final String? image;
  final String? role;
  final String? description;
  final bool? isFavourite;
  final List<VoiceActor> voiceActors;
  List<Media>? media;
  final String? nativeName;

  String? age;
  String? gender;
  String? bloodType;
  String? dateOfBirth;

  Character({
    this.id,
    this.name,
    this.favourites,
    this.image,
    this.role,
    this.description,
    this.isFavourite,
    this.voiceActors = const [],
    this.media,
    this.nativeName,
    this.age,
    this.gender,
    this.bloodType,
    this.dateOfBirth,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    final bool isEdge = json.containsKey('node');
    final Map<String, dynamic> nodeJson = isEdge 
        ? (json['node'] as Map<String, dynamic>?) ?? {} 
        : json;

    final id = nodeJson['id']?.toString();
    final nameMap = nodeJson['name'] as Map<String, dynamic>?;
    final name = nameMap?['userPreferred'] ?? nameMap?['full'];
    final nativeName = nameMap?['native'];
    final favourites = nodeJson['favourites'] ?? 0;
    
    final imageMap = nodeJson['image'] as Map<String, dynamic>?;
    final image = imageMap?['large'];
    
    final description = nodeJson['description'];
    final isFavourite = nodeJson['isFavourite'];
    final role = json['role'] ?? json['characterRole'];

    List<VoiceActor> voiceActors = [];
    if (json['voiceActors'] != null) {
      voiceActors = (json['voiceActors'] as List)
          .map((actor) => VoiceActor.fromJson(actor as Map<String, dynamic>))
          .toList();
    }

    String? dob;
    if (nodeJson['dateOfBirth'] != null) {
      final date = nodeJson['dateOfBirth'];
      if (date['year'] != null || date['month'] != null || date['day'] != null) {
        dob = "${date['month'] ?? '?'}/${date['day'] ?? '?'}/${date['year'] ?? '?'}";
      }
    }

    List<Media>? mediaList;
    if (nodeJson['media'] != null && nodeJson['media']['edges'] != null) {
      var voiceActorsMap = <String, VoiceActor>{};
      mediaList = (nodeJson['media']['edges'] as List?)?.map((e) {
        var media = Media.fromSmallJson(
          e['node'],
          e['node']['type'] == 'MANGA',
          role: e['characterRole'],
        );

        if (e['voiceActors'] != null) {
          for (var va in e['voiceActors']) {
            var actor = VoiceActor.fromJson(va);
            if (actor.id != null) {
              if (!voiceActorsMap.containsKey(actor.id!) ||
                  (voiceActorsMap[actor.id!]?.language == null && actor.language != null)) {
                voiceActorsMap[actor.id!] = actor;
              }
            }
          }
        }
        return media;
      }).toList();

      if (voiceActors.isEmpty && voiceActorsMap.isNotEmpty) {
        voiceActors = voiceActorsMap.values.toList()
          ..sort((a, b) {
            if (a.language == "Japanese" && b.language != "Japanese") return -1;
            if (a.language != "Japanese" && b.language == "Japanese") return 1;

            if (a.language == "English" && b.language != "English") return -1;
            if (a.language != "English" && b.language == "English") return 1;

            return (a.language ?? "").compareTo(b.language ?? "");
          });
      }
    }

    return Character(
      id: id,
      name: name,
      nativeName: nativeName,
      favourites: favourites,
      image: image,
      role: role,
      description: description,
      isFavourite: isFavourite,
      age: nodeJson['age'],
      gender: nodeJson['gender'],
      bloodType: nodeJson['bloodType'],
      dateOfBirth: dob,
      voiceActors: voiceActors,
      media: mediaList,
    );
  }
}
