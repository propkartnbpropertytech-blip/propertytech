// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_collections.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLookupItemLocalCollection on Isar {
  IsarCollection<LookupItemLocal> get lookupItemLocals => this.collection();
}

const LookupItemLocalSchema = CollectionSchema(
  name: r'LookupItemLocal',
  id: 1318305215323522560,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'categoryId': PropertySchema(
      id: 1,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'cityId': PropertySchema(
      id: 2,
      name: r'cityId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'pincode': PropertySchema(
      id: 5,
      name: r'pincode',
      type: IsarType.string,
    )
  },
  estimateSize: _lookupItemLocalEstimateSize,
  serialize: _lookupItemLocalSerialize,
  deserialize: _lookupItemLocalDeserialize,
  deserializeProp: _lookupItemLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _lookupItemLocalGetId,
  getLinks: _lookupItemLocalGetLinks,
  attach: _lookupItemLocalAttach,
  version: '3.1.0+1',
);

int _lookupItemLocalEstimateSize(
  LookupItemLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  {
    final value = object.categoryId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cityId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.pincode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _lookupItemLocalSerialize(
  LookupItemLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.categoryId);
  writer.writeString(offsets[2], object.cityId);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.pincode);
}

LookupItemLocal _lookupItemLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LookupItemLocal();
  object.category = reader.readString(offsets[0]);
  object.categoryId = reader.readStringOrNull(offsets[1]);
  object.cityId = reader.readStringOrNull(offsets[2]);
  object.id = reader.readString(offsets[3]);
  object.isarId = id;
  object.name = reader.readString(offsets[4]);
  object.pincode = reader.readStringOrNull(offsets[5]);
  return object;
}

P _lookupItemLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _lookupItemLocalGetId(LookupItemLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _lookupItemLocalGetLinks(LookupItemLocal object) {
  return [];
}

void _lookupItemLocalAttach(
    IsarCollection<dynamic> col, Id id, LookupItemLocal object) {
  object.isarId = id;
}

extension LookupItemLocalByIndex on IsarCollection<LookupItemLocal> {
  Future<LookupItemLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  LookupItemLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<LookupItemLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<LookupItemLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(LookupItemLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(LookupItemLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<LookupItemLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<LookupItemLocal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension LookupItemLocalQueryWhereSort
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QWhere> {
  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LookupItemLocalQueryWhere
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QWhereClause> {
  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterWhereClause>
      idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LookupItemLocalQueryFilter
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QFilterCondition> {
  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryId',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      categoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cityId',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cityId',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cityId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityId',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      cityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cityId',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      isarIdEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameEqualTo(
    String value, {
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

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
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

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameLessThan(
    String value, {
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

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
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

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameEndsWith(
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

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pincode',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pincode',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pincode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pincode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pincode',
        value: '',
      ));
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterFilterCondition>
      pincodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pincode',
        value: '',
      ));
    });
  }
}

extension LookupItemLocalQueryObject
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QFilterCondition> {}

extension LookupItemLocalQueryLinks
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QFilterCondition> {}

extension LookupItemLocalQuerySortBy
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QSortBy> {
  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> sortByCityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      sortByCityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> sortByPincode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      sortByPincodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.desc);
    });
  }
}

extension LookupItemLocalQuerySortThenBy
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QSortThenBy> {
  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> thenByCityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByCityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy> thenByPincode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.asc);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QAfterSortBy>
      thenByPincodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.desc);
    });
  }
}

extension LookupItemLocalQueryWhereDistinct
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QDistinct> {
  QueryBuilder<LookupItemLocal, LookupItemLocal, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QDistinct>
      distinctByCategoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QDistinct> distinctByCityId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LookupItemLocal, LookupItemLocal, QDistinct> distinctByPincode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pincode', caseSensitive: caseSensitive);
    });
  }
}

extension LookupItemLocalQueryProperty
    on QueryBuilder<LookupItemLocal, LookupItemLocal, QQueryProperty> {
  QueryBuilder<LookupItemLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<LookupItemLocal, String, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<LookupItemLocal, String?, QQueryOperations>
      categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<LookupItemLocal, String?, QQueryOperations> cityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cityId');
    });
  }

  QueryBuilder<LookupItemLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LookupItemLocal, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<LookupItemLocal, String?, QQueryOperations> pincodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pincode');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPropertyLocalCollection on Isar {
  IsarCollection<PropertyLocal> get propertyLocals => this.collection();
}

const PropertyLocalSchema = CollectionSchema(
  name: r'PropertyLocal',
  id: -8271700807818507264,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'adminId': PropertySchema(
      id: 1,
      name: r'adminId',
      type: IsarType.string,
    ),
    r'ageOfProperty': PropertySchema(
      id: 2,
      name: r'ageOfProperty',
      type: IsarType.long,
    ),
    r'amenities': PropertySchema(
      id: 3,
      name: r'amenities',
      type: IsarType.stringList,
    ),
    r'areaId': PropertySchema(
      id: 4,
      name: r'areaId',
      type: IsarType.string,
    ),
    r'areaName': PropertySchema(
      id: 5,
      name: r'areaName',
      type: IsarType.string,
    ),
    r'balconies': PropertySchema(
      id: 6,
      name: r'balconies',
      type: IsarType.long,
    ),
    r'bathrooms': PropertySchema(
      id: 7,
      name: r'bathrooms',
      type: IsarType.long,
    ),
    r'bedrooms': PropertySchema(
      id: 8,
      name: r'bedrooms',
      type: IsarType.long,
    ),
    r'blockWing': PropertySchema(
      id: 9,
      name: r'blockWing',
      type: IsarType.string,
    ),
    r'brokerName': PropertySchema(
      id: 10,
      name: r'brokerName',
      type: IsarType.string,
    ),
    r'brokerageTypeId': PropertySchema(
      id: 11,
      name: r'brokerageTypeId',
      type: IsarType.string,
    ),
    r'brokerageTypeName': PropertySchema(
      id: 12,
      name: r'brokerageTypeName',
      type: IsarType.string,
    ),
    r'carpetArea': PropertySchema(
      id: 13,
      name: r'carpetArea',
      type: IsarType.double,
    ),
    r'categoryId': PropertySchema(
      id: 14,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'categoryName': PropertySchema(
      id: 15,
      name: r'categoryName',
      type: IsarType.string,
    ),
    r'cityId': PropertySchema(
      id: 16,
      name: r'cityId',
      type: IsarType.string,
    ),
    r'cityName': PropertySchema(
      id: 17,
      name: r'cityName',
      type: IsarType.string,
    ),
    r'configurationId': PropertySchema(
      id: 18,
      name: r'configurationId',
      type: IsarType.string,
    ),
    r'configurationName': PropertySchema(
      id: 19,
      name: r'configurationName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 20,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 21,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'createdByName': PropertySchema(
      id: 22,
      name: r'createdByName',
      type: IsarType.string,
    ),
    r'deposit': PropertySchema(
      id: 23,
      name: r'deposit',
      type: IsarType.double,
    ),
    r'description': PropertySchema(
      id: 24,
      name: r'description',
      type: IsarType.string,
    ),
    r'facingTypeId': PropertySchema(
      id: 25,
      name: r'facingTypeId',
      type: IsarType.string,
    ),
    r'facingTypeName': PropertySchema(
      id: 26,
      name: r'facingTypeName',
      type: IsarType.string,
    ),
    r'flatNo': PropertySchema(
      id: 27,
      name: r'flatNo',
      type: IsarType.string,
    ),
    r'floorNo': PropertySchema(
      id: 28,
      name: r'floorNo',
      type: IsarType.long,
    ),
    r'furnishingTypeId': PropertySchema(
      id: 29,
      name: r'furnishingTypeId',
      type: IsarType.string,
    ),
    r'furnishingTypeName': PropertySchema(
      id: 30,
      name: r'furnishingTypeName',
      type: IsarType.string,
    ),
    r'googlePlaceId': PropertySchema(
      id: 31,
      name: r'googlePlaceId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 32,
      name: r'id',
      type: IsarType.string,
    ),
    r'images': PropertySchema(
      id: 33,
      name: r'images',
      type: IsarType.stringList,
    ),
    r'isVerified': PropertySchema(
      id: 34,
      name: r'isVerified',
      type: IsarType.bool,
    ),
    r'landmark': PropertySchema(
      id: 35,
      name: r'landmark',
      type: IsarType.string,
    ),
    r'latitude': PropertySchema(
      id: 36,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'listingTypeId': PropertySchema(
      id: 37,
      name: r'listingTypeId',
      type: IsarType.string,
    ),
    r'listingTypeName': PropertySchema(
      id: 38,
      name: r'listingTypeName',
      type: IsarType.string,
    ),
    r'longitude': PropertySchema(
      id: 39,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'maintenance': PropertySchema(
      id: 40,
      name: r'maintenance',
      type: IsarType.double,
    ),
    r'organizationId': PropertySchema(
      id: 41,
      name: r'organizationId',
      type: IsarType.string,
    ),
    r'ownerMobile': PropertySchema(
      id: 42,
      name: r'ownerMobile',
      type: IsarType.string,
    ),
    r'ownerName': PropertySchema(
      id: 43,
      name: r'ownerName',
      type: IsarType.string,
    ),
    r'ownershipTypeId': PropertySchema(
      id: 44,
      name: r'ownershipTypeId',
      type: IsarType.string,
    ),
    r'ownershipTypeName': PropertySchema(
      id: 45,
      name: r'ownershipTypeName',
      type: IsarType.string,
    ),
    r'parking': PropertySchema(
      id: 46,
      name: r'parking',
      type: IsarType.long,
    ),
    r'pincode': PropertySchema(
      id: 47,
      name: r'pincode',
      type: IsarType.string,
    ),
    r'plotArea': PropertySchema(
      id: 48,
      name: r'plotArea',
      type: IsarType.double,
    ),
    r'possessionDate': PropertySchema(
      id: 49,
      name: r'possessionDate',
      type: IsarType.dateTime,
    ),
    r'price': PropertySchema(
      id: 50,
      name: r'price',
      type: IsarType.double,
    ),
    r'propertyCode': PropertySchema(
      id: 51,
      name: r'propertyCode',
      type: IsarType.string,
    ),
    r'propertyStatusId': PropertySchema(
      id: 52,
      name: r'propertyStatusId',
      type: IsarType.string,
    ),
    r'propertyStatusName': PropertySchema(
      id: 53,
      name: r'propertyStatusName',
      type: IsarType.string,
    ),
    r'propertyTypeId': PropertySchema(
      id: 54,
      name: r'propertyTypeId',
      type: IsarType.string,
    ),
    r'propertyTypeName': PropertySchema(
      id: 55,
      name: r'propertyTypeName',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 56,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'superBuiltupArea': PropertySchema(
      id: 57,
      name: r'superBuiltupArea',
      type: IsarType.double,
    ),
    r'title': PropertySchema(
      id: 58,
      name: r'title',
      type: IsarType.string,
    ),
    r'totalFloor': PropertySchema(
      id: 59,
      name: r'totalFloor',
      type: IsarType.long,
    ),
    r'videos': PropertySchema(
      id: 60,
      name: r'videos',
      type: IsarType.stringList,
    )
  },
  estimateSize: _propertyLocalEstimateSize,
  serialize: _propertyLocalSerialize,
  deserialize: _propertyLocalDeserialize,
  deserializeProp: _propertyLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _propertyLocalGetId,
  getLinks: _propertyLocalGetLinks,
  attach: _propertyLocalAttach,
  version: '3.1.0+1',
);

int _propertyLocalEstimateSize(
  PropertyLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.address.length * 3;
  {
    final value = object.adminId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.amenities.length * 3;
  {
    for (var i = 0; i < object.amenities.length; i++) {
      final value = object.amenities[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.areaId.length * 3;
  bytesCount += 3 + object.areaName.length * 3;
  {
    final value = object.blockWing;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.brokerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.brokerageTypeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.brokerageTypeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.categoryId.length * 3;
  bytesCount += 3 + object.categoryName.length * 3;
  bytesCount += 3 + object.cityId.length * 3;
  bytesCount += 3 + object.cityName.length * 3;
  {
    final value = object.configurationId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.configurationName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.createdBy.length * 3;
  bytesCount += 3 + object.createdByName.length * 3;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.facingTypeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.facingTypeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.flatNo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.furnishingTypeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.furnishingTypeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.googlePlaceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.images.length * 3;
  {
    for (var i = 0; i < object.images.length; i++) {
      final value = object.images[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.landmark;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.listingTypeId.length * 3;
  bytesCount += 3 + object.listingTypeName.length * 3;
  {
    final value = object.organizationId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.ownerMobile.length * 3;
  bytesCount += 3 + object.ownerName.length * 3;
  {
    final value = object.ownershipTypeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.ownershipTypeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.pincode.length * 3;
  bytesCount += 3 + object.propertyCode.length * 3;
  bytesCount += 3 + object.propertyStatusId.length * 3;
  bytesCount += 3 + object.propertyStatusName.length * 3;
  bytesCount += 3 + object.propertyTypeId.length * 3;
  bytesCount += 3 + object.propertyTypeName.length * 3;
  {
    final value = object.remarks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.videos.length * 3;
  {
    for (var i = 0; i < object.videos.length; i++) {
      final value = object.videos[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _propertyLocalSerialize(
  PropertyLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.adminId);
  writer.writeLong(offsets[2], object.ageOfProperty);
  writer.writeStringList(offsets[3], object.amenities);
  writer.writeString(offsets[4], object.areaId);
  writer.writeString(offsets[5], object.areaName);
  writer.writeLong(offsets[6], object.balconies);
  writer.writeLong(offsets[7], object.bathrooms);
  writer.writeLong(offsets[8], object.bedrooms);
  writer.writeString(offsets[9], object.blockWing);
  writer.writeString(offsets[10], object.brokerName);
  writer.writeString(offsets[11], object.brokerageTypeId);
  writer.writeString(offsets[12], object.brokerageTypeName);
  writer.writeDouble(offsets[13], object.carpetArea);
  writer.writeString(offsets[14], object.categoryId);
  writer.writeString(offsets[15], object.categoryName);
  writer.writeString(offsets[16], object.cityId);
  writer.writeString(offsets[17], object.cityName);
  writer.writeString(offsets[18], object.configurationId);
  writer.writeString(offsets[19], object.configurationName);
  writer.writeDateTime(offsets[20], object.createdAt);
  writer.writeString(offsets[21], object.createdBy);
  writer.writeString(offsets[22], object.createdByName);
  writer.writeDouble(offsets[23], object.deposit);
  writer.writeString(offsets[24], object.description);
  writer.writeString(offsets[25], object.facingTypeId);
  writer.writeString(offsets[26], object.facingTypeName);
  writer.writeString(offsets[27], object.flatNo);
  writer.writeLong(offsets[28], object.floorNo);
  writer.writeString(offsets[29], object.furnishingTypeId);
  writer.writeString(offsets[30], object.furnishingTypeName);
  writer.writeString(offsets[31], object.googlePlaceId);
  writer.writeString(offsets[32], object.id);
  writer.writeStringList(offsets[33], object.images);
  writer.writeBool(offsets[34], object.isVerified);
  writer.writeString(offsets[35], object.landmark);
  writer.writeDouble(offsets[36], object.latitude);
  writer.writeString(offsets[37], object.listingTypeId);
  writer.writeString(offsets[38], object.listingTypeName);
  writer.writeDouble(offsets[39], object.longitude);
  writer.writeDouble(offsets[40], object.maintenance);
  writer.writeString(offsets[41], object.organizationId);
  writer.writeString(offsets[42], object.ownerMobile);
  writer.writeString(offsets[43], object.ownerName);
  writer.writeString(offsets[44], object.ownershipTypeId);
  writer.writeString(offsets[45], object.ownershipTypeName);
  writer.writeLong(offsets[46], object.parking);
  writer.writeString(offsets[47], object.pincode);
  writer.writeDouble(offsets[48], object.plotArea);
  writer.writeDateTime(offsets[49], object.possessionDate);
  writer.writeDouble(offsets[50], object.price);
  writer.writeString(offsets[51], object.propertyCode);
  writer.writeString(offsets[52], object.propertyStatusId);
  writer.writeString(offsets[53], object.propertyStatusName);
  writer.writeString(offsets[54], object.propertyTypeId);
  writer.writeString(offsets[55], object.propertyTypeName);
  writer.writeString(offsets[56], object.remarks);
  writer.writeDouble(offsets[57], object.superBuiltupArea);
  writer.writeString(offsets[58], object.title);
  writer.writeLong(offsets[59], object.totalFloor);
  writer.writeStringList(offsets[60], object.videos);
}

PropertyLocal _propertyLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PropertyLocal();
  object.address = reader.readString(offsets[0]);
  object.adminId = reader.readStringOrNull(offsets[1]);
  object.ageOfProperty = reader.readLongOrNull(offsets[2]);
  object.amenities = reader.readStringList(offsets[3]) ?? [];
  object.areaId = reader.readString(offsets[4]);
  object.areaName = reader.readString(offsets[5]);
  object.balconies = reader.readLong(offsets[6]);
  object.bathrooms = reader.readLong(offsets[7]);
  object.bedrooms = reader.readLong(offsets[8]);
  object.blockWing = reader.readStringOrNull(offsets[9]);
  object.brokerName = reader.readStringOrNull(offsets[10]);
  object.brokerageTypeId = reader.readStringOrNull(offsets[11]);
  object.brokerageTypeName = reader.readStringOrNull(offsets[12]);
  object.carpetArea = reader.readDoubleOrNull(offsets[13]);
  object.categoryId = reader.readString(offsets[14]);
  object.categoryName = reader.readString(offsets[15]);
  object.cityId = reader.readString(offsets[16]);
  object.cityName = reader.readString(offsets[17]);
  object.configurationId = reader.readStringOrNull(offsets[18]);
  object.configurationName = reader.readStringOrNull(offsets[19]);
  object.createdAt = reader.readDateTime(offsets[20]);
  object.createdBy = reader.readString(offsets[21]);
  object.createdByName = reader.readString(offsets[22]);
  object.deposit = reader.readDouble(offsets[23]);
  object.description = reader.readStringOrNull(offsets[24]);
  object.facingTypeId = reader.readStringOrNull(offsets[25]);
  object.facingTypeName = reader.readStringOrNull(offsets[26]);
  object.flatNo = reader.readStringOrNull(offsets[27]);
  object.floorNo = reader.readLongOrNull(offsets[28]);
  object.furnishingTypeId = reader.readStringOrNull(offsets[29]);
  object.furnishingTypeName = reader.readStringOrNull(offsets[30]);
  object.googlePlaceId = reader.readStringOrNull(offsets[31]);
  object.id = reader.readString(offsets[32]);
  object.images = reader.readStringList(offsets[33]) ?? [];
  object.isVerified = reader.readBool(offsets[34]);
  object.isarId = id;
  object.landmark = reader.readStringOrNull(offsets[35]);
  object.latitude = reader.readDoubleOrNull(offsets[36]);
  object.listingTypeId = reader.readString(offsets[37]);
  object.listingTypeName = reader.readString(offsets[38]);
  object.longitude = reader.readDoubleOrNull(offsets[39]);
  object.maintenance = reader.readDouble(offsets[40]);
  object.organizationId = reader.readStringOrNull(offsets[41]);
  object.ownerMobile = reader.readString(offsets[42]);
  object.ownerName = reader.readString(offsets[43]);
  object.ownershipTypeId = reader.readStringOrNull(offsets[44]);
  object.ownershipTypeName = reader.readStringOrNull(offsets[45]);
  object.parking = reader.readLong(offsets[46]);
  object.pincode = reader.readString(offsets[47]);
  object.plotArea = reader.readDoubleOrNull(offsets[48]);
  object.possessionDate = reader.readDateTimeOrNull(offsets[49]);
  object.price = reader.readDouble(offsets[50]);
  object.propertyCode = reader.readString(offsets[51]);
  object.propertyStatusId = reader.readString(offsets[52]);
  object.propertyStatusName = reader.readString(offsets[53]);
  object.propertyTypeId = reader.readString(offsets[54]);
  object.propertyTypeName = reader.readString(offsets[55]);
  object.remarks = reader.readStringOrNull(offsets[56]);
  object.superBuiltupArea = reader.readDoubleOrNull(offsets[57]);
  object.title = reader.readString(offsets[58]);
  object.totalFloor = reader.readLongOrNull(offsets[59]);
  object.videos = reader.readStringList(offsets[60]) ?? [];
  return object;
}

P _propertyLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readDateTime(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readDouble(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readLongOrNull(offset)) as P;
    case 29:
      return (reader.readStringOrNull(offset)) as P;
    case 30:
      return (reader.readStringOrNull(offset)) as P;
    case 31:
      return (reader.readStringOrNull(offset)) as P;
    case 32:
      return (reader.readString(offset)) as P;
    case 33:
      return (reader.readStringList(offset) ?? []) as P;
    case 34:
      return (reader.readBool(offset)) as P;
    case 35:
      return (reader.readStringOrNull(offset)) as P;
    case 36:
      return (reader.readDoubleOrNull(offset)) as P;
    case 37:
      return (reader.readString(offset)) as P;
    case 38:
      return (reader.readString(offset)) as P;
    case 39:
      return (reader.readDoubleOrNull(offset)) as P;
    case 40:
      return (reader.readDouble(offset)) as P;
    case 41:
      return (reader.readStringOrNull(offset)) as P;
    case 42:
      return (reader.readString(offset)) as P;
    case 43:
      return (reader.readString(offset)) as P;
    case 44:
      return (reader.readStringOrNull(offset)) as P;
    case 45:
      return (reader.readStringOrNull(offset)) as P;
    case 46:
      return (reader.readLong(offset)) as P;
    case 47:
      return (reader.readString(offset)) as P;
    case 48:
      return (reader.readDoubleOrNull(offset)) as P;
    case 49:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 50:
      return (reader.readDouble(offset)) as P;
    case 51:
      return (reader.readString(offset)) as P;
    case 52:
      return (reader.readString(offset)) as P;
    case 53:
      return (reader.readString(offset)) as P;
    case 54:
      return (reader.readString(offset)) as P;
    case 55:
      return (reader.readString(offset)) as P;
    case 56:
      return (reader.readStringOrNull(offset)) as P;
    case 57:
      return (reader.readDoubleOrNull(offset)) as P;
    case 58:
      return (reader.readString(offset)) as P;
    case 59:
      return (reader.readLongOrNull(offset)) as P;
    case 60:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _propertyLocalGetId(PropertyLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _propertyLocalGetLinks(PropertyLocal object) {
  return [];
}

void _propertyLocalAttach(
    IsarCollection<dynamic> col, Id id, PropertyLocal object) {
  object.isarId = id;
}

extension PropertyLocalByIndex on IsarCollection<PropertyLocal> {
  Future<PropertyLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  PropertyLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<PropertyLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<PropertyLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(PropertyLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(PropertyLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<PropertyLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<PropertyLocal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension PropertyLocalQueryWhereSort
    on QueryBuilder<PropertyLocal, PropertyLocal, QWhere> {
  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PropertyLocalQueryWhere
    on QueryBuilder<PropertyLocal, PropertyLocal, QWhereClause> {
  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PropertyLocalQueryFilter
    on QueryBuilder<PropertyLocal, PropertyLocal, QFilterCondition> {
  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'adminId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'adminId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'adminId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'adminId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'adminId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      adminIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'adminId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ageOfPropertyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ageOfProperty',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ageOfPropertyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ageOfProperty',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ageOfPropertyEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ageOfProperty',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ageOfPropertyGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ageOfProperty',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ageOfPropertyLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ageOfProperty',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ageOfPropertyBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ageOfProperty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amenities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amenities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amenities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amenities',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'amenities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'amenities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'amenities',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'amenities',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amenities',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'amenities',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'amenities',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'amenities',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'amenities',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'amenities',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'amenities',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      amenitiesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'amenities',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'areaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'areaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'areaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'areaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'areaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'areaId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'areaId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'areaId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'areaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'areaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'areaName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'areaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'areaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'areaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'areaName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      areaNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'areaName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      balconiesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balconies',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      balconiesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balconies',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      balconiesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balconies',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      balconiesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balconies',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bathroomsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bathrooms',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bathroomsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bathrooms',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bathroomsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bathrooms',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bathroomsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bathrooms',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bedroomsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bedrooms',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bedroomsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bedrooms',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bedroomsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bedrooms',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      bedroomsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bedrooms',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'blockWing',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'blockWing',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockWing',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockWing',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockWing',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockWing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'blockWing',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'blockWing',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blockWing',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blockWing',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockWing',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      blockWingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blockWing',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'brokerName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'brokerName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brokerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'brokerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'brokerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'brokerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'brokerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'brokerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'brokerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'brokerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brokerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'brokerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'brokerageTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'brokerageTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brokerageTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'brokerageTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'brokerageTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'brokerageTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'brokerageTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'brokerageTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'brokerageTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'brokerageTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brokerageTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'brokerageTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'brokerageTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'brokerageTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brokerageTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'brokerageTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'brokerageTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'brokerageTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'brokerageTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'brokerageTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'brokerageTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'brokerageTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brokerageTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      brokerageTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'brokerageTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      carpetAreaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'carpetArea',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      carpetAreaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'carpetArea',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      carpetAreaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carpetArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      carpetAreaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carpetArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      carpetAreaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carpetArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      carpetAreaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carpetArea',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      categoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cityId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cityId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cityName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cityName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      cityNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cityName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'configurationId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'configurationId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configurationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configurationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configurationId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'configurationName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'configurationName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configurationName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configurationName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      configurationNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configurationName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdByName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdByName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdByName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      createdByNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdByName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      depositEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deposit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      depositGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deposit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      depositLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deposit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      depositBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deposit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
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

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
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

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
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

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
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

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
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

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
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

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'facingTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'facingTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'facingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'facingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'facingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'facingTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'facingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'facingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'facingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'facingTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'facingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'facingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'facingTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'facingTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'facingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'facingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'facingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'facingTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'facingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'facingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'facingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'facingTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'facingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      facingTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'facingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flatNo',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flatNo',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flatNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flatNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flatNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flatNo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'flatNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'flatNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'flatNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'flatNo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flatNo',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      flatNoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'flatNo',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      floorNoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'floorNo',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      floorNoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'floorNo',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      floorNoEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'floorNo',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      floorNoGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'floorNo',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      floorNoLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'floorNo',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      floorNoBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'floorNo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'furnishingTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'furnishingTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'furnishingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'furnishingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'furnishingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'furnishingTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'furnishingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'furnishingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'furnishingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'furnishingTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'furnishingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'furnishingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'furnishingTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'furnishingTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'furnishingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'furnishingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'furnishingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'furnishingTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'furnishingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'furnishingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'furnishingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'furnishingTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'furnishingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      furnishingTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'furnishingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'googlePlaceId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'googlePlaceId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'googlePlaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'googlePlaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'googlePlaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'googlePlaceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'googlePlaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'googlePlaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'googlePlaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'googlePlaceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'googlePlaceId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      googlePlaceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'googlePlaceId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'images',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'images',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'images',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'images',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'images',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      imagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'images',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      isVerifiedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isVerified',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      isarIdEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'landmark',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'landmark',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'landmark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'landmark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'landmark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'landmark',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'landmark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'landmark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'landmark',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'landmark',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'landmark',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      landmarkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'landmark',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listingTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listingTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'listingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listingTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listingTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      listingTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'listingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      longitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      maintenanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maintenance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      maintenanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maintenance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      maintenanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maintenance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      maintenanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maintenance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'organizationId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'organizationId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'organizationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      organizationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerMobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerMobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerMobile',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerMobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerMobile',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ownershipTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ownershipTypeId',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownershipTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownershipTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownershipTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownershipTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownershipTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownershipTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownershipTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownershipTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownershipTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownershipTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ownershipTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ownershipTypeName',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownershipTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownershipTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownershipTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownershipTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownershipTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownershipTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownershipTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownershipTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownershipTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      ownershipTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownershipTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      parkingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parking',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      parkingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parking',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      parkingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parking',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      parkingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parking',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pincode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pincode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pincode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pincode',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      pincodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pincode',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      plotAreaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'plotArea',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      plotAreaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'plotArea',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      plotAreaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plotArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      plotAreaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plotArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      plotAreaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plotArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      plotAreaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plotArea',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      possessionDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'possessionDate',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      possessionDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'possessionDate',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      possessionDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'possessionDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      possessionDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'possessionDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      possessionDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'possessionDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      possessionDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'possessionDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyStatusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyStatusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyStatusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyStatusId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyStatusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyStatusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyStatusId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyStatusId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyStatusId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyStatusId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyStatusName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyStatusName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyStatusName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyStatusNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyStatusName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      propertyTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      superBuiltupAreaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'superBuiltupArea',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      superBuiltupAreaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'superBuiltupArea',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      superBuiltupAreaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'superBuiltupArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      superBuiltupAreaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'superBuiltupArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      superBuiltupAreaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'superBuiltupArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      superBuiltupAreaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'superBuiltupArea',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      totalFloorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalFloor',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      totalFloorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalFloor',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      totalFloorEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalFloor',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      totalFloorGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalFloor',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      totalFloorLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalFloor',
        value: value,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      totalFloorBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalFloor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'videos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'videos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'videos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'videos',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'videos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'videos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'videos',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'videos',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'videos',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'videos',
        value: '',
      ));
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'videos',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'videos',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'videos',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'videos',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'videos',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition>
      videosLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'videos',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension PropertyLocalQueryObject
    on QueryBuilder<PropertyLocal, PropertyLocal, QFilterCondition> {}

extension PropertyLocalQueryLinks
    on QueryBuilder<PropertyLocal, PropertyLocal, QFilterCondition> {}

extension PropertyLocalQuerySortBy
    on QueryBuilder<PropertyLocal, PropertyLocal, QSortBy> {
  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByAdminId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByAdminIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByAgeOfProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageOfProperty', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByAgeOfPropertyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageOfProperty', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByAreaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByAreaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByAreaName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByAreaNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByBalconies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balconies', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBalconiesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balconies', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByBathrooms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bathrooms', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBathroomsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bathrooms', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByBedrooms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bedrooms', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBedroomsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bedrooms', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByBlockWing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockWing', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBlockWingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockWing', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByBrokerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBrokerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBrokerageTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBrokerageTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBrokerageTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByBrokerageTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByCarpetArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carpetArea', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCarpetAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carpetArea', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByCityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByCityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByCityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByConfigurationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByConfigurationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByConfigurationName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByConfigurationNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCreatedByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByCreatedByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByDeposit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deposit', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByDepositDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deposit', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFacingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFacingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFacingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFacingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByFlatNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flatNo', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByFlatNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flatNo', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByFloorNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floorNo', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByFloorNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floorNo', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFurnishingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFurnishingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFurnishingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByFurnishingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByGooglePlaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googlePlaceId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByGooglePlaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googlePlaceId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByIsVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByIsVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByLandmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'landmark', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByLandmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'landmark', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByListingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByListingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByListingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByListingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByMaintenance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maintenance', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByMaintenanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maintenance', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByOwnerMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerMobile', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOwnerMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerMobile', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByOwnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOwnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOwnershipTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOwnershipTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOwnershipTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByOwnershipTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByParking() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parking', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByParkingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parking', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByPincode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByPincodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByPlotArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plotArea', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPlotAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plotArea', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPossessionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'possessionDate', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPossessionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'possessionDate', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyStatusId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyStatusIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByPropertyTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortBySuperBuiltupArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'superBuiltupArea', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortBySuperBuiltupAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'superBuiltupArea', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> sortByTotalFloor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFloor', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      sortByTotalFloorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFloor', Sort.desc);
    });
  }
}

extension PropertyLocalQuerySortThenBy
    on QueryBuilder<PropertyLocal, PropertyLocal, QSortThenBy> {
  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByAdminId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByAdminIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByAgeOfProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageOfProperty', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByAgeOfPropertyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageOfProperty', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByAreaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByAreaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByAreaName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByAreaNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'areaName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByBalconies() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balconies', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBalconiesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balconies', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByBathrooms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bathrooms', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBathroomsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bathrooms', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByBedrooms() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bedrooms', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBedroomsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bedrooms', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByBlockWing() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockWing', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBlockWingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockWing', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByBrokerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBrokerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBrokerageTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBrokerageTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBrokerageTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByBrokerageTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brokerageTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByCarpetArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carpetArea', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCarpetAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carpetArea', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByCityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByCityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByCityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByConfigurationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByConfigurationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByConfigurationName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByConfigurationNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCreatedByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByCreatedByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByDeposit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deposit', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByDepositDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deposit', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFacingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFacingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFacingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFacingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'facingTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByFlatNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flatNo', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByFlatNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flatNo', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByFloorNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floorNo', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByFloorNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'floorNo', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFurnishingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFurnishingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFurnishingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByFurnishingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'furnishingTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByGooglePlaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googlePlaceId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByGooglePlaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googlePlaceId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByIsVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByIsVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVerified', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByLandmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'landmark', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByLandmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'landmark', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByListingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByListingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByListingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByListingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByMaintenance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maintenance', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByMaintenanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maintenance', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByOwnerMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerMobile', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOwnerMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerMobile', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByOwnerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOwnerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOwnershipTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOwnershipTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOwnershipTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByOwnershipTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownershipTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByParking() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parking', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByParkingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parking', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByPincode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByPincodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pincode', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByPlotArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plotArea', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPlotAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'plotArea', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPossessionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'possessionDate', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPossessionDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'possessionDate', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyStatusId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyStatusIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyStatusName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByPropertyTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenBySuperBuiltupArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'superBuiltupArea', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenBySuperBuiltupAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'superBuiltupArea', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy> thenByTotalFloor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFloor', Sort.asc);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QAfterSortBy>
      thenByTotalFloorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalFloor', Sort.desc);
    });
  }
}

extension PropertyLocalQueryWhereDistinct
    on QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> {
  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByAdminId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'adminId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByAgeOfProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ageOfProperty');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByAmenities() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amenities');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByAreaId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'areaId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByAreaName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'areaName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByBalconies() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balconies');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByBathrooms() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bathrooms');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByBedrooms() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bedrooms');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByBlockWing(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockWing', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByBrokerName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'brokerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByBrokerageTypeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'brokerageTypeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByBrokerageTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'brokerageTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCarpetArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carpetArea');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCategoryId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCategoryName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCityId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCityName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cityName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByConfigurationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configurationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByConfigurationName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configurationName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCreatedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByCreatedByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdByName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByDeposit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deposit');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByFacingTypeId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'facingTypeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByFacingTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'facingTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByFlatNo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flatNo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByFloorNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'floorNo');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByFurnishingTypeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'furnishingTypeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByFurnishingTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'furnishingTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByGooglePlaceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'googlePlaceId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByImages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'images');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByIsVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isVerified');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByLandmark(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'landmark', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByListingTypeId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listingTypeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByListingTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listingTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByMaintenance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maintenance');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByOrganizationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByOwnerMobile(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerMobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByOwnerName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByOwnershipTypeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownershipTypeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByOwnershipTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownershipTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByParking() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parking');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByPincode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pincode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByPlotArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plotArea');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByPossessionDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'possessionDate');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByPropertyCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByPropertyStatusId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyStatusId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByPropertyStatusName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyStatusName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByPropertyTypeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyTypeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctByPropertyTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct>
      distinctBySuperBuiltupArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'superBuiltupArea');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByTotalFloor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalFloor');
    });
  }

  QueryBuilder<PropertyLocal, PropertyLocal, QDistinct> distinctByVideos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videos');
    });
  }
}

extension PropertyLocalQueryProperty
    on QueryBuilder<PropertyLocal, PropertyLocal, QQueryProperty> {
  QueryBuilder<PropertyLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations> adminIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'adminId');
    });
  }

  QueryBuilder<PropertyLocal, int?, QQueryOperations> ageOfPropertyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ageOfProperty');
    });
  }

  QueryBuilder<PropertyLocal, List<String>, QQueryOperations>
      amenitiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amenities');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> areaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'areaId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> areaNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'areaName');
    });
  }

  QueryBuilder<PropertyLocal, int, QQueryOperations> balconiesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balconies');
    });
  }

  QueryBuilder<PropertyLocal, int, QQueryOperations> bathroomsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bathrooms');
    });
  }

  QueryBuilder<PropertyLocal, int, QQueryOperations> bedroomsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bedrooms');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations> blockWingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockWing');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations> brokerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'brokerName');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      brokerageTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'brokerageTypeId');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      brokerageTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'brokerageTypeName');
    });
  }

  QueryBuilder<PropertyLocal, double?, QQueryOperations> carpetAreaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carpetArea');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> categoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryName');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> cityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cityId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> cityNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cityName');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      configurationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configurationId');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      configurationNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configurationName');
    });
  }

  QueryBuilder<PropertyLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations>
      createdByNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdByName');
    });
  }

  QueryBuilder<PropertyLocal, double, QQueryOperations> depositProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deposit');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      facingTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'facingTypeId');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      facingTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'facingTypeName');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations> flatNoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flatNo');
    });
  }

  QueryBuilder<PropertyLocal, int?, QQueryOperations> floorNoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'floorNo');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      furnishingTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'furnishingTypeId');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      furnishingTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'furnishingTypeName');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      googlePlaceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'googlePlaceId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PropertyLocal, List<String>, QQueryOperations> imagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'images');
    });
  }

  QueryBuilder<PropertyLocal, bool, QQueryOperations> isVerifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isVerified');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations> landmarkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'landmark');
    });
  }

  QueryBuilder<PropertyLocal, double?, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations>
      listingTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listingTypeId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations>
      listingTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listingTypeName');
    });
  }

  QueryBuilder<PropertyLocal, double?, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<PropertyLocal, double, QQueryOperations> maintenanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maintenance');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      organizationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> ownerMobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerMobile');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> ownerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerName');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      ownershipTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownershipTypeId');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations>
      ownershipTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownershipTypeName');
    });
  }

  QueryBuilder<PropertyLocal, int, QQueryOperations> parkingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parking');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> pincodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pincode');
    });
  }

  QueryBuilder<PropertyLocal, double?, QQueryOperations> plotAreaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plotArea');
    });
  }

  QueryBuilder<PropertyLocal, DateTime?, QQueryOperations>
      possessionDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'possessionDate');
    });
  }

  QueryBuilder<PropertyLocal, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> propertyCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyCode');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations>
      propertyStatusIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyStatusId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations>
      propertyStatusNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyStatusName');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations>
      propertyTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyTypeId');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations>
      propertyTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyTypeName');
    });
  }

  QueryBuilder<PropertyLocal, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<PropertyLocal, double?, QQueryOperations>
      superBuiltupAreaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'superBuiltupArea');
    });
  }

  QueryBuilder<PropertyLocal, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<PropertyLocal, int?, QQueryOperations> totalFloorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalFloor');
    });
  }

  QueryBuilder<PropertyLocal, List<String>, QQueryOperations> videosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videos');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRequirementLocalCollection on Isar {
  IsarCollection<RequirementLocal> get requirementLocals => this.collection();
}

const RequirementLocalSchema = CollectionSchema(
  name: r'RequirementLocal',
  id: -7980756281068083200,
  properties: {
    r'adminId': PropertySchema(
      id: 0,
      name: r'adminId',
      type: IsarType.string,
    ),
    r'areaIds': PropertySchema(
      id: 1,
      name: r'areaIds',
      type: IsarType.stringList,
    ),
    r'areaNames': PropertySchema(
      id: 2,
      name: r'areaNames',
      type: IsarType.stringList,
    ),
    r'assignedTo': PropertySchema(
      id: 3,
      name: r'assignedTo',
      type: IsarType.string,
    ),
    r'assigneeName': PropertySchema(
      id: 4,
      name: r'assigneeName',
      type: IsarType.string,
    ),
    r'budget': PropertySchema(
      id: 5,
      name: r'budget',
      type: IsarType.double,
    ),
    r'categoryId': PropertySchema(
      id: 6,
      name: r'categoryId',
      type: IsarType.string,
    ),
    r'categoryName': PropertySchema(
      id: 7,
      name: r'categoryName',
      type: IsarType.string,
    ),
    r'clientMobile': PropertySchema(
      id: 8,
      name: r'clientMobile',
      type: IsarType.string,
    ),
    r'clientName': PropertySchema(
      id: 9,
      name: r'clientName',
      type: IsarType.string,
    ),
    r'configurationId': PropertySchema(
      id: 10,
      name: r'configurationId',
      type: IsarType.string,
    ),
    r'configurationIds': PropertySchema(
      id: 11,
      name: r'configurationIds',
      type: IsarType.stringList,
    ),
    r'configurationName': PropertySchema(
      id: 12,
      name: r'configurationName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 13,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 14,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'creatorName': PropertySchema(
      id: 15,
      name: r'creatorName',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 16,
      name: r'id',
      type: IsarType.string,
    ),
    r'listingTypeId': PropertySchema(
      id: 17,
      name: r'listingTypeId',
      type: IsarType.string,
    ),
    r'listingTypeName': PropertySchema(
      id: 18,
      name: r'listingTypeName',
      type: IsarType.string,
    ),
    r'maxArea': PropertySchema(
      id: 19,
      name: r'maxArea',
      type: IsarType.double,
    ),
    r'maxBudget': PropertySchema(
      id: 20,
      name: r'maxBudget',
      type: IsarType.double,
    ),
    r'minArea': PropertySchema(
      id: 21,
      name: r'minArea',
      type: IsarType.double,
    ),
    r'minBudget': PropertySchema(
      id: 22,
      name: r'minBudget',
      type: IsarType.double,
    ),
    r'organizationId': PropertySchema(
      id: 23,
      name: r'organizationId',
      type: IsarType.string,
    ),
    r'propertyTypeId': PropertySchema(
      id: 24,
      name: r'propertyTypeId',
      type: IsarType.string,
    ),
    r'propertyTypeIds': PropertySchema(
      id: 25,
      name: r'propertyTypeIds',
      type: IsarType.stringList,
    ),
    r'propertyTypeName': PropertySchema(
      id: 26,
      name: r'propertyTypeName',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 27,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 28,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _requirementLocalEstimateSize,
  serialize: _requirementLocalSerialize,
  deserialize: _requirementLocalDeserialize,
  deserializeProp: _requirementLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _requirementLocalGetId,
  getLinks: _requirementLocalGetLinks,
  attach: _requirementLocalAttach,
  version: '3.1.0+1',
);

int _requirementLocalEstimateSize(
  RequirementLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.adminId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.areaIds.length * 3;
  {
    for (var i = 0; i < object.areaIds.length; i++) {
      final value = object.areaIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.areaNames.length * 3;
  {
    for (var i = 0; i < object.areaNames.length; i++) {
      final value = object.areaNames[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.assignedTo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.assigneeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.categoryId.length * 3;
  bytesCount += 3 + object.categoryName.length * 3;
  bytesCount += 3 + object.clientMobile.length * 3;
  bytesCount += 3 + object.clientName.length * 3;
  {
    final value = object.configurationId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.configurationIds;
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
    final value = object.configurationName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.createdBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.creatorName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.listingTypeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.listingTypeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.organizationId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.propertyTypeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.propertyTypeIds;
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
    final value = object.propertyTypeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remarks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _requirementLocalSerialize(
  RequirementLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.adminId);
  writer.writeStringList(offsets[1], object.areaIds);
  writer.writeStringList(offsets[2], object.areaNames);
  writer.writeString(offsets[3], object.assignedTo);
  writer.writeString(offsets[4], object.assigneeName);
  writer.writeDouble(offsets[5], object.budget);
  writer.writeString(offsets[6], object.categoryId);
  writer.writeString(offsets[7], object.categoryName);
  writer.writeString(offsets[8], object.clientMobile);
  writer.writeString(offsets[9], object.clientName);
  writer.writeString(offsets[10], object.configurationId);
  writer.writeStringList(offsets[11], object.configurationIds);
  writer.writeString(offsets[12], object.configurationName);
  writer.writeDateTime(offsets[13], object.createdAt);
  writer.writeString(offsets[14], object.createdBy);
  writer.writeString(offsets[15], object.creatorName);
  writer.writeString(offsets[16], object.id);
  writer.writeString(offsets[17], object.listingTypeId);
  writer.writeString(offsets[18], object.listingTypeName);
  writer.writeDouble(offsets[19], object.maxArea);
  writer.writeDouble(offsets[20], object.maxBudget);
  writer.writeDouble(offsets[21], object.minArea);
  writer.writeDouble(offsets[22], object.minBudget);
  writer.writeString(offsets[23], object.organizationId);
  writer.writeString(offsets[24], object.propertyTypeId);
  writer.writeStringList(offsets[25], object.propertyTypeIds);
  writer.writeString(offsets[26], object.propertyTypeName);
  writer.writeString(offsets[27], object.remarks);
  writer.writeString(offsets[28], object.status);
}

RequirementLocal _requirementLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RequirementLocal();
  object.adminId = reader.readStringOrNull(offsets[0]);
  object.areaIds = reader.readStringList(offsets[1]) ?? [];
  object.areaNames = reader.readStringList(offsets[2]) ?? [];
  object.assignedTo = reader.readStringOrNull(offsets[3]);
  object.assigneeName = reader.readStringOrNull(offsets[4]);
  object.budget = reader.readDoubleOrNull(offsets[5]);
  object.categoryId = reader.readString(offsets[6]);
  object.categoryName = reader.readString(offsets[7]);
  object.clientMobile = reader.readString(offsets[8]);
  object.clientName = reader.readString(offsets[9]);
  object.configurationId = reader.readStringOrNull(offsets[10]);
  object.configurationIds = reader.readStringList(offsets[11]);
  object.configurationName = reader.readStringOrNull(offsets[12]);
  object.createdAt = reader.readDateTime(offsets[13]);
  object.createdBy = reader.readStringOrNull(offsets[14]);
  object.creatorName = reader.readStringOrNull(offsets[15]);
  object.id = reader.readString(offsets[16]);
  object.isarId = id;
  object.listingTypeId = reader.readStringOrNull(offsets[17]);
  object.listingTypeName = reader.readStringOrNull(offsets[18]);
  object.maxArea = reader.readDoubleOrNull(offsets[19]);
  object.maxBudget = reader.readDouble(offsets[20]);
  object.minArea = reader.readDoubleOrNull(offsets[21]);
  object.minBudget = reader.readDouble(offsets[22]);
  object.organizationId = reader.readStringOrNull(offsets[23]);
  object.propertyTypeId = reader.readStringOrNull(offsets[24]);
  object.propertyTypeIds = reader.readStringList(offsets[25]);
  object.propertyTypeName = reader.readStringOrNull(offsets[26]);
  object.remarks = reader.readStringOrNull(offsets[27]);
  object.status = reader.readString(offsets[28]);
  return object;
}

P _requirementLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringList(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    case 22:
      return (reader.readDouble(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readStringList(offset)) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _requirementLocalGetId(RequirementLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _requirementLocalGetLinks(RequirementLocal object) {
  return [];
}

void _requirementLocalAttach(
    IsarCollection<dynamic> col, Id id, RequirementLocal object) {
  object.isarId = id;
}

extension RequirementLocalByIndex on IsarCollection<RequirementLocal> {
  Future<RequirementLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  RequirementLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<RequirementLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<RequirementLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(RequirementLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(RequirementLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<RequirementLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<RequirementLocal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension RequirementLocalQueryWhereSort
    on QueryBuilder<RequirementLocal, RequirementLocal, QWhere> {
  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RequirementLocalQueryWhere
    on QueryBuilder<RequirementLocal, RequirementLocal, QWhereClause> {
  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterWhereClause>
      idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RequirementLocalQueryFilter
    on QueryBuilder<RequirementLocal, RequirementLocal, QFilterCondition> {
  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'adminId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'adminId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'adminId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'adminId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'adminId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'adminId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      adminIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'adminId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'areaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'areaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'areaIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'areaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'areaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'areaIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'areaIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'areaIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'areaNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'areaNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'areaNames',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'areaNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'areaNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'areaNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'areaNames',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'areaNames',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'areaNames',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaNames',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaNames',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaNames',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaNames',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaNames',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      areaNamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'areaNames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'assignedTo',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'assignedTo',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assignedTo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assignedTo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedTo',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assignedToIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assignedTo',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'assigneeName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'assigneeName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assigneeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assigneeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assigneeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assigneeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assigneeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assigneeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assigneeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assigneeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assigneeName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      assigneeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assigneeName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      budgetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'budget',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      budgetIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'budget',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      budgetEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      budgetGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'budget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      budgetLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'budget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      budgetBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'budget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      categoryNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientMobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientMobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientMobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientMobile',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientMobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientMobile',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      clientNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'configurationId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'configurationId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configurationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configurationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configurationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configurationId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'configurationIds',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'configurationIds',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configurationIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configurationIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configurationIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configurationIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configurationIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configurationIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configurationIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configurationIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'configurationIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'configurationIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'configurationIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'configurationIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'configurationIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'configurationIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'configurationName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'configurationName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configurationName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'configurationName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'configurationName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configurationName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      configurationNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'configurationName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdBy',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'creatorName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'creatorName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creatorName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'creatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'creatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'creatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'creatorName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creatorName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      creatorNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'creatorName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      isarIdEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'listingTypeId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'listingTypeId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listingTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listingTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listingTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'listingTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'listingTypeName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'listingTypeName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'listingTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'listingTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'listingTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'listingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      listingTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'listingTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxAreaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'maxArea',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxAreaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'maxArea',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxAreaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxAreaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxAreaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxAreaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxArea',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxBudgetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxBudgetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxBudgetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      maxBudgetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxBudget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minAreaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'minArea',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minAreaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'minArea',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minAreaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minAreaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minAreaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minArea',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minAreaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minArea',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minBudgetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minBudgetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minBudgetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      minBudgetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minBudget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'organizationId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'organizationId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'organizationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      organizationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'propertyTypeId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'propertyTypeId',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyTypeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyTypeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyTypeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyTypeId',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'propertyTypeIds',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'propertyTypeIds',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyTypeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyTypeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyTypeIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyTypeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyTypeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyTypeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyTypeIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyTypeIds',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyTypeIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyTypeIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyTypeIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyTypeIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyTypeIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyTypeIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'propertyTypeName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'propertyTypeName',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyTypeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyTypeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyTypeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      propertyTypeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyTypeName',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusEqualTo(
    String value, {
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

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
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

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusLessThan(
    String value, {
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

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
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

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
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

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
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

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension RequirementLocalQueryObject
    on QueryBuilder<RequirementLocal, RequirementLocal, QFilterCondition> {}

extension RequirementLocalQueryLinks
    on QueryBuilder<RequirementLocal, RequirementLocal, QFilterCondition> {}

extension RequirementLocalQuerySortBy
    on QueryBuilder<RequirementLocal, RequirementLocal, QSortBy> {
  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByAdminId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByAdminIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByAssignedTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByAssignedToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByAssigneeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assigneeName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByAssigneeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assigneeName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budget', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budget', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByClientMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientMobile', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByClientMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientMobile', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByClientName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByClientNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByConfigurationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByConfigurationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByConfigurationName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByConfigurationNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCreatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByCreatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByListingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByListingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByListingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByListingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMaxArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxArea', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMaxAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxArea', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMaxBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxBudget', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMaxBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxBudget', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMinArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minArea', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMinAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minArea', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMinBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minBudget', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByMinBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minBudget', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByPropertyTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByPropertyTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByPropertyTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByPropertyTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension RequirementLocalQuerySortThenBy
    on QueryBuilder<RequirementLocal, RequirementLocal, QSortThenBy> {
  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByAdminId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByAdminIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'adminId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByAssignedTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByAssignedToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByAssigneeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assigneeName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByAssigneeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assigneeName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budget', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budget', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCategoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCategoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCategoryName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCategoryNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByClientMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientMobile', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByClientMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientMobile', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByClientName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByClientNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByConfigurationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByConfigurationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByConfigurationName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByConfigurationNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configurationName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCreatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByCreatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creatorName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByListingTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByListingTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByListingTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByListingTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'listingTypeName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMaxArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxArea', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMaxAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxArea', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMaxBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxBudget', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMaxBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxBudget', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMinArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minArea', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMinAreaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minArea', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMinBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minBudget', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByMinBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minBudget', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByOrganizationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByOrganizationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByPropertyTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByPropertyTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeId', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByPropertyTypeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByPropertyTypeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTypeName', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension RequirementLocalQueryWhereDistinct
    on QueryBuilder<RequirementLocal, RequirementLocal, QDistinct> {
  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct> distinctByAdminId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'adminId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByAreaIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'areaIds');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByAreaNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'areaNames');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByAssignedTo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedTo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByAssigneeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assigneeName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'budget');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByCategoryId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByCategoryName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByClientMobile({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientMobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByClientName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByConfigurationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configurationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByConfigurationIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configurationIds');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByConfigurationName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configurationName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByCreatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByCreatorName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creatorName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByListingTypeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listingTypeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByListingTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'listingTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByMaxArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxArea');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByMaxBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxBudget');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByMinArea() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minArea');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByMinBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minBudget');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByOrganizationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByPropertyTypeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyTypeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByPropertyTypeIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyTypeIds');
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct>
      distinctByPropertyTypeName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyTypeName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RequirementLocal, RequirementLocal, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension RequirementLocalQueryProperty
    on QueryBuilder<RequirementLocal, RequirementLocal, QQueryProperty> {
  QueryBuilder<RequirementLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations> adminIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'adminId');
    });
  }

  QueryBuilder<RequirementLocal, List<String>, QQueryOperations>
      areaIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'areaIds');
    });
  }

  QueryBuilder<RequirementLocal, List<String>, QQueryOperations>
      areaNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'areaNames');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      assignedToProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedTo');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      assigneeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assigneeName');
    });
  }

  QueryBuilder<RequirementLocal, double?, QQueryOperations> budgetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'budget');
    });
  }

  QueryBuilder<RequirementLocal, String, QQueryOperations>
      categoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryId');
    });
  }

  QueryBuilder<RequirementLocal, String, QQueryOperations>
      categoryNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryName');
    });
  }

  QueryBuilder<RequirementLocal, String, QQueryOperations>
      clientMobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientMobile');
    });
  }

  QueryBuilder<RequirementLocal, String, QQueryOperations>
      clientNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientName');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      configurationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configurationId');
    });
  }

  QueryBuilder<RequirementLocal, List<String>?, QQueryOperations>
      configurationIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configurationIds');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      configurationNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configurationName');
    });
  }

  QueryBuilder<RequirementLocal, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      creatorNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creatorName');
    });
  }

  QueryBuilder<RequirementLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      listingTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listingTypeId');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      listingTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'listingTypeName');
    });
  }

  QueryBuilder<RequirementLocal, double?, QQueryOperations> maxAreaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxArea');
    });
  }

  QueryBuilder<RequirementLocal, double, QQueryOperations> maxBudgetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxBudget');
    });
  }

  QueryBuilder<RequirementLocal, double?, QQueryOperations> minAreaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minArea');
    });
  }

  QueryBuilder<RequirementLocal, double, QQueryOperations> minBudgetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minBudget');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      organizationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationId');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      propertyTypeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyTypeId');
    });
  }

  QueryBuilder<RequirementLocal, List<String>?, QQueryOperations>
      propertyTypeIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyTypeIds');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations>
      propertyTypeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyTypeName');
    });
  }

  QueryBuilder<RequirementLocal, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<RequirementLocal, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFollowupLocalCollection on Isar {
  IsarCollection<FollowupLocal> get followupLocals => this.collection();
}

const FollowupLocalSchema = CollectionSchema(
  name: r'FollowupLocal',
  id: -4721984852078906368,
  properties: {
    r'clientName': PropertySchema(
      id: 0,
      name: r'clientName',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 2,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'followupDate': PropertySchema(
      id: 3,
      name: r'followupDate',
      type: IsarType.dateTime,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'mobile': PropertySchema(
      id: 5,
      name: r'mobile',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 6,
      name: r'notes',
      type: IsarType.string,
    ),
    r'propertyCode': PropertySchema(
      id: 7,
      name: r'propertyCode',
      type: IsarType.string,
    ),
    r'propertyId': PropertySchema(
      id: 8,
      name: r'propertyId',
      type: IsarType.string,
    ),
    r'propertyTitle': PropertySchema(
      id: 9,
      name: r'propertyTitle',
      type: IsarType.string,
    ),
    r'requirementCustomerName': PropertySchema(
      id: 10,
      name: r'requirementCustomerName',
      type: IsarType.string,
    ),
    r'requirementId': PropertySchema(
      id: 11,
      name: r'requirementId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _followupLocalEstimateSize,
  serialize: _followupLocalSerialize,
  deserialize: _followupLocalDeserialize,
  deserializeProp: _followupLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _followupLocalGetId,
  getLinks: _followupLocalGetLinks,
  attach: _followupLocalAttach,
  version: '3.1.0+1',
);

int _followupLocalEstimateSize(
  FollowupLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clientName.length * 3;
  bytesCount += 3 + object.createdBy.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.mobile.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.propertyCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.propertyId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.propertyTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.requirementCustomerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.requirementId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _followupLocalSerialize(
  FollowupLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.clientName);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.createdBy);
  writer.writeDateTime(offsets[3], object.followupDate);
  writer.writeString(offsets[4], object.id);
  writer.writeString(offsets[5], object.mobile);
  writer.writeString(offsets[6], object.notes);
  writer.writeString(offsets[7], object.propertyCode);
  writer.writeString(offsets[8], object.propertyId);
  writer.writeString(offsets[9], object.propertyTitle);
  writer.writeString(offsets[10], object.requirementCustomerName);
  writer.writeString(offsets[11], object.requirementId);
  writer.writeString(offsets[12], object.status);
}

FollowupLocal _followupLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FollowupLocal();
  object.clientName = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.createdBy = reader.readString(offsets[2]);
  object.followupDate = reader.readDateTime(offsets[3]);
  object.id = reader.readString(offsets[4]);
  object.isarId = id;
  object.mobile = reader.readString(offsets[5]);
  object.notes = reader.readStringOrNull(offsets[6]);
  object.propertyCode = reader.readStringOrNull(offsets[7]);
  object.propertyId = reader.readStringOrNull(offsets[8]);
  object.propertyTitle = reader.readStringOrNull(offsets[9]);
  object.requirementCustomerName = reader.readStringOrNull(offsets[10]);
  object.requirementId = reader.readStringOrNull(offsets[11]);
  object.status = reader.readString(offsets[12]);
  return object;
}

P _followupLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _followupLocalGetId(FollowupLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _followupLocalGetLinks(FollowupLocal object) {
  return [];
}

void _followupLocalAttach(
    IsarCollection<dynamic> col, Id id, FollowupLocal object) {
  object.isarId = id;
}

extension FollowupLocalByIndex on IsarCollection<FollowupLocal> {
  Future<FollowupLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  FollowupLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<FollowupLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<FollowupLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(FollowupLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(FollowupLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<FollowupLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<FollowupLocal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension FollowupLocalQueryWhereSort
    on QueryBuilder<FollowupLocal, FollowupLocal, QWhere> {
  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FollowupLocalQueryWhere
    on QueryBuilder<FollowupLocal, FollowupLocal, QWhereClause> {
  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension FollowupLocalQueryFilter
    on QueryBuilder<FollowupLocal, FollowupLocal, QFilterCondition> {
  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientName',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      clientNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientName',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      followupDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followupDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      followupDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followupDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      followupDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followupDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      followupDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followupDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      isarIdEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      mobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'propertyCode',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'propertyCode',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyCode',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'propertyId',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'propertyId',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'propertyTitle',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'propertyTitle',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      propertyTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'requirementCustomerName',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'requirementCustomerName',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requirementCustomerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requirementCustomerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requirementCustomerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requirementCustomerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'requirementCustomerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'requirementCustomerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'requirementCustomerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'requirementCustomerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requirementCustomerName',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementCustomerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'requirementCustomerName',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'requirementId',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'requirementId',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requirementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requirementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requirementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requirementId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'requirementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'requirementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'requirementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'requirementId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requirementId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      requirementIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'requirementId',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusEqualTo(
    String value, {
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

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
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

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusLessThan(
    String value, {
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

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
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

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
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

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
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

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension FollowupLocalQueryObject
    on QueryBuilder<FollowupLocal, FollowupLocal, QFilterCondition> {}

extension FollowupLocalQueryLinks
    on QueryBuilder<FollowupLocal, FollowupLocal, QFilterCondition> {}

extension FollowupLocalQuerySortBy
    on QueryBuilder<FollowupLocal, FollowupLocal, QSortBy> {
  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByClientName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByClientNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByFollowupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupDate', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByFollowupDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupDate', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByPropertyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByPropertyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByPropertyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByPropertyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByPropertyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTitle', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByPropertyTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTitle', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByRequirementCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementCustomerName', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByRequirementCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementCustomerName', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByRequirementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementId', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      sortByRequirementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementId', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension FollowupLocalQuerySortThenBy
    on QueryBuilder<FollowupLocal, FollowupLocal, QSortThenBy> {
  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByClientName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByClientNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientName', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByFollowupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupDate', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByFollowupDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupDate', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByPropertyCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByPropertyCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyCode', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByPropertyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByPropertyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByPropertyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTitle', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByPropertyTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyTitle', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByRequirementCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementCustomerName', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByRequirementCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementCustomerName', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByRequirementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementId', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy>
      thenByRequirementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requirementId', Sort.desc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension FollowupLocalQueryWhereDistinct
    on QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> {
  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByClientName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByCreatedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct>
      distinctByFollowupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followupDate');
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByMobile(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByPropertyCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByPropertyId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByPropertyTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyTitle',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct>
      distinctByRequirementCustomerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requirementCustomerName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByRequirementId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requirementId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowupLocal, FollowupLocal, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension FollowupLocalQueryProperty
    on QueryBuilder<FollowupLocal, FollowupLocal, QQueryProperty> {
  QueryBuilder<FollowupLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<FollowupLocal, String, QQueryOperations> clientNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientName');
    });
  }

  QueryBuilder<FollowupLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FollowupLocal, String, QQueryOperations> createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<FollowupLocal, DateTime, QQueryOperations>
      followupDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followupDate');
    });
  }

  QueryBuilder<FollowupLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FollowupLocal, String, QQueryOperations> mobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobile');
    });
  }

  QueryBuilder<FollowupLocal, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<FollowupLocal, String?, QQueryOperations>
      propertyCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyCode');
    });
  }

  QueryBuilder<FollowupLocal, String?, QQueryOperations> propertyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyId');
    });
  }

  QueryBuilder<FollowupLocal, String?, QQueryOperations>
      propertyTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyTitle');
    });
  }

  QueryBuilder<FollowupLocal, String?, QQueryOperations>
      requirementCustomerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requirementCustomerName');
    });
  }

  QueryBuilder<FollowupLocal, String?, QQueryOperations>
      requirementIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requirementId');
    });
  }

  QueryBuilder<FollowupLocal, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBuilderLocalCollection on Isar {
  IsarCollection<BuilderLocal> get builderLocals => this.collection();
}

const BuilderLocalSchema = CollectionSchema(
  name: r'BuilderLocal',
  id: 435823299237027840,
  properties: {
    r'activeProjects': PropertySchema(
      id: 0,
      name: r'activeProjects',
      type: IsarType.stringList,
    ),
    r'companyName': PropertySchema(
      id: 1,
      name: r'companyName',
      type: IsarType.string,
    ),
    r'contactPerson': PropertySchema(
      id: 2,
      name: r'contactPerson',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'email': PropertySchema(
      id: 4,
      name: r'email',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 5,
      name: r'id',
      type: IsarType.string,
    ),
    r'mobile': PropertySchema(
      id: 6,
      name: r'mobile',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 7,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'tier': PropertySchema(
      id: 8,
      name: r'tier',
      type: IsarType.string,
    )
  },
  estimateSize: _builderLocalEstimateSize,
  serialize: _builderLocalSerialize,
  deserialize: _builderLocalDeserialize,
  deserializeProp: _builderLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _builderLocalGetId,
  getLinks: _builderLocalGetLinks,
  attach: _builderLocalAttach,
  version: '3.1.0+1',
);

int _builderLocalEstimateSize(
  BuilderLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activeProjects.length * 3;
  {
    for (var i = 0; i < object.activeProjects.length; i++) {
      final value = object.activeProjects[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.companyName.length * 3;
  bytesCount += 3 + object.contactPerson.length * 3;
  bytesCount += 3 + object.email.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.mobile.length * 3;
  {
    final value = object.remarks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tier.length * 3;
  return bytesCount;
}

void _builderLocalSerialize(
  BuilderLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.activeProjects);
  writer.writeString(offsets[1], object.companyName);
  writer.writeString(offsets[2], object.contactPerson);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.email);
  writer.writeString(offsets[5], object.id);
  writer.writeString(offsets[6], object.mobile);
  writer.writeString(offsets[7], object.remarks);
  writer.writeString(offsets[8], object.tier);
}

BuilderLocal _builderLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BuilderLocal();
  object.activeProjects = reader.readStringList(offsets[0]) ?? [];
  object.companyName = reader.readString(offsets[1]);
  object.contactPerson = reader.readString(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.email = reader.readString(offsets[4]);
  object.id = reader.readString(offsets[5]);
  object.isarId = id;
  object.mobile = reader.readString(offsets[6]);
  object.remarks = reader.readStringOrNull(offsets[7]);
  object.tier = reader.readString(offsets[8]);
  return object;
}

P _builderLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _builderLocalGetId(BuilderLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _builderLocalGetLinks(BuilderLocal object) {
  return [];
}

void _builderLocalAttach(
    IsarCollection<dynamic> col, Id id, BuilderLocal object) {
  object.isarId = id;
}

extension BuilderLocalByIndex on IsarCollection<BuilderLocal> {
  Future<BuilderLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  BuilderLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<BuilderLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<BuilderLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(BuilderLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(BuilderLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<BuilderLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<BuilderLocal> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension BuilderLocalQueryWhereSort
    on QueryBuilder<BuilderLocal, BuilderLocal, QWhere> {
  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BuilderLocalQueryWhere
    on QueryBuilder<BuilderLocal, BuilderLocal, QWhereClause> {
  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension BuilderLocalQueryFilter
    on QueryBuilder<BuilderLocal, BuilderLocal, QFilterCondition> {
  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeProjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activeProjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activeProjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activeProjects',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activeProjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activeProjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activeProjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activeProjects',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeProjects',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activeProjects',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeProjects',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeProjects',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeProjects',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeProjects',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeProjects',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      activeProjectsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeProjects',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'companyName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'companyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'companyName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'companyName',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      companyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'companyName',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactPerson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactPerson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactPerson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPerson',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      contactPersonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactPerson',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> emailEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      emailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> emailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> emailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> emailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> emailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> isarIdEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> mobileEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      mobileGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      mobileLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> mobileBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      mobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      mobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      mobileContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> mobileMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      mobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      mobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> tierEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      tierGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> tierLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> tierBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tier',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      tierStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> tierEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> tierContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tier',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> tierMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tier',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      tierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tier',
        value: '',
      ));
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition>
      tierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tier',
        value: '',
      ));
    });
  }
}

extension BuilderLocalQueryObject
    on QueryBuilder<BuilderLocal, BuilderLocal, QFilterCondition> {}

extension BuilderLocalQueryLinks
    on QueryBuilder<BuilderLocal, BuilderLocal, QFilterCondition> {}

extension BuilderLocalQuerySortBy
    on QueryBuilder<BuilderLocal, BuilderLocal, QSortBy> {
  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy>
      sortByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByContactPerson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy>
      sortByContactPersonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByTier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tier', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> sortByTierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tier', Sort.desc);
    });
  }
}

extension BuilderLocalQuerySortThenBy
    on QueryBuilder<BuilderLocal, BuilderLocal, QSortThenBy> {
  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByCompanyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy>
      thenByCompanyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companyName', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByContactPerson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy>
      thenByContactPersonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPerson', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByTier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tier', Sort.asc);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QAfterSortBy> thenByTierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tier', Sort.desc);
    });
  }
}

extension BuilderLocalQueryWhereDistinct
    on QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> {
  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct>
      distinctByActiveProjects() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activeProjects');
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctByCompanyName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctByContactPerson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactPerson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctByMobile(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BuilderLocal, BuilderLocal, QDistinct> distinctByTier(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tier', caseSensitive: caseSensitive);
    });
  }
}

extension BuilderLocalQueryProperty
    on QueryBuilder<BuilderLocal, BuilderLocal, QQueryProperty> {
  QueryBuilder<BuilderLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<BuilderLocal, List<String>, QQueryOperations>
      activeProjectsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeProjects');
    });
  }

  QueryBuilder<BuilderLocal, String, QQueryOperations> companyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companyName');
    });
  }

  QueryBuilder<BuilderLocal, String, QQueryOperations> contactPersonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactPerson');
    });
  }

  QueryBuilder<BuilderLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BuilderLocal, String, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<BuilderLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BuilderLocal, String, QQueryOperations> mobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobile');
    });
  }

  QueryBuilder<BuilderLocal, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<BuilderLocal, String, QQueryOperations> tierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tier');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOwnerLocalCollection on Isar {
  IsarCollection<OwnerLocal> get ownerLocals => this.collection();
}

const OwnerLocalSchema = CollectionSchema(
  name: r'OwnerLocal',
  id: 886259216879823872,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'email': PropertySchema(
      id: 2,
      name: r'email',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'mobile': PropertySchema(
      id: 4,
      name: r'mobile',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 6,
      name: r'remarks',
      type: IsarType.string,
    )
  },
  estimateSize: _ownerLocalEstimateSize,
  serialize: _ownerLocalSerialize,
  deserialize: _ownerLocalDeserialize,
  deserializeProp: _ownerLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _ownerLocalGetId,
  getLinks: _ownerLocalGetLinks,
  attach: _ownerLocalAttach,
  version: '3.1.0+1',
);

int _ownerLocalEstimateSize(
  OwnerLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.email;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.mobile.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.remarks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _ownerLocalSerialize(
  OwnerLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.email);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.mobile);
  writer.writeString(offsets[5], object.name);
  writer.writeString(offsets[6], object.remarks);
}

OwnerLocal _ownerLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OwnerLocal();
  object.address = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.email = reader.readStringOrNull(offsets[2]);
  object.id = reader.readString(offsets[3]);
  object.isarId = id;
  object.mobile = reader.readString(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.remarks = reader.readStringOrNull(offsets[6]);
  return object;
}

P _ownerLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ownerLocalGetId(OwnerLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _ownerLocalGetLinks(OwnerLocal object) {
  return [];
}

void _ownerLocalAttach(IsarCollection<dynamic> col, Id id, OwnerLocal object) {
  object.isarId = id;
}

extension OwnerLocalByIndex on IsarCollection<OwnerLocal> {
  Future<OwnerLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  OwnerLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<OwnerLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<OwnerLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(OwnerLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(OwnerLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<OwnerLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<OwnerLocal> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension OwnerLocalQueryWhereSort
    on QueryBuilder<OwnerLocal, OwnerLocal, QWhere> {
  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OwnerLocalQueryWhere
    on QueryBuilder<OwnerLocal, OwnerLocal, QWhereClause> {
  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhereClause> idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OwnerLocalQueryFilter
    on QueryBuilder<OwnerLocal, OwnerLocal, QFilterCondition> {
  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> isarIdEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> mobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      mobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameEqualTo(
    String value, {
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameGreaterThan(
    String value, {
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameLessThan(
    String value, {
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameContains(
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      remarksGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }
}

extension OwnerLocalQueryObject
    on QueryBuilder<OwnerLocal, OwnerLocal, QFilterCondition> {}

extension OwnerLocalQueryLinks
    on QueryBuilder<OwnerLocal, OwnerLocal, QFilterCondition> {}

extension OwnerLocalQuerySortBy
    on QueryBuilder<OwnerLocal, OwnerLocal, QSortBy> {
  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }
}

extension OwnerLocalQuerySortThenBy
    on QueryBuilder<OwnerLocal, OwnerLocal, QSortThenBy> {
  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }
}

extension OwnerLocalQueryWhereDistinct
    on QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> {
  QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> distinctByMobile(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OwnerLocal, OwnerLocal, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }
}

extension OwnerLocalQueryProperty
    on QueryBuilder<OwnerLocal, OwnerLocal, QQueryProperty> {
  QueryBuilder<OwnerLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<OwnerLocal, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<OwnerLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OwnerLocal, String?, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<OwnerLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OwnerLocal, String, QQueryOperations> mobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobile');
    });
  }

  QueryBuilder<OwnerLocal, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<OwnerLocal, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetClientLocalCollection on Isar {
  IsarCollection<ClientLocal> get clientLocals => this.collection();
}

const ClientLocalSchema = CollectionSchema(
  name: r'ClientLocal',
  id: 4502856345066684416,
  properties: {
    r'assignedAgent': PropertySchema(
      id: 0,
      name: r'assignedAgent',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'email': PropertySchema(
      id: 2,
      name: r'email',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'mobile': PropertySchema(
      id: 4,
      name: r'mobile',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 6,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'source': PropertySchema(
      id: 7,
      name: r'source',
      type: IsarType.string,
    ),
    r'stage': PropertySchema(
      id: 8,
      name: r'stage',
      type: IsarType.string,
    )
  },
  estimateSize: _clientLocalEstimateSize,
  serialize: _clientLocalSerialize,
  deserialize: _clientLocalDeserialize,
  deserializeProp: _clientLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _clientLocalGetId,
  getLinks: _clientLocalGetLinks,
  attach: _clientLocalAttach,
  version: '3.1.0+1',
);

int _clientLocalEstimateSize(
  ClientLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.assignedAgent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.email.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.mobile.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.remarks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.stage.length * 3;
  return bytesCount;
}

void _clientLocalSerialize(
  ClientLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assignedAgent);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.email);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.mobile);
  writer.writeString(offsets[5], object.name);
  writer.writeString(offsets[6], object.remarks);
  writer.writeString(offsets[7], object.source);
  writer.writeString(offsets[8], object.stage);
}

ClientLocal _clientLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ClientLocal();
  object.assignedAgent = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.email = reader.readString(offsets[2]);
  object.id = reader.readString(offsets[3]);
  object.isarId = id;
  object.mobile = reader.readString(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.remarks = reader.readStringOrNull(offsets[6]);
  object.source = reader.readString(offsets[7]);
  object.stage = reader.readString(offsets[8]);
  return object;
}

P _clientLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _clientLocalGetId(ClientLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _clientLocalGetLinks(ClientLocal object) {
  return [];
}

void _clientLocalAttach(
    IsarCollection<dynamic> col, Id id, ClientLocal object) {
  object.isarId = id;
}

extension ClientLocalByIndex on IsarCollection<ClientLocal> {
  Future<ClientLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  ClientLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<ClientLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<ClientLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(ClientLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(ClientLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<ClientLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<ClientLocal> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension ClientLocalQueryWhereSort
    on QueryBuilder<ClientLocal, ClientLocal, QWhere> {
  QueryBuilder<ClientLocal, ClientLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ClientLocalQueryWhere
    on QueryBuilder<ClientLocal, ClientLocal, QWhereClause> {
  QueryBuilder<ClientLocal, ClientLocal, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ClientLocalQueryFilter
    on QueryBuilder<ClientLocal, ClientLocal, QFilterCondition> {
  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'assignedAgent',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'assignedAgent',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assignedAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assignedAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assignedAgent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assignedAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assignedAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assignedAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assignedAgent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedAgent',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      assignedAgentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assignedAgent',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      emailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> isarIdEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> mobileEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      mobileGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> mobileLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> mobileBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      mobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> mobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> mobileContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> mobileMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      mobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      mobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameEqualTo(
    String value, {
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameGreaterThan(
    String value, {
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameLessThan(
    String value, {
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameContains(
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      remarksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      remarksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remarks',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> remarksEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      remarksGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> remarksLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> remarksBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> remarksContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> remarksMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> sourceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> sourceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      stageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> stageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stage',
        value: '',
      ));
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition>
      stageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stage',
        value: '',
      ));
    });
  }
}

extension ClientLocalQueryObject
    on QueryBuilder<ClientLocal, ClientLocal, QFilterCondition> {}

extension ClientLocalQueryLinks
    on QueryBuilder<ClientLocal, ClientLocal, QFilterCondition> {}

extension ClientLocalQuerySortBy
    on QueryBuilder<ClientLocal, ClientLocal, QSortBy> {
  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByAssignedAgent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAgent', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy>
      sortByAssignedAgentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAgent', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByStage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> sortByStageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.desc);
    });
  }
}

extension ClientLocalQuerySortThenBy
    on QueryBuilder<ClientLocal, ClientLocal, QSortThenBy> {
  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByAssignedAgent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAgent', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy>
      thenByAssignedAgentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAgent', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByStage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.asc);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QAfterSortBy> thenByStageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stage', Sort.desc);
    });
  }
}

extension ClientLocalQueryWhereDistinct
    on QueryBuilder<ClientLocal, ClientLocal, QDistinct> {
  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctByAssignedAgent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedAgent',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctByMobile(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ClientLocal, ClientLocal, QDistinct> distinctByStage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stage', caseSensitive: caseSensitive);
    });
  }
}

extension ClientLocalQueryProperty
    on QueryBuilder<ClientLocal, ClientLocal, QQueryProperty> {
  QueryBuilder<ClientLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ClientLocal, String?, QQueryOperations> assignedAgentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedAgent');
    });
  }

  QueryBuilder<ClientLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ClientLocal, String, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<ClientLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ClientLocal, String, QQueryOperations> mobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobile');
    });
  }

  QueryBuilder<ClientLocal, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ClientLocal, String?, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<ClientLocal, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<ClientLocal, String, QQueryOperations> stageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stage');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOutboxLocalCollection on Isar {
  IsarCollection<OutboxLocal> get outboxLocals => this.collection();
}

const OutboxLocalSchema = CollectionSchema(
  name: r'OutboxLocal',
  id: -8922081633273292800,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deviceId': PropertySchema(
      id: 1,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'endpoint': PropertySchema(
      id: 2,
      name: r'endpoint',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'method': PropertySchema(
      id: 4,
      name: r'method',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 5,
      name: r'payloadJson',
      type: IsarType.string,
    )
  },
  estimateSize: _outboxLocalEstimateSize,
  serialize: _outboxLocalSerialize,
  deserialize: _outboxLocalDeserialize,
  deserializeProp: _outboxLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _outboxLocalGetId,
  getLinks: _outboxLocalGetLinks,
  attach: _outboxLocalAttach,
  version: '3.1.0+1',
);

int _outboxLocalEstimateSize(
  OutboxLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.deviceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.endpoint.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.method.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  return bytesCount;
}

void _outboxLocalSerialize(
  OutboxLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.deviceId);
  writer.writeString(offsets[2], object.endpoint);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.method);
  writer.writeString(offsets[5], object.payloadJson);
}

OutboxLocal _outboxLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutboxLocal();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.deviceId = reader.readStringOrNull(offsets[1]);
  object.endpoint = reader.readString(offsets[2]);
  object.id = reader.readString(offsets[3]);
  object.isarId = id;
  object.method = reader.readString(offsets[4]);
  object.payloadJson = reader.readString(offsets[5]);
  return object;
}

P _outboxLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _outboxLocalGetId(OutboxLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _outboxLocalGetLinks(OutboxLocal object) {
  return [];
}

void _outboxLocalAttach(
    IsarCollection<dynamic> col, Id id, OutboxLocal object) {
  object.isarId = id;
}

extension OutboxLocalByIndex on IsarCollection<OutboxLocal> {
  Future<OutboxLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  OutboxLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<OutboxLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<OutboxLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(OutboxLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(OutboxLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<OutboxLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<OutboxLocal> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension OutboxLocalQueryWhereSort
    on QueryBuilder<OutboxLocal, OutboxLocal, QWhere> {
  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OutboxLocalQueryWhere
    on QueryBuilder<OutboxLocal, OutboxLocal, QWhereClause> {
  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OutboxLocalQueryFilter
    on QueryBuilder<OutboxLocal, OutboxLocal, QFilterCondition> {
  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deviceId',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deviceId',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> deviceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> deviceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> deviceIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> endpointEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      endpointGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      endpointLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> endpointBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endpoint',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      endpointStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      endpointEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      endpointContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'endpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> endpointMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'endpoint',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      endpointIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      endpointIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'endpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> isarIdEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> methodEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      methodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> methodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> methodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'method',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      methodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> methodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> methodContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition> methodMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'method',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      methodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      methodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payloadJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterFilterCondition>
      payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadJson',
        value: '',
      ));
    });
  }
}

extension OutboxLocalQueryObject
    on QueryBuilder<OutboxLocal, OutboxLocal, QFilterCondition> {}

extension OutboxLocalQueryLinks
    on QueryBuilder<OutboxLocal, OutboxLocal, QFilterCondition> {}

extension OutboxLocalQuerySortBy
    on QueryBuilder<OutboxLocal, OutboxLocal, QSortBy> {
  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }
}

extension OutboxLocalQuerySortThenBy
    on QueryBuilder<OutboxLocal, OutboxLocal, QSortThenBy> {
  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByEndpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByEndpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endpoint', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QAfterSortBy> thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }
}

extension OutboxLocalQueryWhereDistinct
    on QueryBuilder<OutboxLocal, OutboxLocal, QDistinct> {
  QueryBuilder<OutboxLocal, OutboxLocal, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QDistinct> distinctByDeviceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QDistinct> distinctByEndpoint(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endpoint', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QDistinct> distinctByMethod(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'method', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxLocal, OutboxLocal, QDistinct> distinctByPayloadJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }
}

extension OutboxLocalQueryProperty
    on QueryBuilder<OutboxLocal, OutboxLocal, QQueryProperty> {
  QueryBuilder<OutboxLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<OutboxLocal, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OutboxLocal, String?, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<OutboxLocal, String, QQueryOperations> endpointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endpoint');
    });
  }

  QueryBuilder<OutboxLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OutboxLocal, String, QQueryOperations> methodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'method');
    });
  }

  QueryBuilder<OutboxLocal, String, QQueryOperations> payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDashboardLocalCollection on Isar {
  IsarCollection<DashboardLocal> get dashboardLocals => this.collection();
}

const DashboardLocalSchema = CollectionSchema(
  name: r'DashboardLocal',
  id: 7985840613772204032,
  properties: {
    r'activityJson': PropertySchema(
      id: 0,
      name: r'activityJson',
      type: IsarType.string,
    ),
    r'checklistJson': PropertySchema(
      id: 1,
      name: r'checklistJson',
      type: IsarType.string,
    ),
    r'followupsJson': PropertySchema(
      id: 2,
      name: r'followupsJson',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'recentPropertiesJson': PropertySchema(
      id: 4,
      name: r'recentPropertiesJson',
      type: IsarType.string,
    ),
    r'siteVisitsJson': PropertySchema(
      id: 5,
      name: r'siteVisitsJson',
      type: IsarType.string,
    ),
    r'summary': PropertySchema(
      id: 6,
      name: r'summary',
      type: IsarType.object,
      target: r'DashboardSummaryLocal',
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _dashboardLocalEstimateSize,
  serialize: _dashboardLocalSerialize,
  deserialize: _dashboardLocalDeserialize,
  deserializeProp: _dashboardLocalDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471488,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'DashboardSummaryLocal': DashboardSummaryLocalSchema},
  getId: _dashboardLocalGetId,
  getLinks: _dashboardLocalGetLinks,
  attach: _dashboardLocalAttach,
  version: '3.1.0+1',
);

int _dashboardLocalEstimateSize(
  DashboardLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activityJson.length * 3;
  bytesCount += 3 + object.checklistJson.length * 3;
  bytesCount += 3 + object.followupsJson.length * 3;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.recentPropertiesJson.length * 3;
  {
    final value = object.siteVisitsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 +
      DashboardSummaryLocalSchema.estimateSize(
          object.summary, allOffsets[DashboardSummaryLocal]!, allOffsets);
  return bytesCount;
}

void _dashboardLocalSerialize(
  DashboardLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activityJson);
  writer.writeString(offsets[1], object.checklistJson);
  writer.writeString(offsets[2], object.followupsJson);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.recentPropertiesJson);
  writer.writeString(offsets[5], object.siteVisitsJson);
  writer.writeObject<DashboardSummaryLocal>(
    offsets[6],
    allOffsets,
    DashboardSummaryLocalSchema.serialize,
    object.summary,
  );
  writer.writeDateTime(offsets[7], object.updatedAt);
}

DashboardLocal _dashboardLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DashboardLocal();
  object.activityJson = reader.readString(offsets[0]);
  object.checklistJson = reader.readString(offsets[1]);
  object.followupsJson = reader.readString(offsets[2]);
  object.id = reader.readString(offsets[3]);
  object.isarId = id;
  object.recentPropertiesJson = reader.readString(offsets[4]);
  object.siteVisitsJson = reader.readStringOrNull(offsets[5]);
  object.summary = reader.readObjectOrNull<DashboardSummaryLocal>(
        offsets[6],
        DashboardSummaryLocalSchema.deserialize,
        allOffsets,
      ) ??
      DashboardSummaryLocal();
  object.updatedAt = reader.readDateTime(offsets[7]);
  return object;
}

P _dashboardLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readObjectOrNull<DashboardSummaryLocal>(
            offset,
            DashboardSummaryLocalSchema.deserialize,
            allOffsets,
          ) ??
          DashboardSummaryLocal()) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dashboardLocalGetId(DashboardLocal object) {
  return object.isarId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _dashboardLocalGetLinks(DashboardLocal object) {
  return [];
}

void _dashboardLocalAttach(
    IsarCollection<dynamic> col, Id id, DashboardLocal object) {
  object.isarId = id;
}

extension DashboardLocalByIndex on IsarCollection<DashboardLocal> {
  Future<DashboardLocal?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  DashboardLocal? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<DashboardLocal?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<DashboardLocal?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(DashboardLocal object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(DashboardLocal object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<DashboardLocal> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<DashboardLocal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension DashboardLocalQueryWhereSort
    on QueryBuilder<DashboardLocal, DashboardLocal, QWhere> {
  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DashboardLocalQueryWhere
    on QueryBuilder<DashboardLocal, DashboardLocal, QWhereClause> {
  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DashboardLocalQueryFilter
    on QueryBuilder<DashboardLocal, DashboardLocal, QFilterCondition> {
  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activityJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activityJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activityJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activityJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      activityJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activityJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checklistJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'checklistJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'checklistJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'checklistJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'checklistJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'checklistJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'checklistJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'checklistJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checklistJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      checklistJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'checklistJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'followupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'followupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'followupsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'followupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'followupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'followupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'followupsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'followupsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      followupsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'followupsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      isarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      isarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isarId',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      isarIdEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      isarIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      isarIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      isarIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recentPropertiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recentPropertiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recentPropertiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recentPropertiesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recentPropertiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recentPropertiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recentPropertiesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recentPropertiesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recentPropertiesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      recentPropertiesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recentPropertiesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'siteVisitsJson',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'siteVisitsJson',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteVisitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'siteVisitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'siteVisitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'siteVisitsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'siteVisitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'siteVisitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'siteVisitsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'siteVisitsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'siteVisitsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      siteVisitsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'siteVisitsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DashboardLocalQueryObject
    on QueryBuilder<DashboardLocal, DashboardLocal, QFilterCondition> {
  QueryBuilder<DashboardLocal, DashboardLocal, QAfterFilterCondition> summary(
      FilterQuery<DashboardSummaryLocal> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'summary');
    });
  }
}

extension DashboardLocalQueryLinks
    on QueryBuilder<DashboardLocal, DashboardLocal, QFilterCondition> {}

extension DashboardLocalQuerySortBy
    on QueryBuilder<DashboardLocal, DashboardLocal, QSortBy> {
  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByActivityJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByActivityJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByChecklistJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklistJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByChecklistJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklistJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByFollowupsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupsJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByFollowupsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupsJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByRecentPropertiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recentPropertiesJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByRecentPropertiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recentPropertiesJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortBySiteVisitsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteVisitsJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortBySiteVisitsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteVisitsJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DashboardLocalQuerySortThenBy
    on QueryBuilder<DashboardLocal, DashboardLocal, QSortThenBy> {
  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByActivityJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByActivityJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByChecklistJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklistJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByChecklistJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checklistJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByFollowupsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupsJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByFollowupsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followupsJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByRecentPropertiesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recentPropertiesJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByRecentPropertiesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recentPropertiesJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenBySiteVisitsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteVisitsJson', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenBySiteVisitsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'siteVisitsJson', Sort.desc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DashboardLocalQueryWhereDistinct
    on QueryBuilder<DashboardLocal, DashboardLocal, QDistinct> {
  QueryBuilder<DashboardLocal, DashboardLocal, QDistinct>
      distinctByActivityJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QDistinct>
      distinctByChecklistJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checklistJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QDistinct>
      distinctByFollowupsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followupsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QDistinct>
      distinctByRecentPropertiesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recentPropertiesJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QDistinct>
      distinctBySiteVisitsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'siteVisitsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DashboardLocal, DashboardLocal, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DashboardLocalQueryProperty
    on QueryBuilder<DashboardLocal, DashboardLocal, QQueryProperty> {
  QueryBuilder<DashboardLocal, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<DashboardLocal, String, QQueryOperations>
      activityJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityJson');
    });
  }

  QueryBuilder<DashboardLocal, String, QQueryOperations>
      checklistJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checklistJson');
    });
  }

  QueryBuilder<DashboardLocal, String, QQueryOperations>
      followupsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followupsJson');
    });
  }

  QueryBuilder<DashboardLocal, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DashboardLocal, String, QQueryOperations>
      recentPropertiesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recentPropertiesJson');
    });
  }

  QueryBuilder<DashboardLocal, String?, QQueryOperations>
      siteVisitsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'siteVisitsJson');
    });
  }

  QueryBuilder<DashboardLocal, DashboardSummaryLocal, QQueryOperations>
      summaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'summary');
    });
  }

  QueryBuilder<DashboardLocal, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DashboardSummaryLocalSchema = Schema(
  name: r'DashboardSummaryLocal',
  id: 5416242803166401536,
  properties: {
    r'available': PropertySchema(
      id: 0,
      name: r'available',
      type: IsarType.long,
    ),
    r'availableTrend': PropertySchema(
      id: 1,
      name: r'availableTrend',
      type: IsarType.double,
    ),
    r'monthlyGrowth': PropertySchema(
      id: 2,
      name: r'monthlyGrowth',
      type: IsarType.string,
    ),
    r'rentalAvailable': PropertySchema(
      id: 3,
      name: r'rentalAvailable',
      type: IsarType.long,
    ),
    r'rentalRented': PropertySchema(
      id: 4,
      name: r'rentalRented',
      type: IsarType.long,
    ),
    r'rentalRequirements': PropertySchema(
      id: 5,
      name: r'rentalRequirements',
      type: IsarType.long,
    ),
    r'rented': PropertySchema(
      id: 6,
      name: r'rented',
      type: IsarType.long,
    ),
    r'rentedTrend': PropertySchema(
      id: 7,
      name: r'rentedTrend',
      type: IsarType.double,
    ),
    r'requirements': PropertySchema(
      id: 8,
      name: r'requirements',
      type: IsarType.long,
    ),
    r'requirementsTrend': PropertySchema(
      id: 9,
      name: r'requirementsTrend',
      type: IsarType.double,
    ),
    r'resaleAvailable': PropertySchema(
      id: 10,
      name: r'resaleAvailable',
      type: IsarType.long,
    ),
    r'resaleRequirements': PropertySchema(
      id: 11,
      name: r'resaleRequirements',
      type: IsarType.long,
    ),
    r'resaleSold': PropertySchema(
      id: 12,
      name: r'resaleSold',
      type: IsarType.long,
    ),
    r'sold': PropertySchema(
      id: 13,
      name: r'sold',
      type: IsarType.long,
    ),
    r'soldTrend': PropertySchema(
      id: 14,
      name: r'soldTrend',
      type: IsarType.double,
    ),
    r'topArea': PropertySchema(
      id: 15,
      name: r'topArea',
      type: IsarType.string,
    ),
    r'topBroker': PropertySchema(
      id: 16,
      name: r'topBroker',
      type: IsarType.string,
    ),
    r'topProperty': PropertySchema(
      id: 17,
      name: r'topProperty',
      type: IsarType.string,
    ),
    r'totalProperties': PropertySchema(
      id: 18,
      name: r'totalProperties',
      type: IsarType.long,
    ),
    r'totalPropertiesTrend': PropertySchema(
      id: 19,
      name: r'totalPropertiesTrend',
      type: IsarType.double,
    ),
    r'users': PropertySchema(
      id: 20,
      name: r'users',
      type: IsarType.long,
    )
  },
  estimateSize: _dashboardSummaryLocalEstimateSize,
  serialize: _dashboardSummaryLocalSerialize,
  deserialize: _dashboardSummaryLocalDeserialize,
  deserializeProp: _dashboardSummaryLocalDeserializeProp,
);

int _dashboardSummaryLocalEstimateSize(
  DashboardSummaryLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.monthlyGrowth;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.topArea;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.topBroker;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.topProperty;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dashboardSummaryLocalSerialize(
  DashboardSummaryLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.available);
  writer.writeDouble(offsets[1], object.availableTrend);
  writer.writeString(offsets[2], object.monthlyGrowth);
  writer.writeLong(offsets[3], object.rentalAvailable);
  writer.writeLong(offsets[4], object.rentalRented);
  writer.writeLong(offsets[5], object.rentalRequirements);
  writer.writeLong(offsets[6], object.rented);
  writer.writeDouble(offsets[7], object.rentedTrend);
  writer.writeLong(offsets[8], object.requirements);
  writer.writeDouble(offsets[9], object.requirementsTrend);
  writer.writeLong(offsets[10], object.resaleAvailable);
  writer.writeLong(offsets[11], object.resaleRequirements);
  writer.writeLong(offsets[12], object.resaleSold);
  writer.writeLong(offsets[13], object.sold);
  writer.writeDouble(offsets[14], object.soldTrend);
  writer.writeString(offsets[15], object.topArea);
  writer.writeString(offsets[16], object.topBroker);
  writer.writeString(offsets[17], object.topProperty);
  writer.writeLong(offsets[18], object.totalProperties);
  writer.writeDouble(offsets[19], object.totalPropertiesTrend);
  writer.writeLong(offsets[20], object.users);
}

DashboardSummaryLocal _dashboardSummaryLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DashboardSummaryLocal();
  object.available = reader.readLongOrNull(offsets[0]);
  object.availableTrend = reader.readDoubleOrNull(offsets[1]);
  object.monthlyGrowth = reader.readStringOrNull(offsets[2]);
  object.rentalAvailable = reader.readLongOrNull(offsets[3]);
  object.rentalRented = reader.readLongOrNull(offsets[4]);
  object.rentalRequirements = reader.readLongOrNull(offsets[5]);
  object.rented = reader.readLongOrNull(offsets[6]);
  object.rentedTrend = reader.readDoubleOrNull(offsets[7]);
  object.requirements = reader.readLongOrNull(offsets[8]);
  object.requirementsTrend = reader.readDoubleOrNull(offsets[9]);
  object.resaleAvailable = reader.readLongOrNull(offsets[10]);
  object.resaleRequirements = reader.readLongOrNull(offsets[11]);
  object.resaleSold = reader.readLongOrNull(offsets[12]);
  object.sold = reader.readLongOrNull(offsets[13]);
  object.soldTrend = reader.readDoubleOrNull(offsets[14]);
  object.topArea = reader.readStringOrNull(offsets[15]);
  object.topBroker = reader.readStringOrNull(offsets[16]);
  object.topProperty = reader.readStringOrNull(offsets[17]);
  object.totalProperties = reader.readLongOrNull(offsets[18]);
  object.totalPropertiesTrend = reader.readDoubleOrNull(offsets[19]);
  object.users = reader.readLongOrNull(offsets[20]);
  return object;
}

P _dashboardSummaryLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DashboardSummaryLocalQueryFilter on QueryBuilder<
    DashboardSummaryLocal, DashboardSummaryLocal, QFilterCondition> {
  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'available',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'available',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'available',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'available',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'available',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'available',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableTrendIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'availableTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableTrendIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'availableTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableTrendEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availableTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableTrendGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'availableTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableTrendLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'availableTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> availableTrendBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'availableTrend',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'monthlyGrowth',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'monthlyGrowth',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyGrowth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyGrowth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyGrowth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyGrowth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'monthlyGrowth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'monthlyGrowth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      monthlyGrowthContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'monthlyGrowth',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      monthlyGrowthMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'monthlyGrowth',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyGrowth',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> monthlyGrowthIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'monthlyGrowth',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalAvailableIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rentalAvailable',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalAvailableIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rentalAvailable',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalAvailableEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rentalAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalAvailableGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rentalAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalAvailableLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rentalAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalAvailableBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rentalAvailable',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRentedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rentalRented',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRentedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rentalRented',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRentedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rentalRented',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRentedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rentalRented',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRentedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rentalRented',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRentedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rentalRented',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRequirementsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rentalRequirements',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRequirementsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rentalRequirements',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRequirementsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rentalRequirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRequirementsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rentalRequirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRequirementsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rentalRequirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentalRequirementsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rentalRequirements',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rented',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rented',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rented',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rented',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rented',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rented',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedTrendIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rentedTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedTrendIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rentedTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedTrendEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rentedTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedTrendGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rentedTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedTrendLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rentedTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> rentedTrendBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rentedTrend',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'requirements',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'requirements',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requirements',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsTrendIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'requirementsTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsTrendIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'requirementsTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsTrendEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requirementsTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsTrendGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requirementsTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsTrendLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requirementsTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> requirementsTrendBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requirementsTrend',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleAvailableIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'resaleAvailable',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleAvailableIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'resaleAvailable',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleAvailableEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resaleAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleAvailableGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'resaleAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleAvailableLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'resaleAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleAvailableBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'resaleAvailable',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleRequirementsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'resaleRequirements',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleRequirementsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'resaleRequirements',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleRequirementsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resaleRequirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleRequirementsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'resaleRequirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleRequirementsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'resaleRequirements',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleRequirementsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'resaleRequirements',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleSoldIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'resaleSold',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleSoldIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'resaleSold',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleSoldEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resaleSold',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleSoldGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'resaleSold',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleSoldLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'resaleSold',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> resaleSoldBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'resaleSold',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sold',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sold',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sold',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sold',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sold',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sold',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldTrendIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'soldTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldTrendIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'soldTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldTrendEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soldTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldTrendGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'soldTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldTrendLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'soldTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> soldTrendBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'soldTrend',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topArea',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topArea',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topArea',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topArea',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topArea',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topArea',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topArea',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topArea',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      topAreaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topArea',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      topAreaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topArea',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topArea',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topAreaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topArea',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topBroker',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topBroker',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topBroker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topBroker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topBroker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topBroker',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topBroker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topBroker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      topBrokerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topBroker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      topBrokerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topBroker',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topBroker',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topBrokerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topBroker',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topProperty',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topProperty',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topProperty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topProperty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topProperty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topProperty',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topProperty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topProperty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      topPropertyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topProperty',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
          QAfterFilterCondition>
      topPropertyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topProperty',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topProperty',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> topPropertyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topProperty',
        value: '',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalProperties',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalProperties',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalProperties',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalProperties',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalProperties',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalProperties',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesTrendIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalPropertiesTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesTrendIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalPropertiesTrend',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesTrendEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalPropertiesTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesTrendGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalPropertiesTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesTrendLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalPropertiesTrend',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> totalPropertiesTrendBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalPropertiesTrend',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> usersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'users',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> usersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'users',
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> usersEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'users',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> usersGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'users',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> usersLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'users',
        value: value,
      ));
    });
  }

  QueryBuilder<DashboardSummaryLocal, DashboardSummaryLocal,
      QAfterFilterCondition> usersBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'users',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DashboardSummaryLocalQueryObject on QueryBuilder<
    DashboardSummaryLocal, DashboardSummaryLocal, QFilterCondition> {}
