// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_media.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOfflineMediaCollection on Isar {
  IsarCollection<OfflineMedia> get offlineMedias => this.collection();
}

const OfflineMediaSchema = CollectionSchema(
  name: r'OfflineMedia',
  id: -1071799766706376061,
  properties: {
    r'aired': PropertySchema(
      id: 0,
      name: r'aired',
      type: IsarType.string,
    ),
    r'chapters': PropertySchema(
      id: 1,
      name: r'chapters',
      type: IsarType.objectList,
      target: r'Chapter',
    ),
    r'cover': PropertySchema(
      id: 2,
      name: r'cover',
      type: IsarType.string,
    ),
    r'currentChapter': PropertySchema(
      id: 3,
      name: r'currentChapter',
      type: IsarType.object,
      target: r'Chapter',
    ),
    r'currentEpisode': PropertySchema(
      id: 4,
      name: r'currentEpisode',
      type: IsarType.object,
      target: r'Episode',
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'duration': PropertySchema(
      id: 6,
      name: r'duration',
      type: IsarType.string,
    ),
    r'english': PropertySchema(
      id: 7,
      name: r'english',
      type: IsarType.string,
    ),
    r'episodes': PropertySchema(
      id: 8,
      name: r'episodes',
      type: IsarType.objectList,
      target: r'Episode',
    ),
    r'format': PropertySchema(
      id: 9,
      name: r'format',
      type: IsarType.string,
    ),
    r'genres': PropertySchema(
      id: 10,
      name: r'genres',
      type: IsarType.stringList,
    ),
    r'japanese': PropertySchema(
      id: 11,
      name: r'japanese',
      type: IsarType.string,
    ),
    r'jname': PropertySchema(
      id: 12,
      name: r'jname',
      type: IsarType.string,
    ),
    r'mediaId': PropertySchema(
      id: 13,
      name: r'mediaId',
      type: IsarType.string,
    ),
    r'mediaTypeIndex': PropertySchema(
      id: 14,
      name: r'mediaTypeIndex',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 15,
      name: r'name',
      type: IsarType.string,
    ),
    r'popularity': PropertySchema(
      id: 16,
      name: r'popularity',
      type: IsarType.string,
    ),
    r'poster': PropertySchema(
      id: 17,
      name: r'poster',
      type: IsarType.string,
    ),
    r'premiered': PropertySchema(
      id: 18,
      name: r'premiered',
      type: IsarType.string,
    ),
    r'rating': PropertySchema(
      id: 19,
      name: r'rating',
      type: IsarType.string,
    ),
    r'readChapters': PropertySchema(
      id: 20,
      name: r'readChapters',
      type: IsarType.objectList,
      target: r'Chapter',
    ),
    r'season': PropertySchema(
      id: 21,
      name: r'season',
      type: IsarType.string,
    ),
    r'serviceIndex': PropertySchema(
      id: 22,
      name: r'serviceIndex',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 23,
      name: r'status',
      type: IsarType.string,
    ),
    r'studios': PropertySchema(
      id: 24,
      name: r'studios',
      type: IsarType.stringList,
    ),
    r'totalChapters': PropertySchema(
      id: 25,
      name: r'totalChapters',
      type: IsarType.string,
    ),
    r'totalEpisodes': PropertySchema(
      id: 26,
      name: r'totalEpisodes',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 27,
      name: r'type',
      type: IsarType.string,
    ),
    r'watchedEpisodes': PropertySchema(
      id: 28,
      name: r'watchedEpisodes',
      type: IsarType.objectList,
      target: r'Episode',
    )
  },
  estimateSize: _offlineMediaEstimateSize,
  serialize: _offlineMediaSerialize,
  deserialize: _offlineMediaDeserialize,
  deserializeProp: _offlineMediaDeserializeProp,
  idName: r'id',
  indexes: {
    r'mediaId': IndexSchema(
      id: -8001372983137409759,
      name: r'mediaId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mediaId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'Chapter': ChapterSchema,
    r'Episode': EpisodeSchema,
    r'Video': VideoSchema,
    r'Track': TrackSchema
  },
  getId: _offlineMediaGetId,
  getLinks: _offlineMediaGetLinks,
  attach: _offlineMediaAttach,
  version: '3.3.0-dev.3',
);

int _offlineMediaEstimateSize(
  OfflineMedia object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aired;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.chapters;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[Chapter]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += ChapterSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.cover;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.currentChapter;
    if (value != null) {
      bytesCount += 3 +
          ChapterSchema.estimateSize(value, allOffsets[Chapter]!, allOffsets);
    }
  }
  {
    final value = object.currentEpisode;
    if (value != null) {
      bytesCount += 3 +
          EpisodeSchema.estimateSize(value, allOffsets[Episode]!, allOffsets);
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.duration;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.english;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.episodes;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[Episode]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += EpisodeSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.format;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.genres;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final value = object.japanese;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.jname;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mediaId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.popularity;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.poster;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.premiered;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rating;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.readChapters;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[Chapter]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += ChapterSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.season;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.status;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.studios;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final value = object.totalChapters;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.totalEpisodes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.watchedEpisodes;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[Episode]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += EpisodeSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  return bytesCount;
}

void _offlineMediaSerialize(
  OfflineMedia object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aired);
  writer.writeObjectList<Chapter>(
    offsets[1],
    allOffsets,
    ChapterSchema.serialize,
    object.chapters,
  );
  writer.writeString(offsets[2], object.cover);
  writer.writeObject<Chapter>(
    offsets[3],
    allOffsets,
    ChapterSchema.serialize,
    object.currentChapter,
  );
  writer.writeObject<Episode>(
    offsets[4],
    allOffsets,
    EpisodeSchema.serialize,
    object.currentEpisode,
  );
  writer.writeString(offsets[5], object.description);
  writer.writeString(offsets[6], object.duration);
  writer.writeString(offsets[7], object.english);
  writer.writeObjectList<Episode>(
    offsets[8],
    allOffsets,
    EpisodeSchema.serialize,
    object.episodes,
  );
  writer.writeString(offsets[9], object.format);
  writer.writeStringList(offsets[10], object.genres);
  writer.writeString(offsets[11], object.japanese);
  writer.writeString(offsets[12], object.jname);
  writer.writeString(offsets[13], object.mediaId);
  writer.writeLong(offsets[14], object.mediaTypeIndex);
  writer.writeString(offsets[15], object.name);
  writer.writeString(offsets[16], object.popularity);
  writer.writeString(offsets[17], object.poster);
  writer.writeString(offsets[18], object.premiered);
  writer.writeString(offsets[19], object.rating);
  writer.writeObjectList<Chapter>(
    offsets[20],
    allOffsets,
    ChapterSchema.serialize,
    object.readChapters,
  );
  writer.writeString(offsets[21], object.season);
  writer.writeLong(offsets[22], object.serviceIndex);
  writer.writeString(offsets[23], object.status);
  writer.writeStringList(offsets[24], object.studios);
  writer.writeString(offsets[25], object.totalChapters);
  writer.writeString(offsets[26], object.totalEpisodes);
  writer.writeString(offsets[27], object.type);
  writer.writeObjectList<Episode>(
    offsets[28],
    allOffsets,
    EpisodeSchema.serialize,
    object.watchedEpisodes,
  );
}

OfflineMedia _offlineMediaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OfflineMedia(
    aired: reader.readStringOrNull(offsets[0]),
    chapters: reader.readObjectList<Chapter>(
      offsets[1],
      ChapterSchema.deserialize,
      allOffsets,
      Chapter(),
    ),
    cover: reader.readStringOrNull(offsets[2]),
    currentChapter: reader.readObjectOrNull<Chapter>(
      offsets[3],
      ChapterSchema.deserialize,
      allOffsets,
    ),
    currentEpisode: reader.readObjectOrNull<Episode>(
      offsets[4],
      EpisodeSchema.deserialize,
      allOffsets,
    ),
    description: reader.readStringOrNull(offsets[5]),
    duration: reader.readStringOrNull(offsets[6]),
    english: reader.readStringOrNull(offsets[7]),
    episodes: reader.readObjectList<Episode>(
      offsets[8],
      EpisodeSchema.deserialize,
      allOffsets,
      Episode(),
    ),
    format: reader.readStringOrNull(offsets[9]),
    genres: reader.readStringList(offsets[10]),
    japanese: reader.readStringOrNull(offsets[11]),
    jname: reader.readStringOrNull(offsets[12]),
    mediaId: reader.readStringOrNull(offsets[13]),
    mediaTypeIndex: reader.readLongOrNull(offsets[14]),
    name: reader.readStringOrNull(offsets[15]),
    popularity: reader.readStringOrNull(offsets[16]),
    poster: reader.readStringOrNull(offsets[17]),
    premiered: reader.readStringOrNull(offsets[18]),
    rating: reader.readStringOrNull(offsets[19]),
    readChapters: reader.readObjectList<Chapter>(
      offsets[20],
      ChapterSchema.deserialize,
      allOffsets,
      Chapter(),
    ),
    season: reader.readStringOrNull(offsets[21]),
    serviceIndex: reader.readLongOrNull(offsets[22]),
    status: reader.readStringOrNull(offsets[23]),
    studios: reader.readStringList(offsets[24]),
    totalChapters: reader.readStringOrNull(offsets[25]),
    totalEpisodes: reader.readStringOrNull(offsets[26]),
    type: reader.readStringOrNull(offsets[27]),
    watchedEpisodes: reader.readObjectList<Episode>(
      offsets[28],
      EpisodeSchema.deserialize,
      allOffsets,
      Episode(),
    ),
  );
  object.id = id;
  return object;
}

P _offlineMediaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectList<Chapter>(
        offset,
        ChapterSchema.deserialize,
        allOffsets,
        Chapter(),
      )) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readObjectOrNull<Chapter>(
        offset,
        ChapterSchema.deserialize,
        allOffsets,
      )) as P;
    case 4:
      return (reader.readObjectOrNull<Episode>(
        offset,
        EpisodeSchema.deserialize,
        allOffsets,
      )) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readObjectList<Episode>(
        offset,
        EpisodeSchema.deserialize,
        allOffsets,
        Episode(),
      )) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringList(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readObjectList<Chapter>(
        offset,
        ChapterSchema.deserialize,
        allOffsets,
        Chapter(),
      )) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readLongOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readStringList(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readObjectList<Episode>(
        offset,
        EpisodeSchema.deserialize,
        allOffsets,
        Episode(),
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _offlineMediaGetId(OfflineMedia object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _offlineMediaGetLinks(OfflineMedia object) {
  return [];
}

void _offlineMediaAttach(
    IsarCollection<dynamic> col, Id id, OfflineMedia object) {
  object.id = id;
}

extension OfflineMediaQueryWhereSort
    on QueryBuilder<OfflineMedia, OfflineMedia, QWhere> {
  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OfflineMediaQueryWhere
    on QueryBuilder<OfflineMedia, OfflineMedia, QWhereClause> {
  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> mediaIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mediaId',
        value: [null],
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause>
      mediaIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mediaId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> mediaIdEqualTo(
      String? mediaId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mediaId',
        value: [mediaId],
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterWhereClause> mediaIdNotEqualTo(
      String? mediaId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mediaId',
              lower: [],
              upper: [mediaId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mediaId',
              lower: [mediaId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mediaId',
              lower: [mediaId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mediaId',
              lower: [],
              upper: [mediaId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OfflineMediaQueryFilter
    on QueryBuilder<OfflineMedia, OfflineMedia, QFilterCondition> {
  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      airedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aired',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      airedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aired',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> airedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aired',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      airedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aired',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> airedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aired',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> airedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aired',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      airedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aired',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> airedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aired',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> airedContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aired',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> airedMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aired',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      airedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aired',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      airedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aired',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chapters',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chapters',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'chapters',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'chapters',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'chapters',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'chapters',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'chapters',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'chapters',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      coverIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cover',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      coverIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cover',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> coverEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cover',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      coverGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cover',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> coverLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cover',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> coverBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cover',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      coverStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cover',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> coverEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cover',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> coverContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cover',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> coverMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cover',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      coverIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cover',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      coverIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cover',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      currentChapterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentChapter',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      currentChapterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentChapter',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      currentEpisodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentEpisode',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      currentEpisodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentEpisode',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'duration',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'duration',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duration',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duration',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duration',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'duration',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'duration',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'duration',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'duration',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duration',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      durationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'duration',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'english',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'english',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'english',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'english',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'english',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'english',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'english',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'english',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'english',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'english',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'english',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      englishIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'english',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'episodes',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'episodes',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'format',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'format',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> formatEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'format',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'format',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'format',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> formatBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'format',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'format',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'format',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'format',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> formatMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'format',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'format',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      formatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'format',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'genres',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'genres',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'genres',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'genres',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'genres',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'genres',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'genres',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'genres',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'genres',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'genres',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'genres',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'genres',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'genres',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'genres',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'genres',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'genres',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'genres',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      genresLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'genres',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'japanese',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'japanese',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'japanese',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'japanese',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'japanese',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      japaneseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'japanese',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      jnameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'jname',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      jnameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'jname',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> jnameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jname',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      jnameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jname',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> jnameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jname',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> jnameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jname',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      jnameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jname',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> jnameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jname',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> jnameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jname',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> jnameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jname',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      jnameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jname',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      jnameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jname',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaId',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaId',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaTypeIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaTypeIndex',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaTypeIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaTypeIndex',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaTypeIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaTypeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaTypeIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaTypeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaTypeIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaTypeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      mediaTypeIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaTypeIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'popularity',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'popularity',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'popularity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'popularity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'popularity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'popularity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'popularity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'popularity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'popularity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'popularity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'popularity',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      popularityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'popularity',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'poster',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'poster',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> posterEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> posterBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'poster',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> posterMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'poster',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poster',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      posterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'poster',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'premiered',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'premiered',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'premiered',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'premiered',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'premiered',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'premiered',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'premiered',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'premiered',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'premiered',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'premiered',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'premiered',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      premieredIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'premiered',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rating',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rating',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> ratingEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> ratingBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> ratingMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rating',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      ratingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rating',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'readChapters',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'readChapters',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readChapters',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readChapters',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readChapters',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readChapters',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readChapters',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readChapters',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'season',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'season',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> seasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> seasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'season',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> seasonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'season',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'season',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      seasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'season',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      serviceIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serviceIndex',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      serviceIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serviceIndex',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      serviceIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      serviceIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serviceIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      serviceIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serviceIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      serviceIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serviceIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> statusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> statusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'studios',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'studios',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studios',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studios',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studios',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studios',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'studios',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'studios',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'studios',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'studios',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studios',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'studios',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studios',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studios',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studios',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studios',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studios',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      studiosLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'studios',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalChapters',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalChapters',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalChapters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalChapters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalChapters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalChapters',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'totalChapters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'totalChapters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'totalChapters',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'totalChapters',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalChapters',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalChaptersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'totalChapters',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalEpisodes',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalEpisodes',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalEpisodes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalEpisodes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalEpisodes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalEpisodes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'totalEpisodes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'totalEpisodes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'totalEpisodes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'totalEpisodes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalEpisodes',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      totalEpisodesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'totalEpisodes',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> typeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'watchedEpisodes',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'watchedEpisodes',
      ));
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'watchedEpisodes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'watchedEpisodes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'watchedEpisodes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'watchedEpisodes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'watchedEpisodes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'watchedEpisodes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension OfflineMediaQueryObject
    on QueryBuilder<OfflineMedia, OfflineMedia, QFilterCondition> {
  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      chaptersElement(FilterQuery<Chapter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'chapters');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      currentChapter(FilterQuery<Chapter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'currentChapter');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      currentEpisode(FilterQuery<Episode> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'currentEpisode');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      episodesElement(FilterQuery<Episode> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'episodes');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      readChaptersElement(FilterQuery<Chapter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'readChapters');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterFilterCondition>
      watchedEpisodesElement(FilterQuery<Episode> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'watchedEpisodes');
    });
  }
}

extension OfflineMediaQueryLinks
    on QueryBuilder<OfflineMedia, OfflineMedia, QFilterCondition> {}

extension OfflineMediaQuerySortBy
    on QueryBuilder<OfflineMedia, OfflineMedia, QSortBy> {
  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByAired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aired', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByAiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aired', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByJapanese() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByJapaneseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByJname() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jname', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByJnameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jname', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      sortByMediaTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      sortByMediaTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByPopularity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularity', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      sortByPopularityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularity', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByPoster() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poster', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByPosterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poster', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByPremiered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiered', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByPremieredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiered', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortBySeason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortBySeasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByServiceIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceIndex', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      sortByServiceIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceIndex', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByTotalChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      sortByTotalChaptersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      sortByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension OfflineMediaQuerySortThenBy
    on QueryBuilder<OfflineMedia, OfflineMedia, QSortThenBy> {
  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByAired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aired', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByAiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aired', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'english', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'format', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByJapanese() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByJapaneseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByJname() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jname', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByJnameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jname', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      thenByMediaTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      thenByMediaTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByPopularity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularity', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      thenByPopularityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'popularity', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByPoster() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poster', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByPosterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poster', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByPremiered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiered', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByPremieredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiered', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenBySeason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenBySeasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByServiceIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceIndex', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      thenByServiceIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceIndex', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByTotalChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      thenByTotalChaptersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy>
      thenByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension OfflineMediaQueryWhereDistinct
    on QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> {
  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByAired(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aired', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByCover(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cover', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByDuration(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duration', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByEnglish(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'english', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByFormat(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'format', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByGenres() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'genres');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByJapanese(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'japanese', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByJname(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jname', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByMediaId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct>
      distinctByMediaTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaTypeIndex');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByPopularity(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'popularity', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByPoster(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'poster', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByPremiered(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'premiered', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByRating(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctBySeason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'season', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByServiceIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serviceIndex');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByStudios() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studios');
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByTotalChapters(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalChapters',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByTotalEpisodes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalEpisodes',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineMedia, OfflineMedia, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension OfflineMediaQueryProperty
    on QueryBuilder<OfflineMedia, OfflineMedia, QQueryProperty> {
  QueryBuilder<OfflineMedia, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> airedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aired');
    });
  }

  QueryBuilder<OfflineMedia, List<Chapter>?, QQueryOperations>
      chaptersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapters');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> coverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cover');
    });
  }

  QueryBuilder<OfflineMedia, Chapter?, QQueryOperations>
      currentChapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentChapter');
    });
  }

  QueryBuilder<OfflineMedia, Episode?, QQueryOperations>
      currentEpisodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentEpisode');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> durationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duration');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> englishProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'english');
    });
  }

  QueryBuilder<OfflineMedia, List<Episode>?, QQueryOperations>
      episodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episodes');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> formatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'format');
    });
  }

  QueryBuilder<OfflineMedia, List<String>?, QQueryOperations> genresProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'genres');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> japaneseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'japanese');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> jnameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jname');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> mediaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaId');
    });
  }

  QueryBuilder<OfflineMedia, int?, QQueryOperations> mediaTypeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaTypeIndex');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> popularityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'popularity');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> posterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'poster');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> premieredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'premiered');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<OfflineMedia, List<Chapter>?, QQueryOperations>
      readChaptersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readChapters');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> seasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'season');
    });
  }

  QueryBuilder<OfflineMedia, int?, QQueryOperations> serviceIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serviceIndex');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<OfflineMedia, List<String>?, QQueryOperations>
      studiosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studios');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations>
      totalChaptersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalChapters');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations>
      totalEpisodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalEpisodes');
    });
  }

  QueryBuilder<OfflineMedia, String?, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<OfflineMedia, List<Episode>?, QQueryOperations>
      watchedEpisodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'watchedEpisodes');
    });
  }
}
