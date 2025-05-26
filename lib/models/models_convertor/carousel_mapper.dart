import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/core/Model/Manga.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/function.dart';

extension MMangaMapper on MManga {
  CarouselData toCarouselData({
    DataVariant variant = DataVariant.extension,
    bool isManga = false,
  }) {
    return CarouselData(
      id: link,
      title: name,
      poster: imageUrl,
      extraData: '??',
      releasing: status == Status.ongoing,
    );
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
        extraData: episodeCount ?? "??",
        releasing: mediaStatus == "RELEASING");
  }
}

extension MediaMapper on Media {
  CarouselData toCarouselData(
      {DataVariant variant = DataVariant.regular, bool isManga = false}) {
    return CarouselData(
        id: id.toString(),
        title: title,
        poster: poster,
        extraData: rating.toString(),
        releasing: status == "RELEASING");
  }
}
