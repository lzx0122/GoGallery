// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncRecordCollection on Isar {
  IsarCollection<SyncRecord> get syncRecords => this.collection();
}

const SyncRecordSchema = CollectionSchema(
  name: r'SyncRecord',
  id: -4886533455886102454,
  properties: {
    r'fileHash': PropertySchema(
      id: 0,
      name: r'fileHash',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 1,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastSyncTime': PropertySchema(
      id: 2,
      name: r'lastSyncTime',
      type: IsarType.dateTime,
    ),
    r'localId': PropertySchema(
      id: 3,
      name: r'localId',
      type: IsarType.string,
    )
  },
  estimateSize: _syncRecordEstimateSize,
  serialize: _syncRecordSerialize,
  deserialize: _syncRecordDeserialize,
  deserializeProp: _syncRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'localId': IndexSchema(
      id: 1199848425898359622,
      name: r'localId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'localId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'fileHash': IndexSchema(
      id: -5944002318434853925,
      name: r'fileHash',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fileHash',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _syncRecordGetId,
  getLinks: _syncRecordGetLinks,
  attach: _syncRecordAttach,
  version: '3.1.0+1',
);

int _syncRecordEstimateSize(
  SyncRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.fileHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _syncRecordSerialize(
  SyncRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.fileHash);
  writer.writeBool(offsets[1], object.isSynced);
  writer.writeDateTime(offsets[2], object.lastSyncTime);
  writer.writeString(offsets[3], object.localId);
}

SyncRecord _syncRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncRecord();
  object.fileHash = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[1]);
  object.lastSyncTime = reader.readDateTimeOrNull(offsets[2]);
  object.localId = reader.readStringOrNull(offsets[3]);
  return object;
}

P _syncRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncRecordGetId(SyncRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncRecordGetLinks(SyncRecord object) {
  return [];
}

void _syncRecordAttach(IsarCollection<dynamic> col, Id id, SyncRecord object) {
  object.id = id;
}

extension SyncRecordByIndex on IsarCollection<SyncRecord> {
  Future<SyncRecord?> getByLocalId(String? localId) {
    return getByIndex(r'localId', [localId]);
  }

  SyncRecord? getByLocalIdSync(String? localId) {
    return getByIndexSync(r'localId', [localId]);
  }

  Future<bool> deleteByLocalId(String? localId) {
    return deleteByIndex(r'localId', [localId]);
  }

  bool deleteByLocalIdSync(String? localId) {
    return deleteByIndexSync(r'localId', [localId]);
  }

  Future<List<SyncRecord?>> getAllByLocalId(List<String?> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'localId', values);
  }

  List<SyncRecord?> getAllByLocalIdSync(List<String?> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'localId', values);
  }

  Future<int> deleteAllByLocalId(List<String?> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'localId', values);
  }

  int deleteAllByLocalIdSync(List<String?> localIdValues) {
    final values = localIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'localId', values);
  }

  Future<Id> putByLocalId(SyncRecord object) {
    return putByIndex(r'localId', object);
  }

  Id putByLocalIdSync(SyncRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'localId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByLocalId(List<SyncRecord> objects) {
    return putAllByIndex(r'localId', objects);
  }

  List<Id> putAllByLocalIdSync(List<SyncRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'localId', objects, saveLinks: saveLinks);
  }
}

extension SyncRecordQueryWhereSort
    on QueryBuilder<SyncRecord, SyncRecord, QWhere> {
  QueryBuilder<SyncRecord, SyncRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncRecordQueryWhere
    on QueryBuilder<SyncRecord, SyncRecord, QWhereClause> {
  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> localIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'localId',
        value: [null],
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> localIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'localId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> localIdEqualTo(
      String? localId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'localId',
        value: [localId],
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> localIdNotEqualTo(
      String? localId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [],
              upper: [localId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [localId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [localId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'localId',
              lower: [],
              upper: [localId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> fileHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fileHash',
        value: [null],
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> fileHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fileHash',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> fileHashEqualTo(
      String? fileHash) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fileHash',
        value: [fileHash],
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterWhereClause> fileHashNotEqualTo(
      String? fileHash) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [],
              upper: [fileHash],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [fileHash],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [fileHash],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [],
              upper: [fileHash],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SyncRecordQueryFilter
    on QueryBuilder<SyncRecord, SyncRecord, QFilterCondition> {
  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> fileHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fileHash',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      fileHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fileHash',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> fileHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      fileHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> fileHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> fileHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      fileHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> fileHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> fileHashContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> fileHashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      fileHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      fileHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileHash',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      lastSyncTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncTime',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      lastSyncTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncTime',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      lastSyncTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      lastSyncTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      lastSyncTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      lastSyncTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localId',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      localIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localId',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      localIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition> localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterFilterCondition>
      localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localId',
        value: '',
      ));
    });
  }
}

extension SyncRecordQueryObject
    on QueryBuilder<SyncRecord, SyncRecord, QFilterCondition> {}

extension SyncRecordQueryLinks
    on QueryBuilder<SyncRecord, SyncRecord, QFilterCondition> {}

extension SyncRecordQuerySortBy
    on QueryBuilder<SyncRecord, SyncRecord, QSortBy> {
  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByFileHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByFileHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.desc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByLastSyncTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.desc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }
}

extension SyncRecordQuerySortThenBy
    on QueryBuilder<SyncRecord, SyncRecord, QSortThenBy> {
  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByFileHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByFileHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.desc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByLastSyncTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncTime', Sort.desc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QAfterSortBy> thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }
}

extension SyncRecordQueryWhereDistinct
    on QueryBuilder<SyncRecord, SyncRecord, QDistinct> {
  QueryBuilder<SyncRecord, SyncRecord, QDistinct> distinctByFileHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QDistinct> distinctByLastSyncTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncTime');
    });
  }

  QueryBuilder<SyncRecord, SyncRecord, QDistinct> distinctByLocalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }
}

extension SyncRecordQueryProperty
    on QueryBuilder<SyncRecord, SyncRecord, QQueryProperty> {
  QueryBuilder<SyncRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncRecord, String?, QQueryOperations> fileHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileHash');
    });
  }

  QueryBuilder<SyncRecord, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<SyncRecord, DateTime?, QQueryOperations> lastSyncTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncTime');
    });
  }

  QueryBuilder<SyncRecord, String?, QQueryOperations> localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }
}
