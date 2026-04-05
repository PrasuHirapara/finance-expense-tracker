// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DbCategoriesTable extends DbCategories
    with TableInfo<$DbCategoriesTable, DbCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbCategoriesTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconCodePoint,
    colorValue,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCategory> instance, {
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
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DbCategoriesTable createAlias(String alias) {
    return $DbCategoriesTable(attachedDatabase, alias);
  }
}

class DbCategory extends DataClass implements Insertable<DbCategory> {
  final int id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final DateTime createdAt;
  const DbCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['color_value'] = Variable<int>(colorValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbCategoriesCompanion toCompanion(bool nullToAbsent) {
    return DbCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconCodePoint: Value(iconCodePoint),
      colorValue: Value(colorValue),
      createdAt: Value(createdAt),
    );
  }

  factory DbCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'colorValue': serializer.toJson<int>(colorValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbCategory copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    DateTime? createdAt,
  }) => DbCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    colorValue: colorValue ?? this.colorValue,
    createdAt: createdAt ?? this.createdAt,
  );
  DbCategory copyWithCompanion(DbCategoriesCompanion data) {
    return DbCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorValue: $colorValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, iconCodePoint, colorValue, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconCodePoint == this.iconCodePoint &&
          other.colorValue == this.colorValue &&
          other.createdAt == this.createdAt);
}

class DbCategoriesCompanion extends UpdateCompanion<DbCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> iconCodePoint;
  final Value<int> colorValue;
  final Value<DateTime> createdAt;
  const DbCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int iconCodePoint,
    required int colorValue,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       iconCodePoint = Value(iconCodePoint),
       colorValue = Value(colorValue);
  static Insertable<DbCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? iconCodePoint,
    Expression<int>? colorValue,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (colorValue != null) 'color_value': colorValue,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? iconCodePoint,
    Value<int>? colorValue,
    Value<DateTime>? createdAt,
  }) {
    return DbCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
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
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorValue: $colorValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DbBanksTable extends DbBanks with TableInfo<$DbBanksTable, DbBank> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbBanksTable(this.attachedDatabase, [this._alias]);
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
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_banks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbBank> instance, {
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbBank map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbBank(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DbBanksTable createAlias(String alias) {
    return $DbBanksTable(attachedDatabase, alias);
  }
}

class DbBank extends DataClass implements Insertable<DbBank> {
  final int id;
  final String name;
  final DateTime createdAt;
  const DbBank({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbBanksCompanion toCompanion(bool nullToAbsent) {
    return DbBanksCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory DbBank.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbBank(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbBank copyWith({int? id, String? name, DateTime? createdAt}) => DbBank(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  DbBank copyWithCompanion(DbBanksCompanion data) {
    return DbBank(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbBank(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbBank &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class DbBanksCompanion extends UpdateCompanion<DbBank> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const DbBanksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbBanksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DbBank> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbBanksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return DbBanksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbBanksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DbFinanceEntriesTable extends DbFinanceEntries
    with TableInfo<$DbFinanceEntriesTable, DbFinanceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbFinanceEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
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
      'REFERENCES db_categories (id)',
    ),
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<int> bankId = GeneratedColumn<int>(
    'bank_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_banks (id)',
    ),
  );
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentModeMeta = const VerificationMeta(
    'paymentMode',
  );
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
    'payment_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    amount,
    type,
    categoryId,
    bankId,
    entryDate,
    paymentMode,
    notes,
    counterparty,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_finance_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbFinanceEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
        _paymentModeMeta,
        paymentMode.isAcceptableOrUnknown(
          data['payment_mode']!,
          _paymentModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentModeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbFinanceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbFinanceEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bank_id'],
      ),
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entry_date'],
      )!,
      paymentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_mode'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DbFinanceEntriesTable createAlias(String alias) {
    return $DbFinanceEntriesTable(attachedDatabase, alias);
  }
}

class DbFinanceEntry extends DataClass implements Insertable<DbFinanceEntry> {
  final int id;
  final String title;
  final double amount;
  final String type;
  final int categoryId;
  final int? bankId;
  final DateTime entryDate;
  final String paymentMode;
  final String notes;
  final String? counterparty;
  final DateTime createdAt;
  const DbFinanceEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.bankId,
    required this.entryDate,
    required this.paymentMode,
    required this.notes,
    this.counterparty,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || bankId != null) {
      map['bank_id'] = Variable<int>(bankId);
    }
    map['entry_date'] = Variable<DateTime>(entryDate);
    map['payment_mode'] = Variable<String>(paymentMode);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbFinanceEntriesCompanion toCompanion(bool nullToAbsent) {
    return DbFinanceEntriesCompanion(
      id: Value(id),
      title: Value(title),
      amount: Value(amount),
      type: Value(type),
      categoryId: Value(categoryId),
      bankId: bankId == null && nullToAbsent
          ? const Value.absent()
          : Value(bankId),
      entryDate: Value(entryDate),
      paymentMode: Value(paymentMode),
      notes: Value(notes),
      counterparty: counterparty == null && nullToAbsent
          ? const Value.absent()
          : Value(counterparty),
      createdAt: Value(createdAt),
    );
  }

  factory DbFinanceEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbFinanceEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      bankId: serializer.fromJson<int?>(json['bankId']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      notes: serializer.fromJson<String>(json['notes']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'categoryId': serializer.toJson<int>(categoryId),
      'bankId': serializer.toJson<int?>(bankId),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'notes': serializer.toJson<String>(notes),
      'counterparty': serializer.toJson<String?>(counterparty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbFinanceEntry copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    Value<int?> bankId = const Value.absent(),
    DateTime? entryDate,
    String? paymentMode,
    String? notes,
    Value<String?> counterparty = const Value.absent(),
    DateTime? createdAt,
  }) => DbFinanceEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId,
    bankId: bankId.present ? bankId.value : this.bankId,
    entryDate: entryDate ?? this.entryDate,
    paymentMode: paymentMode ?? this.paymentMode,
    notes: notes ?? this.notes,
    counterparty: counterparty.present ? counterparty.value : this.counterparty,
    createdAt: createdAt ?? this.createdAt,
  );
  DbFinanceEntry copyWithCompanion(DbFinanceEntriesCompanion data) {
    return DbFinanceEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      paymentMode: data.paymentMode.present
          ? data.paymentMode.value
          : this.paymentMode,
      notes: data.notes.present ? data.notes.value : this.notes,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbFinanceEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('bankId: $bankId, ')
          ..write('entryDate: $entryDate, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('notes: $notes, ')
          ..write('counterparty: $counterparty, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amount,
    type,
    categoryId,
    bankId,
    entryDate,
    paymentMode,
    notes,
    counterparty,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbFinanceEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.categoryId == this.categoryId &&
          other.bankId == this.bankId &&
          other.entryDate == this.entryDate &&
          other.paymentMode == this.paymentMode &&
          other.notes == this.notes &&
          other.counterparty == this.counterparty &&
          other.createdAt == this.createdAt);
}

class DbFinanceEntriesCompanion extends UpdateCompanion<DbFinanceEntry> {
  final Value<int> id;
  final Value<String> title;
  final Value<double> amount;
  final Value<String> type;
  final Value<int> categoryId;
  final Value<int?> bankId;
  final Value<DateTime> entryDate;
  final Value<String> paymentMode;
  final Value<String> notes;
  final Value<String?> counterparty;
  final Value<DateTime> createdAt;
  const DbFinanceEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.bankId = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.notes = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbFinanceEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required double amount,
    required String type,
    required int categoryId,
    this.bankId = const Value.absent(),
    required DateTime entryDate,
    required String paymentMode,
    this.notes = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       amount = Value(amount),
       type = Value(type),
       categoryId = Value(categoryId),
       entryDate = Value(entryDate),
       paymentMode = Value(paymentMode);
  static Insertable<DbFinanceEntry> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<int>? categoryId,
    Expression<int>? bankId,
    Expression<DateTime>? entryDate,
    Expression<String>? paymentMode,
    Expression<String>? notes,
    Expression<String>? counterparty,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (categoryId != null) 'category_id': categoryId,
      if (bankId != null) 'bank_id': bankId,
      if (entryDate != null) 'entry_date': entryDate,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (notes != null) 'notes': notes,
      if (counterparty != null) 'counterparty': counterparty,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbFinanceEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<double>? amount,
    Value<String>? type,
    Value<int>? categoryId,
    Value<int?>? bankId,
    Value<DateTime>? entryDate,
    Value<String>? paymentMode,
    Value<String>? notes,
    Value<String?>? counterparty,
    Value<DateTime>? createdAt,
  }) {
    return DbFinanceEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      bankId: bankId ?? this.bankId,
      entryDate: entryDate ?? this.entryDate,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      counterparty: counterparty ?? this.counterparty,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<int>(bankId.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbFinanceEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('bankId: $bankId, ')
          ..write('entryDate: $entryDate, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('notes: $notes, ')
          ..write('counterparty: $counterparty, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DbSplitRecordsTable extends DbSplitRecords
    with TableInfo<$DbSplitRecordsTable, DbSplitRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbSplitRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _expenseEntryIdMeta = const VerificationMeta(
    'expenseEntryId',
  );
  @override
  late final GeneratedColumn<int> expenseEntryId = GeneratedColumn<int>(
    'expense_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_finance_entries (id)',
    ),
  );
  static const VerificationMeta _lentEntryIdMeta = const VerificationMeta(
    'lentEntryId',
  );
  @override
  late final GeneratedColumn<int> lentEntryId = GeneratedColumn<int>(
    'lent_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_finance_entries (id)',
    ),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseEntryId,
    lentEntryId,
    totalAmount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_split_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbSplitRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('expense_entry_id')) {
      context.handle(
        _expenseEntryIdMeta,
        expenseEntryId.isAcceptableOrUnknown(
          data['expense_entry_id']!,
          _expenseEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('lent_entry_id')) {
      context.handle(
        _lentEntryIdMeta,
        lentEntryId.isAcceptableOrUnknown(
          data['lent_entry_id']!,
          _lentEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbSplitRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbSplitRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      expenseEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expense_entry_id'],
      ),
      lentEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lent_entry_id'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DbSplitRecordsTable createAlias(String alias) {
    return $DbSplitRecordsTable(attachedDatabase, alias);
  }
}

class DbSplitRecord extends DataClass implements Insertable<DbSplitRecord> {
  final int id;
  final int? expenseEntryId;
  final int? lentEntryId;
  final double totalAmount;
  final DateTime createdAt;
  const DbSplitRecord({
    required this.id,
    this.expenseEntryId,
    this.lentEntryId,
    required this.totalAmount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || expenseEntryId != null) {
      map['expense_entry_id'] = Variable<int>(expenseEntryId);
    }
    if (!nullToAbsent || lentEntryId != null) {
      map['lent_entry_id'] = Variable<int>(lentEntryId);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbSplitRecordsCompanion toCompanion(bool nullToAbsent) {
    return DbSplitRecordsCompanion(
      id: Value(id),
      expenseEntryId: expenseEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseEntryId),
      lentEntryId: lentEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(lentEntryId),
      totalAmount: Value(totalAmount),
      createdAt: Value(createdAt),
    );
  }

  factory DbSplitRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbSplitRecord(
      id: serializer.fromJson<int>(json['id']),
      expenseEntryId: serializer.fromJson<int?>(json['expenseEntryId']),
      lentEntryId: serializer.fromJson<int?>(json['lentEntryId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'expenseEntryId': serializer.toJson<int?>(expenseEntryId),
      'lentEntryId': serializer.toJson<int?>(lentEntryId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbSplitRecord copyWith({
    int? id,
    Value<int?> expenseEntryId = const Value.absent(),
    Value<int?> lentEntryId = const Value.absent(),
    double? totalAmount,
    DateTime? createdAt,
  }) => DbSplitRecord(
    id: id ?? this.id,
    expenseEntryId: expenseEntryId.present
        ? expenseEntryId.value
        : this.expenseEntryId,
    lentEntryId: lentEntryId.present ? lentEntryId.value : this.lentEntryId,
    totalAmount: totalAmount ?? this.totalAmount,
    createdAt: createdAt ?? this.createdAt,
  );
  DbSplitRecord copyWithCompanion(DbSplitRecordsCompanion data) {
    return DbSplitRecord(
      id: data.id.present ? data.id.value : this.id,
      expenseEntryId: data.expenseEntryId.present
          ? data.expenseEntryId.value
          : this.expenseEntryId,
      lentEntryId: data.lentEntryId.present
          ? data.lentEntryId.value
          : this.lentEntryId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbSplitRecord(')
          ..write('id: $id, ')
          ..write('expenseEntryId: $expenseEntryId, ')
          ..write('lentEntryId: $lentEntryId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, expenseEntryId, lentEntryId, totalAmount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbSplitRecord &&
          other.id == this.id &&
          other.expenseEntryId == this.expenseEntryId &&
          other.lentEntryId == this.lentEntryId &&
          other.totalAmount == this.totalAmount &&
          other.createdAt == this.createdAt);
}

class DbSplitRecordsCompanion extends UpdateCompanion<DbSplitRecord> {
  final Value<int> id;
  final Value<int?> expenseEntryId;
  final Value<int?> lentEntryId;
  final Value<double> totalAmount;
  final Value<DateTime> createdAt;
  const DbSplitRecordsCompanion({
    this.id = const Value.absent(),
    this.expenseEntryId = const Value.absent(),
    this.lentEntryId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbSplitRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.expenseEntryId = const Value.absent(),
    this.lentEntryId = const Value.absent(),
    required double totalAmount,
    this.createdAt = const Value.absent(),
  }) : totalAmount = Value(totalAmount);
  static Insertable<DbSplitRecord> custom({
    Expression<int>? id,
    Expression<int>? expenseEntryId,
    Expression<int>? lentEntryId,
    Expression<double>? totalAmount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseEntryId != null) 'expense_entry_id': expenseEntryId,
      if (lentEntryId != null) 'lent_entry_id': lentEntryId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbSplitRecordsCompanion copyWith({
    Value<int>? id,
    Value<int?>? expenseEntryId,
    Value<int?>? lentEntryId,
    Value<double>? totalAmount,
    Value<DateTime>? createdAt,
  }) {
    return DbSplitRecordsCompanion(
      id: id ?? this.id,
      expenseEntryId: expenseEntryId ?? this.expenseEntryId,
      lentEntryId: lentEntryId ?? this.lentEntryId,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (expenseEntryId.present) {
      map['expense_entry_id'] = Variable<int>(expenseEntryId.value);
    }
    if (lentEntryId.present) {
      map['lent_entry_id'] = Variable<int>(lentEntryId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbSplitRecordsCompanion(')
          ..write('id: $id, ')
          ..write('expenseEntryId: $expenseEntryId, ')
          ..write('lentEntryId: $lentEntryId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DbSplitParticipantsTable extends DbSplitParticipants
    with TableInfo<$DbSplitParticipantsTable, DbSplitParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbSplitParticipantsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _splitRecordIdMeta = const VerificationMeta(
    'splitRecordId',
  );
  @override
  late final GeneratedColumn<int> splitRecordId = GeneratedColumn<int>(
    'split_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_split_records (id)',
    ),
  );
  static const VerificationMeta _participantNameMeta = const VerificationMeta(
    'participantName',
  );
  @override
  late final GeneratedColumn<String> participantName = GeneratedColumn<String>(
    'participant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentageMeta = const VerificationMeta(
    'percentage',
  );
  @override
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
    'percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSelfMeta = const VerificationMeta('isSelf');
  @override
  late final GeneratedColumn<bool> isSelf = GeneratedColumn<bool>(
    'is_self',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_self" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settledAmountMeta = const VerificationMeta(
    'settledAmount',
  );
  @override
  late final GeneratedColumn<double> settledAmount = GeneratedColumn<double>(
    'settled_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    splitRecordId,
    participantName,
    amount,
    percentage,
    isSelf,
    settledAmount,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_split_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbSplitParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('split_record_id')) {
      context.handle(
        _splitRecordIdMeta,
        splitRecordId.isAcceptableOrUnknown(
          data['split_record_id']!,
          _splitRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_splitRecordIdMeta);
    }
    if (data.containsKey('participant_name')) {
      context.handle(
        _participantNameMeta,
        participantName.isAcceptableOrUnknown(
          data['participant_name']!,
          _participantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantNameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
        _percentageMeta,
        percentage.isAcceptableOrUnknown(data['percentage']!, _percentageMeta),
      );
    } else if (isInserting) {
      context.missing(_percentageMeta);
    }
    if (data.containsKey('is_self')) {
      context.handle(
        _isSelfMeta,
        isSelf.isAcceptableOrUnknown(data['is_self']!, _isSelfMeta),
      );
    }
    if (data.containsKey('settled_amount')) {
      context.handle(
        _settledAmountMeta,
        settledAmount.isAcceptableOrUnknown(
          data['settled_amount']!,
          _settledAmountMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbSplitParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbSplitParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      splitRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_record_id'],
      )!,
      participantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      percentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentage'],
      )!,
      isSelf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_self'],
      )!,
      settledAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}settled_amount'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DbSplitParticipantsTable createAlias(String alias) {
    return $DbSplitParticipantsTable(attachedDatabase, alias);
  }
}

class DbSplitParticipant extends DataClass
    implements Insertable<DbSplitParticipant> {
  final int id;
  final int splitRecordId;
  final String participantName;
  final double amount;
  final double percentage;
  final bool isSelf;
  final double settledAmount;
  final int sortOrder;
  final DateTime createdAt;
  const DbSplitParticipant({
    required this.id,
    required this.splitRecordId,
    required this.participantName,
    required this.amount,
    required this.percentage,
    required this.isSelf,
    required this.settledAmount,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['split_record_id'] = Variable<int>(splitRecordId);
    map['participant_name'] = Variable<String>(participantName);
    map['amount'] = Variable<double>(amount);
    map['percentage'] = Variable<double>(percentage);
    map['is_self'] = Variable<bool>(isSelf);
    map['settled_amount'] = Variable<double>(settledAmount);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbSplitParticipantsCompanion toCompanion(bool nullToAbsent) {
    return DbSplitParticipantsCompanion(
      id: Value(id),
      splitRecordId: Value(splitRecordId),
      participantName: Value(participantName),
      amount: Value(amount),
      percentage: Value(percentage),
      isSelf: Value(isSelf),
      settledAmount: Value(settledAmount),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory DbSplitParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbSplitParticipant(
      id: serializer.fromJson<int>(json['id']),
      splitRecordId: serializer.fromJson<int>(json['splitRecordId']),
      participantName: serializer.fromJson<String>(json['participantName']),
      amount: serializer.fromJson<double>(json['amount']),
      percentage: serializer.fromJson<double>(json['percentage']),
      isSelf: serializer.fromJson<bool>(json['isSelf']),
      settledAmount: serializer.fromJson<double>(json['settledAmount']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'splitRecordId': serializer.toJson<int>(splitRecordId),
      'participantName': serializer.toJson<String>(participantName),
      'amount': serializer.toJson<double>(amount),
      'percentage': serializer.toJson<double>(percentage),
      'isSelf': serializer.toJson<bool>(isSelf),
      'settledAmount': serializer.toJson<double>(settledAmount),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbSplitParticipant copyWith({
    int? id,
    int? splitRecordId,
    String? participantName,
    double? amount,
    double? percentage,
    bool? isSelf,
    double? settledAmount,
    int? sortOrder,
    DateTime? createdAt,
  }) => DbSplitParticipant(
    id: id ?? this.id,
    splitRecordId: splitRecordId ?? this.splitRecordId,
    participantName: participantName ?? this.participantName,
    amount: amount ?? this.amount,
    percentage: percentage ?? this.percentage,
    isSelf: isSelf ?? this.isSelf,
    settledAmount: settledAmount ?? this.settledAmount,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  DbSplitParticipant copyWithCompanion(DbSplitParticipantsCompanion data) {
    return DbSplitParticipant(
      id: data.id.present ? data.id.value : this.id,
      splitRecordId: data.splitRecordId.present
          ? data.splitRecordId.value
          : this.splitRecordId,
      participantName: data.participantName.present
          ? data.participantName.value
          : this.participantName,
      amount: data.amount.present ? data.amount.value : this.amount,
      percentage: data.percentage.present
          ? data.percentage.value
          : this.percentage,
      isSelf: data.isSelf.present ? data.isSelf.value : this.isSelf,
      settledAmount: data.settledAmount.present
          ? data.settledAmount.value
          : this.settledAmount,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbSplitParticipant(')
          ..write('id: $id, ')
          ..write('splitRecordId: $splitRecordId, ')
          ..write('participantName: $participantName, ')
          ..write('amount: $amount, ')
          ..write('percentage: $percentage, ')
          ..write('isSelf: $isSelf, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    splitRecordId,
    participantName,
    amount,
    percentage,
    isSelf,
    settledAmount,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbSplitParticipant &&
          other.id == this.id &&
          other.splitRecordId == this.splitRecordId &&
          other.participantName == this.participantName &&
          other.amount == this.amount &&
          other.percentage == this.percentage &&
          other.isSelf == this.isSelf &&
          other.settledAmount == this.settledAmount &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class DbSplitParticipantsCompanion extends UpdateCompanion<DbSplitParticipant> {
  final Value<int> id;
  final Value<int> splitRecordId;
  final Value<String> participantName;
  final Value<double> amount;
  final Value<double> percentage;
  final Value<bool> isSelf;
  final Value<double> settledAmount;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const DbSplitParticipantsCompanion({
    this.id = const Value.absent(),
    this.splitRecordId = const Value.absent(),
    this.participantName = const Value.absent(),
    this.amount = const Value.absent(),
    this.percentage = const Value.absent(),
    this.isSelf = const Value.absent(),
    this.settledAmount = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbSplitParticipantsCompanion.insert({
    this.id = const Value.absent(),
    required int splitRecordId,
    required String participantName,
    required double amount,
    required double percentage,
    this.isSelf = const Value.absent(),
    this.settledAmount = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : splitRecordId = Value(splitRecordId),
       participantName = Value(participantName),
       amount = Value(amount),
       percentage = Value(percentage);
  static Insertable<DbSplitParticipant> custom({
    Expression<int>? id,
    Expression<int>? splitRecordId,
    Expression<String>? participantName,
    Expression<double>? amount,
    Expression<double>? percentage,
    Expression<bool>? isSelf,
    Expression<double>? settledAmount,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitRecordId != null) 'split_record_id': splitRecordId,
      if (participantName != null) 'participant_name': participantName,
      if (amount != null) 'amount': amount,
      if (percentage != null) 'percentage': percentage,
      if (isSelf != null) 'is_self': isSelf,
      if (settledAmount != null) 'settled_amount': settledAmount,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbSplitParticipantsCompanion copyWith({
    Value<int>? id,
    Value<int>? splitRecordId,
    Value<String>? participantName,
    Value<double>? amount,
    Value<double>? percentage,
    Value<bool>? isSelf,
    Value<double>? settledAmount,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return DbSplitParticipantsCompanion(
      id: id ?? this.id,
      splitRecordId: splitRecordId ?? this.splitRecordId,
      participantName: participantName ?? this.participantName,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      isSelf: isSelf ?? this.isSelf,
      settledAmount: settledAmount ?? this.settledAmount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (splitRecordId.present) {
      map['split_record_id'] = Variable<int>(splitRecordId.value);
    }
    if (participantName.present) {
      map['participant_name'] = Variable<String>(participantName.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (isSelf.present) {
      map['is_self'] = Variable<bool>(isSelf.value);
    }
    if (settledAmount.present) {
      map['settled_amount'] = Variable<double>(settledAmount.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbSplitParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('splitRecordId: $splitRecordId, ')
          ..write('participantName: $participantName, ')
          ..write('amount: $amount, ')
          ..write('percentage: $percentage, ')
          ..write('isSelf: $isSelf, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DbLentSettlementsTable extends DbLentSettlements
    with TableInfo<$DbLentSettlementsTable, DbLentSettlement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbLentSettlementsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _splitRecordIdMeta = const VerificationMeta(
    'splitRecordId',
  );
  @override
  late final GeneratedColumn<int> splitRecordId = GeneratedColumn<int>(
    'split_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_split_records (id)',
    ),
  );
  static const VerificationMeta _splitParticipantIdMeta =
      const VerificationMeta('splitParticipantId');
  @override
  late final GeneratedColumn<int> splitParticipantId = GeneratedColumn<int>(
    'split_participant_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_split_participants (id)',
    ),
  );
  static const VerificationMeta _incomeEntryIdMeta = const VerificationMeta(
    'incomeEntryId',
  );
  @override
  late final GeneratedColumn<int> incomeEntryId = GeneratedColumn<int>(
    'income_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES db_finance_entries (id)',
    ),
  );
  static const VerificationMeta _settledAmountMeta = const VerificationMeta(
    'settledAmount',
  );
  @override
  late final GeneratedColumn<double> settledAmount = GeneratedColumn<double>(
    'settled_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    splitRecordId,
    splitParticipantId,
    incomeEntryId,
    settledAmount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_lent_settlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbLentSettlement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('split_record_id')) {
      context.handle(
        _splitRecordIdMeta,
        splitRecordId.isAcceptableOrUnknown(
          data['split_record_id']!,
          _splitRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_splitRecordIdMeta);
    }
    if (data.containsKey('split_participant_id')) {
      context.handle(
        _splitParticipantIdMeta,
        splitParticipantId.isAcceptableOrUnknown(
          data['split_participant_id']!,
          _splitParticipantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_splitParticipantIdMeta);
    }
    if (data.containsKey('income_entry_id')) {
      context.handle(
        _incomeEntryIdMeta,
        incomeEntryId.isAcceptableOrUnknown(
          data['income_entry_id']!,
          _incomeEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_incomeEntryIdMeta);
    }
    if (data.containsKey('settled_amount')) {
      context.handle(
        _settledAmountMeta,
        settledAmount.isAcceptableOrUnknown(
          data['settled_amount']!,
          _settledAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settledAmountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbLentSettlement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbLentSettlement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      splitRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_record_id'],
      )!,
      splitParticipantId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_participant_id'],
      )!,
      incomeEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}income_entry_id'],
      )!,
      settledAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}settled_amount'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DbLentSettlementsTable createAlias(String alias) {
    return $DbLentSettlementsTable(attachedDatabase, alias);
  }
}

class DbLentSettlement extends DataClass
    implements Insertable<DbLentSettlement> {
  final int id;
  final int splitRecordId;
  final int splitParticipantId;
  final int incomeEntryId;
  final double settledAmount;
  final DateTime createdAt;
  const DbLentSettlement({
    required this.id,
    required this.splitRecordId,
    required this.splitParticipantId,
    required this.incomeEntryId,
    required this.settledAmount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['split_record_id'] = Variable<int>(splitRecordId);
    map['split_participant_id'] = Variable<int>(splitParticipantId);
    map['income_entry_id'] = Variable<int>(incomeEntryId);
    map['settled_amount'] = Variable<double>(settledAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbLentSettlementsCompanion toCompanion(bool nullToAbsent) {
    return DbLentSettlementsCompanion(
      id: Value(id),
      splitRecordId: Value(splitRecordId),
      splitParticipantId: Value(splitParticipantId),
      incomeEntryId: Value(incomeEntryId),
      settledAmount: Value(settledAmount),
      createdAt: Value(createdAt),
    );
  }

  factory DbLentSettlement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbLentSettlement(
      id: serializer.fromJson<int>(json['id']),
      splitRecordId: serializer.fromJson<int>(json['splitRecordId']),
      splitParticipantId: serializer.fromJson<int>(json['splitParticipantId']),
      incomeEntryId: serializer.fromJson<int>(json['incomeEntryId']),
      settledAmount: serializer.fromJson<double>(json['settledAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'splitRecordId': serializer.toJson<int>(splitRecordId),
      'splitParticipantId': serializer.toJson<int>(splitParticipantId),
      'incomeEntryId': serializer.toJson<int>(incomeEntryId),
      'settledAmount': serializer.toJson<double>(settledAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbLentSettlement copyWith({
    int? id,
    int? splitRecordId,
    int? splitParticipantId,
    int? incomeEntryId,
    double? settledAmount,
    DateTime? createdAt,
  }) => DbLentSettlement(
    id: id ?? this.id,
    splitRecordId: splitRecordId ?? this.splitRecordId,
    splitParticipantId: splitParticipantId ?? this.splitParticipantId,
    incomeEntryId: incomeEntryId ?? this.incomeEntryId,
    settledAmount: settledAmount ?? this.settledAmount,
    createdAt: createdAt ?? this.createdAt,
  );
  DbLentSettlement copyWithCompanion(DbLentSettlementsCompanion data) {
    return DbLentSettlement(
      id: data.id.present ? data.id.value : this.id,
      splitRecordId: data.splitRecordId.present
          ? data.splitRecordId.value
          : this.splitRecordId,
      splitParticipantId: data.splitParticipantId.present
          ? data.splitParticipantId.value
          : this.splitParticipantId,
      incomeEntryId: data.incomeEntryId.present
          ? data.incomeEntryId.value
          : this.incomeEntryId,
      settledAmount: data.settledAmount.present
          ? data.settledAmount.value
          : this.settledAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbLentSettlement(')
          ..write('id: $id, ')
          ..write('splitRecordId: $splitRecordId, ')
          ..write('splitParticipantId: $splitParticipantId, ')
          ..write('incomeEntryId: $incomeEntryId, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    splitRecordId,
    splitParticipantId,
    incomeEntryId,
    settledAmount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbLentSettlement &&
          other.id == this.id &&
          other.splitRecordId == this.splitRecordId &&
          other.splitParticipantId == this.splitParticipantId &&
          other.incomeEntryId == this.incomeEntryId &&
          other.settledAmount == this.settledAmount &&
          other.createdAt == this.createdAt);
}

class DbLentSettlementsCompanion extends UpdateCompanion<DbLentSettlement> {
  final Value<int> id;
  final Value<int> splitRecordId;
  final Value<int> splitParticipantId;
  final Value<int> incomeEntryId;
  final Value<double> settledAmount;
  final Value<DateTime> createdAt;
  const DbLentSettlementsCompanion({
    this.id = const Value.absent(),
    this.splitRecordId = const Value.absent(),
    this.splitParticipantId = const Value.absent(),
    this.incomeEntryId = const Value.absent(),
    this.settledAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbLentSettlementsCompanion.insert({
    this.id = const Value.absent(),
    required int splitRecordId,
    required int splitParticipantId,
    required int incomeEntryId,
    required double settledAmount,
    this.createdAt = const Value.absent(),
  }) : splitRecordId = Value(splitRecordId),
       splitParticipantId = Value(splitParticipantId),
       incomeEntryId = Value(incomeEntryId),
       settledAmount = Value(settledAmount);
  static Insertable<DbLentSettlement> custom({
    Expression<int>? id,
    Expression<int>? splitRecordId,
    Expression<int>? splitParticipantId,
    Expression<int>? incomeEntryId,
    Expression<double>? settledAmount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitRecordId != null) 'split_record_id': splitRecordId,
      if (splitParticipantId != null)
        'split_participant_id': splitParticipantId,
      if (incomeEntryId != null) 'income_entry_id': incomeEntryId,
      if (settledAmount != null) 'settled_amount': settledAmount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbLentSettlementsCompanion copyWith({
    Value<int>? id,
    Value<int>? splitRecordId,
    Value<int>? splitParticipantId,
    Value<int>? incomeEntryId,
    Value<double>? settledAmount,
    Value<DateTime>? createdAt,
  }) {
    return DbLentSettlementsCompanion(
      id: id ?? this.id,
      splitRecordId: splitRecordId ?? this.splitRecordId,
      splitParticipantId: splitParticipantId ?? this.splitParticipantId,
      incomeEntryId: incomeEntryId ?? this.incomeEntryId,
      settledAmount: settledAmount ?? this.settledAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (splitRecordId.present) {
      map['split_record_id'] = Variable<int>(splitRecordId.value);
    }
    if (splitParticipantId.present) {
      map['split_participant_id'] = Variable<int>(splitParticipantId.value);
    }
    if (incomeEntryId.present) {
      map['income_entry_id'] = Variable<int>(incomeEntryId.value);
    }
    if (settledAmount.present) {
      map['settled_amount'] = Variable<double>(settledAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbLentSettlementsCompanion(')
          ..write('id: $id, ')
          ..write('splitRecordId: $splitRecordId, ')
          ..write('splitParticipantId: $splitParticipantId, ')
          ..write('incomeEntryId: $incomeEntryId, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DbTasksTable extends DbTasks with TableInfo<$DbTasksTable, DbTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbTasksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceTaskIdMeta = const VerificationMeta(
    'sourceTaskId',
  );
  @override
  late final GeneratedColumn<int> sourceTaskId = GeneratedColumn<int>(
    'source_task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskDateMeta = const VerificationMeta(
    'taskDate',
  );
  @override
  late final GeneratedColumn<DateTime> taskDate = GeneratedColumn<DateTime>(
    'task_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _isDailyMeta = const VerificationMeta(
    'isDaily',
  );
  @override
  late final GeneratedColumn<bool> isDaily = GeneratedColumn<bool>(
    'is_daily',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_daily" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceTaskId,
    title,
    description,
    category,
    taskDate,
    priority,
    isDaily,
    isCompleted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_task_id')) {
      context.handle(
        _sourceTaskIdMeta,
        sourceTaskId.isAcceptableOrUnknown(
          data['source_task_id']!,
          _sourceTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('task_date')) {
      context.handle(
        _taskDateMeta,
        taskDate.isAcceptableOrUnknown(data['task_date']!, _taskDateMeta),
      );
    } else if (isInserting) {
      context.missing(_taskDateMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_daily')) {
      context.handle(
        _isDailyMeta,
        isDaily.isAcceptableOrUnknown(data['is_daily']!, _isDailyMeta),
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_task_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      taskDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}task_date'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      isDaily: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_daily'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DbTasksTable createAlias(String alias) {
    return $DbTasksTable(attachedDatabase, alias);
  }
}

class DbTask extends DataClass implements Insertable<DbTask> {
  final int id;
  final int? sourceTaskId;
  final String title;
  final String description;
  final String category;
  final DateTime taskDate;
  final int priority;
  final bool isDaily;
  final bool isCompleted;
  final DateTime createdAt;
  const DbTask({
    required this.id,
    this.sourceTaskId,
    required this.title,
    required this.description,
    required this.category,
    required this.taskDate,
    required this.priority,
    required this.isDaily,
    required this.isCompleted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sourceTaskId != null) {
      map['source_task_id'] = Variable<int>(sourceTaskId);
    }
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['task_date'] = Variable<DateTime>(taskDate);
    map['priority'] = Variable<int>(priority);
    map['is_daily'] = Variable<bool>(isDaily);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbTasksCompanion toCompanion(bool nullToAbsent) {
    return DbTasksCompanion(
      id: Value(id),
      sourceTaskId: sourceTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTaskId),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      taskDate: Value(taskDate),
      priority: Value(priority),
      isDaily: Value(isDaily),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
    );
  }

  factory DbTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbTask(
      id: serializer.fromJson<int>(json['id']),
      sourceTaskId: serializer.fromJson<int?>(json['sourceTaskId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      taskDate: serializer.fromJson<DateTime>(json['taskDate']),
      priority: serializer.fromJson<int>(json['priority']),
      isDaily: serializer.fromJson<bool>(json['isDaily']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceTaskId': serializer.toJson<int?>(sourceTaskId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'taskDate': serializer.toJson<DateTime>(taskDate),
      'priority': serializer.toJson<int>(priority),
      'isDaily': serializer.toJson<bool>(isDaily),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbTask copyWith({
    int? id,
    Value<int?> sourceTaskId = const Value.absent(),
    String? title,
    String? description,
    String? category,
    DateTime? taskDate,
    int? priority,
    bool? isDaily,
    bool? isCompleted,
    DateTime? createdAt,
  }) => DbTask(
    id: id ?? this.id,
    sourceTaskId: sourceTaskId.present ? sourceTaskId.value : this.sourceTaskId,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    taskDate: taskDate ?? this.taskDate,
    priority: priority ?? this.priority,
    isDaily: isDaily ?? this.isDaily,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
  );
  DbTask copyWithCompanion(DbTasksCompanion data) {
    return DbTask(
      id: data.id.present ? data.id.value : this.id,
      sourceTaskId: data.sourceTaskId.present
          ? data.sourceTaskId.value
          : this.sourceTaskId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      taskDate: data.taskDate.present ? data.taskDate.value : this.taskDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      isDaily: data.isDaily.present ? data.isDaily.value : this.isDaily,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbTask(')
          ..write('id: $id, ')
          ..write('sourceTaskId: $sourceTaskId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('taskDate: $taskDate, ')
          ..write('priority: $priority, ')
          ..write('isDaily: $isDaily, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceTaskId,
    title,
    description,
    category,
    taskDate,
    priority,
    isDaily,
    isCompleted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbTask &&
          other.id == this.id &&
          other.sourceTaskId == this.sourceTaskId &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.taskDate == this.taskDate &&
          other.priority == this.priority &&
          other.isDaily == this.isDaily &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt);
}

class DbTasksCompanion extends UpdateCompanion<DbTask> {
  final Value<int> id;
  final Value<int?> sourceTaskId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> category;
  final Value<DateTime> taskDate;
  final Value<int> priority;
  final Value<bool> isDaily;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  const DbTasksCompanion({
    this.id = const Value.absent(),
    this.sourceTaskId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.taskDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDaily = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DbTasksCompanion.insert({
    this.id = const Value.absent(),
    this.sourceTaskId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required String category,
    required DateTime taskDate,
    this.priority = const Value.absent(),
    this.isDaily = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       category = Value(category),
       taskDate = Value(taskDate);
  static Insertable<DbTask> custom({
    Expression<int>? id,
    Expression<int>? sourceTaskId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<DateTime>? taskDate,
    Expression<int>? priority,
    Expression<bool>? isDaily,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceTaskId != null) 'source_task_id': sourceTaskId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (taskDate != null) 'task_date': taskDate,
      if (priority != null) 'priority': priority,
      if (isDaily != null) 'is_daily': isDaily,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DbTasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? sourceTaskId,
    Value<String>? title,
    Value<String>? description,
    Value<String>? category,
    Value<DateTime>? taskDate,
    Value<int>? priority,
    Value<bool>? isDaily,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
  }) {
    return DbTasksCompanion(
      id: id ?? this.id,
      sourceTaskId: sourceTaskId ?? this.sourceTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      taskDate: taskDate ?? this.taskDate,
      priority: priority ?? this.priority,
      isDaily: isDaily ?? this.isDaily,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceTaskId.present) {
      map['source_task_id'] = Variable<int>(sourceTaskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (taskDate.present) {
      map['task_date'] = Variable<DateTime>(taskDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isDaily.present) {
      map['is_daily'] = Variable<bool>(isDaily.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbTasksCompanion(')
          ..write('id: $id, ')
          ..write('sourceTaskId: $sourceTaskId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('taskDate: $taskDate, ')
          ..write('priority: $priority, ')
          ..write('isDaily: $isDaily, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DbCredentialsTable extends DbCredentials
    with TableInfo<$DbCredentialsTable, DbCredential> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbCredentialsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPayloadMeta = const VerificationMeta(
    'encryptedPayload',
  );
  @override
  late final GeneratedColumn<String> encryptedPayload = GeneratedColumn<String>(
    'encrypted_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltBase64Meta = const VerificationMeta(
    'saltBase64',
  );
  @override
  late final GeneratedColumn<String> saltBase64 = GeneratedColumn<String>(
    'salt_base64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nonceBase64Meta = const VerificationMeta(
    'nonceBase64',
  );
  @override
  late final GeneratedColumn<String> nonceBase64 = GeneratedColumn<String>(
    'nonce_base64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    encryptedPayload,
    saltBase64,
    nonceBase64,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_credentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCredential> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
        _encryptedPayloadMeta,
        encryptedPayload.isAcceptableOrUnknown(
          data['encrypted_payload']!,
          _encryptedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('salt_base64')) {
      context.handle(
        _saltBase64Meta,
        saltBase64.isAcceptableOrUnknown(data['salt_base64']!, _saltBase64Meta),
      );
    } else if (isInserting) {
      context.missing(_saltBase64Meta);
    }
    if (data.containsKey('nonce_base64')) {
      context.handle(
        _nonceBase64Meta,
        nonceBase64.isAcceptableOrUnknown(
          data['nonce_base64']!,
          _nonceBase64Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nonceBase64Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbCredential map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCredential(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      encryptedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_payload'],
      )!,
      saltBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salt_base64'],
      )!,
      nonceBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nonce_base64'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DbCredentialsTable createAlias(String alias) {
    return $DbCredentialsTable(attachedDatabase, alias);
  }
}

class DbCredential extends DataClass implements Insertable<DbCredential> {
  final int id;
  final String title;
  final String encryptedPayload;
  final String saltBase64;
  final String nonceBase64;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DbCredential({
    required this.id,
    required this.title,
    required this.encryptedPayload,
    required this.saltBase64,
    required this.nonceBase64,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['encrypted_payload'] = Variable<String>(encryptedPayload);
    map['salt_base64'] = Variable<String>(saltBase64);
    map['nonce_base64'] = Variable<String>(nonceBase64);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DbCredentialsCompanion toCompanion(bool nullToAbsent) {
    return DbCredentialsCompanion(
      id: Value(id),
      title: Value(title),
      encryptedPayload: Value(encryptedPayload),
      saltBase64: Value(saltBase64),
      nonceBase64: Value(nonceBase64),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbCredential.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCredential(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      encryptedPayload: serializer.fromJson<String>(json['encryptedPayload']),
      saltBase64: serializer.fromJson<String>(json['saltBase64']),
      nonceBase64: serializer.fromJson<String>(json['nonceBase64']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'encryptedPayload': serializer.toJson<String>(encryptedPayload),
      'saltBase64': serializer.toJson<String>(saltBase64),
      'nonceBase64': serializer.toJson<String>(nonceBase64),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbCredential copyWith({
    int? id,
    String? title,
    String? encryptedPayload,
    String? saltBase64,
    String? nonceBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DbCredential(
    id: id ?? this.id,
    title: title ?? this.title,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    saltBase64: saltBase64 ?? this.saltBase64,
    nonceBase64: nonceBase64 ?? this.nonceBase64,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DbCredential copyWithCompanion(DbCredentialsCompanion data) {
    return DbCredential(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      saltBase64: data.saltBase64.present
          ? data.saltBase64.value
          : this.saltBase64,
      nonceBase64: data.nonceBase64.present
          ? data.nonceBase64.value
          : this.nonceBase64,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCredential(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('saltBase64: $saltBase64, ')
          ..write('nonceBase64: $nonceBase64, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    encryptedPayload,
    saltBase64,
    nonceBase64,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCredential &&
          other.id == this.id &&
          other.title == this.title &&
          other.encryptedPayload == this.encryptedPayload &&
          other.saltBase64 == this.saltBase64 &&
          other.nonceBase64 == this.nonceBase64 &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DbCredentialsCompanion extends UpdateCompanion<DbCredential> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> encryptedPayload;
  final Value<String> saltBase64;
  final Value<String> nonceBase64;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DbCredentialsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.saltBase64 = const Value.absent(),
    this.nonceBase64 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DbCredentialsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String encryptedPayload,
    required String saltBase64,
    required String nonceBase64,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       encryptedPayload = Value(encryptedPayload),
       saltBase64 = Value(saltBase64),
       nonceBase64 = Value(nonceBase64);
  static Insertable<DbCredential> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? encryptedPayload,
    Expression<String>? saltBase64,
    Expression<String>? nonceBase64,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (saltBase64 != null) 'salt_base64': saltBase64,
      if (nonceBase64 != null) 'nonce_base64': nonceBase64,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DbCredentialsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? encryptedPayload,
    Value<String>? saltBase64,
    Value<String>? nonceBase64,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DbCredentialsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      saltBase64: saltBase64 ?? this.saltBase64,
      nonceBase64: nonceBase64 ?? this.nonceBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<String>(encryptedPayload.value);
    }
    if (saltBase64.present) {
      map['salt_base64'] = Variable<String>(saltBase64.value);
    }
    if (nonceBase64.present) {
      map['nonce_base64'] = Variable<String>(nonceBase64.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbCredentialsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('saltBase64: $saltBase64, ')
          ..write('nonceBase64: $nonceBase64, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DbCategoriesTable dbCategories = $DbCategoriesTable(this);
  late final $DbBanksTable dbBanks = $DbBanksTable(this);
  late final $DbFinanceEntriesTable dbFinanceEntries = $DbFinanceEntriesTable(
    this,
  );
  late final $DbSplitRecordsTable dbSplitRecords = $DbSplitRecordsTable(this);
  late final $DbSplitParticipantsTable dbSplitParticipants =
      $DbSplitParticipantsTable(this);
  late final $DbLentSettlementsTable dbLentSettlements =
      $DbLentSettlementsTable(this);
  late final $DbTasksTable dbTasks = $DbTasksTable(this);
  late final $DbCredentialsTable dbCredentials = $DbCredentialsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dbCategories,
    dbBanks,
    dbFinanceEntries,
    dbSplitRecords,
    dbSplitParticipants,
    dbLentSettlements,
    dbTasks,
    dbCredentials,
  ];
}

typedef $$DbCategoriesTableCreateCompanionBuilder =
    DbCategoriesCompanion Function({
      Value<int> id,
      required String name,
      required int iconCodePoint,
      required int colorValue,
      Value<DateTime> createdAt,
    });
typedef $$DbCategoriesTableUpdateCompanionBuilder =
    DbCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> iconCodePoint,
      Value<int> colorValue,
      Value<DateTime> createdAt,
    });

final class $$DbCategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $DbCategoriesTable, DbCategory> {
  $$DbCategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DbFinanceEntriesTable, List<DbFinanceEntry>>
  _dbFinanceEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dbFinanceEntries,
    aliasName: $_aliasNameGenerator(
      db.dbCategories.id,
      db.dbFinanceEntries.categoryId,
    ),
  );

  $$DbFinanceEntriesTableProcessedTableManager get dbFinanceEntriesRefs {
    final manager = $$DbFinanceEntriesTableTableManager(
      $_db,
      $_db.dbFinanceEntries,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dbFinanceEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DbCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $DbCategoriesTable> {
  $$DbCategoriesTableFilterComposer({
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

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dbFinanceEntriesRefs(
    Expression<bool> Function($$DbFinanceEntriesTableFilterComposer f) f,
  ) {
    final $$DbFinanceEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DbCategoriesTable> {
  $$DbCategoriesTableOrderingComposer({
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

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbCategoriesTable> {
  $$DbCategoriesTableAnnotationComposer({
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

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> dbFinanceEntriesRefs<T extends Object>(
    Expression<T> Function($$DbFinanceEntriesTableAnnotationComposer a) f,
  ) {
    final $$DbFinanceEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbCategoriesTable,
          DbCategory,
          $$DbCategoriesTableFilterComposer,
          $$DbCategoriesTableOrderingComposer,
          $$DbCategoriesTableAnnotationComposer,
          $$DbCategoriesTableCreateCompanionBuilder,
          $$DbCategoriesTableUpdateCompanionBuilder,
          (DbCategory, $$DbCategoriesTableReferences),
          DbCategory,
          PrefetchHooks Function({bool dbFinanceEntriesRefs})
        > {
  $$DbCategoriesTableTableManager(_$AppDatabase db, $DbCategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbCategoriesCompanion(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorValue: colorValue,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int iconCodePoint,
                required int colorValue,
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbCategoriesCompanion.insert(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorValue: colorValue,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dbFinanceEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (dbFinanceEntriesRefs) db.dbFinanceEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dbFinanceEntriesRefs)
                    await $_getPrefetchedData<
                      DbCategory,
                      $DbCategoriesTable,
                      DbFinanceEntry
                    >(
                      currentTable: table,
                      referencedTable: $$DbCategoriesTableReferences
                          ._dbFinanceEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DbCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).dbFinanceEntriesRefs,
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

typedef $$DbCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbCategoriesTable,
      DbCategory,
      $$DbCategoriesTableFilterComposer,
      $$DbCategoriesTableOrderingComposer,
      $$DbCategoriesTableAnnotationComposer,
      $$DbCategoriesTableCreateCompanionBuilder,
      $$DbCategoriesTableUpdateCompanionBuilder,
      (DbCategory, $$DbCategoriesTableReferences),
      DbCategory,
      PrefetchHooks Function({bool dbFinanceEntriesRefs})
    >;
typedef $$DbBanksTableCreateCompanionBuilder =
    DbBanksCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$DbBanksTableUpdateCompanionBuilder =
    DbBanksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

final class $$DbBanksTableReferences
    extends BaseReferences<_$AppDatabase, $DbBanksTable, DbBank> {
  $$DbBanksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DbFinanceEntriesTable, List<DbFinanceEntry>>
  _dbFinanceEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dbFinanceEntries,
    aliasName: $_aliasNameGenerator(db.dbBanks.id, db.dbFinanceEntries.bankId),
  );

  $$DbFinanceEntriesTableProcessedTableManager get dbFinanceEntriesRefs {
    final manager = $$DbFinanceEntriesTableTableManager(
      $_db,
      $_db.dbFinanceEntries,
    ).filter((f) => f.bankId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dbFinanceEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DbBanksTableFilterComposer
    extends Composer<_$AppDatabase, $DbBanksTable> {
  $$DbBanksTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dbFinanceEntriesRefs(
    Expression<bool> Function($$DbFinanceEntriesTableFilterComposer f) f,
  ) {
    final $$DbFinanceEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.bankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbBanksTableOrderingComposer
    extends Composer<_$AppDatabase, $DbBanksTable> {
  $$DbBanksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbBanksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbBanksTable> {
  $$DbBanksTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> dbFinanceEntriesRefs<T extends Object>(
    Expression<T> Function($$DbFinanceEntriesTableAnnotationComposer a) f,
  ) {
    final $$DbFinanceEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.bankId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbBanksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbBanksTable,
          DbBank,
          $$DbBanksTableFilterComposer,
          $$DbBanksTableOrderingComposer,
          $$DbBanksTableAnnotationComposer,
          $$DbBanksTableCreateCompanionBuilder,
          $$DbBanksTableUpdateCompanionBuilder,
          (DbBank, $$DbBanksTableReferences),
          DbBank,
          PrefetchHooks Function({bool dbFinanceEntriesRefs})
        > {
  $$DbBanksTableTableManager(_$AppDatabase db, $DbBanksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbBanksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbBanksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbBanksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbBanksCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbBanksCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbBanksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dbFinanceEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (dbFinanceEntriesRefs) db.dbFinanceEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dbFinanceEntriesRefs)
                    await $_getPrefetchedData<
                      DbBank,
                      $DbBanksTable,
                      DbFinanceEntry
                    >(
                      currentTable: table,
                      referencedTable: $$DbBanksTableReferences
                          ._dbFinanceEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$DbBanksTableReferences(
                        db,
                        table,
                        p0,
                      ).dbFinanceEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.bankId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DbBanksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbBanksTable,
      DbBank,
      $$DbBanksTableFilterComposer,
      $$DbBanksTableOrderingComposer,
      $$DbBanksTableAnnotationComposer,
      $$DbBanksTableCreateCompanionBuilder,
      $$DbBanksTableUpdateCompanionBuilder,
      (DbBank, $$DbBanksTableReferences),
      DbBank,
      PrefetchHooks Function({bool dbFinanceEntriesRefs})
    >;
typedef $$DbFinanceEntriesTableCreateCompanionBuilder =
    DbFinanceEntriesCompanion Function({
      Value<int> id,
      required String title,
      required double amount,
      required String type,
      required int categoryId,
      Value<int?> bankId,
      required DateTime entryDate,
      required String paymentMode,
      Value<String> notes,
      Value<String?> counterparty,
      Value<DateTime> createdAt,
    });
typedef $$DbFinanceEntriesTableUpdateCompanionBuilder =
    DbFinanceEntriesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<double> amount,
      Value<String> type,
      Value<int> categoryId,
      Value<int?> bankId,
      Value<DateTime> entryDate,
      Value<String> paymentMode,
      Value<String> notes,
      Value<String?> counterparty,
      Value<DateTime> createdAt,
    });

final class $$DbFinanceEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $DbFinanceEntriesTable, DbFinanceEntry> {
  $$DbFinanceEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DbCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.dbCategories.createAlias(
        $_aliasNameGenerator(
          db.dbFinanceEntries.categoryId,
          db.dbCategories.id,
        ),
      );

  $$DbCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$DbCategoriesTableTableManager(
      $_db,
      $_db.dbCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DbBanksTable _bankIdTable(_$AppDatabase db) => db.dbBanks.createAlias(
    $_aliasNameGenerator(db.dbFinanceEntries.bankId, db.dbBanks.id),
  );

  $$DbBanksTableProcessedTableManager? get bankId {
    final $_column = $_itemColumn<int>('bank_id');
    if ($_column == null) return null;
    final manager = $$DbBanksTableTableManager(
      $_db,
      $_db.dbBanks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bankIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DbSplitRecordsTable, List<DbSplitRecord>>
  _expenseSplitRecordsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dbSplitRecords,
    aliasName: $_aliasNameGenerator(
      db.dbFinanceEntries.id,
      db.dbSplitRecords.expenseEntryId,
    ),
  );

  $$DbSplitRecordsTableProcessedTableManager get expenseSplitRecords {
    final manager = $$DbSplitRecordsTableTableManager(
      $_db,
      $_db.dbSplitRecords,
    ).filter((f) => f.expenseEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseSplitRecordsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DbSplitRecordsTable, List<DbSplitRecord>>
  _lentSplitRecordsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dbSplitRecords,
    aliasName: $_aliasNameGenerator(
      db.dbFinanceEntries.id,
      db.dbSplitRecords.lentEntryId,
    ),
  );

  $$DbSplitRecordsTableProcessedTableManager get lentSplitRecords {
    final manager = $$DbSplitRecordsTableTableManager(
      $_db,
      $_db.dbSplitRecords,
    ).filter((f) => f.lentEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lentSplitRecordsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DbLentSettlementsTable, List<DbLentSettlement>>
  _dbLentSettlementsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dbLentSettlements,
        aliasName: $_aliasNameGenerator(
          db.dbFinanceEntries.id,
          db.dbLentSettlements.incomeEntryId,
        ),
      );

  $$DbLentSettlementsTableProcessedTableManager get dbLentSettlementsRefs {
    final manager = $$DbLentSettlementsTableTableManager(
      $_db,
      $_db.dbLentSettlements,
    ).filter((f) => f.incomeEntryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dbLentSettlementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DbFinanceEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DbFinanceEntriesTable> {
  $$DbFinanceEntriesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DbCategoriesTableFilterComposer get categoryId {
    final $$DbCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.dbCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.dbCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbBanksTableFilterComposer get bankId {
    final $$DbBanksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.dbBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbBanksTableFilterComposer(
            $db: $db,
            $table: $db.dbBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expenseSplitRecords(
    Expression<bool> Function($$DbSplitRecordsTableFilterComposer f) f,
  ) {
    final $$DbSplitRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.expenseEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lentSplitRecords(
    Expression<bool> Function($$DbSplitRecordsTableFilterComposer f) f,
  ) {
    final $$DbSplitRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.lentEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dbLentSettlementsRefs(
    Expression<bool> Function($$DbLentSettlementsTableFilterComposer f) f,
  ) {
    final $$DbLentSettlementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbLentSettlements,
      getReferencedColumn: (t) => t.incomeEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbLentSettlementsTableFilterComposer(
            $db: $db,
            $table: $db.dbLentSettlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbFinanceEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DbFinanceEntriesTable> {
  $$DbFinanceEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DbCategoriesTableOrderingComposer get categoryId {
    final $$DbCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.dbCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.dbCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbBanksTableOrderingComposer get bankId {
    final $$DbBanksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.dbBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbBanksTableOrderingComposer(
            $db: $db,
            $table: $db.dbBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbFinanceEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbFinanceEntriesTable> {
  $$DbFinanceEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<String> get paymentMode => $composableBuilder(
    column: $table.paymentMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DbCategoriesTableAnnotationComposer get categoryId {
    final $$DbCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.dbCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dbCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbBanksTableAnnotationComposer get bankId {
    final $$DbBanksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bankId,
      referencedTable: $db.dbBanks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbBanksTableAnnotationComposer(
            $db: $db,
            $table: $db.dbBanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expenseSplitRecords<T extends Object>(
    Expression<T> Function($$DbSplitRecordsTableAnnotationComposer a) f,
  ) {
    final $$DbSplitRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.expenseEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lentSplitRecords<T extends Object>(
    Expression<T> Function($$DbSplitRecordsTableAnnotationComposer a) f,
  ) {
    final $$DbSplitRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.lentEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dbLentSettlementsRefs<T extends Object>(
    Expression<T> Function($$DbLentSettlementsTableAnnotationComposer a) f,
  ) {
    final $$DbLentSettlementsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dbLentSettlements,
          getReferencedColumn: (t) => t.incomeEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DbLentSettlementsTableAnnotationComposer(
                $db: $db,
                $table: $db.dbLentSettlements,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DbFinanceEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbFinanceEntriesTable,
          DbFinanceEntry,
          $$DbFinanceEntriesTableFilterComposer,
          $$DbFinanceEntriesTableOrderingComposer,
          $$DbFinanceEntriesTableAnnotationComposer,
          $$DbFinanceEntriesTableCreateCompanionBuilder,
          $$DbFinanceEntriesTableUpdateCompanionBuilder,
          (DbFinanceEntry, $$DbFinanceEntriesTableReferences),
          DbFinanceEntry,
          PrefetchHooks Function({
            bool categoryId,
            bool bankId,
            bool expenseSplitRecords,
            bool lentSplitRecords,
            bool dbLentSettlementsRefs,
          })
        > {
  $$DbFinanceEntriesTableTableManager(
    _$AppDatabase db,
    $DbFinanceEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbFinanceEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbFinanceEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbFinanceEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int?> bankId = const Value.absent(),
                Value<DateTime> entryDate = const Value.absent(),
                Value<String> paymentMode = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbFinanceEntriesCompanion(
                id: id,
                title: title,
                amount: amount,
                type: type,
                categoryId: categoryId,
                bankId: bankId,
                entryDate: entryDate,
                paymentMode: paymentMode,
                notes: notes,
                counterparty: counterparty,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required double amount,
                required String type,
                required int categoryId,
                Value<int?> bankId = const Value.absent(),
                required DateTime entryDate,
                required String paymentMode,
                Value<String> notes = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbFinanceEntriesCompanion.insert(
                id: id,
                title: title,
                amount: amount,
                type: type,
                categoryId: categoryId,
                bankId: bankId,
                entryDate: entryDate,
                paymentMode: paymentMode,
                notes: notes,
                counterparty: counterparty,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbFinanceEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                bankId = false,
                expenseSplitRecords = false,
                lentSplitRecords = false,
                dbLentSettlementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expenseSplitRecords) db.dbSplitRecords,
                    if (lentSplitRecords) db.dbSplitRecords,
                    if (dbLentSettlementsRefs) db.dbLentSettlements,
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
                                    referencedTable:
                                        $$DbFinanceEntriesTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$DbFinanceEntriesTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (bankId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bankId,
                                    referencedTable:
                                        $$DbFinanceEntriesTableReferences
                                            ._bankIdTable(db),
                                    referencedColumn:
                                        $$DbFinanceEntriesTableReferences
                                            ._bankIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expenseSplitRecords)
                        await $_getPrefetchedData<
                          DbFinanceEntry,
                          $DbFinanceEntriesTable,
                          DbSplitRecord
                        >(
                          currentTable: table,
                          referencedTable: $$DbFinanceEntriesTableReferences
                              ._expenseSplitRecordsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbFinanceEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseSplitRecords,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.expenseEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lentSplitRecords)
                        await $_getPrefetchedData<
                          DbFinanceEntry,
                          $DbFinanceEntriesTable,
                          DbSplitRecord
                        >(
                          currentTable: table,
                          referencedTable: $$DbFinanceEntriesTableReferences
                              ._lentSplitRecordsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbFinanceEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).lentSplitRecords,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lentEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dbLentSettlementsRefs)
                        await $_getPrefetchedData<
                          DbFinanceEntry,
                          $DbFinanceEntriesTable,
                          DbLentSettlement
                        >(
                          currentTable: table,
                          referencedTable: $$DbFinanceEntriesTableReferences
                              ._dbLentSettlementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbFinanceEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).dbLentSettlementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.incomeEntryId == item.id,
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

typedef $$DbFinanceEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbFinanceEntriesTable,
      DbFinanceEntry,
      $$DbFinanceEntriesTableFilterComposer,
      $$DbFinanceEntriesTableOrderingComposer,
      $$DbFinanceEntriesTableAnnotationComposer,
      $$DbFinanceEntriesTableCreateCompanionBuilder,
      $$DbFinanceEntriesTableUpdateCompanionBuilder,
      (DbFinanceEntry, $$DbFinanceEntriesTableReferences),
      DbFinanceEntry,
      PrefetchHooks Function({
        bool categoryId,
        bool bankId,
        bool expenseSplitRecords,
        bool lentSplitRecords,
        bool dbLentSettlementsRefs,
      })
    >;
typedef $$DbSplitRecordsTableCreateCompanionBuilder =
    DbSplitRecordsCompanion Function({
      Value<int> id,
      Value<int?> expenseEntryId,
      Value<int?> lentEntryId,
      required double totalAmount,
      Value<DateTime> createdAt,
    });
typedef $$DbSplitRecordsTableUpdateCompanionBuilder =
    DbSplitRecordsCompanion Function({
      Value<int> id,
      Value<int?> expenseEntryId,
      Value<int?> lentEntryId,
      Value<double> totalAmount,
      Value<DateTime> createdAt,
    });

final class $$DbSplitRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $DbSplitRecordsTable, DbSplitRecord> {
  $$DbSplitRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DbFinanceEntriesTable _expenseEntryIdTable(_$AppDatabase db) =>
      db.dbFinanceEntries.createAlias(
        $_aliasNameGenerator(
          db.dbSplitRecords.expenseEntryId,
          db.dbFinanceEntries.id,
        ),
      );

  $$DbFinanceEntriesTableProcessedTableManager? get expenseEntryId {
    final $_column = $_itemColumn<int>('expense_entry_id');
    if ($_column == null) return null;
    final manager = $$DbFinanceEntriesTableTableManager(
      $_db,
      $_db.dbFinanceEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DbFinanceEntriesTable _lentEntryIdTable(_$AppDatabase db) =>
      db.dbFinanceEntries.createAlias(
        $_aliasNameGenerator(
          db.dbSplitRecords.lentEntryId,
          db.dbFinanceEntries.id,
        ),
      );

  $$DbFinanceEntriesTableProcessedTableManager? get lentEntryId {
    final $_column = $_itemColumn<int>('lent_entry_id');
    if ($_column == null) return null;
    final manager = $$DbFinanceEntriesTableTableManager(
      $_db,
      $_db.dbFinanceEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lentEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $DbSplitParticipantsTable,
    List<DbSplitParticipant>
  >
  _dbSplitParticipantsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dbSplitParticipants,
        aliasName: $_aliasNameGenerator(
          db.dbSplitRecords.id,
          db.dbSplitParticipants.splitRecordId,
        ),
      );

  $$DbSplitParticipantsTableProcessedTableManager get dbSplitParticipantsRefs {
    final manager = $$DbSplitParticipantsTableTableManager(
      $_db,
      $_db.dbSplitParticipants,
    ).filter((f) => f.splitRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dbSplitParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DbLentSettlementsTable, List<DbLentSettlement>>
  _dbLentSettlementsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dbLentSettlements,
        aliasName: $_aliasNameGenerator(
          db.dbSplitRecords.id,
          db.dbLentSettlements.splitRecordId,
        ),
      );

  $$DbLentSettlementsTableProcessedTableManager get dbLentSettlementsRefs {
    final manager = $$DbLentSettlementsTableTableManager(
      $_db,
      $_db.dbLentSettlements,
    ).filter((f) => f.splitRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dbLentSettlementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DbSplitRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DbSplitRecordsTable> {
  $$DbSplitRecordsTableFilterComposer({
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

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DbFinanceEntriesTableFilterComposer get expenseEntryId {
    final $$DbFinanceEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbFinanceEntriesTableFilterComposer get lentEntryId {
    final $$DbFinanceEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lentEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> dbSplitParticipantsRefs(
    Expression<bool> Function($$DbSplitParticipantsTableFilterComposer f) f,
  ) {
    final $$DbSplitParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbSplitParticipants,
      getReferencedColumn: (t) => t.splitRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.dbSplitParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dbLentSettlementsRefs(
    Expression<bool> Function($$DbLentSettlementsTableFilterComposer f) f,
  ) {
    final $$DbLentSettlementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbLentSettlements,
      getReferencedColumn: (t) => t.splitRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbLentSettlementsTableFilterComposer(
            $db: $db,
            $table: $db.dbLentSettlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbSplitRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbSplitRecordsTable> {
  $$DbSplitRecordsTableOrderingComposer({
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

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DbFinanceEntriesTableOrderingComposer get expenseEntryId {
    final $$DbFinanceEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbFinanceEntriesTableOrderingComposer get lentEntryId {
    final $$DbFinanceEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lentEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbSplitRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbSplitRecordsTable> {
  $$DbSplitRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DbFinanceEntriesTableAnnotationComposer get expenseEntryId {
    final $$DbFinanceEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbFinanceEntriesTableAnnotationComposer get lentEntryId {
    final $$DbFinanceEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lentEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> dbSplitParticipantsRefs<T extends Object>(
    Expression<T> Function($$DbSplitParticipantsTableAnnotationComposer a) f,
  ) {
    final $$DbSplitParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dbSplitParticipants,
          getReferencedColumn: (t) => t.splitRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DbSplitParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.dbSplitParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> dbLentSettlementsRefs<T extends Object>(
    Expression<T> Function($$DbLentSettlementsTableAnnotationComposer a) f,
  ) {
    final $$DbLentSettlementsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dbLentSettlements,
          getReferencedColumn: (t) => t.splitRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DbLentSettlementsTableAnnotationComposer(
                $db: $db,
                $table: $db.dbLentSettlements,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DbSplitRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbSplitRecordsTable,
          DbSplitRecord,
          $$DbSplitRecordsTableFilterComposer,
          $$DbSplitRecordsTableOrderingComposer,
          $$DbSplitRecordsTableAnnotationComposer,
          $$DbSplitRecordsTableCreateCompanionBuilder,
          $$DbSplitRecordsTableUpdateCompanionBuilder,
          (DbSplitRecord, $$DbSplitRecordsTableReferences),
          DbSplitRecord,
          PrefetchHooks Function({
            bool expenseEntryId,
            bool lentEntryId,
            bool dbSplitParticipantsRefs,
            bool dbLentSettlementsRefs,
          })
        > {
  $$DbSplitRecordsTableTableManager(
    _$AppDatabase db,
    $DbSplitRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbSplitRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbSplitRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbSplitRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> expenseEntryId = const Value.absent(),
                Value<int?> lentEntryId = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbSplitRecordsCompanion(
                id: id,
                expenseEntryId: expenseEntryId,
                lentEntryId: lentEntryId,
                totalAmount: totalAmount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> expenseEntryId = const Value.absent(),
                Value<int?> lentEntryId = const Value.absent(),
                required double totalAmount,
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbSplitRecordsCompanion.insert(
                id: id,
                expenseEntryId: expenseEntryId,
                lentEntryId: lentEntryId,
                totalAmount: totalAmount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbSplitRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                expenseEntryId = false,
                lentEntryId = false,
                dbSplitParticipantsRefs = false,
                dbLentSettlementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dbSplitParticipantsRefs) db.dbSplitParticipants,
                    if (dbLentSettlementsRefs) db.dbLentSettlements,
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
                        if (expenseEntryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.expenseEntryId,
                                    referencedTable:
                                        $$DbSplitRecordsTableReferences
                                            ._expenseEntryIdTable(db),
                                    referencedColumn:
                                        $$DbSplitRecordsTableReferences
                                            ._expenseEntryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (lentEntryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lentEntryId,
                                    referencedTable:
                                        $$DbSplitRecordsTableReferences
                                            ._lentEntryIdTable(db),
                                    referencedColumn:
                                        $$DbSplitRecordsTableReferences
                                            ._lentEntryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dbSplitParticipantsRefs)
                        await $_getPrefetchedData<
                          DbSplitRecord,
                          $DbSplitRecordsTable,
                          DbSplitParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$DbSplitRecordsTableReferences
                              ._dbSplitParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbSplitRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).dbSplitParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.splitRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dbLentSettlementsRefs)
                        await $_getPrefetchedData<
                          DbSplitRecord,
                          $DbSplitRecordsTable,
                          DbLentSettlement
                        >(
                          currentTable: table,
                          referencedTable: $$DbSplitRecordsTableReferences
                              ._dbLentSettlementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbSplitRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).dbLentSettlementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.splitRecordId == item.id,
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

typedef $$DbSplitRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbSplitRecordsTable,
      DbSplitRecord,
      $$DbSplitRecordsTableFilterComposer,
      $$DbSplitRecordsTableOrderingComposer,
      $$DbSplitRecordsTableAnnotationComposer,
      $$DbSplitRecordsTableCreateCompanionBuilder,
      $$DbSplitRecordsTableUpdateCompanionBuilder,
      (DbSplitRecord, $$DbSplitRecordsTableReferences),
      DbSplitRecord,
      PrefetchHooks Function({
        bool expenseEntryId,
        bool lentEntryId,
        bool dbSplitParticipantsRefs,
        bool dbLentSettlementsRefs,
      })
    >;
typedef $$DbSplitParticipantsTableCreateCompanionBuilder =
    DbSplitParticipantsCompanion Function({
      Value<int> id,
      required int splitRecordId,
      required String participantName,
      required double amount,
      required double percentage,
      Value<bool> isSelf,
      Value<double> settledAmount,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$DbSplitParticipantsTableUpdateCompanionBuilder =
    DbSplitParticipantsCompanion Function({
      Value<int> id,
      Value<int> splitRecordId,
      Value<String> participantName,
      Value<double> amount,
      Value<double> percentage,
      Value<bool> isSelf,
      Value<double> settledAmount,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$DbSplitParticipantsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DbSplitParticipantsTable,
          DbSplitParticipant
        > {
  $$DbSplitParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DbSplitRecordsTable _splitRecordIdTable(_$AppDatabase db) =>
      db.dbSplitRecords.createAlias(
        $_aliasNameGenerator(
          db.dbSplitParticipants.splitRecordId,
          db.dbSplitRecords.id,
        ),
      );

  $$DbSplitRecordsTableProcessedTableManager get splitRecordId {
    final $_column = $_itemColumn<int>('split_record_id')!;

    final manager = $$DbSplitRecordsTableTableManager(
      $_db,
      $_db.dbSplitRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DbLentSettlementsTable, List<DbLentSettlement>>
  _dbLentSettlementsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dbLentSettlements,
        aliasName: $_aliasNameGenerator(
          db.dbSplitParticipants.id,
          db.dbLentSettlements.splitParticipantId,
        ),
      );

  $$DbLentSettlementsTableProcessedTableManager get dbLentSettlementsRefs {
    final manager =
        $$DbLentSettlementsTableTableManager(
          $_db,
          $_db.dbLentSettlements,
        ).filter(
          (f) => f.splitParticipantId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _dbLentSettlementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DbSplitParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $DbSplitParticipantsTable> {
  $$DbSplitParticipantsTableFilterComposer({
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

  ColumnFilters<String> get participantName => $composableBuilder(
    column: $table.participantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSelf => $composableBuilder(
    column: $table.isSelf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DbSplitRecordsTableFilterComposer get splitRecordId {
    final $$DbSplitRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitRecordId,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> dbLentSettlementsRefs(
    Expression<bool> Function($$DbLentSettlementsTableFilterComposer f) f,
  ) {
    final $$DbLentSettlementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dbLentSettlements,
      getReferencedColumn: (t) => t.splitParticipantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbLentSettlementsTableFilterComposer(
            $db: $db,
            $table: $db.dbLentSettlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DbSplitParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbSplitParticipantsTable> {
  $$DbSplitParticipantsTableOrderingComposer({
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

  ColumnOrderings<String> get participantName => $composableBuilder(
    column: $table.participantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSelf => $composableBuilder(
    column: $table.isSelf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DbSplitRecordsTableOrderingComposer get splitRecordId {
    final $$DbSplitRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitRecordId,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbSplitParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbSplitParticipantsTable> {
  $$DbSplitParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get participantName => $composableBuilder(
    column: $table.participantName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSelf =>
      $composableBuilder(column: $table.isSelf, builder: (column) => column);

  GeneratedColumn<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DbSplitRecordsTableAnnotationComposer get splitRecordId {
    final $$DbSplitRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitRecordId,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> dbLentSettlementsRefs<T extends Object>(
    Expression<T> Function($$DbLentSettlementsTableAnnotationComposer a) f,
  ) {
    final $$DbLentSettlementsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dbLentSettlements,
          getReferencedColumn: (t) => t.splitParticipantId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DbLentSettlementsTableAnnotationComposer(
                $db: $db,
                $table: $db.dbLentSettlements,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DbSplitParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbSplitParticipantsTable,
          DbSplitParticipant,
          $$DbSplitParticipantsTableFilterComposer,
          $$DbSplitParticipantsTableOrderingComposer,
          $$DbSplitParticipantsTableAnnotationComposer,
          $$DbSplitParticipantsTableCreateCompanionBuilder,
          $$DbSplitParticipantsTableUpdateCompanionBuilder,
          (DbSplitParticipant, $$DbSplitParticipantsTableReferences),
          DbSplitParticipant,
          PrefetchHooks Function({
            bool splitRecordId,
            bool dbLentSettlementsRefs,
          })
        > {
  $$DbSplitParticipantsTableTableManager(
    _$AppDatabase db,
    $DbSplitParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbSplitParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbSplitParticipantsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DbSplitParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> splitRecordId = const Value.absent(),
                Value<String> participantName = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> percentage = const Value.absent(),
                Value<bool> isSelf = const Value.absent(),
                Value<double> settledAmount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbSplitParticipantsCompanion(
                id: id,
                splitRecordId: splitRecordId,
                participantName: participantName,
                amount: amount,
                percentage: percentage,
                isSelf: isSelf,
                settledAmount: settledAmount,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int splitRecordId,
                required String participantName,
                required double amount,
                required double percentage,
                Value<bool> isSelf = const Value.absent(),
                Value<double> settledAmount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbSplitParticipantsCompanion.insert(
                id: id,
                splitRecordId: splitRecordId,
                participantName: participantName,
                amount: amount,
                percentage: percentage,
                isSelf: isSelf,
                settledAmount: settledAmount,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbSplitParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({splitRecordId = false, dbLentSettlementsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dbLentSettlementsRefs) db.dbLentSettlements,
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
                        if (splitRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.splitRecordId,
                                    referencedTable:
                                        $$DbSplitParticipantsTableReferences
                                            ._splitRecordIdTable(db),
                                    referencedColumn:
                                        $$DbSplitParticipantsTableReferences
                                            ._splitRecordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dbLentSettlementsRefs)
                        await $_getPrefetchedData<
                          DbSplitParticipant,
                          $DbSplitParticipantsTable,
                          DbLentSettlement
                        >(
                          currentTable: table,
                          referencedTable: $$DbSplitParticipantsTableReferences
                              ._dbLentSettlementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DbSplitParticipantsTableReferences(
                                db,
                                table,
                                p0,
                              ).dbLentSettlementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.splitParticipantId == item.id,
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

typedef $$DbSplitParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbSplitParticipantsTable,
      DbSplitParticipant,
      $$DbSplitParticipantsTableFilterComposer,
      $$DbSplitParticipantsTableOrderingComposer,
      $$DbSplitParticipantsTableAnnotationComposer,
      $$DbSplitParticipantsTableCreateCompanionBuilder,
      $$DbSplitParticipantsTableUpdateCompanionBuilder,
      (DbSplitParticipant, $$DbSplitParticipantsTableReferences),
      DbSplitParticipant,
      PrefetchHooks Function({bool splitRecordId, bool dbLentSettlementsRefs})
    >;
typedef $$DbLentSettlementsTableCreateCompanionBuilder =
    DbLentSettlementsCompanion Function({
      Value<int> id,
      required int splitRecordId,
      required int splitParticipantId,
      required int incomeEntryId,
      required double settledAmount,
      Value<DateTime> createdAt,
    });
typedef $$DbLentSettlementsTableUpdateCompanionBuilder =
    DbLentSettlementsCompanion Function({
      Value<int> id,
      Value<int> splitRecordId,
      Value<int> splitParticipantId,
      Value<int> incomeEntryId,
      Value<double> settledAmount,
      Value<DateTime> createdAt,
    });

final class $$DbLentSettlementsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DbLentSettlementsTable,
          DbLentSettlement
        > {
  $$DbLentSettlementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DbSplitRecordsTable _splitRecordIdTable(_$AppDatabase db) =>
      db.dbSplitRecords.createAlias(
        $_aliasNameGenerator(
          db.dbLentSettlements.splitRecordId,
          db.dbSplitRecords.id,
        ),
      );

  $$DbSplitRecordsTableProcessedTableManager get splitRecordId {
    final $_column = $_itemColumn<int>('split_record_id')!;

    final manager = $$DbSplitRecordsTableTableManager(
      $_db,
      $_db.dbSplitRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DbSplitParticipantsTable _splitParticipantIdTable(_$AppDatabase db) =>
      db.dbSplitParticipants.createAlias(
        $_aliasNameGenerator(
          db.dbLentSettlements.splitParticipantId,
          db.dbSplitParticipants.id,
        ),
      );

  $$DbSplitParticipantsTableProcessedTableManager get splitParticipantId {
    final $_column = $_itemColumn<int>('split_participant_id')!;

    final manager = $$DbSplitParticipantsTableTableManager(
      $_db,
      $_db.dbSplitParticipants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitParticipantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DbFinanceEntriesTable _incomeEntryIdTable(_$AppDatabase db) =>
      db.dbFinanceEntries.createAlias(
        $_aliasNameGenerator(
          db.dbLentSettlements.incomeEntryId,
          db.dbFinanceEntries.id,
        ),
      );

  $$DbFinanceEntriesTableProcessedTableManager get incomeEntryId {
    final $_column = $_itemColumn<int>('income_entry_id')!;

    final manager = $$DbFinanceEntriesTableTableManager(
      $_db,
      $_db.dbFinanceEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_incomeEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DbLentSettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $DbLentSettlementsTable> {
  $$DbLentSettlementsTableFilterComposer({
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

  ColumnFilters<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DbSplitRecordsTableFilterComposer get splitRecordId {
    final $$DbSplitRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitRecordId,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbSplitParticipantsTableFilterComposer get splitParticipantId {
    final $$DbSplitParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitParticipantId,
      referencedTable: $db.dbSplitParticipants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.dbSplitParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbFinanceEntriesTableFilterComposer get incomeEntryId {
    final $$DbFinanceEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incomeEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbLentSettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbLentSettlementsTable> {
  $$DbLentSettlementsTableOrderingComposer({
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

  ColumnOrderings<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DbSplitRecordsTableOrderingComposer get splitRecordId {
    final $$DbSplitRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitRecordId,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbSplitParticipantsTableOrderingComposer get splitParticipantId {
    final $$DbSplitParticipantsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.splitParticipantId,
          referencedTable: $db.dbSplitParticipants,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DbSplitParticipantsTableOrderingComposer(
                $db: $db,
                $table: $db.dbSplitParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$DbFinanceEntriesTableOrderingComposer get incomeEntryId {
    final $$DbFinanceEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incomeEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbLentSettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbLentSettlementsTable> {
  $$DbLentSettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DbSplitRecordsTableAnnotationComposer get splitRecordId {
    final $$DbSplitRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.splitRecordId,
      referencedTable: $db.dbSplitRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbSplitRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dbSplitRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DbSplitParticipantsTableAnnotationComposer get splitParticipantId {
    final $$DbSplitParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.splitParticipantId,
          referencedTable: $db.dbSplitParticipants,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DbSplitParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.dbSplitParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$DbFinanceEntriesTableAnnotationComposer get incomeEntryId {
    final $$DbFinanceEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incomeEntryId,
      referencedTable: $db.dbFinanceEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DbFinanceEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dbFinanceEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DbLentSettlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbLentSettlementsTable,
          DbLentSettlement,
          $$DbLentSettlementsTableFilterComposer,
          $$DbLentSettlementsTableOrderingComposer,
          $$DbLentSettlementsTableAnnotationComposer,
          $$DbLentSettlementsTableCreateCompanionBuilder,
          $$DbLentSettlementsTableUpdateCompanionBuilder,
          (DbLentSettlement, $$DbLentSettlementsTableReferences),
          DbLentSettlement,
          PrefetchHooks Function({
            bool splitRecordId,
            bool splitParticipantId,
            bool incomeEntryId,
          })
        > {
  $$DbLentSettlementsTableTableManager(
    _$AppDatabase db,
    $DbLentSettlementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbLentSettlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbLentSettlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbLentSettlementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> splitRecordId = const Value.absent(),
                Value<int> splitParticipantId = const Value.absent(),
                Value<int> incomeEntryId = const Value.absent(),
                Value<double> settledAmount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbLentSettlementsCompanion(
                id: id,
                splitRecordId: splitRecordId,
                splitParticipantId: splitParticipantId,
                incomeEntryId: incomeEntryId,
                settledAmount: settledAmount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int splitRecordId,
                required int splitParticipantId,
                required int incomeEntryId,
                required double settledAmount,
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbLentSettlementsCompanion.insert(
                id: id,
                splitRecordId: splitRecordId,
                splitParticipantId: splitParticipantId,
                incomeEntryId: incomeEntryId,
                settledAmount: settledAmount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DbLentSettlementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                splitRecordId = false,
                splitParticipantId = false,
                incomeEntryId = false,
              }) {
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
                        if (splitRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.splitRecordId,
                                    referencedTable:
                                        $$DbLentSettlementsTableReferences
                                            ._splitRecordIdTable(db),
                                    referencedColumn:
                                        $$DbLentSettlementsTableReferences
                                            ._splitRecordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (splitParticipantId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.splitParticipantId,
                                    referencedTable:
                                        $$DbLentSettlementsTableReferences
                                            ._splitParticipantIdTable(db),
                                    referencedColumn:
                                        $$DbLentSettlementsTableReferences
                                            ._splitParticipantIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (incomeEntryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.incomeEntryId,
                                    referencedTable:
                                        $$DbLentSettlementsTableReferences
                                            ._incomeEntryIdTable(db),
                                    referencedColumn:
                                        $$DbLentSettlementsTableReferences
                                            ._incomeEntryIdTable(db)
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

typedef $$DbLentSettlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbLentSettlementsTable,
      DbLentSettlement,
      $$DbLentSettlementsTableFilterComposer,
      $$DbLentSettlementsTableOrderingComposer,
      $$DbLentSettlementsTableAnnotationComposer,
      $$DbLentSettlementsTableCreateCompanionBuilder,
      $$DbLentSettlementsTableUpdateCompanionBuilder,
      (DbLentSettlement, $$DbLentSettlementsTableReferences),
      DbLentSettlement,
      PrefetchHooks Function({
        bool splitRecordId,
        bool splitParticipantId,
        bool incomeEntryId,
      })
    >;
typedef $$DbTasksTableCreateCompanionBuilder =
    DbTasksCompanion Function({
      Value<int> id,
      Value<int?> sourceTaskId,
      required String title,
      Value<String> description,
      required String category,
      required DateTime taskDate,
      Value<int> priority,
      Value<bool> isDaily,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
    });
typedef $$DbTasksTableUpdateCompanionBuilder =
    DbTasksCompanion Function({
      Value<int> id,
      Value<int?> sourceTaskId,
      Value<String> title,
      Value<String> description,
      Value<String> category,
      Value<DateTime> taskDate,
      Value<int> priority,
      Value<bool> isDaily,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
    });

class $$DbTasksTableFilterComposer
    extends Composer<_$AppDatabase, $DbTasksTable> {
  $$DbTasksTableFilterComposer({
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

  ColumnFilters<int> get sourceTaskId => $composableBuilder(
    column: $table.sourceTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get taskDate => $composableBuilder(
    column: $table.taskDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DbTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $DbTasksTable> {
  $$DbTasksTableOrderingComposer({
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

  ColumnOrderings<int> get sourceTaskId => $composableBuilder(
    column: $table.sourceTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get taskDate => $composableBuilder(
    column: $table.taskDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbTasksTable> {
  $$DbTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sourceTaskId => $composableBuilder(
    column: $table.sourceTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get taskDate =>
      $composableBuilder(column: $table.taskDate, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isDaily =>
      $composableBuilder(column: $table.isDaily, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DbTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbTasksTable,
          DbTask,
          $$DbTasksTableFilterComposer,
          $$DbTasksTableOrderingComposer,
          $$DbTasksTableAnnotationComposer,
          $$DbTasksTableCreateCompanionBuilder,
          $$DbTasksTableUpdateCompanionBuilder,
          (DbTask, BaseReferences<_$AppDatabase, $DbTasksTable, DbTask>),
          DbTask,
          PrefetchHooks Function()
        > {
  $$DbTasksTableTableManager(_$AppDatabase db, $DbTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sourceTaskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> taskDate = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isDaily = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbTasksCompanion(
                id: id,
                sourceTaskId: sourceTaskId,
                title: title,
                description: description,
                category: category,
                taskDate: taskDate,
                priority: priority,
                isDaily: isDaily,
                isCompleted: isCompleted,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sourceTaskId = const Value.absent(),
                required String title,
                Value<String> description = const Value.absent(),
                required String category,
                required DateTime taskDate,
                Value<int> priority = const Value.absent(),
                Value<bool> isDaily = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DbTasksCompanion.insert(
                id: id,
                sourceTaskId: sourceTaskId,
                title: title,
                description: description,
                category: category,
                taskDate: taskDate,
                priority: priority,
                isDaily: isDaily,
                isCompleted: isCompleted,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DbTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbTasksTable,
      DbTask,
      $$DbTasksTableFilterComposer,
      $$DbTasksTableOrderingComposer,
      $$DbTasksTableAnnotationComposer,
      $$DbTasksTableCreateCompanionBuilder,
      $$DbTasksTableUpdateCompanionBuilder,
      (DbTask, BaseReferences<_$AppDatabase, $DbTasksTable, DbTask>),
      DbTask,
      PrefetchHooks Function()
    >;
typedef $$DbCredentialsTableCreateCompanionBuilder =
    DbCredentialsCompanion Function({
      Value<int> id,
      required String title,
      required String encryptedPayload,
      required String saltBase64,
      required String nonceBase64,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DbCredentialsTableUpdateCompanionBuilder =
    DbCredentialsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> encryptedPayload,
      Value<String> saltBase64,
      Value<String> nonceBase64,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DbCredentialsTableFilterComposer
    extends Composer<_$AppDatabase, $DbCredentialsTable> {
  $$DbCredentialsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saltBase64 => $composableBuilder(
    column: $table.saltBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nonceBase64 => $composableBuilder(
    column: $table.nonceBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DbCredentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbCredentialsTable> {
  $$DbCredentialsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saltBase64 => $composableBuilder(
    column: $table.saltBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nonceBase64 => $composableBuilder(
    column: $table.nonceBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbCredentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbCredentialsTable> {
  $$DbCredentialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saltBase64 => $composableBuilder(
    column: $table.saltBase64,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nonceBase64 => $composableBuilder(
    column: $table.nonceBase64,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DbCredentialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DbCredentialsTable,
          DbCredential,
          $$DbCredentialsTableFilterComposer,
          $$DbCredentialsTableOrderingComposer,
          $$DbCredentialsTableAnnotationComposer,
          $$DbCredentialsTableCreateCompanionBuilder,
          $$DbCredentialsTableUpdateCompanionBuilder,
          (
            DbCredential,
            BaseReferences<_$AppDatabase, $DbCredentialsTable, DbCredential>,
          ),
          DbCredential,
          PrefetchHooks Function()
        > {
  $$DbCredentialsTableTableManager(_$AppDatabase db, $DbCredentialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbCredentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbCredentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbCredentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> encryptedPayload = const Value.absent(),
                Value<String> saltBase64 = const Value.absent(),
                Value<String> nonceBase64 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DbCredentialsCompanion(
                id: id,
                title: title,
                encryptedPayload: encryptedPayload,
                saltBase64: saltBase64,
                nonceBase64: nonceBase64,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String encryptedPayload,
                required String saltBase64,
                required String nonceBase64,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DbCredentialsCompanion.insert(
                id: id,
                title: title,
                encryptedPayload: encryptedPayload,
                saltBase64: saltBase64,
                nonceBase64: nonceBase64,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DbCredentialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DbCredentialsTable,
      DbCredential,
      $$DbCredentialsTableFilterComposer,
      $$DbCredentialsTableOrderingComposer,
      $$DbCredentialsTableAnnotationComposer,
      $$DbCredentialsTableCreateCompanionBuilder,
      $$DbCredentialsTableUpdateCompanionBuilder,
      (
        DbCredential,
        BaseReferences<_$AppDatabase, $DbCredentialsTable, DbCredential>,
      ),
      DbCredential,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DbCategoriesTableTableManager get dbCategories =>
      $$DbCategoriesTableTableManager(_db, _db.dbCategories);
  $$DbBanksTableTableManager get dbBanks =>
      $$DbBanksTableTableManager(_db, _db.dbBanks);
  $$DbFinanceEntriesTableTableManager get dbFinanceEntries =>
      $$DbFinanceEntriesTableTableManager(_db, _db.dbFinanceEntries);
  $$DbSplitRecordsTableTableManager get dbSplitRecords =>
      $$DbSplitRecordsTableTableManager(_db, _db.dbSplitRecords);
  $$DbSplitParticipantsTableTableManager get dbSplitParticipants =>
      $$DbSplitParticipantsTableTableManager(_db, _db.dbSplitParticipants);
  $$DbLentSettlementsTableTableManager get dbLentSettlements =>
      $$DbLentSettlementsTableTableManager(_db, _db.dbLentSettlements);
  $$DbTasksTableTableManager get dbTasks =>
      $$DbTasksTableTableManager(_db, _db.dbTasks);
  $$DbCredentialsTableTableManager get dbCredentials =>
      $$DbCredentialsTableTableManager(_db, _db.dbCredentials);
}
