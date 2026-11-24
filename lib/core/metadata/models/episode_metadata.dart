import 'package:anymex/models/Media/media.dart';
import 'package:flutter/material.dart';

class EpisodeMetadataItem {
  final String number;
  final String? title;
  final String? description;
  final String? thumbnail;
  final bool? isFiller;
  final bool? isRecap;
  final String? airDate;
  final int? runtimeMinutes;
  final double? rating;
  final String? sourceId;

  const EpisodeMetadataItem({
    required this.number,
    this.title,
    this.description,
    this.thumbnail,
    this.isFiller,
    this.isRecap,
    this.airDate,
    this.runtimeMinutes,
    this.rating,
    this.sourceId,
  });

  EpisodeMetadataItem copyWith({
    String? number,
    String? title,
    String? description,
    String? thumbnail,
    bool? isFiller,
    bool? isRecap,
    String? airDate,
    int? runtimeMinutes,
    double? rating,
    String? sourceId,
  }) {
    return EpisodeMetadataItem(
      number: number ?? this.number,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      isFiller: isFiller ?? this.isFiller,
      isRecap: isRecap ?? this.isRecap,
      airDate: airDate ?? this.airDate,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      rating: rating ?? this.rating,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  EpisodeMetadataItem mergeWith(EpisodeMetadataItem other) {
    return EpisodeMetadataItem(
      number: number,
      title: (title != null && title!.trim().isNotEmpty) ? title : other.title,
      description: (description != null && description!.trim().isNotEmpty)
          ? description
          : other.description,
      thumbnail: (thumbnail != null && thumbnail!.trim().isNotEmpty)
          ? thumbnail
          : other.thumbnail,
      isFiller: isFiller ?? other.isFiller,
      isRecap: isRecap ?? other.isRecap,
      airDate: (airDate != null && airDate!.trim().isNotEmpty)
          ? airDate
          : other.airDate,
      runtimeMinutes: runtimeMinutes ?? other.runtimeMinutes,
      rating: rating ?? other.rating,
      sourceId: sourceId ?? other.sourceId,
    );
  }
}

class MetadataTargetIds {
  String? anilistId;
  String? malId;
  String? simklId;
  String? kitsuId;
  String? tmdbId;
  String? imdbId;
  String? title;

  MetadataTargetIds({
    this.anilistId,
    this.malId,
    this.simklId,
    this.kitsuId,
    this.tmdbId,
    this.imdbId,
    this.title,
  });

  bool get hasAnyId =>
      (anilistId != null && anilistId != '0' && anilistId!.isNotEmpty) ||
      (malId != null && malId != '0' && malId!.isNotEmpty) ||
      (simklId != null && simklId != '0' && simklId!.isNotEmpty) ||
      (kitsuId != null && kitsuId != '0' && kitsuId!.isNotEmpty) ||
      (tmdbId != null && tmdbId!.isNotEmpty) ||
      (imdbId != null && imdbId!.isNotEmpty);

  String get cacheKey =>
      '${anilistId ?? ""}_${malId ?? ""}_${simklId ?? ""}_${kitsuId ?? ""}_${tmdbId ?? ""}';

  factory MetadataTargetIds.fromMedia(Media media) {
    final mediaIds = media.mediaIds;
    return MetadataTargetIds(
      anilistId: media.id != '0' ? media.id : mediaIds?.anilistId,
      malId: media.idMal != '0' ? media.idMal : mediaIds?.malId,
      simklId: mediaIds?.simklId,
      kitsuId: mediaIds?.kitsuId,
      tmdbId: mediaIds?.tmdbId,
      title: media.title,
    );
  }
}

class MetadataProviderInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const MetadataProviderInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
