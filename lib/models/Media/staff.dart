import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';

class Staff {
  final String? id;
  final String? name;
  final String? nativeName;
  final String? image;
  final String? role;
  final String? description;
  final bool? isFavourite;
  final int? favourites;
  final List<String>? primaryOccupations;
  final List<Media>? media;
  final List<Character>? characters;
  final int? age;
  final String? gender;
  final String? homeTown;
  final String? dateOfBirth;
  final String? yearsActive;

  Staff({
    this.id,
    this.name,
    this.nativeName,
    this.image,
    this.role,
    this.description,
    this.isFavourite,
    this.favourites,
    this.primaryOccupations,
    this.media,
    this.characters,
    this.age,
    this.gender,
    this.homeTown,
    this.dateOfBirth,
    this.yearsActive,
    this.bloodType,
  });

  final String? bloodType;

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['node']['id']?.toString(),
      name: json['node']['name']['userPreferred'] ??
          json['node']['name']['full'],
      nativeName: json['node']['name']['native'],
      image: json['node']['image']['large'],
      role: json['role'],
      description: json['node']['description'],
      isFavourite: json['node']['isFavourite'],
      favourites: json['node']['favourites'],
      primaryOccupations: (json['node']['primaryOccupations'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }


    factory Staff.fromDetailJson(Map<String, dynamic> json) {
    
    var parsedCharacters = <Character>[];
    if (json['characters'] != null && json['characters']['edges'] != null) {
      for (var edge in json['characters']['edges']) {
        if (edge['node'] == null) continue;
        
        var charNode = edge['node'];
        var character = Character.fromSmallJson(charNode);
        
        
        if (charNode['media'] != null && charNode['media']['nodes'] != null && (charNode['media']['nodes'] as List).isNotEmpty) {
           var medNode = charNode['media']['nodes'][0];
           var media = Media.fromSmallJson(medNode, false);
           character.media = [media];
        }
        
        parsedCharacters.add(character);
      }
    }

   
    var staffMedia = (json['staffMedia']['edges'] as List?)?.map((e) {
         return Media.fromSmallJson(e['node'], false, role: e['staffRole']);
    }).toList() ?? [];

    
  
    final uniqueStaffMedia = <String, Media>{};
    for (var m in staffMedia) {
       final key = "${m.id}|${m.characterRole ?? 'unknown'}"; 
       uniqueStaffMedia[key] = m;
    }

   

    return Staff(
      id: json['id']?.toString(),
      name: json['name']['userPreferred'] ?? json['name']['full'],
      nativeName: json['name']['native'],
      image: json['image']['large'],
      description: json['description'],
      isFavourite: json['isFavourite'],
      favourites: json['favourites'],
      media: uniqueStaffMedia.values.toList(), 
      characters: parsedCharacters,             
      primaryOccupations: (json['primaryOccupations'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      age: json['age'],
      gender: json['gender'],
      homeTown: json['homeTown'],
      dateOfBirth: _parseDate(json['dateOfBirth']),
      yearsActive: _parseYearsActive(json['yearsActive']),
      bloodType: json['bloodType'],
    );
  }

  static String? _parseDate(Map<String, dynamic>? date) {
    if (date == null) return null;
    final year = date['year'];
    final month = date['month'];
    final day = date['day'];
    if (year == null && month == null && day == null) return null;
    
    final List<String> parts = [];
  
    if (month != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      parts.add(months[month - 1]);
    }
    if (day != null) parts.add(day.toString());
    if (parts.isNotEmpty && year != null) parts.add(',');
    if (year != null) parts.add(year.toString());
    
    return parts.join(' ').replaceAll(' ,', ',');
  }

  static String? _parseYearsActive(List<dynamic>? years) {
    if (years == null || years.isEmpty) return null;
    if (years.length == 1) {
      return '${years[0]}-Present';
    }
    return '${years[0]}-${years[1] ?? "Present"}';
  }
}
