// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LessonProgressTableTable extends LessonProgressTable
    with TableInfo<$LessonProgressTableTable, LessonProgressTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completionDateMeta = const VerificationMeta(
    'completionDate',
  );
  @override
  late final GeneratedColumn<DateTime> completionDate =
      GeneratedColumn<DateTime>(
        'completion_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageCode,
    stars,
    completionDate,
    isCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('completion_date')) {
      context.handle(
        _completionDateMeta,
        completionDate.isAcceptableOrUnknown(
          data['completion_date']!,
          _completionDateMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, languageCode};
  @override
  LessonProgressTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      completionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completion_date'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $LessonProgressTableTable createAlias(String alias) {
    return $LessonProgressTableTable(attachedDatabase, alias);
  }
}

class LessonProgressTableData extends DataClass
    implements Insertable<LessonProgressTableData> {
  final String id;
  final String languageCode;
  final int stars;
  final DateTime? completionDate;
  final bool isCompleted;
  const LessonProgressTableData({
    required this.id,
    required this.languageCode,
    required this.stars,
    this.completionDate,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_code'] = Variable<String>(languageCode);
    map['stars'] = Variable<int>(stars);
    if (!nullToAbsent || completionDate != null) {
      map['completion_date'] = Variable<DateTime>(completionDate);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  LessonProgressTableCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressTableCompanion(
      id: Value(id),
      languageCode: Value(languageCode),
      stars: Value(stars),
      completionDate: completionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(completionDate),
      isCompleted: Value(isCompleted),
    );
  }

  factory LessonProgressTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressTableData(
      id: serializer.fromJson<String>(json['id']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      stars: serializer.fromJson<int>(json['stars']),
      completionDate: serializer.fromJson<DateTime?>(json['completionDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageCode': serializer.toJson<String>(languageCode),
      'stars': serializer.toJson<int>(stars),
      'completionDate': serializer.toJson<DateTime?>(completionDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  LessonProgressTableData copyWith({
    String? id,
    String? languageCode,
    int? stars,
    Value<DateTime?> completionDate = const Value.absent(),
    bool? isCompleted,
  }) => LessonProgressTableData(
    id: id ?? this.id,
    languageCode: languageCode ?? this.languageCode,
    stars: stars ?? this.stars,
    completionDate: completionDate.present
        ? completionDate.value
        : this.completionDate,
    isCompleted: isCompleted ?? this.isCompleted,
  );
  LessonProgressTableData copyWithCompanion(LessonProgressTableCompanion data) {
    return LessonProgressTableData(
      id: data.id.present ? data.id.value : this.id,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      stars: data.stars.present ? data.stars.value : this.stars,
      completionDate: data.completionDate.present
          ? data.completionDate.value
          : this.completionDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressTableData(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('stars: $stars, ')
          ..write('completionDate: $completionDate, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, languageCode, stars, completionDate, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressTableData &&
          other.id == this.id &&
          other.languageCode == this.languageCode &&
          other.stars == this.stars &&
          other.completionDate == this.completionDate &&
          other.isCompleted == this.isCompleted);
}

class LessonProgressTableCompanion
    extends UpdateCompanion<LessonProgressTableData> {
  final Value<String> id;
  final Value<String> languageCode;
  final Value<int> stars;
  final Value<DateTime?> completionDate;
  final Value<bool> isCompleted;
  final Value<int> rowid;
  const LessonProgressTableCompanion({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.stars = const Value.absent(),
    this.completionDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressTableCompanion.insert({
    required String id,
    required String languageCode,
    this.stars = const Value.absent(),
    this.completionDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageCode = Value(languageCode);
  static Insertable<LessonProgressTableData> custom({
    Expression<String>? id,
    Expression<String>? languageCode,
    Expression<int>? stars,
    Expression<DateTime>? completionDate,
    Expression<bool>? isCompleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageCode != null) 'language_code': languageCode,
      if (stars != null) 'stars': stars,
      if (completionDate != null) 'completion_date': completionDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressTableCompanion copyWith({
    Value<String>? id,
    Value<String>? languageCode,
    Value<int>? stars,
    Value<DateTime?>? completionDate,
    Value<bool>? isCompleted,
    Value<int>? rowid,
  }) {
    return LessonProgressTableCompanion(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      stars: stars ?? this.stars,
      completionDate: completionDate ?? this.completionDate,
      isCompleted: isCompleted ?? this.isCompleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (completionDate.present) {
      map['completion_date'] = Variable<DateTime>(completionDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressTableCompanion(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('stars: $stars, ')
          ..write('completionDate: $completionDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordStrengthTableTable extends WordStrengthTable
    with TableInfo<$WordStrengthTableTable, WordStrengthTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordStrengthTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  @override
  late final GeneratedColumn<double> strength = GeneratedColumn<double>(
    'strength',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _lastReviewDateMeta = const VerificationMeta(
    'lastReviewDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewDate =
      GeneratedColumn<DateTime>(
        'last_review_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    word,
    languageCode,
    strength,
    lastReviewDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_strength_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordStrengthTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    }
    if (data.containsKey('last_review_date')) {
      context.handle(
        _lastReviewDateMeta,
        lastReviewDate.isAcceptableOrUnknown(
          data['last_review_date']!,
          _lastReviewDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word, languageCode};
  @override
  WordStrengthTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordStrengthTableData(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}strength'],
      )!,
      lastReviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review_date'],
      ),
    );
  }

  @override
  $WordStrengthTableTable createAlias(String alias) {
    return $WordStrengthTableTable(attachedDatabase, alias);
  }
}

class WordStrengthTableData extends DataClass
    implements Insertable<WordStrengthTableData> {
  final String word;
  final String languageCode;
  final double strength;
  final DateTime? lastReviewDate;
  const WordStrengthTableData({
    required this.word,
    required this.languageCode,
    required this.strength,
    this.lastReviewDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['language_code'] = Variable<String>(languageCode);
    map['strength'] = Variable<double>(strength);
    if (!nullToAbsent || lastReviewDate != null) {
      map['last_review_date'] = Variable<DateTime>(lastReviewDate);
    }
    return map;
  }

  WordStrengthTableCompanion toCompanion(bool nullToAbsent) {
    return WordStrengthTableCompanion(
      word: Value(word),
      languageCode: Value(languageCode),
      strength: Value(strength),
      lastReviewDate: lastReviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewDate),
    );
  }

  factory WordStrengthTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordStrengthTableData(
      word: serializer.fromJson<String>(json['word']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      strength: serializer.fromJson<double>(json['strength']),
      lastReviewDate: serializer.fromJson<DateTime?>(json['lastReviewDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'languageCode': serializer.toJson<String>(languageCode),
      'strength': serializer.toJson<double>(strength),
      'lastReviewDate': serializer.toJson<DateTime?>(lastReviewDate),
    };
  }

  WordStrengthTableData copyWith({
    String? word,
    String? languageCode,
    double? strength,
    Value<DateTime?> lastReviewDate = const Value.absent(),
  }) => WordStrengthTableData(
    word: word ?? this.word,
    languageCode: languageCode ?? this.languageCode,
    strength: strength ?? this.strength,
    lastReviewDate: lastReviewDate.present
        ? lastReviewDate.value
        : this.lastReviewDate,
  );
  WordStrengthTableData copyWithCompanion(WordStrengthTableCompanion data) {
    return WordStrengthTableData(
      word: data.word.present ? data.word.value : this.word,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      strength: data.strength.present ? data.strength.value : this.strength,
      lastReviewDate: data.lastReviewDate.present
          ? data.lastReviewDate.value
          : this.lastReviewDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordStrengthTableData(')
          ..write('word: $word, ')
          ..write('languageCode: $languageCode, ')
          ..write('strength: $strength, ')
          ..write('lastReviewDate: $lastReviewDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(word, languageCode, strength, lastReviewDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordStrengthTableData &&
          other.word == this.word &&
          other.languageCode == this.languageCode &&
          other.strength == this.strength &&
          other.lastReviewDate == this.lastReviewDate);
}

class WordStrengthTableCompanion
    extends UpdateCompanion<WordStrengthTableData> {
  final Value<String> word;
  final Value<String> languageCode;
  final Value<double> strength;
  final Value<DateTime?> lastReviewDate;
  final Value<int> rowid;
  const WordStrengthTableCompanion({
    this.word = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.strength = const Value.absent(),
    this.lastReviewDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordStrengthTableCompanion.insert({
    required String word,
    required String languageCode,
    this.strength = const Value.absent(),
    this.lastReviewDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       languageCode = Value(languageCode);
  static Insertable<WordStrengthTableData> custom({
    Expression<String>? word,
    Expression<String>? languageCode,
    Expression<double>? strength,
    Expression<DateTime>? lastReviewDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (languageCode != null) 'language_code': languageCode,
      if (strength != null) 'strength': strength,
      if (lastReviewDate != null) 'last_review_date': lastReviewDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordStrengthTableCompanion copyWith({
    Value<String>? word,
    Value<String>? languageCode,
    Value<double>? strength,
    Value<DateTime?>? lastReviewDate,
    Value<int>? rowid,
  }) {
    return WordStrengthTableCompanion(
      word: word ?? this.word,
      languageCode: languageCode ?? this.languageCode,
      strength: strength ?? this.strength,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (strength.present) {
      map['strength'] = Variable<double>(strength.value);
    }
    if (lastReviewDate.present) {
      map['last_review_date'] = Variable<DateTime>(lastReviewDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordStrengthTableCompanion(')
          ..write('word: $word, ')
          ..write('languageCode: $languageCode, ')
          ..write('strength: $strength, ')
          ..write('lastReviewDate: $lastReviewDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LessonProgressTableTable lessonProgressTable =
      $LessonProgressTableTable(this);
  late final $WordStrengthTableTable wordStrengthTable =
      $WordStrengthTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lessonProgressTable,
    wordStrengthTable,
  ];
}

typedef $$LessonProgressTableTableCreateCompanionBuilder =
    LessonProgressTableCompanion Function({
      required String id,
      required String languageCode,
      Value<int> stars,
      Value<DateTime?> completionDate,
      Value<bool> isCompleted,
      Value<int> rowid,
    });
typedef $$LessonProgressTableTableUpdateCompanionBuilder =
    LessonProgressTableCompanion Function({
      Value<String> id,
      Value<String> languageCode,
      Value<int> stars,
      Value<DateTime?> completionDate,
      Value<bool> isCompleted,
      Value<int> rowid,
    });

class $$LessonProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressTableTable> {
  $$LessonProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completionDate => $composableBuilder(
    column: $table.completionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressTableTable> {
  $$LessonProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completionDate => $composableBuilder(
    column: $table.completionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressTableTable> {
  $$LessonProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<DateTime> get completionDate => $composableBuilder(
    column: $table.completionDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );
}

class $$LessonProgressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonProgressTableTable,
          LessonProgressTableData,
          $$LessonProgressTableTableFilterComposer,
          $$LessonProgressTableTableOrderingComposer,
          $$LessonProgressTableTableAnnotationComposer,
          $$LessonProgressTableTableCreateCompanionBuilder,
          $$LessonProgressTableTableUpdateCompanionBuilder,
          (
            LessonProgressTableData,
            BaseReferences<
              _$AppDatabase,
              $LessonProgressTableTable,
              LessonProgressTableData
            >,
          ),
          LessonProgressTableData,
          PrefetchHooks Function()
        > {
  $$LessonProgressTableTableTableManager(
    _$AppDatabase db,
    $LessonProgressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LessonProgressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<DateTime?> completionDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressTableCompanion(
                id: id,
                languageCode: languageCode,
                stars: stars,
                completionDate: completionDate,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageCode,
                Value<int> stars = const Value.absent(),
                Value<DateTime?> completionDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressTableCompanion.insert(
                id: id,
                languageCode: languageCode,
                stars: stars,
                completionDate: completionDate,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonProgressTableTable,
      LessonProgressTableData,
      $$LessonProgressTableTableFilterComposer,
      $$LessonProgressTableTableOrderingComposer,
      $$LessonProgressTableTableAnnotationComposer,
      $$LessonProgressTableTableCreateCompanionBuilder,
      $$LessonProgressTableTableUpdateCompanionBuilder,
      (
        LessonProgressTableData,
        BaseReferences<
          _$AppDatabase,
          $LessonProgressTableTable,
          LessonProgressTableData
        >,
      ),
      LessonProgressTableData,
      PrefetchHooks Function()
    >;
typedef $$WordStrengthTableTableCreateCompanionBuilder =
    WordStrengthTableCompanion Function({
      required String word,
      required String languageCode,
      Value<double> strength,
      Value<DateTime?> lastReviewDate,
      Value<int> rowid,
    });
typedef $$WordStrengthTableTableUpdateCompanionBuilder =
    WordStrengthTableCompanion Function({
      Value<String> word,
      Value<String> languageCode,
      Value<double> strength,
      Value<DateTime?> lastReviewDate,
      Value<int> rowid,
    });

class $$WordStrengthTableTableFilterComposer
    extends Composer<_$AppDatabase, $WordStrengthTableTable> {
  $$WordStrengthTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewDate => $composableBuilder(
    column: $table.lastReviewDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordStrengthTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WordStrengthTableTable> {
  $$WordStrengthTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewDate => $composableBuilder(
    column: $table.lastReviewDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordStrengthTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordStrengthTableTable> {
  $$WordStrengthTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewDate => $composableBuilder(
    column: $table.lastReviewDate,
    builder: (column) => column,
  );
}

class $$WordStrengthTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordStrengthTableTable,
          WordStrengthTableData,
          $$WordStrengthTableTableFilterComposer,
          $$WordStrengthTableTableOrderingComposer,
          $$WordStrengthTableTableAnnotationComposer,
          $$WordStrengthTableTableCreateCompanionBuilder,
          $$WordStrengthTableTableUpdateCompanionBuilder,
          (
            WordStrengthTableData,
            BaseReferences<
              _$AppDatabase,
              $WordStrengthTableTable,
              WordStrengthTableData
            >,
          ),
          WordStrengthTableData,
          PrefetchHooks Function()
        > {
  $$WordStrengthTableTableTableManager(
    _$AppDatabase db,
    $WordStrengthTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordStrengthTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordStrengthTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordStrengthTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<double> strength = const Value.absent(),
                Value<DateTime?> lastReviewDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordStrengthTableCompanion(
                word: word,
                languageCode: languageCode,
                strength: strength,
                lastReviewDate: lastReviewDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                required String languageCode,
                Value<double> strength = const Value.absent(),
                Value<DateTime?> lastReviewDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordStrengthTableCompanion.insert(
                word: word,
                languageCode: languageCode,
                strength: strength,
                lastReviewDate: lastReviewDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordStrengthTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordStrengthTableTable,
      WordStrengthTableData,
      $$WordStrengthTableTableFilterComposer,
      $$WordStrengthTableTableOrderingComposer,
      $$WordStrengthTableTableAnnotationComposer,
      $$WordStrengthTableTableCreateCompanionBuilder,
      $$WordStrengthTableTableUpdateCompanionBuilder,
      (
        WordStrengthTableData,
        BaseReferences<
          _$AppDatabase,
          $WordStrengthTableTable,
          WordStrengthTableData
        >,
      ),
      WordStrengthTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LessonProgressTableTableTableManager get lessonProgressTable =>
      $$LessonProgressTableTableTableManager(_db, _db.lessonProgressTable);
  $$WordStrengthTableTableTableManager get wordStrengthTable =>
      $$WordStrengthTableTableTableManager(_db, _db.wordStrengthTable);
}
