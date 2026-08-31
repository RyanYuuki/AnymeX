import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/media_ids.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/models/Media/staff.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/novel/details/widgets/chapters_section.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:get/get.dart';

class Media {
  String id;
  String idMal;
  MediaIds? mediaIds;
  String title;
  String romajiTitle;

  String get displayTitle {
    if (Get.isRegistered<Settings>() &&
        Get.find<Settings>().useAlternateTitle.value) {
      if (romajiTitle.isNotEmpty && romajiTitle != '?') {
        return romajiTitle;
      }
    }
    return title;
  }

  String description;
  String poster;
  String largePoster;
  String? cover;
  String totalEpisodes;
  String type;
  String color;
  String season;
  String premiered;
  String duration;
  String status;
  String rating;
  String popularity;
  String format;
  String aired;
  ItemType mediaType;
  List<DEpisode>? mediaContent;
  List<Chapter>? altMediaContent;
  String? totalChapters;
  List<String> genres;
  List<String>? studios;
  List<Character>? characters;
  List<Staff>? staff;
  List<Relation>? relations;
  List<Media> recommendations;
  NextAiringEpisode? nextAiringEpisode;
  List<Ranking> rankings;
  ServicesType serviceType;
  DateTime? latestEpisodeReleasedAt;
  bool? isAdult;
  String? sourceName;
  String? sourceId;
  String? sourceMaterial;
  List<TrackedMedia>? friendsWatching;
  String? userStatus;
  String? characterRole;
  int? seasonYear;
  List<String> synonyms;
  List<MediaTag> tags;
  List<ExternalLink>? externalLinks;

  // String get uniqueId => "$id-${serviceType.name}";
  String get uniqueId => id.split('*').first;

  Media(
      {this.id = '0',
      this.idMal = '0',
      this.isAdult,
      this.mediaType = ItemType.anime,
      this.title = '?',
      this.color = '',
      this.romajiTitle = '?',
      this.description = '?',
      this.poster = '?',
      this.largePoster = '?',
      this.cover,
      this.totalEpisodes = '?',
      this.type = '?',
      this.season = '?',
      this.premiered = '?',
      this.duration = '?',
      this.status = 'ONGOING.. probably?',
      this.rating = '?',
      this.popularity = '?',
      this.format = '?',
      this.aired = '?',
      this.totalChapters = '?',
      this.genres = const [],
      this.studios,
      this.characters,
      this.staff,
      this.seasonYear,
      this.altMediaContent,
      this.relations,
      this.recommendations = const [],
      this.nextAiringEpisode,
      this.rankings = const [],
      this.mediaContent,
      required this.serviceType,
      this.sourceName,
      this.sourceId,
      this.sourceMaterial,
      this.friendsWatching,
      this.userStatus,
      this.characterRole,
      this.synonyms = const [],
      this.tags = const [],
      this.externalLinks,
      this.latestEpisodeReleasedAt});

  OfflineMedia toOfflineMedia() {
    return OfflineMedia(
      mediaId: id,
      idMal: idMal,
      name: title,
      jname: romajiTitle,
      description: description,
      poster: poster,
      cover: cover,
      totalEpisodes: totalEpisodes,
      type: type,
      season: season,
      premiered: premiered,
      duration: duration,
      status: status,
      rating: rating,
      popularity: popularity,
      format: format,
      aired: aired,
      totalChapters: totalChapters,
      genres: genres,
      studios: studios,
      chapters: altMediaContent,
      episodes: (mediaContent ?? [])
          .map((e) => Episode(
                number: e.episodeNumber.toString(),
                link: e.url,
                title: e.name,
                desc: e.description,
                thumbnail: e.thumbnail,
                filler: e.filler,
                dateUpload: e.dateUpload,
              ))
          .toList(),
      serviceIndex: serviceType.index,
      mediaTypeIndex: mediaType.index,
    );
  }

  factory Media.fromMAL(Map<String, dynamic> json, {bool isManga = false}) {
    final node = json['node'] ?? {};
    final mediaTypeStr = node['media_type'] as String?;

    ItemType determinedType;
    if (mediaTypeStr != null) {
      final t = mediaTypeStr.toLowerCase();
      if (t == 'tv' ||
          t == 'ova' ||
          t == 'movie' ||
          t == 'special' ||
          t == 'ona' ||
          t == 'music') {
        determinedType = ItemType.anime;
      } else if (t == 'novel' || t == 'light_novel') {
        determinedType = ItemType.novel;
      } else if (t == 'manga' ||
          t == 'one_shot' ||
          t == 'doujinshi' ||
          t == 'manhwa' ||
          t == 'manhua' ||
          t == 'oel') {
        determinedType = ItemType.manga;
      } else {
        determinedType = isManga ? ItemType.manga : ItemType.anime;
      }
    } else {
      determinedType = isManga ? ItemType.manga : ItemType.anime;
    }

    final dynamic rawTitle = node['title'];
    final String parsedTitle = (rawTitle is Map)
        ? (rawTitle['english']?.toString() ??
            rawTitle['romaji']?.toString() ??
            rawTitle['native']?.toString() ??
            '??')
        : (rawTitle?.toString() ?? '??');

    final dynamic rawAltTitles = node['alternative_titles'];
    final String parsedRomaji = (rawAltTitles is Map)
        ? (rawAltTitles['en']?.toString() ??
            rawAltTitles['english']?.toString() ??
            '??')
        : '??';

    final dynamic rawMainPic = node['main_picture'];
    final String parsedPoster = (rawMainPic is Map)
        ? (rawMainPic['medium']?.toString() ?? '??')
        : '??';
    final String parsedCover = (rawMainPic is Map)
        ? (rawMainPic['large']?.toString() ?? '??')
        : '??';

    final dynamic rawStartSeason = node['start_season'];
    final String parsedSeason = (rawStartSeason is Map)
        ? (rawStartSeason['season']?.toString() ?? '??')
        : '??';

    final genresVal = node['genres'];
    List<String> parsedGenres = [];
    if (genresVal is List) {
      parsedGenres = genresVal.map((genre) {
        if (genre is Map) {
          return genre['name']?.toString() ?? '??';
        }
        return genre?.toString() ?? '??';
      }).toList();
    }

    final studiosVal = node['studios'];
    List<String> parsedStudios = [];
    if (studiosVal is Map && studiosVal['nodes'] is List) {
      parsedStudios = (studiosVal['nodes'] as List)
          .map((el) => el['name']?.toString() ?? '??')
          .toList();
    } else if (studiosVal is List) {
      parsedStudios = studiosVal.map((studio) {
        if (studio is Map) {
          return studio['name']?.toString() ?? '??';
        }
        return studio?.toString() ?? '??';
      }).toList();
    }

    return Media(
      id: node['id']?.toString() ?? '0',
      title: parsedTitle,
      romajiTitle: parsedRomaji,
      description: node['synopsis']?.toString() ?? '??',
      poster: parsedPoster,
      cover: parsedCover,
      totalEpisodes: node['num_episodes']?.toString() ?? '??',
      type: node['media_type']?.toString() ?? '??',
      season: parsedSeason,
      premiered: node['start_date']?.toString() ?? '??',
      duration: node['average_episode_duration']?.toString() ?? '??',
      status: (node['status']?.toString() ?? '??').replaceAll('_', ' '),
      rating: node['mean']?.toString() ?? '??',
      popularity: node['popularity']?.toString() ?? '??',
      format: formatFormatString(node['media_type']?.toString(), null),
      sourceMaterial: node['source']?.toString() ?? '?',
      aired: node['start_date']?.toString() ?? '??',
      totalChapters: (mediaTypeStr?.toLowerCase() == 'one_shot')
          ? '1'
          : (node['num_chapters']?.toString() ?? '??'),
      genres: parsedGenres,
      studios: parsedStudios,
      characters: [],
      relations: [],
      recommendations: [],
      nextAiringEpisode: null,
      rankings: [],
      mediaContent: [],
      mediaType: determinedType,
      serviceType: ServicesType.mal,
      synonyms: {
        parsedTitle,
        if (parsedRomaji != '??') parsedRomaji,
        if (rawAltTitles is Map && rawAltTitles['ja'] != null)
          rawAltTitles['ja'].toString(),
        if (rawAltTitles is Map && rawAltTitles['synonyms'] is List)
          ...((rawAltTitles['synonyms'] as List).map((e) => e.toString())),
      }.where((t) => t.isNotEmpty && t != '??' && t != '?').toList(),
    );
  }

  factory Media.fromJikan(Map<String, dynamic> json, {bool isManga = false}) {
    return Media(
      id: json['mal_id']?.toString() ?? '0',
      title: json['title'] ?? '??',
      romajiTitle: json['title_english'] ?? json['title'] ?? '??',
      description: json['synopsis'] ?? '??',
      poster: json['images']?['jpg']?['image_url'] ?? '??',
      cover: json['images']?['jpg']?['large_image_url'] ??
          json['images']?['jpg']?['image_url'] ??
          '??',
      totalEpisodes: json['episodes']?.toString() ?? '??',
      totalChapters:
          (json['type']?.toString().toLowerCase().replaceAll('-', '_') ==
                  'one_shot')
              ? '1'
              : (json['chapters']?.toString() ?? '??'),
      type: json['type'] ?? '??',
      season: json['season'] ?? '??',
      premiered: json['aired']?['from'] ?? json['published']?['from'] ?? '??',
      duration: json['duration'] ?? '??',
      status: (json['status'] ?? '??').replaceAll('_', ' '),
      rating: json['score']?.toString() ?? '??',
      popularity: json['popularity']?.toString() ?? '??',
      format: json['type'] ?? '??',
      aired: json['aired']?['from'] ?? json['published']?['from'] ?? '??',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g['name']?.toString() ?? '??')
              .toList() ??
          [],
      studios: (json['studios'] as List<dynamic>?)
          ?.map((s) => s['name']?.toString() ?? '??')
          .toList(),
      characters: [],
      relations: [],
      recommendations: [],
      nextAiringEpisode: null,
      rankings: [],
      mediaContent: [],
      mediaType: isManga ? ItemType.manga : ItemType.anime,
      serviceType: ServicesType.mal,
      synonyms: {
        if (json['title'] != null) json['title'].toString(),
        if (json['title_english'] != null) json['title_english'].toString(),
        if (json['title_japanese'] != null) json['title_japanese'].toString(),
        ...?((json['title_synonyms'] as List?)?.map((e) => e.toString())),
      }.where((t) => t.isNotEmpty && t != '??' && t != '?').toList(),
    );
  }

  factory Media.fromFullMAL(Map<String, dynamic> json, {bool isManga = false}) {
    final node = json;
    final mediaTypeStr = node['media_type'] as String?;

    ItemType determinedType;
    if (mediaTypeStr != null) {
      final t = mediaTypeStr.toLowerCase();
      if (t == 'tv' ||
          t == 'ova' ||
          t == 'movie' ||
          t == 'special' ||
          t == 'ona' ||
          t == 'music') {
        determinedType = ItemType.anime;
      } else if (t == 'novel' || t == 'light_novel') {
        determinedType = ItemType.novel;
      } else if (t == 'manga' ||
          t == 'one_shot' ||
          t == 'doujinshi' ||
          t == 'manhwa' ||
          t == 'manhua' ||
          t == 'oel') {
        determinedType = ItemType.manga;
      } else {
        determinedType = isManga ? ItemType.manga : ItemType.anime;
      }
    } else {
      determinedType = isManga ? ItemType.manga : ItemType.anime;
    }

    final dynamic rawTitle = node['title'];
    final String parsedTitle = (rawTitle is Map)
        ? (rawTitle['english']?.toString() ??
            rawTitle['romaji']?.toString() ??
            rawTitle['native']?.toString() ??
            '??')
        : (rawTitle?.toString() ?? '??');

    final dynamic rawAltTitles = node['alternative_titles'];
    final String parsedRomaji = (rawAltTitles is Map)
        ? (rawAltTitles['en']?.toString() ??
            rawAltTitles['english']?.toString() ??
            '??')
        : '??';

    final dynamic rawMainPic = node['main_picture'];
    final String parsedPoster = (rawMainPic is Map)
        ? (rawMainPic['medium']?.toString() ?? '??')
        : '??';
    final String parsedCover = (rawMainPic is Map)
        ? (rawMainPic['large']?.toString() ?? '??')
        : '??';

    final dynamic rawStartSeason = node['start_season'];
    final String parsedSeason = (rawStartSeason is Map)
        ? (rawStartSeason['season']?.toString() ?? '??')
        : '??';

    final genresVal = node['genres'];
    List<String> parsedGenres = [];
    if (genresVal is List) {
      parsedGenres = genresVal.map((genre) {
        if (genre is Map) {
          return genre['name']?.toString() ?? '??';
        }
        return genre?.toString() ?? '??';
      }).toList();
    }

    final studiosVal = node['studios'];
    List<String> parsedStudios = [];
    if (studiosVal is Map && studiosVal['nodes'] is List) {
      parsedStudios = (studiosVal['nodes'] as List)
          .map((el) => el['name']?.toString() ?? '??')
          .toList();
    } else if (studiosVal is List) {
      parsedStudios = studiosVal.map((studio) {
        if (studio is Map) {
          return studio['name']?.toString() ?? '??';
        }
        return studio?.toString() ?? '??';
      }).toList();
    }

    final recsVal = node['recommendations'];
    List<Media> parsedRecs = [];
    if (recsVal is Map) {
      if (recsVal['nodes'] is List) {
        parsedRecs = (recsVal['nodes'] as List)
            .map((r) => Media.fromRecs(r))
            .toList();
      } else if (recsVal['edges'] is List) {
        parsedRecs = (recsVal['edges'] as List)
            .map((e) => Media.fromRecs(e['node'] ?? {}))
            .where((m) => m.id.isNotEmpty && m.id != '')
            .toList();
      }
    } else if (recsVal is List) {
      parsedRecs = recsVal
          .map((e) {
            if (e is Map) {
              return Media.fromMAL(Map<String, dynamic>.from(e), isManga: isManga);
            }
            return null;
          })
          .whereType<Media>()
          .toList();
    }

    return Media(
      id: node['id']?.toString() ?? '0',
      title: parsedTitle,
      romajiTitle: parsedRomaji,
      description: node['synopsis']?.toString() ?? '??',
      poster: parsedPoster,
      cover: parsedCover,
      totalEpisodes: node['num_episodes']?.toString() ?? '??',
      type: node['media_type']?.toString().toUpperCase() ?? '??',
      season: parsedSeason,
      premiered: node['start_date']?.toString() ?? '??',
      duration: node['average_episode_duration']?.toString() ?? '??',
      status: node['status']?.toString().replaceAll('_', ' ').toUpperCase() ?? '??',
      rating: node['mean']?.toString() ?? '??',
      popularity: node['popularity']?.toString() ?? '??',
      format: node['media_type']?.toString() ?? '??',
      aired: node['start_date']?.toString() ?? '??',
      totalChapters: (mediaTypeStr?.toLowerCase() == 'one_shot')
          ? '1'
          : (node['num_chapters']?.toString() ?? '??'),
      genres: parsedGenres,
      studios: parsedStudios,
      characters: [],
      recommendations: parsedRecs,
      nextAiringEpisode: null,
      rankings: [],
      mediaContent: [],
      mediaType: determinedType,
      serviceType: ServicesType.mal,
      synonyms: {
        parsedTitle,
        if (parsedRomaji != '??') parsedRomaji,
        if (rawAltTitles is Map && rawAltTitles['ja'] != null)
          rawAltTitles['ja'].toString(),
        if (rawAltTitles is Map && rawAltTitles['synonyms'] is List)
          ...((rawAltTitles['synonyms'] as List).map((e) => e.toString())),
      }.where((t) => t.isNotEmpty && t != '??' && t != '?').toList(),
    );
  }

  factory Media.fromSimkl(Map<String?, dynamic> json, bool isMovie) {
    ItemType type = ItemType.anime;

    String formatStatus(String? rawStatus) {
      if (rawStatus == null || rawStatus.isEmpty) return 'Unknown';
      final s = rawStatus.toLowerCase().trim();
      switch (s) {
        case 'airing':
        case 'returning series':
          return 'Releasing';
        case 'ended':
          return 'Finished';
        case 'released':
          return 'Released';
        case 'canceled':
        case 'cancelled':
          return 'Cancelled';
        case 'in production':
          return 'In Production';
        case 'post production':
          return 'Post Production';
        case 'pilot':
          return 'Pilot';
        default:
          return s
              .split(' ')
              .map((w) =>
                  w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
              .join(' ');
      }
    }

    String formatDate(String? rawDate) {
      if (rawDate == null || rawDate.trim().isEmpty) return 'Unknown release';
      final cleanStr = rawDate.trim();
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(cleanStr);
      if (match != null) {
        final year = match.group(1);
        final month = match.group(2);
        final day = match.group(3);
        return '$day-$month-$year';
      }
      try {
        final parsed = DateTime.tryParse(cleanStr);
        if (parsed != null) {
          final day = parsed.day.toString().padLeft(2, '0');
          final month = parsed.month.toString().padLeft(2, '0');
          return '$day-$month-${parsed.year}';
        }
      } catch (_) {}
      return rawDate;
    }

    String parseSeasons() {
      if (isMovie) return 'N/A';
      final seasons = json['seasons'] as List?;
      if (seasons != null && seasons.isNotEmpty) {
        final regularSeasons =
            seasons.where((s) => s is Map && s['number'] != 0).length;
        final totalCount = regularSeasons > 0 ? regularSeasons : seasons.length;
        return '$totalCount Season${totalCount > 1 ? "s" : ""}';
      }
      return 'N/A';
    }

    String parseFormat() {
      if (isMovie) {
        final showType = json['show_type']?.toString();
        if (showType != null && showType.isNotEmpty) {
          return showType
              .split('_')
              .map((w) =>
                  w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
              .join(' ');
        }
        return 'Movie';
      } else {
        final showType =
            json['show_type']?.toString() ?? json['anime_type']?.toString();
        if (showType != null && showType.isNotEmpty) {
          if (showType.toLowerCase() == 'scripted') return 'TV';
          return showType
              .split('_')
              .map((w) =>
                  w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
              .join(' ');
        }
        return 'TV';
      }
    }

    String parseDuration() {
      final runtime = json['runtime'];
      if (runtime != null &&
          runtime.toString().isNotEmpty &&
          runtime.toString() != '0') {
        final rStr = runtime.toString();
        return rStr.contains('min') ? rStr : '$rStr minutes';
      }
      return 'Unknown';
    }

    NextAiringEpisode? parseNextAiringEpisode() {
      if (isMovie) return null;
      final nextEp = json['next_episode'];
      if (nextEp is Map && nextEp['date'] != null) {
        try {
          final dt = DateTime.tryParse(nextEp['date'].toString());
          if (dt != null) {
            final now = DateTime.now();
            final airingAtSeconds = dt.millisecondsSinceEpoch ~/ 1000;
            final timeUntil =
                (dt.millisecondsSinceEpoch - now.millisecondsSinceEpoch) ~/
                    1000;
            final epNum = (nextEp['episode'] as num?)?.toInt() ?? 1;
            return NextAiringEpisode(
              airingAt: airingAtSeconds,
              timeUntilAiring: timeUntil > 0 ? timeUntil : 0,
              episode: epNum,
            );
          }
        } catch (_) {}
      }
      if (json['episodes'] is List) {
        final now = DateTime.now();
        for (final ep in (json['episodes'] as List)) {
          if (ep is Map) {
            final isAired = ep['aired'] == true;
            final dateStr = ep['date']?.toString();
            if (!isAired && dateStr != null) {
              final dt = DateTime.tryParse(dateStr);
              if (dt != null && dt.isAfter(now)) {
                final airingAtSeconds = dt.millisecondsSinceEpoch ~/ 1000;
                final timeUntil =
                    (dt.millisecondsSinceEpoch - now.millisecondsSinceEpoch) ~/
                        1000;
                final epNum = (ep['episode'] as num?)?.toInt() ?? 1;
                return NextAiringEpisode(
                  airingAt: airingAtSeconds,
                  timeUntilAiring: timeUntil,
                  episode: epNum,
                );
              }
            }
          }
        }
      }
      return null;
    }

    final rawRank = json['rank'];
    final popularityStr = (rawRank != null &&
            rawRank.toString().isNotEmpty &&
            rawRank.toString() != '0')
        ? rawRank.toString()
        : 'N/A';

    final simklRating = json['ratings']?['simkl']?['rating'];
    final imdbRating = json['ratings']?['imdb']?['rating'];
    final ratingStr = (simklRating != null && simklRating.toString().isNotEmpty)
        ? simklRating.toString()
        : (imdbRating != null && imdbRating.toString().isNotEmpty)
            ? imdbRating.toString()
            : 'N/A';

    final releasedDateStr = formatDate(json['released'] ?? json['first_aired']);

    List<String>? studiosList;
    if (!isMovie &&
        json['network'] != null &&
        json['network'].toString().isNotEmpty) {
      studiosList = [json['network'].toString()];
    } else if (isMovie &&
        json['director'] != null &&
        json['director'].toString().isNotEmpty) {
      studiosList = ['Director: ${json['director']}'];
    }

    final synonymsSet = <String>{};
    if (json['en_title'] != null) synonymsSet.add(json['en_title'].toString());
    if (json['alt_titles'] is List) {
      for (final item in (json['alt_titles'] as List)) {
        if (item is Map && item['name'] != null) {
          synonymsSet.add(item['name'].toString());
        } else if (item is String) {
          synonymsSet.add(item);
        }
      }
    }
    final synonymsList =
        synonymsSet.where((s) => s.isNotEmpty && s != json['title']).toList();

    final tagsList = <MediaTag>[];
    if (json['certification'] != null &&
        json['certification'].toString().isNotEmpty) {
      tagsList.add(MediaTag(name: json['certification'].toString(), rank: 100));
    }
    if (json['country'] != null && json['country'].toString().isNotEmpty) {
      tagsList.add(
          MediaTag(name: json['country'].toString().toUpperCase(), rank: 90));
    }
    if (json['language'] != null && json['language'].toString().isNotEmpty) {
      tagsList.add(
          MediaTag(name: json['language'].toString().toUpperCase(), rank: 80));
    }

    List<Relation>? relationsList;
    if (json['relations'] is List) {
      relationsList = (json['relations'] as List)
          .map((r) {
            if (r is Map) {
              final rTitle = r['title']?.toString() ?? 'Unknown Title';
              final relType = (r['relation_type']?.toString() ?? 'RELATED')
                  .replaceAll('_', ' ')
                  .toUpperCase();
              final rIds = r['ids'] as Map?;
              final rSimklId = rIds?['simkl']?.toString() ??
                  rIds?['simkl_id']?.toString() ??
                  '0';
              final rType = (r['anime_type']?.toString() ??
                      r['type']?.toString() ??
                      'ANIME')
                  .toUpperCase();
              return Relation(
                id: int.tryParse(rSimklId) ?? 0,
                title: rTitle,
                poster: '',
                cover: '',
                type: rType,
                averageScore: '0',
                relationType: relType,
                status: '',
              );
            }
            return null;
          })
          .whereType<Relation>()
          .toList();
    }

    final linksList = <ExternalLink>[];
    final ids = json['ids'] as Map?;
    if (ids != null) {
      final simklId =
          ids['simkl_id']?.toString() ?? ids['simkl']?.toString() ?? '';
      final slug = ids['slug']?.toString() ?? '';
      final imdbId = ids['imdb']?.toString() ?? '';
      final tmdbId = ids['tmdb']?.toString() ?? '';
      final netflixId = ids['netflix']?.toString() ?? '';
      final huluId = ids['hulu']?.toString() ?? '';
      final crunchyId = ids['crunchyroll']?.toString() ?? '';

      if (simklId.isNotEmpty) {
        linksList.add(ExternalLink(
          site: 'Simkl',
          url:
              'https://simkl.com/${isMovie ? "movies" : "tv"}/$simklId${slug.isNotEmpty ? "/$slug" : ""}',
        ));
      }
      if (imdbId.isNotEmpty) {
        linksList.add(ExternalLink(
          site: 'IMDb',
          url: 'https://www.imdb.com/title/$imdbId',
        ));
      }
      if (tmdbId.isNotEmpty) {
        linksList.add(ExternalLink(
          site: 'TMDb',
          url: 'https://www.themoviedb.org/${isMovie ? "movie" : "tv"}/$tmdbId',
        ));
      }
      if (netflixId.isNotEmpty) {
        linksList.add(ExternalLink(
          site: 'Netflix',
          url: 'https://www.netflix.com/title/$netflixId',
        ));
      }
      if (huluId.isNotEmpty) {
        linksList.add(ExternalLink(
          site: 'Hulu',
          url: 'https://www.hulu.com/series/$huluId',
        ));
      }
      if (crunchyId.isNotEmpty) {
        linksList.add(ExternalLink(
          site: 'Crunchyroll',
          url: 'https://www.crunchyroll.com/series/$crunchyId',
        ));
      }
    }

    if (json['trailers'] is List) {
      for (final t in (json['trailers'] as List)) {
        if (t is Map &&
            t['youtube'] != null &&
            t['youtube'].toString().isNotEmpty) {
          final ytId = t['youtube'].toString();
          final tName = t['name']?.toString() ?? 'Trailer';
          linksList.add(ExternalLink(
            site: 'Trailer ($tName)',
            url: 'https://www.youtube.com/watch?v=$ytId',
          ));
        }
      }
    }

    return Media(
      id: '${json['ids']?['simkl_id']?.toString() ?? json['ids']?['simkl']?.toString()}*${isMovie ? "MOVIE" : "SERIES"}',
      title: json['title'] ?? 'Unknown Title',
      romajiTitle: json['title'] ?? 'Unknown Romaji Title',
      description: json['overview'] ?? 'No description available.',
      poster: json['poster'] != null
          ? 'https://wsrv.nl/?url=https://simkl.in/posters/${json['poster']}_m.jpg'
          : '',
      cover: json['fanart'] != null
          ? 'https://wsrv.nl/?url=https://simkl.in/fanart/${json['fanart']}_medium.jpg'
          : null,
      totalEpisodes: (json['total_episodes'] ??
                  json['total_episodes_count'] ??
                  json['episodes_count'] ??
                  json['episodes'])
              ?.toString() ??
          (isMovie ? '1' : '??'),
      type: isMovie ? 'Movie' : 'Show',
      format: parseFormat(),
      season: parseSeasons(),
      premiered: releasedDateStr,
      duration: parseDuration(),
      status: formatStatus(json['status']),
      rating: ratingStr,
      popularity: popularityStr,
      mediaType: type,
      aired: releasedDateStr,
      totalChapters: '0',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((genre) => genre.toString())
              .toList() ??
          [],
      studios: studiosList,
      synonyms: synonymsList,
      tags: tagsList,
      relations: relationsList,
      externalLinks: linksList.isNotEmpty ? linksList : null,
      nextAiringEpisode: parseNextAiringEpisode(),
      recommendations: (json['users_recommendations'] as List<dynamic>?)
              ?.map((e) {
                try {
                  return Media.fromSmallSimkl(e, isMovie);
                } catch (error) {
                  Logger.i('Error parsing recommendation: $error');
                  return null;
                }
              })
              .where((e) => e != null)
              .toList()
              .cast<Media>() ??
          [],
      serviceType: ServicesType.simkl,
    );
  }

  factory Media.fromSimklSearch(Map<String?, dynamic> json) {
    final endpointType = json['endpoint_type']?.toString() ?? 'anime';
    final isMovie = endpointType == 'movies';
    final simklId = json['ids']?['simkl_id']?.toString() ??
        json['ids']?['simkl']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final posterPath = json['poster']?.toString();
    final posterUrl = (posterPath != null && posterPath.isNotEmpty)
        ? 'https://wsrv.nl/?url=https://simkl.in/posters/${posterPath}_m.jpg'
        : '';
    final epCount = json['ep_count']?.toString();
    final year = json['year']?.toString();
    final status = json['status']?.toString();
    final rating = json['ratings']?['simkl']?['rating']?.toString();
    final rank = json['rank']?.toString();
    final title = json['title']?.toString() ?? 'Unknown Title';
    final romaji = json['title_romaji']?.toString() ?? title;

    return Media(
      id: '$simklId*${isMovie ? "MOVIE" : "SERIES"}',
      title: title,
      romajiTitle: romaji,
      description: json['overview']?.toString() ?? '',
      poster: posterUrl,
      largePoster: posterUrl,
      cover: posterUrl,
      totalEpisodes: (epCount != null && epCount.isNotEmpty) ? epCount : '?',
      type: endpointType.toUpperCase(),
      season: '?',
      premiered: year ?? '?',
      duration: '?',
      status: (status != null && status.isNotEmpty)
          ? status[0].toUpperCase() + status.substring(1)
          : '?',
      rating: rating ?? '?',
      popularity: rank ?? '0',
      format: json['type']?.toString() ?? '?',
      aired: year ?? '?',
      totalChapters: '0',
      genres: const [],
      recommendations: const [],
      mediaType: ItemType.anime,
      serviceType: ServicesType.simkl,
      seasonYear: year != null ? int.tryParse(year) : null,
    );
  }

  factory Media.fromSmallSimkl(Map<String?, dynamic> json, bool isMovie) {
    ItemType type = ItemType.anime;
    String posterUrl = '';
    if (json['poster'] != null) {
      if (json['poster'].toString().startsWith('http')) {
        posterUrl = json['poster'];
      } else {
        posterUrl = 'https://simkl.in/posters/${json['poster']}_m.jpg';
      }
    }

    String rawDate = json['date']?.toString() ??
        json['release_date']?.toString() ??
        json['released']?.toString() ??
        '';
    String releaseDate = rawDate.trim();
    if (rawDate.isNotEmpty) {
      final match =
          RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(rawDate.trim());
      if (match != null) {
        releaseDate = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      }
    }

    NextAiringEpisode? nextAiring;
    if (json['date'] != null) {
      final parsedDate = DateTime.tryParse(json['date'].toString());
      if (parsedDate != null) {
        final epObj = json['episode'];
        final epNumRaw = epObj is Map ? epObj['episode'] : null;
        final epNum = epNumRaw is int
            ? epNumRaw
            : (int.tryParse(epNumRaw?.toString() ?? '') ?? 1);
        final airingSeconds = parsedDate.millisecondsSinceEpoch ~/ 1000;
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        nextAiring = NextAiringEpisode(
          airingAt: airingSeconds,
          timeUntilAiring: airingSeconds - nowSeconds,
          episode: epNum,
        );
      }
    }

    final rawRank = json['rank'];
    final popularityStr = (rawRank != null &&
            rawRank.toString().isNotEmpty &&
            rawRank.toString() != '0')
        ? rawRank.toString()
        : 'N/A';

    final rawRating = json['ratings']?['simkl']?['rating'];
    final ratingStr = (rawRating != null && rawRating.toString().isNotEmpty)
        ? rawRating.toString()
        : '0.0';

    return Media(
      id: '${json['ids']?['simkl_id']?.toString() ?? json['ids']?['simkl']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString()}*${isMovie ? "MOVIE" : "SERIES"}',
      title: json['title'] ?? 'Unknown Title',
      romajiTitle: json['title'] ?? 'Unknown Title',
      description:
          json['overview'] ?? json['plot'] ?? 'No description available.',
      poster: posterUrl,
      largePoster: posterUrl,
      cover: json['fanart'] != null
          ? 'https://simkl.in/fanart/${json['fanart']}_medium.jpg'
          : posterUrl,
      totalEpisodes: (json['total_episodes'] ??
                  json['total_episodes_count'] ??
                  json['episodes_count'] ??
                  json['episodes'])
              ?.toString() ??
          (isMovie ? '1' : '??'),
      type: isMovie ? 'Movie' : 'Show',
      format: isMovie ? 'Movie' : 'TV',
      rating: ratingStr,
      popularity: popularityStr,
      mediaType: type,
      serviceType: ServicesType.simkl,
      aired: releaseDate,
      nextAiringEpisode: nextAiring,
      genres: [],
    );
  }

  factory Media.froDMedia(DMedia manga, ItemType type) {
    final titleStr = (manga.title != null &&
            manga.title!.isNotEmpty &&
            manga.title != 'Unknown Title')
        ? manga.title!
        : '';
    return Media(
      id: manga.url ?? '',
      title: titleStr,
      romajiTitle: titleStr,
      description: manga.description ?? "No description available.",
      poster: manga.cover ?? "",
      cover: manga.cover,
      totalEpisodes: manga.episodes?.length.toString() ?? '??',
      status: '??',
      mediaType: type,
      aired: 'Unknown',
      totalChapters: manga.episodes?.length.toString(),
      genres: manga.genre ?? [],
      studios: null,
      characters: [],
      relations: [],
      recommendations: [],
      nextAiringEpisode: null,
      rankings: [],
      mediaContent: manga.episodes,
      serviceType: ServicesType.extensions,
    );
  }

  factory Media.fromDManga(DMedia manga, ItemType type) {
    final titleStr = (manga.title != null &&
            manga.title!.isNotEmpty &&
            manga.title != 'Unknown Title')
        ? manga.title!
        : '';
    return Media(
      id: manga.url ?? '',
      title: titleStr,
      romajiTitle: titleStr,
      description: manga.description ?? "No description available.",
      poster: manga.cover ?? "",
      cover: manga.cover,
      totalEpisodes: manga.episodes?.length.toString() ?? '??',
      status: '??',
      mediaType: type,
      aired: 'Unknown',
      totalChapters: manga.episodes?.length.toString(),
      genres: manga.genre ?? [],
      studios: null,
      characters: [],
      relations: [],
      recommendations: [],
      nextAiringEpisode: null,
      rankings: [],
      altMediaContent:
          manga.episodes?.map((e) => e.toChapter()).toList().reversed.toList(),
      serviceType: ServicesType.extensions,
    );
  }

  factory Media.fromJson(Map<String, dynamic> json,
      {Map<String, dynamic>? pageJson}) {
    final isAnime = json['type'] == "ANIME";
    final isNovel = json['type'] == "MANGA" &&
        (json['format'] ?? '').toUpperCase() == 'NOVEL';
    ItemType type = isAnime
        ? ItemType.anime
        : isNovel
            ? ItemType.novel
            : json['type'] == "MANGA"
                ? ItemType.manga
                : ItemType.novel;

    List<Media> recs = [];
    final recsJson = json['recommendations'];
    if (recsJson != null) {
      if (recsJson is Map) {
        if (recsJson['nodes'] != null) {
          recs = (recsJson['nodes'] as List)
              .map((r) => Media.fromRecs(r))
              .toList();
        } else if (recsJson['edges'] != null) {
          recs = (recsJson['edges'] as List)
              .map((e) => Media.fromRecs(e['node'] ?? {}))
              .where((m) => m.id.isNotEmpty && m.id != '')
              .toList();
        }
      } else if (recsJson is List) {
        recs = recsJson
            .map((r) {
              if (r is Map) {
                final nodeData = r['node'] ?? r;
                if (nodeData is Map) {
                  return Media.fromMAL(Map<String, dynamic>.from(r));
                }
              }
              return null;
            })
            .whereType<Media>()
            .toList();
      }
    }

    final titleVal = json['title'];
    final String parsedTitle = (titleVal is Map)
        ? (titleVal['userPreferred']?.toString() ??
            titleVal['english']?.toString() ??
            titleVal['romaji']?.toString() ??
            '??')
        : (titleVal?.toString() ?? '??');
    final String parsedRomaji = (titleVal is Map)
        ? (titleVal['romaji']?.toString() ?? '??')
        : (titleVal?.toString() ?? '??');

    final coverVal = json['coverImage'];
    final String parsedPoster = (coverVal is Map)
        ? (coverVal['large']?.toString() ?? coverVal['medium']?.toString() ?? '??')
        : (json['main_picture'] is Map
            ? json['main_picture']['medium']?.toString() ?? '??'
            : '??');
    final String parsedColor = (coverVal is Map) ? (coverVal['color']?.toString() ?? '') : '';

    final genresVal = json['genres'];
    List<String> parsedGenres = [];
    if (genresVal is List) {
      parsedGenres = genresVal.map((e) {
        if (e is Map) return e['name']?.toString() ?? '??';
        return e.toString();
      }).toList();
    }

    final studiosVal = json['studios'];
    List<String> parsedStudios = [];
    if (studiosVal is Map && studiosVal['nodes'] is List) {
      parsedStudios = (studiosVal['nodes'] as List)
          .map((el) => el['name']?.toString() ?? '??')
          .toList();
    } else if (studiosVal is List) {
      parsedStudios = studiosVal.map((el) {
        if (el is Map) return el['name']?.toString() ?? '??';
        return el.toString();
      }).toList();
    }

    final charactersVal = json['characters'];
    List<Character> parsedCharacters = [];
    if (charactersVal is Map && charactersVal['edges'] is List) {
      parsedCharacters = (charactersVal['edges'] as List)
          .map((character) => Character.fromJson(character))
          .toList();
    }

    final relationsVal = json['relations'];
    List<Relation> parsedRelations = [];
    if (relationsVal is Map && relationsVal['edges'] is List) {
      parsedRelations = (relationsVal['edges'] as List)
          .map((relation) => Relation.fromJson(relation))
          .toList();
    }

    var media = Media(
      id: json['id'].toString(),
      idMal: json['idMal']?.toString() ?? '0',
      romajiTitle: parsedRomaji,
      title: parsedTitle,
      description: json['description']?.toString() ?? '?',
      poster: parsedPoster,
      isAdult: json['isAdult'] ?? false,
      color: parsedColor,
      cover: json['bannerImage']?.toString(),
      totalEpisodes: (json['episodes'] as int?)?.toString() ?? '?',
      type: json['type']?.toString() ?? '?',
      season: json['season']?.toString() ?? '?',
      premiered: '${json['season'] ?? '?'} ${json['seasonYear'] ?? '?'}',
      duration: '${json['duration'] ?? '?'}m',
      status: (json['status']?.toString() ?? '?').replaceAll('_', ' '),
      rating: ((json['averageScore'] ?? 0) / 10).toString(),
      popularity: json['popularity']?.toString() ?? '6900',
      format: formatFormatString(json['format']?.toString(), json['countryOfOrigin']?.toString()),
      sourceMaterial: json['source']?.toString() ?? '?',
      aired: _parseDateRange(json['startDate'], json['endDate']),
      seasonYear: json['seasonYear'] ?? json['startDate']?['year'],
      totalChapters:
          (json['format']?.toString().toLowerCase().replaceAll('-', '_') ==
                  'one_shot')
              ? '1'
              : (json['chapters']?.toString() ?? '?'),
      genres: parsedGenres,
      studios: parsedStudios,
      characters: parsedCharacters,
      relations: parsedRelations,
      recommendations: recs,
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? NextAiringEpisode.fromJson(json['nextAiringEpisode'])
          : null,
      rankings: (json['rankings'] as List?)
              ?.map((ranking) => Ranking.fromJson(ranking))
              .toList() ??
          [],
      mediaType: type,
      serviceType: ServicesType.anilist,
      synonyms: {
        parsedTitle,
        if (parsedRomaji != '??') parsedRomaji,
        if (titleVal is Map) ...{
          if (titleVal['english'] != null) titleVal['english'].toString(),
          if (titleVal['userPreferred'] != null) titleVal['userPreferred'].toString(),
          if (titleVal['romaji'] != null) titleVal['romaji'].toString(),
          if (titleVal['native'] != null) titleVal['native'].toString(),
        },
        if (json['synonyms'] is List)
          ...((json['synonyms'] as List).map((e) => e.toString())),
      }.where((t) => t.isNotEmpty && t != '??' && t != '?').toList(),
      tags: (json['tags'] as List?)
              ?.map((t) => MediaTag.fromJson(t))
              .where((t) => !t.isMediaSpoiler && !t.isGeneralSpoiler)
              .toList() ??
          [],
    );

    if (json['staffPreview'] != null) {
      media.staff = (json['staffPreview']['edges'] as List?)
          ?.map((e) => Staff.fromJson(e))
          .toList();
    }

    if (pageJson != null) {
      media.friendsWatching = (pageJson['mediaList'] as List?)
          ?.map((e) => TrackedMedia.fromSocialJson(e))
          .toList();
    }

    return media;
  }

  void mergeSecondaryData(Map<String, dynamic> mediaJson,
      {Map<String, dynamic>? pageJson}) {
    if (mediaJson['staffPreview'] != null) {
      staff = (mediaJson['staffPreview']['edges'] as List?)
          ?.map((e) => Staff.fromJson(e))
          .toList();
    }

    if (pageJson != null) {
      friendsWatching = (pageJson['mediaList'] as List?)
          ?.map((e) => TrackedMedia.fromSocialJson(e))
          .toList();
    }
  }

  factory Media.fromSmallJson(Map<String, dynamic> json, bool isManga,
      {bool isMal = false, String? role}) {
    if (json['type'] == 'MANGA') {
      // Logger.i('Parsing MANGA: ${json['title']['romaji']}');
    }
    return Media(
      id: (isMal ? json['idMal']?.toString() : json['id'].toString()) ?? '',
      romajiTitle: json['title']['romaji'] ?? '?',
      title: json['title']['userPreferred'] ??
          json['title']['english'] ??
          json['title']['romaji'] ??
          '?',
      description: json['description'] ?? '',
      isAdult: (json['isAdult'] as bool?) ?? false,
      totalEpisodes: (json['episodes'] as int?)?.toString() ?? '?',
      poster: json['coverImage']?['large'] ?? '?',
      largePoster: json['coverImage']?['extraLarge'] ?? '?',
      cover: json['bannerImage'],
      rating: ((json['averageScore'] ?? 0) / 10).toStringAsFixed(1),
      type: json['type'] ?? (isManga ? 'MANGA' : 'ANIME'),
      mediaType: (json['type'] == 'MANGA' || isManga)
          ? ItemType.manga
          : ItemType.anime,
      userStatus: json['mediaListEntry']?['status'],
      serviceType: ServicesType.anilist,
      characterRole: role,
      seasonYear: json['seasonYear'] ?? json['startDate']?['year'],
      synonyms: {
        if (json['title']?['english'] != null)
          json['title']['english'].toString(),
        if (json['title']?['userPreferred'] != null)
          json['title']['userPreferred'].toString(),
        if (json['title']?['romaji'] != null)
          json['title']['romaji'].toString(),
        if (json['title']?['native'] != null)
          json['title']['native'].toString(),
        ...?((json['synonyms'] as List?)?.cast<String>()),
      }.where((t) => t.isNotEmpty && t != '??' && t != '?').toList(),
    )..type = json['type'] ?? (isManga ? 'MANGA' : 'ANIME');
  }
  factory Media.fromCarouselData(CarouselData data, ItemType type) {
    return Media(
        id: data.id!.toString(),
        romajiTitle: data.title ?? '?',
        title: data.title ?? '?',
        poster: data.poster ?? '?',
        rating: data.extraData ?? '0.0',
        mediaType: type,
        serviceType: data.servicesType);
  }

  factory Media.fromRecs(Map<String, dynamic> json) {
    final rec = json['mediaRecommendation'];
    if (rec == null) {
      return Media(
          id: '',
          title: '',
          poster: '',
          rating: '0',
          serviceType: ServicesType.anilist);
    }
    final title = rec['title'];
    return Media(
        id: rec['id'].toString(),
        title: title?['userPreferred'] ??
            title?['english'] ??
            title?['romaji'] ??
            '',
        poster: rec['coverImage']?['large'] ?? '',
        rating: ((rec['averageScore'] ?? 0) / 10).toString(),
        serviceType: ServicesType.anilist);
  }

  factory Media.fromOfflineMedia(OfflineMedia offline, [ItemType? type]) {
    return Media(
      id: offline.mediaId.toString(),
      idMal: offline.idMal ?? '0',
      title: offline.name ?? offline.english ?? offline.jname ?? '?',
      romajiTitle: offline.jname ?? '?',
      description: offline.description ?? '?',
      poster: offline.poster ?? '?',
      cover: offline.cover,
      totalEpisodes: offline.totalEpisodes?.toString() ?? '?',
      type: offline.type ?? '?',
      season: offline.season ?? '?',
      premiered: offline.premiered ?? '?',
      duration: offline.duration ?? '?',
      status: offline.status ?? '?',
      rating: offline.rating ?? '?',
      popularity: offline.popularity ?? '?',
      format: offline.format ?? '?',
      aired: offline.aired ?? '?',
      totalChapters: offline.totalChapters?.toString() ?? '?',
      genres: offline.genres ?? const [],
      studios: offline.studios,
      characters: null,
      relations: null,
      recommendations: const [],
      nextAiringEpisode: null,
      rankings: const [],
      mediaType: type ?? offline.itemType,
      serviceType: offline.serviceIndex != null
          ? ServicesType.values[offline.serviceIndex!]
          : ServicesType.anilist,
    );
  }

  /// Factory for parsing underrated anime/manga from GitHub JSON
  factory Media.fromUnderratedJson(Map<String, dynamic> json, bool isManga) {
    return Media(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? 'Unknown Title',
      romajiTitle: json['title'] ?? 'Unknown Title',
      description:
          json['reason'] ?? json['description'] ?? 'No description available.',
      poster: json['cover'] ?? json['poster'] ?? '',
      cover: json['cover'] ?? json['banner'] ?? '',
      totalEpisodes: json['episodes']?.toString() ?? '?',
      totalChapters: json['chapters']?.toString() ?? '?',
      rating:
          json['score']?.toString() ?? json['averageScore']?.toString() ?? '?',
      type: isManga ? 'MANGA' : 'ANIME',
      mediaType: isManga ? ItemType.manga : ItemType.anime,
      serviceType: ServicesType.anilist,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g.toString())
              .toList() ??
          [],
    );
  }

  /// Factory for parsing media from AniList API for underrated section
  factory Media.fromUnderratedAnilist(Map<String, dynamic> json, bool isManga) {
    ItemType type = isManga ? ItemType.manga : ItemType.anime;

    return Media(
      id: json['id']?.toString() ?? '0',
      idMal: json['idMal']?.toString() ?? '0',
      romajiTitle: json['title']?['romaji'] ?? '?',
      title: json['title']?['userPreferred'] ??
          json['title']?['english'] ??
          json['title']?['romaji'] ??
          '?',
      description: json['description'] ?? '',
      poster: json['coverImage']?['large'] ?? '',
      largePoster: json['coverImage']?['extraLarge'] ?? '',
      cover: json['bannerImage'],
      color: json['coverImage']?['color'] ?? '',
      totalEpisodes: json['episodes']?.toString() ?? '?',
      totalChapters:
          (json['format']?.toString().toLowerCase().replaceAll('-', '_') ==
                  'one_shot')
              ? '1'
              : (json['chapters']?.toString() ?? '?'),
      rating: ((json['averageScore'] ?? 0) / 10).toStringAsFixed(1),
      popularity: json['popularity']?.toString() ?? '0',
      type: json['type'] ?? (isManga ? 'MANGA' : 'ANIME'),
      status: (json['status'] ?? '?').replaceAll('_', ' '),
      format: json['format'] ?? '?',
      season: json['season'] ?? '?',
      seasonYear: json['seasonYear'] ?? json['startDate']?['year'],
      premiered: '${json['season'] ?? '?'} ${json['seasonYear'] ?? '?'}',
      genres: List<String>.from(json['genres'] ?? []),
      studios: (json['studios']?['nodes'] as List?)
              ?.map((el) => el['name'].toString())
              .toList() ??
          [],
      mediaType: type,
      serviceType: ServicesType.anilist,
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? NextAiringEpisode.fromJson(json['nextAiringEpisode'])
          : null,
    );
  }

  static String _parseDateRange(
      Map<String, dynamic>? start, Map<String, dynamic>? end) {
    if (start == null && end == null) return 'Unknown';
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);
    return '$startDate to $endDate';
  }

  static String _formatDate(Map<String, dynamic>? date) {
    if (date == null) return '?';
    return '${date['year'] ?? '?'}-${date['month']?.toString().padLeft(2, '0') ?? '?'}-${date['day']?.toString().padLeft(2, '0') ?? '?'}';
  }
}

class NextAiringEpisode {
  final int airingAt;
  final int timeUntilAiring;
  final int episode;

  NextAiringEpisode({
    required this.airingAt,
    required this.timeUntilAiring,
    required this.episode,
  });

  factory NextAiringEpisode.fromJson(Map<String, dynamic> json) {
    return NextAiringEpisode(
        airingAt: json['airingAt'],
        timeUntilAiring: json['timeUntilAiring'],
        episode: json['episode']);
  }
}

class Ranking {
  final int rank;
  final String type;
  final int year;

  Ranking({required this.rank, required this.type, required this.year});

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      rank: json['rank'] ?? 0,
      type: json['type'] ?? '?',
      year: json['year'] ?? 0,
    );
  }
}

class MediaTag {
  final String name;
  final int rank;
  final bool isMediaSpoiler;
  final bool isGeneralSpoiler;

  const MediaTag({
    required this.name,
    required this.rank,
    this.isMediaSpoiler = false,
    this.isGeneralSpoiler = false,
  });

  factory MediaTag.fromJson(Map<String, dynamic> json) {
    return MediaTag(
      name: json['name'] ?? '',
      rank: json['rank'] ?? 0,
      isMediaSpoiler: json['isMediaSpoiler'] ?? false,
      isGeneralSpoiler: json['isGeneralSpoiler'] ?? false,
    );
  }
}

extension RemoveDupesOnTM on List<TrackedMedia> {
  List<TrackedMedia> removeDupes() {
    final seen = <String>{};
    return where((media) => seen.add(media.id!)).toList();
  }
}

class ExternalLink {
  final String site;
  final String url;
  final String? icon;

  ExternalLink({
    required this.site,
    required this.url,
    this.icon,
  });
}

String formatFormatString(String? format, String? countryOfOrigin) {
  if (format == null) return '?';
  final upperFormat = format.toUpperCase();
  if (upperFormat == 'MANGA') {
    final origin = (countryOfOrigin ?? '').toUpperCase();
    if (origin == 'KR') return 'Manga (South Korea)';
    if (origin == 'CN') return 'Manga (China)';
    if (origin == 'TW') return 'Manga (Taiwan)';
    return 'Manga';
  }
  switch (upperFormat) {
    case 'TV': return 'TV';
    case 'TV_SHORT': return 'TV Short';
    case 'MOVIE': return 'Movie';
    case 'SPECIAL': return 'Special';
    case 'OVA': return 'OVA';
    case 'ONA': return 'ONA';
    case 'MUSIC': return 'Music';
    case 'MANGA': return 'Manga';
    case 'NOVEL': return 'Novel';
    case 'ONE_SHOT': return 'One Shot';
    default:
      return upperFormat.replaceAll('_', ' ').split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0] + word.substring(1).toLowerCase();
      }).join(' ');
  }
}

String formatSourceMaterial(String? source) {
  if (source == null || source == '?') return '?';
  final upper = source.toUpperCase();
  switch (upper) {
    case 'ORIGINAL': return 'Original';
    case 'LIGHT_NOVEL': return 'Light Novel';
    case 'VISUAL_NOVEL': return 'Visual Novel';
    case 'VIDEO_GAME': return 'Video Game';
    case 'WEB_NOVEL': return 'Web Novel';
    case 'LIVE_ACTION': return 'Live Action';
    case 'MULTIMEDIA_PROJECT': return 'Multimedia Project';
    case 'PICTURE_BOOK': return 'Picture Book';
    default:
      return upper.replaceAll('_', ' ').split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0] + word.substring(1).toLowerCase();
      }).join(' ');
  }
}
