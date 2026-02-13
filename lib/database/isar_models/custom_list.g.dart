// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_list.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomListCollection on Isar {
  IsarCollection<CustomList> get customLists => this.collection();
}

const CustomListSchema = CollectionSchema(
  name: r'CustomList',
  id: -8525547938508663416,
  properties: {
    r'listName': PropertySchema(
      id: 0,
      name: r'listName',
      type: IsarType.string,
    ),
    r'mediaIds': PropertySchema(
      id: 1,
      name: r'mediaIds',
      type: IsarType.stringList,
    ),
    r'mediaTypeIndex': PropertySchema(
      id: 2,
      name: r'mediaTypeIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _customListEstimateSize,
  serialize: _customListSerialize,
  deserialize: _customListDeserialize,
  deserializeProp: _customListDeserializeProp,
  idName: r'id',
  indexes: {
    r'listName': IndexSchema(
      id: -9160894145738258075,
      name: r'listName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'listName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _customListGetId,
  getLinks: _customListGetLinks,
  attach: _customListAttach,
  version: '3.3.0-dev.3',
);

int _customListEstimateSize(
  CustomList object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.listName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.mediaIds;
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
  return bytesCount;
}

void _customListSerialize(
  CustomList object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.listName);
  writer.writeStringList(offsets[1], object.mediaIds);
  writer.writeLong(offsets[2], object.mediaTypeIndex);
}

CustomList _customListDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomList(
    listName: reader.readStringOrNull(offsets[0]),
    mediaIds: reader.readStringList(offsets[1]),
    mediaTypeIndex: reader.readLongOrNull(offsets[2]) ?? 0,
  );
  object.id = id;
  return object;
}

P _customListDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _customListGetId(CustomList object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customListGetLinks(CustomList object) {
  return [];
}

void _customListAttach(IsarCollection<dynamic> col, Id id, CustomList object) {
  object.id = id;
}

extension CustomListQueryWhereSort
    on QueryBuilder<CustomList, CustomList, QWhere> {
  QueryBuilder<CustomList, CustomList, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomListQueryWhere
    on QueryBuilder<CustomList, CustomList, QWhereClause> {
  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idBetween(
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

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> listNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'listName',
        value: [null],
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> listNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'listName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> listNameEqualTo(
      String? listName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'listName',
        value: [listName],
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> listNameNotEqualTo(
      String? listName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listName',
              lower: [],
              upper: [listName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listName',
              lower: [listName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listName',
              lower: [listName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'listName',
              lower: [],
              upper: [listName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CustomListQueryFilter
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {
  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> listNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'listName',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      listNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'listName',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> listNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      listNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> listNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> listNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      listNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> listNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> listNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> listNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      listNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listName',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      listNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'listName',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> mediaIdsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mediaIds',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mediaIds',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'mediaIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'mediaIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'mediaIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'mediaIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'mediaIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'mediaIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaTypeIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaTypeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaTypeIndexGreaterThan(
    int value, {
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaTypeIndexLessThan(
    int value, {
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      mediaTypeIndexBetween(
    int lower,
    int upper, {
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
}

extension CustomListQueryObject
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {}

extension CustomListQueryLinks
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {}

extension CustomListQuerySortBy
    on QueryBuilder<CustomList, CustomList, QSortBy> {
  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByListName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listName', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByListNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listName', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByMediaTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy>
      sortByMediaTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.desc);
    });
  }
}

extension CustomListQuerySortThenBy
    on QueryBuilder<CustomList, CustomList, QSortThenBy> {
  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByListName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listName', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByListNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listName', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByMediaTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy>
      thenByMediaTypeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTypeIndex', Sort.desc);
    });
  }
}

extension CustomListQueryWhereDistinct
    on QueryBuilder<CustomList, CustomList, QDistinct> {
  QueryBuilder<CustomList, CustomList, QDistinct> distinctByListName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctByMediaIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaIds');
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctByMediaTypeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaTypeIndex');
    });
  }
}

extension CustomListQueryProperty
    on QueryBuilder<CustomList, CustomList, QQueryProperty> {
  QueryBuilder<CustomList, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomList, String?, QQueryOperations> listNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listName');
    });
  }

  QueryBuilder<CustomList, List<String>?, QQueryOperations> mediaIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaIds');
    });
  }

  QueryBuilder<CustomList, int, QQueryOperations> mediaTypeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaTypeIndex');
    });
  }
}
