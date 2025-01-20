import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:get/get.dart';

enum ServicesType { anilist, mal, simkl }

class ServiceHandler extends GetxController {
  final serviceType = ServicesType.anilist.obs;
  Rx<Media> detailsData = Media(
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
  ).obs;

  Future<Media> fetchDetails(Media media) async {
    switch (serviceType.value) {
      case ServicesType.anilist:
        return await AnilistData.fetchAnimeInfo(media.id.toString());
      case ServicesType.mal:
        return await MalService().fetchDetails();
      case ServicesType.simkl:
        return await SimklService().fetchDetails();
      default:
        return await AnilistData.fetchAnimeInfo(media.id.toString());
    }
  }

  void changeService(ServicesType type) {
    serviceType.value = type;
  }
}
