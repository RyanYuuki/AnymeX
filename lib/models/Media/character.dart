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
    return Character(
      id: json['node']['id']?.toString(),
      name: json['node']['name']['userPreferred'] ??
          json['node']['name']['full'],
      nativeName: json['node']['name']['native'],
      favourites: json['node']['favourites'] ?? 0,
      image: json['node']['image']['large'],
      role: json['role'],
      description: json['node']['description'],
      isFavourite: json['node']['isFavourite'],
      voiceActors: (json['voiceActors'] as List?)
              ?.map((actor) => VoiceActor.fromJson(actor))
              .toList() ??
          [],
    );
  }

  factory Character.fromSmallJson(Map<String, dynamic> json) {
    return Character(
      id: json['id']?.toString(),
      name: json['name']['userPreferred'] ?? json['name']['full'],
      nativeName: json['name']['native'],
      favourites: json['favourites'] ?? 0,
      image: json['image']['large'],
      description: json['description'],
      isFavourite: json['isFavourite'],
    );
  }


  factory Character.fromDetailJson(Map<String, dynamic> json) {
    String? dob;
    if (json['dateOfBirth'] != null) {
      final date = json['dateOfBirth'];
      if (date['year'] != null || date['month'] != null || date['day'] != null) {
         dob = "${date['month'] ?? '?'}/${date['day'] ?? '?'}/${date['year'] ?? '?'}";
      }
    }

    var voiceActorsMap = <String, VoiceActor>{};
    var mediaList = (json['media']['edges'] as List?)?.map((e) {
         var media = Media.fromSmallJson(e['node'], e['node']['type'] == 'MANGA', 
            role: e['characterRole']);
         
         
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

    return Character(
      id: json['id']?.toString(),
      name: json['name']['userPreferred'] ?? json['name']['full'],
      nativeName: json['name']['native'],
      favourites: json['favourites'],
      image: json['image']['large'],
      description: json['description'],
      isFavourite: json['isFavourite'],
      age: json['age'],
      gender: json['gender'],
      bloodType: json['bloodType'],
      dateOfBirth: dob,
      voiceActors: voiceActorsMap.values.toList()
        ..sort((a, b) {
          
          if (a.language == "Japanese" && b.language != "Japanese") return -1;
          if (a.language != "Japanese" && b.language == "Japanese") return 1;
          
        
          if (a.language == "English" && b.language != "English") return -1;
          if (a.language != "English" && b.language == "English") return 1;
          
        
          return (a.language ?? "").compareTo(b.language ?? "");
        }), 
      media: mediaList,
    );
  }
}
