// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_activity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyActivityCollection on Isar {
  IsarCollection<DailyActivity> get dailyActivitys => this.collection();
}

const DailyActivitySchema = CollectionSchema(
  name: r'DailyActivity',
  id: -9126954269818939179,
  properties: {
    r'activeMediaIds': PropertySchema(
      id: 0,
      name: r'activeMediaIds',
      type: IsarType.stringList,
    ),
    r'chaptersRead': PropertySchema(
      id: 1,
      name: r'chaptersRead',
      type: IsarType.long,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'episodesWatched': PropertySchema(
      id: 3,
      name: r'episodesWatched',
      type: IsarType.long,
    ),
    r'readTimeMinutes': PropertySchema(
      id: 4,
      name: r'readTimeMinutes',
      type: IsarType.long,
    ),
    r'watchTimeMinutes': PropertySchema(
      id: 5,
      name: r'watchTimeMinutes',
      type: IsarType.long,
    )
  },
  estimateSize: _dailyActivityEstimateSize,
  serialize: _dailyActivitySerialize,
  deserialize: _dailyActivityDeserialize,
  deserializeProp: _dailyActivityDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyActivityGetId,
  getLinks: _dailyActivityGetLinks,
  attach: _dailyActivityAttach,
  version: '3.3.0-dev.3',
);

int _dailyActivityEstimateSize(
  DailyActivity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activeMediaIds.length * 3;
  {
    for (var i = 0; i < object.activeMediaIds.length; i++) {
      final value = object.activeMediaIds[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _dailyActivitySerialize(
  DailyActivity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.activeMediaIds);
  writer.writeLong(offsets[1], object.chaptersRead);
  writer.writeDateTime(offsets[2], object.date);
  writer.writeLong(offsets[3], object.episodesWatched);
  writer.writeLong(offsets[4], object.readTimeMinutes);
  writer.writeLong(offsets[5], object.watchTimeMinutes);
}

DailyActivity _dailyActivityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyActivity();
  object.activeMediaIds = reader.readStringList(offsets[0]) ?? [];
  object.chaptersRead = reader.readLong(offsets[1]);
  object.date = reader.readDateTime(offsets[2]);
  object.episodesWatched = reader.readLong(offsets[3]);
  object.id = id;
  object.readTimeMinutes = reader.readLong(offsets[4]);
  object.watchTimeMinutes = reader.readLong(offsets[5]);
  return object;
}

P _dailyActivityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyActivityGetId(DailyActivity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyActivityGetLinks(DailyActivity object) {
  return [];
}

void _dailyActivityAttach(
    IsarCollection<dynamic> col, Id id, DailyActivity object) {
  object.id = id;
}

extension DailyActivityByIndex on IsarCollection<DailyActivity> {
  Future<DailyActivity?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  DailyActivity? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<DailyActivity?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<DailyActivity?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(DailyActivity object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(DailyActivity object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<DailyActivity> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<DailyActivity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension DailyActivityQueryWhereSort
    on QueryBuilder<DailyActivity, DailyActivity, QWhere> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension DailyActivityQueryWhere
    on QueryBuilder<DailyActivity, DailyActivity, QWhereClause> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateNotEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyActivityQueryFilter
    on QueryBuilder<DailyActivity, DailyActivity, QFilterCondition> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeMediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activeMediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activeMediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activeMediaIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activeMediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activeMediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activeMediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activeMediaIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeMediaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activeMediaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeMediaIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeMediaIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeMediaIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeMediaIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeMediaIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      activeMediaIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeMediaIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      chaptersReadEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chaptersRead',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      chaptersReadGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chaptersRead',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      chaptersReadLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chaptersRead',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      chaptersReadBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chaptersRead',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      episodesWatchedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'episodesWatched',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      episodesWatchedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'episodesWatched',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      episodesWatchedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'episodesWatched',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      episodesWatchedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'episodesWatched',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      readTimeMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      readTimeMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      readTimeMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      readTimeMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      watchTimeMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'watchTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      watchTimeMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'watchTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      watchTimeMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'watchTimeMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      watchTimeMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'watchTimeMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyActivityQueryObject
    on QueryBuilder<DailyActivity, DailyActivity, QFilterCondition> {}

extension DailyActivityQueryLinks
    on QueryBuilder<DailyActivity, DailyActivity, QFilterCondition> {}

extension DailyActivityQuerySortBy
    on QueryBuilder<DailyActivity, DailyActivity, QSortBy> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByChaptersRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chaptersRead', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByChaptersReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chaptersRead', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByEpisodesWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodesWatched', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByEpisodesWatchedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodesWatched', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByReadTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByReadTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByWatchTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByWatchTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchTimeMinutes', Sort.desc);
    });
  }
}

extension DailyActivityQuerySortThenBy
    on QueryBuilder<DailyActivity, DailyActivity, QSortThenBy> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByChaptersRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chaptersRead', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByChaptersReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chaptersRead', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByEpisodesWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodesWatched', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByEpisodesWatchedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodesWatched', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByReadTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByReadTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readTimeMinutes', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByWatchTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchTimeMinutes', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByWatchTimeMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchTimeMinutes', Sort.desc);
    });
  }
}

extension DailyActivityQueryWhereDistinct
    on QueryBuilder<DailyActivity, DailyActivity, QDistinct> {
  QueryBuilder<DailyActivity, DailyActivity, QDistinct>
      distinctByActiveMediaIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activeMediaIds');
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QDistinct>
      distinctByChaptersRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chaptersRead');
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QDistinct>
      distinctByEpisodesWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'episodesWatched');
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QDistinct>
      distinctByReadTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readTimeMinutes');
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QDistinct>
      distinctByWatchTimeMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'watchTimeMinutes');
    });
  }
}

extension DailyActivityQueryProperty
    on QueryBuilder<DailyActivity, DailyActivity, QQueryProperty> {
  QueryBuilder<DailyActivity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyActivity, List<String>, QQueryOperations>
      activeMediaIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeMediaIds');
    });
  }

  QueryBuilder<DailyActivity, int, QQueryOperations> chaptersReadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chaptersRead');
    });
  }

  QueryBuilder<DailyActivity, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyActivity, int, QQueryOperations> episodesWatchedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episodesWatched');
    });
  }

  QueryBuilder<DailyActivity, int, QQueryOperations> readTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readTimeMinutes');
    });
  }

  QueryBuilder<DailyActivity, int, QQueryOperations>
      watchTimeMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'watchTimeMinutes');
    });
  }
}
