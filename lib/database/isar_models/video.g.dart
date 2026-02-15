// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const VideoSchema = Schema(
  name: r'Video',
  id: 113594071489080673,
  properties: {
    r'audios': PropertySchema(
      id: 0,
      name: r'audios',
      type: IsarType.objectList,
      target: r'Track',
    ),
    r'headerKeys': PropertySchema(
      id: 1,
      name: r'headerKeys',
      type: IsarType.stringList,
    ),
    r'headerValues': PropertySchema(
      id: 2,
      name: r'headerValues',
      type: IsarType.stringList,
    ),
    r'originalUrl': PropertySchema(
      id: 3,
      name: r'originalUrl',
      type: IsarType.string,
    ),
    r'quality': PropertySchema(
      id: 4,
      name: r'quality',
      type: IsarType.string,
    ),
    r'subtitles': PropertySchema(
      id: 5,
      name: r'subtitles',
      type: IsarType.objectList,
      target: r'Track',
    ),
    r'url': PropertySchema(
      id: 6,
      name: r'url',
      type: IsarType.string,
    )
  },
  estimateSize: _videoEstimateSize,
  serialize: _videoSerialize,
  deserialize: _videoDeserialize,
  deserializeProp: _videoDeserializeProp,
);

int _videoEstimateSize(
  Video object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.audios;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[Track]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += TrackSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final list = object.headerKeys;
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
    final list = object.headerValues;
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
    final value = object.originalUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.quality;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.subtitles;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[Track]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += TrackSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.url;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _videoSerialize(
  Video object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<Track>(
    offsets[0],
    allOffsets,
    TrackSchema.serialize,
    object.audios,
  );
  writer.writeStringList(offsets[1], object.headerKeys);
  writer.writeStringList(offsets[2], object.headerValues);
  writer.writeString(offsets[3], object.originalUrl);
  writer.writeString(offsets[4], object.quality);
  writer.writeObjectList<Track>(
    offsets[5],
    allOffsets,
    TrackSchema.serialize,
    object.subtitles,
  );
  writer.writeString(offsets[6], object.url);
}

Video _videoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Video(
    audios: reader.readObjectList<Track>(
      offsets[0],
      TrackSchema.deserialize,
      allOffsets,
      Track(),
    ),
    headerKeys: reader.readStringList(offsets[1]),
    headerValues: reader.readStringList(offsets[2]),
    originalUrl: reader.readStringOrNull(offsets[3]),
    quality: reader.readStringOrNull(offsets[4]),
    subtitles: reader.readObjectList<Track>(
      offsets[5],
      TrackSchema.deserialize,
      allOffsets,
      Track(),
    ),
    url: reader.readStringOrNull(offsets[6]),
  );
  return object;
}

P _videoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<Track>(
        offset,
        TrackSchema.deserialize,
        allOffsets,
        Track(),
      )) as P;
    case 1:
      return (reader.readStringList(offset)) as P;
    case 2:
      return (reader.readStringList(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readObjectList<Track>(
        offset,
        TrackSchema.deserialize,
        allOffsets,
        Track(),
      )) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension VideoQueryFilter on QueryBuilder<Video, Video, QFilterCondition> {
  QueryBuilder<Video, Video, QAfterFilterCondition> audiosIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audios',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> audiosIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audios',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> audiosLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> audiosIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> audiosIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> audiosLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> audiosLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> audiosLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audios',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'headerKeys',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'headerKeys',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headerKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition>
      headerKeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'headerKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'headerKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'headerKeys',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'headerKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'headerKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'headerKeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'headerKeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headerKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition>
      headerKeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'headerKeys',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerKeys',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerKeys',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerKeys',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerKeys',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerKeys',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerKeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerKeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'headerValues',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'headerValues',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headerValues',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition>
      headerValuesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'headerValues',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'headerValues',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'headerValues',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition>
      headerValuesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'headerValues',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'headerValues',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'headerValues',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'headerValues',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition>
      headerValuesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headerValues',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition>
      headerValuesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'headerValues',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerValues',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerValues',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerValues',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerValues',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition>
      headerValuesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerValues',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> headerValuesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'headerValues',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalUrl',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalUrl',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> originalUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'quality',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'quality',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quality',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quality',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quality',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quality',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'quality',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'quality',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'quality',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'quality',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quality',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> qualityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'quality',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subtitles',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subtitles',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subtitles',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subtitles',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subtitles',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subtitles',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subtitles',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subtitles',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'url',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'url',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }
}

extension VideoQueryObject on QueryBuilder<Video, Video, QFilterCondition> {
  QueryBuilder<Video, Video, QAfterFilterCondition> audiosElement(
      FilterQuery<Track> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'audios');
    });
  }

  QueryBuilder<Video, Video, QAfterFilterCondition> subtitlesElement(
      FilterQuery<Track> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'subtitles');
    });
  }
}
