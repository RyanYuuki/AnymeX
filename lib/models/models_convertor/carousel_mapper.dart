import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/function.dart';

extension DMediaMapper on DMedia {
  CarouselData toCarouselData({
    DataVariant variant = DataVariant.extension,
    bool isManga = false,
  }) {
    return CarouselData(
        id: url,
        title: title,
        poster: cover,
        extraData: '??',
        releasing: false,
        servicesType: ServicesType.extensions);
  }
}

extension OfflineMediaMapper on OfflineMedia {
  CarouselData toCarouselData({
    DataVariant variant = DataVariant.offline,
    bool isManga = false,
  }) {
    return CarouselData(
        id: id,
        title: name,
        poster: poster,
        source: currentChapter?.sourceName ?? currentEpisode?.source,
        servicesType: ServicesType.values[serviceIndex ?? 0],
        extraData:
            (currentChapter?.number ?? currentEpisode?.number ?? 0).toString(),
        releasing: status == "RELEASING");
  }
}

extension RelationMapper on Relation {
  CarouselData toCarouselData(
      {DataVariant variant = DataVariant.relation, bool isManga = false}) {
    return CarouselData(
      id: id.toString(),
      title: title,
      poster: poster,
      source: type,
      servicesType: ServicesType.anilist,
      args: type,
      extraData: relationType,
      releasing: status == "RELEASING",
    );
  }
}

extension TrackedMediaMapper on TrackedMedia {
  CarouselData toCarouselData(
      {DataVariant variant = DataVariant.anilist, bool isManga = false}) {
    return CarouselData(
        id: id.toString(),
        title: title,
        poster: poster,
        servicesType: servicesType,
        extraData: switch (type) {
          "ANIME" =>
            "${episodeCount ?? "??"} | ${releasedEpisodes != null ? releasedEpisodes ?? "??" : totalEpisodes ?? "??"}",
          "MANGA" => "${episodeCount ?? "??"} | ${chapterCount ?? "??"}",
          _ => episodeCount ?? "??"
        },
        releasing: mediaStatus == "RELEASING");
  }
}

extension MediaMapper on Media {
  CarouselData toCarouselData(
      {DataVariant variant = DataVariant.regular, bool isManga = false}) {
    return CarouselData(
        id: id.toString(),
        title: title,
        servicesType: serviceType,
        poster: poster,
        extraData: rating.toString(),
        releasing: status == "RELEASING");
  }
}
