// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta(
    'colorArgb',
  );
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF7F8C8D),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorArgb, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_argb')) {
      context.handle(
        _colorArgbMeta,
        colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_argb'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;

  /// Packed ARGB color (unsigned, e.g. 0xFF2980B9).
  final int colorArgb;
  final int sortOrder;
  const Category({
    required this.id,
    required this.name,
    required this.colorArgb,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_argb'] = Variable<int>(colorArgb);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorArgb: Value(colorArgb),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorArgb: serializer.fromJson<int>(json['colorArgb']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorArgb': serializer.toJson<int>(colorArgb),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({int? id, String? name, int? colorArgb, int? sortOrder}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        colorArgb: colorArgb ?? this.colorArgb,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorArgb, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorArgb == this.colorArgb &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> colorArgb;
  final Value<int> sortOrder;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorArgb = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? colorArgb,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? colorArgb,
    Value<int>? sortOrder,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorArgb: colorArgb ?? this.colorArgb,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExerciseType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ExerciseType>($ExercisesTable.$convertertype);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultRestTimeSecondsMeta =
      const VerificationMeta('defaultRestTimeSeconds');
  @override
  late final GeneratedColumn<int> defaultRestTimeSeconds = GeneratedColumn<int>(
    'default_rest_time_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavouriteMeta = const VerificationMeta(
    'isFavourite',
  );
  @override
  late final GeneratedColumn<bool> isFavourite = GeneratedColumn<bool>(
    'is_favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favourite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    categoryId,
    type,
    notes,
    defaultRestTimeSeconds,
    isFavourite,
    archived,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('default_rest_time_seconds')) {
      context.handle(
        _defaultRestTimeSecondsMeta,
        defaultRestTimeSeconds.isAcceptableOrUnknown(
          data['default_rest_time_seconds']!,
          _defaultRestTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_favourite')) {
      context.handle(
        _isFavouriteMeta,
        isFavourite.isAcceptableOrUnknown(
          data['is_favourite']!,
          _isFavouriteMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      type: $ExercisesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      defaultRestTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_rest_time_seconds'],
      ),
      isFavourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favourite'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExerciseType, int, int> $convertertype =
      const EnumIndexConverter<ExerciseType>(ExerciseType.values);
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String name;
  final int categoryId;
  final ExerciseType type;
  final String? notes;
  final int? defaultRestTimeSeconds;
  final bool isFavourite;
  final bool archived;
  final int sortOrder;
  const Exercise({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.type,
    this.notes,
    this.defaultRestTimeSeconds,
    required this.isFavourite,
    required this.archived,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<int>(categoryId);
    {
      map['type'] = Variable<int>($ExercisesTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || defaultRestTimeSeconds != null) {
      map['default_rest_time_seconds'] = Variable<int>(defaultRestTimeSeconds);
    }
    map['is_favourite'] = Variable<bool>(isFavourite);
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: Value(categoryId),
      type: Value(type),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      defaultRestTimeSeconds: defaultRestTimeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultRestTimeSeconds),
      isFavourite: Value(isFavourite),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      type: $ExercisesTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      defaultRestTimeSeconds: serializer.fromJson<int?>(
        json['defaultRestTimeSeconds'],
      ),
      isFavourite: serializer.fromJson<bool>(json['isFavourite']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<int>(categoryId),
      'type': serializer.toJson<int>(
        $ExercisesTable.$convertertype.toJson(type),
      ),
      'notes': serializer.toJson<String?>(notes),
      'defaultRestTimeSeconds': serializer.toJson<int?>(defaultRestTimeSeconds),
      'isFavourite': serializer.toJson<bool>(isFavourite),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    int? categoryId,
    ExerciseType? type,
    Value<String?> notes = const Value.absent(),
    Value<int?> defaultRestTimeSeconds = const Value.absent(),
    bool? isFavourite,
    bool? archived,
    int? sortOrder,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    type: type ?? this.type,
    notes: notes.present ? notes.value : this.notes,
    defaultRestTimeSeconds: defaultRestTimeSeconds.present
        ? defaultRestTimeSeconds.value
        : this.defaultRestTimeSeconds,
    isFavourite: isFavourite ?? this.isFavourite,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      type: data.type.present ? data.type.value : this.type,
      notes: data.notes.present ? data.notes.value : this.notes,
      defaultRestTimeSeconds: data.defaultRestTimeSeconds.present
          ? data.defaultRestTimeSeconds.value
          : this.defaultRestTimeSeconds,
      isFavourite: data.isFavourite.present
          ? data.isFavourite.value
          : this.isFavourite,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('defaultRestTimeSeconds: $defaultRestTimeSeconds, ')
          ..write('isFavourite: $isFavourite, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    categoryId,
    type,
    notes,
    defaultRestTimeSeconds,
    isFavourite,
    archived,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.type == this.type &&
          other.notes == this.notes &&
          other.defaultRestTimeSeconds == this.defaultRestTimeSeconds &&
          other.isFavourite == this.isFavourite &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> categoryId;
  final Value<ExerciseType> type;
  final Value<String?> notes;
  final Value<int?> defaultRestTimeSeconds;
  final Value<bool> isFavourite;
  final Value<bool> archived;
  final Value<int> sortOrder;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.type = const Value.absent(),
    this.notes = const Value.absent(),
    this.defaultRestTimeSeconds = const Value.absent(),
    this.isFavourite = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int categoryId,
    this.type = const Value.absent(),
    this.notes = const Value.absent(),
    this.defaultRestTimeSeconds = const Value.absent(),
    this.isFavourite = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name),
       categoryId = Value(categoryId);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<int>? type,
    Expression<String>? notes,
    Expression<int>? defaultRestTimeSeconds,
    Expression<bool>? isFavourite,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (type != null) 'type': type,
      if (notes != null) 'notes': notes,
      if (defaultRestTimeSeconds != null)
        'default_rest_time_seconds': defaultRestTimeSeconds,
      if (isFavourite != null) 'is_favourite': isFavourite,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? categoryId,
    Value<ExerciseType>? type,
    Value<String?>? notes,
    Value<int?>? defaultRestTimeSeconds,
    Value<bool>? isFavourite,
    Value<bool>? archived,
    Value<int>? sortOrder,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      defaultRestTimeSeconds:
          defaultRestTimeSeconds ?? this.defaultRestTimeSeconds,
      isFavourite: isFavourite ?? this.isFavourite,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $ExercisesTable.$convertertype.toSql(type.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (defaultRestTimeSeconds.present) {
      map['default_rest_time_seconds'] = Variable<int>(
        defaultRestTimeSeconds.value,
      );
    }
    if (isFavourite.present) {
      map['is_favourite'] = Variable<bool>(isFavourite.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('defaultRestTimeSeconds: $defaultRestTimeSeconds, ')
          ..write('isFavourite: $isFavourite, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ExerciseMultipliersTable extends ExerciseMultipliers
    with TableInfo<$ExerciseMultipliersTable, ExerciseMultiplier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseMultipliersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _factorMeta = const VerificationMeta('factor');
  @override
  late final GeneratedColumn<double> factor = GeneratedColumn<double>(
    'factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    label,
    factor,
    enabled,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_multipliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseMultiplier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('factor')) {
      context.handle(
        _factorMeta,
        factor.isAcceptableOrUnknown(data['factor']!, _factorMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseMultiplier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseMultiplier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      factor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}factor'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ExerciseMultipliersTable createAlias(String alias) {
    return $ExerciseMultipliersTable(attachedDatabase, alias);
  }
}

class ExerciseMultiplier extends DataClass
    implements Insertable<ExerciseMultiplier> {
  final int id;
  final int exerciseId;
  final String label;
  final double factor;
  final bool enabled;
  final int sortOrder;
  const ExerciseMultiplier({
    required this.id,
    required this.exerciseId,
    required this.label,
    required this.factor,
    required this.enabled,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['label'] = Variable<String>(label);
    map['factor'] = Variable<double>(factor);
    map['enabled'] = Variable<bool>(enabled);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ExerciseMultipliersCompanion toCompanion(bool nullToAbsent) {
    return ExerciseMultipliersCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      label: Value(label),
      factor: Value(factor),
      enabled: Value(enabled),
      sortOrder: Value(sortOrder),
    );
  }

  factory ExerciseMultiplier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseMultiplier(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      label: serializer.fromJson<String>(json['label']),
      factor: serializer.fromJson<double>(json['factor']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'label': serializer.toJson<String>(label),
      'factor': serializer.toJson<double>(factor),
      'enabled': serializer.toJson<bool>(enabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ExerciseMultiplier copyWith({
    int? id,
    int? exerciseId,
    String? label,
    double? factor,
    bool? enabled,
    int? sortOrder,
  }) => ExerciseMultiplier(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    label: label ?? this.label,
    factor: factor ?? this.factor,
    enabled: enabled ?? this.enabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ExerciseMultiplier copyWithCompanion(ExerciseMultipliersCompanion data) {
    return ExerciseMultiplier(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      label: data.label.present ? data.label.value : this.label,
      factor: data.factor.present ? data.factor.value : this.factor,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseMultiplier(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('label: $label, ')
          ..write('factor: $factor, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, exerciseId, label, factor, enabled, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseMultiplier &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.label == this.label &&
          other.factor == this.factor &&
          other.enabled == this.enabled &&
          other.sortOrder == this.sortOrder);
}

class ExerciseMultipliersCompanion extends UpdateCompanion<ExerciseMultiplier> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<String> label;
  final Value<double> factor;
  final Value<bool> enabled;
  final Value<int> sortOrder;
  const ExerciseMultipliersCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.label = const Value.absent(),
    this.factor = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ExerciseMultipliersCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required String label,
    this.factor = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       label = Value(label);
  static Insertable<ExerciseMultiplier> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<String>? label,
    Expression<double>? factor,
    Expression<bool>? enabled,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (label != null) 'label': label,
      if (factor != null) 'factor': factor,
      if (enabled != null) 'enabled': enabled,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ExerciseMultipliersCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<String>? label,
    Value<double>? factor,
    Value<bool>? enabled,
    Value<int>? sortOrder,
  }) {
    return ExerciseMultipliersCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      label: label ?? this.label,
      factor: factor ?? this.factor,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (factor.present) {
      map['factor'] = Variable<double>(factor.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseMultipliersCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('label: $label, ')
          ..write('factor: $factor, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawWeightMeta = const VerificationMeta(
    'rawWeight',
  );
  @override
  late final GeneratedColumn<double> rawWeight = GeneratedColumn<double>(
    'raw_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weightMultiplierMeta = const VerificationMeta(
    'weightMultiplier',
  );
  @override
  late final GeneratedColumn<double> weightMultiplier = GeneratedColumn<double>(
    'weight_multiplier',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    date,
    rawWeight,
    weightMultiplier,
    reps,
    distance,
    durationSeconds,
    isComplete,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('raw_weight')) {
      context.handle(
        _rawWeightMeta,
        rawWeight.isAcceptableOrUnknown(data['raw_weight']!, _rawWeightMeta),
      );
    }
    if (data.containsKey('weight_multiplier')) {
      context.handle(
        _weightMultiplierMeta,
        weightMultiplier.isAcceptableOrUnknown(
          data['weight_multiplier']!,
          _weightMultiplierMeta,
        ),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      rawWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}raw_weight'],
      )!,
      weightMultiplier: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_multiplier'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final int id;
  final int exerciseId;

  /// Calendar day, `yyyy-MM-dd`.
  final String date;

  /// The number the user actually entered (before any multiplier).
  final double rawWeight;

  /// Product of the exercise's multipliers applied at log time. 1.0 in v1.
  /// `effectiveWeight = rawWeight * weightMultiplier`.
  final double weightMultiplier;
  final int reps;
  final double distance;
  final int durationSeconds;
  final bool isComplete;
  final String? note;
  final DateTime createdAt;
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.date,
    required this.rawWeight,
    required this.weightMultiplier,
    required this.reps,
    required this.distance,
    required this.durationSeconds,
    required this.isComplete,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['date'] = Variable<String>(date);
    map['raw_weight'] = Variable<double>(rawWeight);
    map['weight_multiplier'] = Variable<double>(weightMultiplier);
    map['reps'] = Variable<int>(reps);
    map['distance'] = Variable<double>(distance);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['is_complete'] = Variable<bool>(isComplete);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      date: Value(date),
      rawWeight: Value(rawWeight),
      weightMultiplier: Value(weightMultiplier),
      reps: Value(reps),
      distance: Value(distance),
      durationSeconds: Value(durationSeconds),
      isComplete: Value(isComplete),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory WorkoutSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      date: serializer.fromJson<String>(json['date']),
      rawWeight: serializer.fromJson<double>(json['rawWeight']),
      weightMultiplier: serializer.fromJson<double>(json['weightMultiplier']),
      reps: serializer.fromJson<int>(json['reps']),
      distance: serializer.fromJson<double>(json['distance']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'date': serializer.toJson<String>(date),
      'rawWeight': serializer.toJson<double>(rawWeight),
      'weightMultiplier': serializer.toJson<double>(weightMultiplier),
      'reps': serializer.toJson<int>(reps),
      'distance': serializer.toJson<double>(distance),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'isComplete': serializer.toJson<bool>(isComplete),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkoutSet copyWith({
    int? id,
    int? exerciseId,
    String? date,
    double? rawWeight,
    double? weightMultiplier,
    int? reps,
    double? distance,
    int? durationSeconds,
    bool? isComplete,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => WorkoutSet(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    date: date ?? this.date,
    rawWeight: rawWeight ?? this.rawWeight,
    weightMultiplier: weightMultiplier ?? this.weightMultiplier,
    reps: reps ?? this.reps,
    distance: distance ?? this.distance,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    isComplete: isComplete ?? this.isComplete,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      date: data.date.present ? data.date.value : this.date,
      rawWeight: data.rawWeight.present ? data.rawWeight.value : this.rawWeight,
      weightMultiplier: data.weightMultiplier.present
          ? data.weightMultiplier.value
          : this.weightMultiplier,
      reps: data.reps.present ? data.reps.value : this.reps,
      distance: data.distance.present ? data.distance.value : this.distance,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('date: $date, ')
          ..write('rawWeight: $rawWeight, ')
          ..write('weightMultiplier: $weightMultiplier, ')
          ..write('reps: $reps, ')
          ..write('distance: $distance, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isComplete: $isComplete, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    date,
    rawWeight,
    weightMultiplier,
    reps,
    distance,
    durationSeconds,
    isComplete,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.date == this.date &&
          other.rawWeight == this.rawWeight &&
          other.weightMultiplier == this.weightMultiplier &&
          other.reps == this.reps &&
          other.distance == this.distance &&
          other.durationSeconds == this.durationSeconds &&
          other.isComplete == this.isComplete &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<String> date;
  final Value<double> rawWeight;
  final Value<double> weightMultiplier;
  final Value<int> reps;
  final Value<double> distance;
  final Value<int> durationSeconds;
  final Value<bool> isComplete;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.date = const Value.absent(),
    this.rawWeight = const Value.absent(),
    this.weightMultiplier = const Value.absent(),
    this.reps = const Value.absent(),
    this.distance = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required String date,
    this.rawWeight = const Value.absent(),
    this.weightMultiplier = const Value.absent(),
    this.reps = const Value.absent(),
    this.distance = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
  }) : exerciseId = Value(exerciseId),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<WorkoutSet> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<String>? date,
    Expression<double>? rawWeight,
    Expression<double>? weightMultiplier,
    Expression<int>? reps,
    Expression<double>? distance,
    Expression<int>? durationSeconds,
    Expression<bool>? isComplete,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (date != null) 'date': date,
      if (rawWeight != null) 'raw_weight': rawWeight,
      if (weightMultiplier != null) 'weight_multiplier': weightMultiplier,
      if (reps != null) 'reps': reps,
      if (distance != null) 'distance': distance,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (isComplete != null) 'is_complete': isComplete,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<String>? date,
    Value<double>? rawWeight,
    Value<double>? weightMultiplier,
    Value<int>? reps,
    Value<double>? distance,
    Value<int>? durationSeconds,
    Value<bool>? isComplete,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      date: date ?? this.date,
      rawWeight: rawWeight ?? this.rawWeight,
      weightMultiplier: weightMultiplier ?? this.weightMultiplier,
      reps: reps ?? this.reps,
      distance: distance ?? this.distance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isComplete: isComplete ?? this.isComplete,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rawWeight.present) {
      map['raw_weight'] = Variable<double>(rawWeight.value);
    }
    if (weightMultiplier.present) {
      map['weight_multiplier'] = Variable<double>(weightMultiplier.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('date: $date, ')
          ..write('rawWeight: $rawWeight, ')
          ..write('weightMultiplier: $weightMultiplier, ')
          ..write('reps: $reps, ')
          ..write('distance: $distance, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isComplete: $isComplete, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDayNotesTable extends WorkoutDayNotes
    with TableInfo<$WorkoutDayNotesTable, WorkoutDayNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDayNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, comment];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_day_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutDayNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    } else if (isInserting) {
      context.missing(_commentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutDayNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDayNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
    );
  }

  @override
  $WorkoutDayNotesTable createAlias(String alias) {
    return $WorkoutDayNotesTable(attachedDatabase, alias);
  }
}

class WorkoutDayNote extends DataClass implements Insertable<WorkoutDayNote> {
  final int id;
  final String date;
  final String comment;
  const WorkoutDayNote({
    required this.id,
    required this.date,
    required this.comment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['comment'] = Variable<String>(comment);
    return map;
  }

  WorkoutDayNotesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDayNotesCompanion(
      id: Value(id),
      date: Value(date),
      comment: Value(comment),
    );
  }

  factory WorkoutDayNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDayNote(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      comment: serializer.fromJson<String>(json['comment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'comment': serializer.toJson<String>(comment),
    };
  }

  WorkoutDayNote copyWith({int? id, String? date, String? comment}) =>
      WorkoutDayNote(
        id: id ?? this.id,
        date: date ?? this.date,
        comment: comment ?? this.comment,
      );
  WorkoutDayNote copyWithCompanion(WorkoutDayNotesCompanion data) {
    return WorkoutDayNote(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      comment: data.comment.present ? data.comment.value : this.comment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDayNote(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, comment);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDayNote &&
          other.id == this.id &&
          other.date == this.date &&
          other.comment == this.comment);
}

class WorkoutDayNotesCompanion extends UpdateCompanion<WorkoutDayNote> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> comment;
  const WorkoutDayNotesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.comment = const Value.absent(),
  });
  WorkoutDayNotesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String comment,
  }) : date = Value(date),
       comment = Value(comment);
  static Insertable<WorkoutDayNote> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? comment,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (comment != null) 'comment': comment,
    });
  }

  WorkoutDayNotesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? comment,
  }) {
    return WorkoutDayNotesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      comment: comment ?? this.comment,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDayNotesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('comment: $comment')
          ..write(')'))
        .toString();
  }
}

class $PrResetMarkersTable extends PrResetMarkers
    with TableInfo<$PrResetMarkersTable, PrResetMarker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrResetMarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pr_reset_markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrResetMarker> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrResetMarker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrResetMarker(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PrResetMarkersTable createAlias(String alias) {
    return $PrResetMarkersTable(attachedDatabase, alias);
  }
}

class PrResetMarker extends DataClass implements Insertable<PrResetMarker> {
  final int id;
  final String date;
  final String? note;
  final DateTime createdAt;
  const PrResetMarker({
    required this.id,
    required this.date,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PrResetMarkersCompanion toCompanion(bool nullToAbsent) {
    return PrResetMarkersCompanion(
      id: Value(id),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory PrResetMarker.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrResetMarker(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PrResetMarker copyWith({
    int? id,
    String? date,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => PrResetMarker(
    id: id ?? this.id,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  PrResetMarker copyWithCompanion(PrResetMarkersCompanion data) {
    return PrResetMarker(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrResetMarker(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrResetMarker &&
          other.id == this.id &&
          other.date == this.date &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class PrResetMarkersCompanion extends UpdateCompanion<PrResetMarker> {
  final Value<int> id;
  final Value<String> date;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const PrResetMarkersCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PrResetMarkersCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.note = const Value.absent(),
    required DateTime createdAt,
  }) : date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<PrResetMarker> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PrResetMarkersCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return PrResetMarkersCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrResetMarkersCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<int> themeMode = GeneratedColumn<int>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstDayOfWeekMeta = const VerificationMeta(
    'firstDayOfWeek',
  );
  @override
  late final GeneratedColumn<int> firstDayOfWeek = GeneratedColumn<int>(
    'first_day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _defaultWeightIncrementMeta =
      const VerificationMeta('defaultWeightIncrement');
  @override
  late final GeneratedColumn<double> defaultWeightIncrement =
      GeneratedColumn<double>(
        'default_weight_increment',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(2.5),
      );
  static const VerificationMeta _restTimerSecondsMeta = const VerificationMeta(
    'restTimerSeconds',
  );
  @override
  late final GeneratedColumn<int> restTimerSeconds = GeneratedColumn<int>(
    'rest_timer_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _restTimerVibrateMeta = const VerificationMeta(
    'restTimerVibrate',
  );
  @override
  late final GeneratedColumn<bool> restTimerVibrate = GeneratedColumn<bool>(
    'rest_timer_vibrate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rest_timer_vibrate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _restTimerSoundMeta = const VerificationMeta(
    'restTimerSound',
  );
  @override
  late final GeneratedColumn<bool> restTimerSound = GeneratedColumn<bool>(
    'rest_timer_sound',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rest_timer_sound" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _restTimerAutoStartMeta =
      const VerificationMeta('restTimerAutoStart');
  @override
  late final GeneratedColumn<bool> restTimerAutoStart = GeneratedColumn<bool>(
    'rest_timer_auto_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rest_timer_auto_start" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _trackPersonalRecordsMeta =
      const VerificationMeta('trackPersonalRecords');
  @override
  late final GeneratedColumn<bool> trackPersonalRecords = GeneratedColumn<bool>(
    'track_personal_records',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_personal_records" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _markSetsCompleteMeta = const VerificationMeta(
    'markSetsComplete',
  );
  @override
  late final GeneratedColumn<bool> markSetsComplete = GeneratedColumn<bool>(
    'mark_sets_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mark_sets_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _keepScreenOnMeta = const VerificationMeta(
    'keepScreenOn',
  );
  @override
  late final GeneratedColumn<bool> keepScreenOn = GeneratedColumn<bool>(
    'keep_screen_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("keep_screen_on" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _estimated1rmMaxRepsMeta =
      const VerificationMeta('estimated1rmMaxReps');
  @override
  late final GeneratedColumn<int> estimated1rmMaxReps = GeneratedColumn<int>(
    'estimated1rm_max_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    firstDayOfWeek,
    defaultWeightIncrement,
    restTimerSeconds,
    restTimerVibrate,
    restTimerSound,
    restTimerAutoStart,
    trackPersonalRecords,
    markSetsComplete,
    keepScreenOn,
    estimated1rmMaxReps,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('first_day_of_week')) {
      context.handle(
        _firstDayOfWeekMeta,
        firstDayOfWeek.isAcceptableOrUnknown(
          data['first_day_of_week']!,
          _firstDayOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('default_weight_increment')) {
      context.handle(
        _defaultWeightIncrementMeta,
        defaultWeightIncrement.isAcceptableOrUnknown(
          data['default_weight_increment']!,
          _defaultWeightIncrementMeta,
        ),
      );
    }
    if (data.containsKey('rest_timer_seconds')) {
      context.handle(
        _restTimerSecondsMeta,
        restTimerSeconds.isAcceptableOrUnknown(
          data['rest_timer_seconds']!,
          _restTimerSecondsMeta,
        ),
      );
    }
    if (data.containsKey('rest_timer_vibrate')) {
      context.handle(
        _restTimerVibrateMeta,
        restTimerVibrate.isAcceptableOrUnknown(
          data['rest_timer_vibrate']!,
          _restTimerVibrateMeta,
        ),
      );
    }
    if (data.containsKey('rest_timer_sound')) {
      context.handle(
        _restTimerSoundMeta,
        restTimerSound.isAcceptableOrUnknown(
          data['rest_timer_sound']!,
          _restTimerSoundMeta,
        ),
      );
    }
    if (data.containsKey('rest_timer_auto_start')) {
      context.handle(
        _restTimerAutoStartMeta,
        restTimerAutoStart.isAcceptableOrUnknown(
          data['rest_timer_auto_start']!,
          _restTimerAutoStartMeta,
        ),
      );
    }
    if (data.containsKey('track_personal_records')) {
      context.handle(
        _trackPersonalRecordsMeta,
        trackPersonalRecords.isAcceptableOrUnknown(
          data['track_personal_records']!,
          _trackPersonalRecordsMeta,
        ),
      );
    }
    if (data.containsKey('mark_sets_complete')) {
      context.handle(
        _markSetsCompleteMeta,
        markSetsComplete.isAcceptableOrUnknown(
          data['mark_sets_complete']!,
          _markSetsCompleteMeta,
        ),
      );
    }
    if (data.containsKey('keep_screen_on')) {
      context.handle(
        _keepScreenOnMeta,
        keepScreenOn.isAcceptableOrUnknown(
          data['keep_screen_on']!,
          _keepScreenOnMeta,
        ),
      );
    }
    if (data.containsKey('estimated1rm_max_reps')) {
      context.handle(
        _estimated1rmMaxRepsMeta,
        estimated1rmMaxReps.isAcceptableOrUnknown(
          data['estimated1rm_max_reps']!,
          _estimated1rmMaxRepsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}theme_mode'],
      )!,
      firstDayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_day_of_week'],
      )!,
      defaultWeightIncrement: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_weight_increment'],
      )!,
      restTimerSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_timer_seconds'],
      )!,
      restTimerVibrate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rest_timer_vibrate'],
      )!,
      restTimerSound: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rest_timer_sound'],
      )!,
      restTimerAutoStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rest_timer_auto_start'],
      )!,
      trackPersonalRecords: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_personal_records'],
      )!,
      markSetsComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mark_sets_complete'],
      )!,
      keepScreenOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}keep_screen_on'],
      )!,
      estimated1rmMaxReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated1rm_max_reps'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final int themeMode;
  final int firstDayOfWeek;
  final double defaultWeightIncrement;
  final int restTimerSeconds;
  final bool restTimerVibrate;
  final bool restTimerSound;
  final bool restTimerAutoStart;
  final bool trackPersonalRecords;
  final bool markSetsComplete;
  final bool keepScreenOn;
  final int estimated1rmMaxReps;
  const AppSettingsRow({
    required this.id,
    required this.themeMode,
    required this.firstDayOfWeek,
    required this.defaultWeightIncrement,
    required this.restTimerSeconds,
    required this.restTimerVibrate,
    required this.restTimerSound,
    required this.restTimerAutoStart,
    required this.trackPersonalRecords,
    required this.markSetsComplete,
    required this.keepScreenOn,
    required this.estimated1rmMaxReps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_mode'] = Variable<int>(themeMode);
    map['first_day_of_week'] = Variable<int>(firstDayOfWeek);
    map['default_weight_increment'] = Variable<double>(defaultWeightIncrement);
    map['rest_timer_seconds'] = Variable<int>(restTimerSeconds);
    map['rest_timer_vibrate'] = Variable<bool>(restTimerVibrate);
    map['rest_timer_sound'] = Variable<bool>(restTimerSound);
    map['rest_timer_auto_start'] = Variable<bool>(restTimerAutoStart);
    map['track_personal_records'] = Variable<bool>(trackPersonalRecords);
    map['mark_sets_complete'] = Variable<bool>(markSetsComplete);
    map['keep_screen_on'] = Variable<bool>(keepScreenOn);
    map['estimated1rm_max_reps'] = Variable<int>(estimated1rmMaxReps);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      firstDayOfWeek: Value(firstDayOfWeek),
      defaultWeightIncrement: Value(defaultWeightIncrement),
      restTimerSeconds: Value(restTimerSeconds),
      restTimerVibrate: Value(restTimerVibrate),
      restTimerSound: Value(restTimerSound),
      restTimerAutoStart: Value(restTimerAutoStart),
      trackPersonalRecords: Value(trackPersonalRecords),
      markSetsComplete: Value(markSetsComplete),
      keepScreenOn: Value(keepScreenOn),
      estimated1rmMaxReps: Value(estimated1rmMaxReps),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      themeMode: serializer.fromJson<int>(json['themeMode']),
      firstDayOfWeek: serializer.fromJson<int>(json['firstDayOfWeek']),
      defaultWeightIncrement: serializer.fromJson<double>(
        json['defaultWeightIncrement'],
      ),
      restTimerSeconds: serializer.fromJson<int>(json['restTimerSeconds']),
      restTimerVibrate: serializer.fromJson<bool>(json['restTimerVibrate']),
      restTimerSound: serializer.fromJson<bool>(json['restTimerSound']),
      restTimerAutoStart: serializer.fromJson<bool>(json['restTimerAutoStart']),
      trackPersonalRecords: serializer.fromJson<bool>(
        json['trackPersonalRecords'],
      ),
      markSetsComplete: serializer.fromJson<bool>(json['markSetsComplete']),
      keepScreenOn: serializer.fromJson<bool>(json['keepScreenOn']),
      estimated1rmMaxReps: serializer.fromJson<int>(
        json['estimated1rmMaxReps'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<int>(themeMode),
      'firstDayOfWeek': serializer.toJson<int>(firstDayOfWeek),
      'defaultWeightIncrement': serializer.toJson<double>(
        defaultWeightIncrement,
      ),
      'restTimerSeconds': serializer.toJson<int>(restTimerSeconds),
      'restTimerVibrate': serializer.toJson<bool>(restTimerVibrate),
      'restTimerSound': serializer.toJson<bool>(restTimerSound),
      'restTimerAutoStart': serializer.toJson<bool>(restTimerAutoStart),
      'trackPersonalRecords': serializer.toJson<bool>(trackPersonalRecords),
      'markSetsComplete': serializer.toJson<bool>(markSetsComplete),
      'keepScreenOn': serializer.toJson<bool>(keepScreenOn),
      'estimated1rmMaxReps': serializer.toJson<int>(estimated1rmMaxReps),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    int? themeMode,
    int? firstDayOfWeek,
    double? defaultWeightIncrement,
    int? restTimerSeconds,
    bool? restTimerVibrate,
    bool? restTimerSound,
    bool? restTimerAutoStart,
    bool? trackPersonalRecords,
    bool? markSetsComplete,
    bool? keepScreenOn,
    int? estimated1rmMaxReps,
  }) => AppSettingsRow(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    defaultWeightIncrement:
        defaultWeightIncrement ?? this.defaultWeightIncrement,
    restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
    restTimerVibrate: restTimerVibrate ?? this.restTimerVibrate,
    restTimerSound: restTimerSound ?? this.restTimerSound,
    restTimerAutoStart: restTimerAutoStart ?? this.restTimerAutoStart,
    trackPersonalRecords: trackPersonalRecords ?? this.trackPersonalRecords,
    markSetsComplete: markSetsComplete ?? this.markSetsComplete,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    estimated1rmMaxReps: estimated1rmMaxReps ?? this.estimated1rmMaxReps,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      firstDayOfWeek: data.firstDayOfWeek.present
          ? data.firstDayOfWeek.value
          : this.firstDayOfWeek,
      defaultWeightIncrement: data.defaultWeightIncrement.present
          ? data.defaultWeightIncrement.value
          : this.defaultWeightIncrement,
      restTimerSeconds: data.restTimerSeconds.present
          ? data.restTimerSeconds.value
          : this.restTimerSeconds,
      restTimerVibrate: data.restTimerVibrate.present
          ? data.restTimerVibrate.value
          : this.restTimerVibrate,
      restTimerSound: data.restTimerSound.present
          ? data.restTimerSound.value
          : this.restTimerSound,
      restTimerAutoStart: data.restTimerAutoStart.present
          ? data.restTimerAutoStart.value
          : this.restTimerAutoStart,
      trackPersonalRecords: data.trackPersonalRecords.present
          ? data.trackPersonalRecords.value
          : this.trackPersonalRecords,
      markSetsComplete: data.markSetsComplete.present
          ? data.markSetsComplete.value
          : this.markSetsComplete,
      keepScreenOn: data.keepScreenOn.present
          ? data.keepScreenOn.value
          : this.keepScreenOn,
      estimated1rmMaxReps: data.estimated1rmMaxReps.present
          ? data.estimated1rmMaxReps.value
          : this.estimated1rmMaxReps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('firstDayOfWeek: $firstDayOfWeek, ')
          ..write('defaultWeightIncrement: $defaultWeightIncrement, ')
          ..write('restTimerSeconds: $restTimerSeconds, ')
          ..write('restTimerVibrate: $restTimerVibrate, ')
          ..write('restTimerSound: $restTimerSound, ')
          ..write('restTimerAutoStart: $restTimerAutoStart, ')
          ..write('trackPersonalRecords: $trackPersonalRecords, ')
          ..write('markSetsComplete: $markSetsComplete, ')
          ..write('keepScreenOn: $keepScreenOn, ')
          ..write('estimated1rmMaxReps: $estimated1rmMaxReps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    firstDayOfWeek,
    defaultWeightIncrement,
    restTimerSeconds,
    restTimerVibrate,
    restTimerSound,
    restTimerAutoStart,
    trackPersonalRecords,
    markSetsComplete,
    keepScreenOn,
    estimated1rmMaxReps,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.firstDayOfWeek == this.firstDayOfWeek &&
          other.defaultWeightIncrement == this.defaultWeightIncrement &&
          other.restTimerSeconds == this.restTimerSeconds &&
          other.restTimerVibrate == this.restTimerVibrate &&
          other.restTimerSound == this.restTimerSound &&
          other.restTimerAutoStart == this.restTimerAutoStart &&
          other.trackPersonalRecords == this.trackPersonalRecords &&
          other.markSetsComplete == this.markSetsComplete &&
          other.keepScreenOn == this.keepScreenOn &&
          other.estimated1rmMaxReps == this.estimated1rmMaxReps);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<int> themeMode;
  final Value<int> firstDayOfWeek;
  final Value<double> defaultWeightIncrement;
  final Value<int> restTimerSeconds;
  final Value<bool> restTimerVibrate;
  final Value<bool> restTimerSound;
  final Value<bool> restTimerAutoStart;
  final Value<bool> trackPersonalRecords;
  final Value<bool> markSetsComplete;
  final Value<bool> keepScreenOn;
  final Value<int> estimated1rmMaxReps;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.firstDayOfWeek = const Value.absent(),
    this.defaultWeightIncrement = const Value.absent(),
    this.restTimerSeconds = const Value.absent(),
    this.restTimerVibrate = const Value.absent(),
    this.restTimerSound = const Value.absent(),
    this.restTimerAutoStart = const Value.absent(),
    this.trackPersonalRecords = const Value.absent(),
    this.markSetsComplete = const Value.absent(),
    this.keepScreenOn = const Value.absent(),
    this.estimated1rmMaxReps = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.firstDayOfWeek = const Value.absent(),
    this.defaultWeightIncrement = const Value.absent(),
    this.restTimerSeconds = const Value.absent(),
    this.restTimerVibrate = const Value.absent(),
    this.restTimerSound = const Value.absent(),
    this.restTimerAutoStart = const Value.absent(),
    this.trackPersonalRecords = const Value.absent(),
    this.markSetsComplete = const Value.absent(),
    this.keepScreenOn = const Value.absent(),
    this.estimated1rmMaxReps = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<int>? themeMode,
    Expression<int>? firstDayOfWeek,
    Expression<double>? defaultWeightIncrement,
    Expression<int>? restTimerSeconds,
    Expression<bool>? restTimerVibrate,
    Expression<bool>? restTimerSound,
    Expression<bool>? restTimerAutoStart,
    Expression<bool>? trackPersonalRecords,
    Expression<bool>? markSetsComplete,
    Expression<bool>? keepScreenOn,
    Expression<int>? estimated1rmMaxReps,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (firstDayOfWeek != null) 'first_day_of_week': firstDayOfWeek,
      if (defaultWeightIncrement != null)
        'default_weight_increment': defaultWeightIncrement,
      if (restTimerSeconds != null) 'rest_timer_seconds': restTimerSeconds,
      if (restTimerVibrate != null) 'rest_timer_vibrate': restTimerVibrate,
      if (restTimerSound != null) 'rest_timer_sound': restTimerSound,
      if (restTimerAutoStart != null)
        'rest_timer_auto_start': restTimerAutoStart,
      if (trackPersonalRecords != null)
        'track_personal_records': trackPersonalRecords,
      if (markSetsComplete != null) 'mark_sets_complete': markSetsComplete,
      if (keepScreenOn != null) 'keep_screen_on': keepScreenOn,
      if (estimated1rmMaxReps != null)
        'estimated1rm_max_reps': estimated1rmMaxReps,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<int>? themeMode,
    Value<int>? firstDayOfWeek,
    Value<double>? defaultWeightIncrement,
    Value<int>? restTimerSeconds,
    Value<bool>? restTimerVibrate,
    Value<bool>? restTimerSound,
    Value<bool>? restTimerAutoStart,
    Value<bool>? trackPersonalRecords,
    Value<bool>? markSetsComplete,
    Value<bool>? keepScreenOn,
    Value<int>? estimated1rmMaxReps,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      defaultWeightIncrement:
          defaultWeightIncrement ?? this.defaultWeightIncrement,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      restTimerVibrate: restTimerVibrate ?? this.restTimerVibrate,
      restTimerSound: restTimerSound ?? this.restTimerSound,
      restTimerAutoStart: restTimerAutoStart ?? this.restTimerAutoStart,
      trackPersonalRecords: trackPersonalRecords ?? this.trackPersonalRecords,
      markSetsComplete: markSetsComplete ?? this.markSetsComplete,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      estimated1rmMaxReps: estimated1rmMaxReps ?? this.estimated1rmMaxReps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<int>(themeMode.value);
    }
    if (firstDayOfWeek.present) {
      map['first_day_of_week'] = Variable<int>(firstDayOfWeek.value);
    }
    if (defaultWeightIncrement.present) {
      map['default_weight_increment'] = Variable<double>(
        defaultWeightIncrement.value,
      );
    }
    if (restTimerSeconds.present) {
      map['rest_timer_seconds'] = Variable<int>(restTimerSeconds.value);
    }
    if (restTimerVibrate.present) {
      map['rest_timer_vibrate'] = Variable<bool>(restTimerVibrate.value);
    }
    if (restTimerSound.present) {
      map['rest_timer_sound'] = Variable<bool>(restTimerSound.value);
    }
    if (restTimerAutoStart.present) {
      map['rest_timer_auto_start'] = Variable<bool>(restTimerAutoStart.value);
    }
    if (trackPersonalRecords.present) {
      map['track_personal_records'] = Variable<bool>(
        trackPersonalRecords.value,
      );
    }
    if (markSetsComplete.present) {
      map['mark_sets_complete'] = Variable<bool>(markSetsComplete.value);
    }
    if (keepScreenOn.present) {
      map['keep_screen_on'] = Variable<bool>(keepScreenOn.value);
    }
    if (estimated1rmMaxReps.present) {
      map['estimated1rm_max_reps'] = Variable<int>(estimated1rmMaxReps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('firstDayOfWeek: $firstDayOfWeek, ')
          ..write('defaultWeightIncrement: $defaultWeightIncrement, ')
          ..write('restTimerSeconds: $restTimerSeconds, ')
          ..write('restTimerVibrate: $restTimerVibrate, ')
          ..write('restTimerSound: $restTimerSound, ')
          ..write('restTimerAutoStart: $restTimerAutoStart, ')
          ..write('trackPersonalRecords: $trackPersonalRecords, ')
          ..write('markSetsComplete: $markSetsComplete, ')
          ..write('keepScreenOn: $keepScreenOn, ')
          ..write('estimated1rmMaxReps: $estimated1rmMaxReps')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $ExerciseMultipliersTable exerciseMultipliers =
      $ExerciseMultipliersTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $WorkoutDayNotesTable workoutDayNotes = $WorkoutDayNotesTable(
    this,
  );
  late final $PrResetMarkersTable prResetMarkers = $PrResetMarkersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    exercises,
    exerciseMultipliers,
    workoutSets,
    workoutDayNotes,
    prResetMarkers,
    appSettings,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      Value<int> colorArgb,
      Value<int> sortOrder,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> colorArgb,
      Value<int> sortOrder,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExercisesTable, List<Exercise>>
  _exercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exercises,
    aliasName: $_aliasNameGenerator(db.categories.id, db.exercises.categoryId),
  );

  $$ExercisesTableProcessedTableManager get exercisesRefs {
    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_exercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exercisesRefs(
    Expression<bool> Function($$ExercisesTableFilterComposer f) f,
  ) {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> exercisesRefs<T extends Object>(
    Expression<T> Function($$ExercisesTableAnnotationComposer a) f,
  ) {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool exercisesRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorArgb = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                colorArgb: colorArgb,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> colorArgb = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                colorArgb: colorArgb,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (exercisesRefs) db.exercises],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exercisesRefs)
                    await $_getPrefetchedData<
                      Category,
                      $CategoriesTable,
                      Exercise
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._exercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).exercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool exercisesRefs})
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      required String name,
      required int categoryId,
      Value<ExerciseType> type,
      Value<String?> notes,
      Value<int?> defaultRestTimeSeconds,
      Value<bool> isFavourite,
      Value<bool> archived,
      Value<int> sortOrder,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> categoryId,
      Value<ExerciseType> type,
      Value<String?> notes,
      Value<int?> defaultRestTimeSeconds,
      Value<bool> isFavourite,
      Value<bool> archived,
      Value<int> sortOrder,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.exercises.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ExerciseMultipliersTable,
    List<ExerciseMultiplier>
  >
  _exerciseMultipliersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exerciseMultipliers,
        aliasName: $_aliasNameGenerator(
          db.exercises.id,
          db.exerciseMultipliers.exerciseId,
        ),
      );

  $$ExerciseMultipliersTableProcessedTableManager get exerciseMultipliersRefs {
    final manager = $$ExerciseMultipliersTableTableManager(
      $_db,
      $_db.exerciseMultipliers,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseMultipliersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
  _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSets,
    aliasName: $_aliasNameGenerator(db.exercises.id, db.workoutSets.exerciseId),
  );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExerciseType, ExerciseType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultRestTimeSeconds => $composableBuilder(
    column: $table.defaultRestTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavourite => $composableBuilder(
    column: $table.isFavourite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> exerciseMultipliersRefs(
    Expression<bool> Function($$ExerciseMultipliersTableFilterComposer f) f,
  ) {
    final $$ExerciseMultipliersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseMultipliers,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseMultipliersTableFilterComposer(
            $db: $db,
            $table: $db.exerciseMultipliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutSetsRefs(
    Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultRestTimeSeconds => $composableBuilder(
    column: $table.defaultRestTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavourite => $composableBuilder(
    column: $table.isFavourite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExerciseType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get defaultRestTimeSeconds => $composableBuilder(
    column: $table.defaultRestTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavourite => $composableBuilder(
    column: $table.isFavourite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> exerciseMultipliersRefs<T extends Object>(
    Expression<T> Function($$ExerciseMultipliersTableAnnotationComposer a) f,
  ) {
    final $$ExerciseMultipliersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseMultipliers,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseMultipliersTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseMultipliers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> workoutSetsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({
            bool categoryId,
            bool exerciseMultipliersRefs,
            bool workoutSetsRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<ExerciseType> type = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> defaultRestTimeSeconds = const Value.absent(),
                Value<bool> isFavourite = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                type: type,
                notes: notes,
                defaultRestTimeSeconds: defaultRestTimeSeconds,
                isFavourite: isFavourite,
                archived: archived,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int categoryId,
                Value<ExerciseType> type = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> defaultRestTimeSeconds = const Value.absent(),
                Value<bool> isFavourite = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                type: type,
                notes: notes,
                defaultRestTimeSeconds: defaultRestTimeSeconds,
                isFavourite: isFavourite,
                archived: archived,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                exerciseMultipliersRefs = false,
                workoutSetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseMultipliersRefs) db.exerciseMultipliers,
                    if (workoutSetsRefs) db.workoutSets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$ExercisesTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$ExercisesTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseMultipliersRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          ExerciseMultiplier
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._exerciseMultipliersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseMultipliersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutSetsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          WorkoutSet
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._workoutSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({
        bool categoryId,
        bool exerciseMultipliersRefs,
        bool workoutSetsRefs,
      })
    >;
typedef $$ExerciseMultipliersTableCreateCompanionBuilder =
    ExerciseMultipliersCompanion Function({
      Value<int> id,
      required int exerciseId,
      required String label,
      Value<double> factor,
      Value<bool> enabled,
      Value<int> sortOrder,
    });
typedef $$ExerciseMultipliersTableUpdateCompanionBuilder =
    ExerciseMultipliersCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<String> label,
      Value<double> factor,
      Value<bool> enabled,
      Value<int> sortOrder,
    });

final class $$ExerciseMultipliersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseMultipliersTable,
          ExerciseMultiplier
        > {
  $$ExerciseMultipliersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(
          db.exerciseMultipliers.exerciseId,
          db.exercises.id,
        ),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseMultipliersTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseMultipliersTable> {
  $$ExerciseMultipliersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get factor => $composableBuilder(
    column: $table.factor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseMultipliersTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseMultipliersTable> {
  $$ExerciseMultipliersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get factor => $composableBuilder(
    column: $table.factor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseMultipliersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseMultipliersTable> {
  $$ExerciseMultipliersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get factor =>
      $composableBuilder(column: $table.factor, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseMultipliersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseMultipliersTable,
          ExerciseMultiplier,
          $$ExerciseMultipliersTableFilterComposer,
          $$ExerciseMultipliersTableOrderingComposer,
          $$ExerciseMultipliersTableAnnotationComposer,
          $$ExerciseMultipliersTableCreateCompanionBuilder,
          $$ExerciseMultipliersTableUpdateCompanionBuilder,
          (ExerciseMultiplier, $$ExerciseMultipliersTableReferences),
          ExerciseMultiplier,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$ExerciseMultipliersTableTableManager(
    _$AppDatabase db,
    $ExerciseMultipliersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseMultipliersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseMultipliersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseMultipliersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> factor = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ExerciseMultipliersCompanion(
                id: id,
                exerciseId: exerciseId,
                label: label,
                factor: factor,
                enabled: enabled,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                required String label,
                Value<double> factor = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ExerciseMultipliersCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                label: label,
                factor: factor,
                enabled: enabled,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseMultipliersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$ExerciseMultipliersTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$ExerciseMultipliersTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseMultipliersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseMultipliersTable,
      ExerciseMultiplier,
      $$ExerciseMultipliersTableFilterComposer,
      $$ExerciseMultipliersTableOrderingComposer,
      $$ExerciseMultipliersTableAnnotationComposer,
      $$ExerciseMultipliersTableCreateCompanionBuilder,
      $$ExerciseMultipliersTableUpdateCompanionBuilder,
      (ExerciseMultiplier, $$ExerciseMultipliersTableReferences),
      ExerciseMultiplier,
      PrefetchHooks Function({bool exerciseId})
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<int> id,
      required int exerciseId,
      required String date,
      Value<double> rawWeight,
      Value<double> weightMultiplier,
      Value<int> reps,
      Value<double> distance,
      Value<int> durationSeconds,
      Value<bool> isComplete,
      Value<String?> note,
      required DateTime createdAt,
    });
typedef $$WorkoutSetsTableUpdateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<String> date,
      Value<double> rawWeight,
      Value<double> weightMultiplier,
      Value<int> reps,
      Value<double> distance,
      Value<int> durationSeconds,
      Value<bool> isComplete,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.workoutSets.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rawWeight => $composableBuilder(
    column: $table.rawWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightMultiplier => $composableBuilder(
    column: $table.weightMultiplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rawWeight => $composableBuilder(
    column: $table.rawWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightMultiplier => $composableBuilder(
    column: $table.weightMultiplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get rawWeight =>
      $composableBuilder(column: $table.rawWeight, builder: (column) => column);

  GeneratedColumn<double> get weightMultiplier => $composableBuilder(
    column: $table.weightMultiplier,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetsTable,
          WorkoutSet,
          $$WorkoutSetsTableFilterComposer,
          $$WorkoutSetsTableOrderingComposer,
          $$WorkoutSetsTableAnnotationComposer,
          $$WorkoutSetsTableCreateCompanionBuilder,
          $$WorkoutSetsTableUpdateCompanionBuilder,
          (WorkoutSet, $$WorkoutSetsTableReferences),
          WorkoutSet,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> rawWeight = const Value.absent(),
                Value<double> weightMultiplier = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WorkoutSetsCompanion(
                id: id,
                exerciseId: exerciseId,
                date: date,
                rawWeight: rawWeight,
                weightMultiplier: weightMultiplier,
                reps: reps,
                distance: distance,
                durationSeconds: durationSeconds,
                isComplete: isComplete,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                required String date,
                Value<double> rawWeight = const Value.absent(),
                Value<double> weightMultiplier = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double> distance = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
              }) => WorkoutSetsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                date: date,
                rawWeight: rawWeight,
                weightMultiplier: weightMultiplier,
                reps: reps,
                distance: distance,
                durationSeconds: durationSeconds,
                isComplete: isComplete,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$WorkoutSetsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$WorkoutSetsTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetsTable,
      WorkoutSet,
      $$WorkoutSetsTableFilterComposer,
      $$WorkoutSetsTableOrderingComposer,
      $$WorkoutSetsTableAnnotationComposer,
      $$WorkoutSetsTableCreateCompanionBuilder,
      $$WorkoutSetsTableUpdateCompanionBuilder,
      (WorkoutSet, $$WorkoutSetsTableReferences),
      WorkoutSet,
      PrefetchHooks Function({bool exerciseId})
    >;
typedef $$WorkoutDayNotesTableCreateCompanionBuilder =
    WorkoutDayNotesCompanion Function({
      Value<int> id,
      required String date,
      required String comment,
    });
typedef $$WorkoutDayNotesTableUpdateCompanionBuilder =
    WorkoutDayNotesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> comment,
    });

class $$WorkoutDayNotesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutDayNotesTable> {
  $$WorkoutDayNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutDayNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutDayNotesTable> {
  $$WorkoutDayNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutDayNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutDayNotesTable> {
  $$WorkoutDayNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);
}

class $$WorkoutDayNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutDayNotesTable,
          WorkoutDayNote,
          $$WorkoutDayNotesTableFilterComposer,
          $$WorkoutDayNotesTableOrderingComposer,
          $$WorkoutDayNotesTableAnnotationComposer,
          $$WorkoutDayNotesTableCreateCompanionBuilder,
          $$WorkoutDayNotesTableUpdateCompanionBuilder,
          (
            WorkoutDayNote,
            BaseReferences<
              _$AppDatabase,
              $WorkoutDayNotesTable,
              WorkoutDayNote
            >,
          ),
          WorkoutDayNote,
          PrefetchHooks Function()
        > {
  $$WorkoutDayNotesTableTableManager(
    _$AppDatabase db,
    $WorkoutDayNotesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDayNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDayNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDayNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> comment = const Value.absent(),
              }) => WorkoutDayNotesCompanion(
                id: id,
                date: date,
                comment: comment,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String comment,
              }) => WorkoutDayNotesCompanion.insert(
                id: id,
                date: date,
                comment: comment,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutDayNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutDayNotesTable,
      WorkoutDayNote,
      $$WorkoutDayNotesTableFilterComposer,
      $$WorkoutDayNotesTableOrderingComposer,
      $$WorkoutDayNotesTableAnnotationComposer,
      $$WorkoutDayNotesTableCreateCompanionBuilder,
      $$WorkoutDayNotesTableUpdateCompanionBuilder,
      (
        WorkoutDayNote,
        BaseReferences<_$AppDatabase, $WorkoutDayNotesTable, WorkoutDayNote>,
      ),
      WorkoutDayNote,
      PrefetchHooks Function()
    >;
typedef $$PrResetMarkersTableCreateCompanionBuilder =
    PrResetMarkersCompanion Function({
      Value<int> id,
      required String date,
      Value<String?> note,
      required DateTime createdAt,
    });
typedef $$PrResetMarkersTableUpdateCompanionBuilder =
    PrResetMarkersCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

class $$PrResetMarkersTableFilterComposer
    extends Composer<_$AppDatabase, $PrResetMarkersTable> {
  $$PrResetMarkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrResetMarkersTableOrderingComposer
    extends Composer<_$AppDatabase, $PrResetMarkersTable> {
  $$PrResetMarkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrResetMarkersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrResetMarkersTable> {
  $$PrResetMarkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PrResetMarkersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrResetMarkersTable,
          PrResetMarker,
          $$PrResetMarkersTableFilterComposer,
          $$PrResetMarkersTableOrderingComposer,
          $$PrResetMarkersTableAnnotationComposer,
          $$PrResetMarkersTableCreateCompanionBuilder,
          $$PrResetMarkersTableUpdateCompanionBuilder,
          (
            PrResetMarker,
            BaseReferences<_$AppDatabase, $PrResetMarkersTable, PrResetMarker>,
          ),
          PrResetMarker,
          PrefetchHooks Function()
        > {
  $$PrResetMarkersTableTableManager(
    _$AppDatabase db,
    $PrResetMarkersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrResetMarkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrResetMarkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrResetMarkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PrResetMarkersCompanion(
                id: id,
                date: date,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
              }) => PrResetMarkersCompanion.insert(
                id: id,
                date: date,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrResetMarkersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrResetMarkersTable,
      PrResetMarker,
      $$PrResetMarkersTableFilterComposer,
      $$PrResetMarkersTableOrderingComposer,
      $$PrResetMarkersTableAnnotationComposer,
      $$PrResetMarkersTableCreateCompanionBuilder,
      $$PrResetMarkersTableUpdateCompanionBuilder,
      (
        PrResetMarker,
        BaseReferences<_$AppDatabase, $PrResetMarkersTable, PrResetMarker>,
      ),
      PrResetMarker,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<int> themeMode,
      Value<int> firstDayOfWeek,
      Value<double> defaultWeightIncrement,
      Value<int> restTimerSeconds,
      Value<bool> restTimerVibrate,
      Value<bool> restTimerSound,
      Value<bool> restTimerAutoStart,
      Value<bool> trackPersonalRecords,
      Value<bool> markSetsComplete,
      Value<bool> keepScreenOn,
      Value<int> estimated1rmMaxReps,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<int> themeMode,
      Value<int> firstDayOfWeek,
      Value<double> defaultWeightIncrement,
      Value<int> restTimerSeconds,
      Value<bool> restTimerVibrate,
      Value<bool> restTimerSound,
      Value<bool> restTimerAutoStart,
      Value<bool> trackPersonalRecords,
      Value<bool> markSetsComplete,
      Value<bool> keepScreenOn,
      Value<int> estimated1rmMaxReps,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstDayOfWeek => $composableBuilder(
    column: $table.firstDayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultWeightIncrement => $composableBuilder(
    column: $table.defaultWeightIncrement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restTimerSeconds => $composableBuilder(
    column: $table.restTimerSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restTimerVibrate => $composableBuilder(
    column: $table.restTimerVibrate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restTimerSound => $composableBuilder(
    column: $table.restTimerSound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restTimerAutoStart => $composableBuilder(
    column: $table.restTimerAutoStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackPersonalRecords => $composableBuilder(
    column: $table.trackPersonalRecords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get markSetsComplete => $composableBuilder(
    column: $table.markSetsComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get keepScreenOn => $composableBuilder(
    column: $table.keepScreenOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimated1rmMaxReps => $composableBuilder(
    column: $table.estimated1rmMaxReps,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstDayOfWeek => $composableBuilder(
    column: $table.firstDayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultWeightIncrement => $composableBuilder(
    column: $table.defaultWeightIncrement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restTimerSeconds => $composableBuilder(
    column: $table.restTimerSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restTimerVibrate => $composableBuilder(
    column: $table.restTimerVibrate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restTimerSound => $composableBuilder(
    column: $table.restTimerSound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restTimerAutoStart => $composableBuilder(
    column: $table.restTimerAutoStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackPersonalRecords => $composableBuilder(
    column: $table.trackPersonalRecords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get markSetsComplete => $composableBuilder(
    column: $table.markSetsComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get keepScreenOn => $composableBuilder(
    column: $table.keepScreenOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimated1rmMaxReps => $composableBuilder(
    column: $table.estimated1rmMaxReps,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<int> get firstDayOfWeek => $composableBuilder(
    column: $table.firstDayOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultWeightIncrement => $composableBuilder(
    column: $table.defaultWeightIncrement,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restTimerSeconds => $composableBuilder(
    column: $table.restTimerSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restTimerVibrate => $composableBuilder(
    column: $table.restTimerVibrate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restTimerSound => $composableBuilder(
    column: $table.restTimerSound,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restTimerAutoStart => $composableBuilder(
    column: $table.restTimerAutoStart,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trackPersonalRecords => $composableBuilder(
    column: $table.trackPersonalRecords,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get markSetsComplete => $composableBuilder(
    column: $table.markSetsComplete,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get keepScreenOn => $composableBuilder(
    column: $table.keepScreenOn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimated1rmMaxReps => $composableBuilder(
    column: $table.estimated1rmMaxReps,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> themeMode = const Value.absent(),
                Value<int> firstDayOfWeek = const Value.absent(),
                Value<double> defaultWeightIncrement = const Value.absent(),
                Value<int> restTimerSeconds = const Value.absent(),
                Value<bool> restTimerVibrate = const Value.absent(),
                Value<bool> restTimerSound = const Value.absent(),
                Value<bool> restTimerAutoStart = const Value.absent(),
                Value<bool> trackPersonalRecords = const Value.absent(),
                Value<bool> markSetsComplete = const Value.absent(),
                Value<bool> keepScreenOn = const Value.absent(),
                Value<int> estimated1rmMaxReps = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                themeMode: themeMode,
                firstDayOfWeek: firstDayOfWeek,
                defaultWeightIncrement: defaultWeightIncrement,
                restTimerSeconds: restTimerSeconds,
                restTimerVibrate: restTimerVibrate,
                restTimerSound: restTimerSound,
                restTimerAutoStart: restTimerAutoStart,
                trackPersonalRecords: trackPersonalRecords,
                markSetsComplete: markSetsComplete,
                keepScreenOn: keepScreenOn,
                estimated1rmMaxReps: estimated1rmMaxReps,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> themeMode = const Value.absent(),
                Value<int> firstDayOfWeek = const Value.absent(),
                Value<double> defaultWeightIncrement = const Value.absent(),
                Value<int> restTimerSeconds = const Value.absent(),
                Value<bool> restTimerVibrate = const Value.absent(),
                Value<bool> restTimerSound = const Value.absent(),
                Value<bool> restTimerAutoStart = const Value.absent(),
                Value<bool> trackPersonalRecords = const Value.absent(),
                Value<bool> markSetsComplete = const Value.absent(),
                Value<bool> keepScreenOn = const Value.absent(),
                Value<int> estimated1rmMaxReps = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                themeMode: themeMode,
                firstDayOfWeek: firstDayOfWeek,
                defaultWeightIncrement: defaultWeightIncrement,
                restTimerSeconds: restTimerSeconds,
                restTimerVibrate: restTimerVibrate,
                restTimerSound: restTimerSound,
                restTimerAutoStart: restTimerAutoStart,
                trackPersonalRecords: trackPersonalRecords,
                markSetsComplete: markSetsComplete,
                keepScreenOn: keepScreenOn,
                estimated1rmMaxReps: estimated1rmMaxReps,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$ExerciseMultipliersTableTableManager get exerciseMultipliers =>
      $$ExerciseMultipliersTableTableManager(_db, _db.exerciseMultipliers);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$WorkoutDayNotesTableTableManager get workoutDayNotes =>
      $$WorkoutDayNotesTableTableManager(_db, _db.workoutDayNotes);
  $$PrResetMarkersTableTableManager get prResetMarkers =>
      $$PrResetMarkersTableTableManager(_db, _db.prResetMarkers);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
