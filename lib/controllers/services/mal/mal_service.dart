import 'package:anymex/models/Media/media.dart';
import 'package:get/get.dart';

class MalService extends GetxController {
  Future<Media> fetchDetails() async {
    return Media(
      id: 0,
      title: "Unknown Title",
      romajiTitle: "Unknown Title",
      description: "Unknown Description",
      poster: "Unknown Poster",
      totalEpisodes: "0",
      type: "Unknown Type",
      season: "Unknown Season",
      premiered: "Unknown Premiered",
      duration: "Unknown Duration",
      status: "Unknown Status",
      rating: "Unknown Rating",
      popularity: "Unknown Popularity",
      format: "Unknown Format",
      aired: "Unknown Aired",
      totalChapters: "0",
      genres: [],
      studios: [],
      characters: [],
      relations: [],
      recommendations: [],
      rankings: [],
    );
  }
}
