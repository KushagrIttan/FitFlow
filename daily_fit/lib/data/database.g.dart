// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ClothingItemsTable extends ClothingItems
    with TableInfo<$ClothingItemsTable, ClothingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingItemsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<ItemCategory, int> category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ItemCategory>($ClothingItemsTable.$convertercategory);
  @override
  late final GeneratedColumnWithTypeConverter<BodyZone, int> bodyZone =
      GeneratedColumn<int>(
        'body_zone',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<BodyZone>($ClothingItemsTable.$converterbodyZone);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Fit, int> fit =
      GeneratedColumn<int>(
        'fit',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Fit>($ClothingItemsTable.$converterfit);
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<String> photo = GeneratedColumn<String>(
    'photo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photosMeta = const VerificationMeta('photos');
  @override
  late final GeneratedColumn<String> photos = GeneratedColumn<String>(
    'photos',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _homeOnlyMeta = const VerificationMeta(
    'homeOnly',
  );
  @override
  late final GeneratedColumn<bool> homeOnly = GeneratedColumn<bool>(
    'home_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("home_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _warmthLevelMeta = const VerificationMeta(
    'warmthLevel',
  );
  @override
  late final GeneratedColumn<int> warmthLevel = GeneratedColumn<int>(
    'warmth_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _inLaundryMeta = const VerificationMeta(
    'inLaundry',
  );
  @override
  late final GeneratedColumn<bool> inLaundry = GeneratedColumn<bool>(
    'in_laundry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_laundry" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastWornDateMeta = const VerificationMeta(
    'lastWornDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastWornDate = GeneratedColumn<DateTime>(
    'last_worn_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wearCountMeta = const VerificationMeta(
    'wearCount',
  );
  @override
  late final GeneratedColumn<int> wearCount = GeneratedColumn<int>(
    'wear_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    bodyZone,
    name,
    color,
    fit,
    photo,
    photos,
    homeOnly,
    warmthLevel,
    inLaundry,
    lastWornDate,
    wearCount,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingItem> instance, {
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
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    } else if (isInserting) {
      context.missing(_photoMeta);
    }
    if (data.containsKey('photos')) {
      context.handle(
        _photosMeta,
        photos.isAcceptableOrUnknown(data['photos']!, _photosMeta),
      );
    }
    if (data.containsKey('home_only')) {
      context.handle(
        _homeOnlyMeta,
        homeOnly.isAcceptableOrUnknown(data['home_only']!, _homeOnlyMeta),
      );
    }
    if (data.containsKey('warmth_level')) {
      context.handle(
        _warmthLevelMeta,
        warmthLevel.isAcceptableOrUnknown(
          data['warmth_level']!,
          _warmthLevelMeta,
        ),
      );
    }
    if (data.containsKey('in_laundry')) {
      context.handle(
        _inLaundryMeta,
        inLaundry.isAcceptableOrUnknown(data['in_laundry']!, _inLaundryMeta),
      );
    }
    if (data.containsKey('last_worn_date')) {
      context.handle(
        _lastWornDateMeta,
        lastWornDate.isAcceptableOrUnknown(
          data['last_worn_date']!,
          _lastWornDateMeta,
        ),
      );
    }
    if (data.containsKey('wear_count')) {
      context.handle(
        _wearCountMeta,
        wearCount.isAcceptableOrUnknown(data['wear_count']!, _wearCountMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClothingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingItem(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      category: $ClothingItemsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      bodyZone: $ClothingItemsTable.$converterbodyZone.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}body_zone'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      fit: $ClothingItemsTable.$converterfit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}fit'],
        )!,
      ),
      photo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}photo'],
          )!,
      photos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photos'],
      ),
      homeOnly:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}home_only'],
          )!,
      warmthLevel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}warmth_level'],
          )!,
      inLaundry:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}in_laundry'],
          )!,
      lastWornDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_worn_date'],
      ),
      wearCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}wear_count'],
          )!,
      dateAdded:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}date_added'],
          )!,
    );
  }

  @override
  $ClothingItemsTable createAlias(String alias) {
    return $ClothingItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ItemCategory, int, int> $convertercategory =
      const EnumIndexConverter<ItemCategory>(ItemCategory.values);
  static JsonTypeConverter2<BodyZone, int, int> $converterbodyZone =
      const EnumIndexConverter<BodyZone>(BodyZone.values);
  static JsonTypeConverter2<Fit, int, int> $converterfit =
      const EnumIndexConverter<Fit>(Fit.values);
}

class ClothingItem extends DataClass implements Insertable<ClothingItem> {
  final int id;
  final ItemCategory category;
  final BodyZone bodyZone;
  final String? name;
  final String? color;
  final Fit fit;
  final String photo;

  /// JSON array of all photo paths; index 0 equals [photo] (the cover).
  /// Null for legacy items with a single photo.
  final String? photos;
  final bool homeOnly;
  final int warmthLevel;
  final bool inLaundry;
  final DateTime? lastWornDate;
  final int wearCount;
  final DateTime dateAdded;
  const ClothingItem({
    required this.id,
    required this.category,
    required this.bodyZone,
    this.name,
    this.color,
    required this.fit,
    required this.photo,
    this.photos,
    required this.homeOnly,
    required this.warmthLevel,
    required this.inLaundry,
    this.lastWornDate,
    required this.wearCount,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['category'] = Variable<int>(
        $ClothingItemsTable.$convertercategory.toSql(category),
      );
    }
    {
      map['body_zone'] = Variable<int>(
        $ClothingItemsTable.$converterbodyZone.toSql(bodyZone),
      );
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    {
      map['fit'] = Variable<int>($ClothingItemsTable.$converterfit.toSql(fit));
    }
    map['photo'] = Variable<String>(photo);
    if (!nullToAbsent || photos != null) {
      map['photos'] = Variable<String>(photos);
    }
    map['home_only'] = Variable<bool>(homeOnly);
    map['warmth_level'] = Variable<int>(warmthLevel);
    map['in_laundry'] = Variable<bool>(inLaundry);
    if (!nullToAbsent || lastWornDate != null) {
      map['last_worn_date'] = Variable<DateTime>(lastWornDate);
    }
    map['wear_count'] = Variable<int>(wearCount);
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  ClothingItemsCompanion toCompanion(bool nullToAbsent) {
    return ClothingItemsCompanion(
      id: Value(id),
      category: Value(category),
      bodyZone: Value(bodyZone),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      fit: Value(fit),
      photo: Value(photo),
      photos:
          photos == null && nullToAbsent ? const Value.absent() : Value(photos),
      homeOnly: Value(homeOnly),
      warmthLevel: Value(warmthLevel),
      inLaundry: Value(inLaundry),
      lastWornDate:
          lastWornDate == null && nullToAbsent
              ? const Value.absent()
              : Value(lastWornDate),
      wearCount: Value(wearCount),
      dateAdded: Value(dateAdded),
    );
  }

  factory ClothingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingItem(
      id: serializer.fromJson<int>(json['id']),
      category: $ClothingItemsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      bodyZone: $ClothingItemsTable.$converterbodyZone.fromJson(
        serializer.fromJson<int>(json['bodyZone']),
      ),
      name: serializer.fromJson<String?>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      fit: $ClothingItemsTable.$converterfit.fromJson(
        serializer.fromJson<int>(json['fit']),
      ),
      photo: serializer.fromJson<String>(json['photo']),
      photos: serializer.fromJson<String?>(json['photos']),
      homeOnly: serializer.fromJson<bool>(json['homeOnly']),
      warmthLevel: serializer.fromJson<int>(json['warmthLevel']),
      inLaundry: serializer.fromJson<bool>(json['inLaundry']),
      lastWornDate: serializer.fromJson<DateTime?>(json['lastWornDate']),
      wearCount: serializer.fromJson<int>(json['wearCount']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<int>(
        $ClothingItemsTable.$convertercategory.toJson(category),
      ),
      'bodyZone': serializer.toJson<int>(
        $ClothingItemsTable.$converterbodyZone.toJson(bodyZone),
      ),
      'name': serializer.toJson<String?>(name),
      'color': serializer.toJson<String?>(color),
      'fit': serializer.toJson<int>(
        $ClothingItemsTable.$converterfit.toJson(fit),
      ),
      'photo': serializer.toJson<String>(photo),
      'photos': serializer.toJson<String?>(photos),
      'homeOnly': serializer.toJson<bool>(homeOnly),
      'warmthLevel': serializer.toJson<int>(warmthLevel),
      'inLaundry': serializer.toJson<bool>(inLaundry),
      'lastWornDate': serializer.toJson<DateTime?>(lastWornDate),
      'wearCount': serializer.toJson<int>(wearCount),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  ClothingItem copyWith({
    int? id,
    ItemCategory? category,
    BodyZone? bodyZone,
    Value<String?> name = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Fit? fit,
    String? photo,
    Value<String?> photos = const Value.absent(),
    bool? homeOnly,
    int? warmthLevel,
    bool? inLaundry,
    Value<DateTime?> lastWornDate = const Value.absent(),
    int? wearCount,
    DateTime? dateAdded,
  }) => ClothingItem(
    id: id ?? this.id,
    category: category ?? this.category,
    bodyZone: bodyZone ?? this.bodyZone,
    name: name.present ? name.value : this.name,
    color: color.present ? color.value : this.color,
    fit: fit ?? this.fit,
    photo: photo ?? this.photo,
    photos: photos.present ? photos.value : this.photos,
    homeOnly: homeOnly ?? this.homeOnly,
    warmthLevel: warmthLevel ?? this.warmthLevel,
    inLaundry: inLaundry ?? this.inLaundry,
    lastWornDate: lastWornDate.present ? lastWornDate.value : this.lastWornDate,
    wearCount: wearCount ?? this.wearCount,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  ClothingItem copyWithCompanion(ClothingItemsCompanion data) {
    return ClothingItem(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      bodyZone: data.bodyZone.present ? data.bodyZone.value : this.bodyZone,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      fit: data.fit.present ? data.fit.value : this.fit,
      photo: data.photo.present ? data.photo.value : this.photo,
      photos: data.photos.present ? data.photos.value : this.photos,
      homeOnly: data.homeOnly.present ? data.homeOnly.value : this.homeOnly,
      warmthLevel:
          data.warmthLevel.present ? data.warmthLevel.value : this.warmthLevel,
      inLaundry: data.inLaundry.present ? data.inLaundry.value : this.inLaundry,
      lastWornDate:
          data.lastWornDate.present
              ? data.lastWornDate.value
              : this.lastWornDate,
      wearCount: data.wearCount.present ? data.wearCount.value : this.wearCount,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItem(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('bodyZone: $bodyZone, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('fit: $fit, ')
          ..write('photo: $photo, ')
          ..write('photos: $photos, ')
          ..write('homeOnly: $homeOnly, ')
          ..write('warmthLevel: $warmthLevel, ')
          ..write('inLaundry: $inLaundry, ')
          ..write('lastWornDate: $lastWornDate, ')
          ..write('wearCount: $wearCount, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    bodyZone,
    name,
    color,
    fit,
    photo,
    photos,
    homeOnly,
    warmthLevel,
    inLaundry,
    lastWornDate,
    wearCount,
    dateAdded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingItem &&
          other.id == this.id &&
          other.category == this.category &&
          other.bodyZone == this.bodyZone &&
          other.name == this.name &&
          other.color == this.color &&
          other.fit == this.fit &&
          other.photo == this.photo &&
          other.photos == this.photos &&
          other.homeOnly == this.homeOnly &&
          other.warmthLevel == this.warmthLevel &&
          other.inLaundry == this.inLaundry &&
          other.lastWornDate == this.lastWornDate &&
          other.wearCount == this.wearCount &&
          other.dateAdded == this.dateAdded);
}

class ClothingItemsCompanion extends UpdateCompanion<ClothingItem> {
  final Value<int> id;
  final Value<ItemCategory> category;
  final Value<BodyZone> bodyZone;
  final Value<String?> name;
  final Value<String?> color;
  final Value<Fit> fit;
  final Value<String> photo;
  final Value<String?> photos;
  final Value<bool> homeOnly;
  final Value<int> warmthLevel;
  final Value<bool> inLaundry;
  final Value<DateTime?> lastWornDate;
  final Value<int> wearCount;
  final Value<DateTime> dateAdded;
  const ClothingItemsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.bodyZone = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.fit = const Value.absent(),
    this.photo = const Value.absent(),
    this.photos = const Value.absent(),
    this.homeOnly = const Value.absent(),
    this.warmthLevel = const Value.absent(),
    this.inLaundry = const Value.absent(),
    this.lastWornDate = const Value.absent(),
    this.wearCount = const Value.absent(),
    this.dateAdded = const Value.absent(),
  });
  ClothingItemsCompanion.insert({
    this.id = const Value.absent(),
    required ItemCategory category,
    required BodyZone bodyZone,
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    required Fit fit,
    required String photo,
    this.photos = const Value.absent(),
    this.homeOnly = const Value.absent(),
    this.warmthLevel = const Value.absent(),
    this.inLaundry = const Value.absent(),
    this.lastWornDate = const Value.absent(),
    this.wearCount = const Value.absent(),
    this.dateAdded = const Value.absent(),
  }) : category = Value(category),
       bodyZone = Value(bodyZone),
       fit = Value(fit),
       photo = Value(photo);
  static Insertable<ClothingItem> custom({
    Expression<int>? id,
    Expression<int>? category,
    Expression<int>? bodyZone,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? fit,
    Expression<String>? photo,
    Expression<String>? photos,
    Expression<bool>? homeOnly,
    Expression<int>? warmthLevel,
    Expression<bool>? inLaundry,
    Expression<DateTime>? lastWornDate,
    Expression<int>? wearCount,
    Expression<DateTime>? dateAdded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (bodyZone != null) 'body_zone': bodyZone,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (fit != null) 'fit': fit,
      if (photo != null) 'photo': photo,
      if (photos != null) 'photos': photos,
      if (homeOnly != null) 'home_only': homeOnly,
      if (warmthLevel != null) 'warmth_level': warmthLevel,
      if (inLaundry != null) 'in_laundry': inLaundry,
      if (lastWornDate != null) 'last_worn_date': lastWornDate,
      if (wearCount != null) 'wear_count': wearCount,
      if (dateAdded != null) 'date_added': dateAdded,
    });
  }

  ClothingItemsCompanion copyWith({
    Value<int>? id,
    Value<ItemCategory>? category,
    Value<BodyZone>? bodyZone,
    Value<String?>? name,
    Value<String?>? color,
    Value<Fit>? fit,
    Value<String>? photo,
    Value<String?>? photos,
    Value<bool>? homeOnly,
    Value<int>? warmthLevel,
    Value<bool>? inLaundry,
    Value<DateTime?>? lastWornDate,
    Value<int>? wearCount,
    Value<DateTime>? dateAdded,
  }) {
    return ClothingItemsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      bodyZone: bodyZone ?? this.bodyZone,
      name: name ?? this.name,
      color: color ?? this.color,
      fit: fit ?? this.fit,
      photo: photo ?? this.photo,
      photos: photos ?? this.photos,
      homeOnly: homeOnly ?? this.homeOnly,
      warmthLevel: warmthLevel ?? this.warmthLevel,
      inLaundry: inLaundry ?? this.inLaundry,
      lastWornDate: lastWornDate ?? this.lastWornDate,
      wearCount: wearCount ?? this.wearCount,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $ClothingItemsTable.$convertercategory.toSql(category.value),
      );
    }
    if (bodyZone.present) {
      map['body_zone'] = Variable<int>(
        $ClothingItemsTable.$converterbodyZone.toSql(bodyZone.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (fit.present) {
      map['fit'] = Variable<int>(
        $ClothingItemsTable.$converterfit.toSql(fit.value),
      );
    }
    if (photo.present) {
      map['photo'] = Variable<String>(photo.value);
    }
    if (photos.present) {
      map['photos'] = Variable<String>(photos.value);
    }
    if (homeOnly.present) {
      map['home_only'] = Variable<bool>(homeOnly.value);
    }
    if (warmthLevel.present) {
      map['warmth_level'] = Variable<int>(warmthLevel.value);
    }
    if (inLaundry.present) {
      map['in_laundry'] = Variable<bool>(inLaundry.value);
    }
    if (lastWornDate.present) {
      map['last_worn_date'] = Variable<DateTime>(lastWornDate.value);
    }
    if (wearCount.present) {
      map['wear_count'] = Variable<int>(wearCount.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('bodyZone: $bodyZone, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('fit: $fit, ')
          ..write('photo: $photo, ')
          ..write('photos: $photos, ')
          ..write('homeOnly: $homeOnly, ')
          ..write('warmthLevel: $warmthLevel, ')
          ..write('inLaundry: $inLaundry, ')
          ..write('lastWornDate: $lastWornDate, ')
          ..write('wearCount: $wearCount, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }
}

class $OutfitLogsTable extends OutfitLogs
    with TableInfo<$OutfitLogsTable, OutfitLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutfitLogsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
    'items',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vibeTagMeta = const VerificationMeta(
    'vibeTag',
  );
  @override
  late final GeneratedColumn<String> vibeTag = GeneratedColumn<String>(
    'vibe_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weatherSnapshotMeta = const VerificationMeta(
    'weatherSnapshot',
  );
  @override
  late final GeneratedColumn<String> weatherSnapshot = GeneratedColumn<String>(
    'weather_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasAiSuggestedMeta = const VerificationMeta(
    'wasAiSuggested',
  );
  @override
  late final GeneratedColumn<bool> wasAiSuggested = GeneratedColumn<bool>(
    'was_ai_suggested',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_ai_suggested" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    items,
    destination,
    vibeTag,
    weatherSnapshot,
    wasAiSuggested,
    rating,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outfit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutfitLog> instance, {
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
    if (data.containsKey('items')) {
      context.handle(
        _itemsMeta,
        items.isAcceptableOrUnknown(data['items']!, _itemsMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('vibe_tag')) {
      context.handle(
        _vibeTagMeta,
        vibeTag.isAcceptableOrUnknown(data['vibe_tag']!, _vibeTagMeta),
      );
    }
    if (data.containsKey('weather_snapshot')) {
      context.handle(
        _weatherSnapshotMeta,
        weatherSnapshot.isAcceptableOrUnknown(
          data['weather_snapshot']!,
          _weatherSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('was_ai_suggested')) {
      context.handle(
        _wasAiSuggestedMeta,
        wasAiSuggested.isAcceptableOrUnknown(
          data['was_ai_suggested']!,
          _wasAiSuggestedMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutfitLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutfitLog(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      date:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}date'],
          )!,
      items:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}items'],
          )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      vibeTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vibe_tag'],
      ),
      weatherSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather_snapshot'],
      ),
      wasAiSuggested:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}was_ai_suggested'],
          )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
    );
  }

  @override
  $OutfitLogsTable createAlias(String alias) {
    return $OutfitLogsTable(attachedDatabase, alias);
  }
}

class OutfitLog extends DataClass implements Insertable<OutfitLog> {
  final int id;
  final DateTime date;
  final String items;
  final String? destination;
  final String? vibeTag;
  final String? weatherSnapshot;
  final bool wasAiSuggested;

  /// Optional user rating (1-5). Used by the recommendation engine to learn
  /// which items appear in outfits the user actually liked.
  final int? rating;
  const OutfitLog({
    required this.id,
    required this.date,
    required this.items,
    this.destination,
    this.vibeTag,
    this.weatherSnapshot,
    required this.wasAiSuggested,
    this.rating,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['items'] = Variable<String>(items);
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || vibeTag != null) {
      map['vibe_tag'] = Variable<String>(vibeTag);
    }
    if (!nullToAbsent || weatherSnapshot != null) {
      map['weather_snapshot'] = Variable<String>(weatherSnapshot);
    }
    map['was_ai_suggested'] = Variable<bool>(wasAiSuggested);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    return map;
  }

  OutfitLogsCompanion toCompanion(bool nullToAbsent) {
    return OutfitLogsCompanion(
      id: Value(id),
      date: Value(date),
      items: Value(items),
      destination:
          destination == null && nullToAbsent
              ? const Value.absent()
              : Value(destination),
      vibeTag:
          vibeTag == null && nullToAbsent
              ? const Value.absent()
              : Value(vibeTag),
      weatherSnapshot:
          weatherSnapshot == null && nullToAbsent
              ? const Value.absent()
              : Value(weatherSnapshot),
      wasAiSuggested: Value(wasAiSuggested),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
    );
  }

  factory OutfitLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutfitLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      items: serializer.fromJson<String>(json['items']),
      destination: serializer.fromJson<String?>(json['destination']),
      vibeTag: serializer.fromJson<String?>(json['vibeTag']),
      weatherSnapshot: serializer.fromJson<String?>(json['weatherSnapshot']),
      wasAiSuggested: serializer.fromJson<bool>(json['wasAiSuggested']),
      rating: serializer.fromJson<int?>(json['rating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'items': serializer.toJson<String>(items),
      'destination': serializer.toJson<String?>(destination),
      'vibeTag': serializer.toJson<String?>(vibeTag),
      'weatherSnapshot': serializer.toJson<String?>(weatherSnapshot),
      'wasAiSuggested': serializer.toJson<bool>(wasAiSuggested),
      'rating': serializer.toJson<int?>(rating),
    };
  }

  OutfitLog copyWith({
    int? id,
    DateTime? date,
    String? items,
    Value<String?> destination = const Value.absent(),
    Value<String?> vibeTag = const Value.absent(),
    Value<String?> weatherSnapshot = const Value.absent(),
    bool? wasAiSuggested,
    Value<int?> rating = const Value.absent(),
  }) => OutfitLog(
    id: id ?? this.id,
    date: date ?? this.date,
    items: items ?? this.items,
    destination: destination.present ? destination.value : this.destination,
    vibeTag: vibeTag.present ? vibeTag.value : this.vibeTag,
    weatherSnapshot:
        weatherSnapshot.present ? weatherSnapshot.value : this.weatherSnapshot,
    wasAiSuggested: wasAiSuggested ?? this.wasAiSuggested,
    rating: rating.present ? rating.value : this.rating,
  );
  OutfitLog copyWithCompanion(OutfitLogsCompanion data) {
    return OutfitLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      items: data.items.present ? data.items.value : this.items,
      destination:
          data.destination.present ? data.destination.value : this.destination,
      vibeTag: data.vibeTag.present ? data.vibeTag.value : this.vibeTag,
      weatherSnapshot:
          data.weatherSnapshot.present
              ? data.weatherSnapshot.value
              : this.weatherSnapshot,
      wasAiSuggested:
          data.wasAiSuggested.present
              ? data.wasAiSuggested.value
              : this.wasAiSuggested,
      rating: data.rating.present ? data.rating.value : this.rating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutfitLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('items: $items, ')
          ..write('destination: $destination, ')
          ..write('vibeTag: $vibeTag, ')
          ..write('weatherSnapshot: $weatherSnapshot, ')
          ..write('wasAiSuggested: $wasAiSuggested, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    items,
    destination,
    vibeTag,
    weatherSnapshot,
    wasAiSuggested,
    rating,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutfitLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.items == this.items &&
          other.destination == this.destination &&
          other.vibeTag == this.vibeTag &&
          other.weatherSnapshot == this.weatherSnapshot &&
          other.wasAiSuggested == this.wasAiSuggested &&
          other.rating == this.rating);
}

class OutfitLogsCompanion extends UpdateCompanion<OutfitLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> items;
  final Value<String?> destination;
  final Value<String?> vibeTag;
  final Value<String?> weatherSnapshot;
  final Value<bool> wasAiSuggested;
  final Value<int?> rating;
  const OutfitLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.items = const Value.absent(),
    this.destination = const Value.absent(),
    this.vibeTag = const Value.absent(),
    this.weatherSnapshot = const Value.absent(),
    this.wasAiSuggested = const Value.absent(),
    this.rating = const Value.absent(),
  });
  OutfitLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String items,
    this.destination = const Value.absent(),
    this.vibeTag = const Value.absent(),
    this.weatherSnapshot = const Value.absent(),
    this.wasAiSuggested = const Value.absent(),
    this.rating = const Value.absent(),
  }) : date = Value(date),
       items = Value(items);
  static Insertable<OutfitLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? items,
    Expression<String>? destination,
    Expression<String>? vibeTag,
    Expression<String>? weatherSnapshot,
    Expression<bool>? wasAiSuggested,
    Expression<int>? rating,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (items != null) 'items': items,
      if (destination != null) 'destination': destination,
      if (vibeTag != null) 'vibe_tag': vibeTag,
      if (weatherSnapshot != null) 'weather_snapshot': weatherSnapshot,
      if (wasAiSuggested != null) 'was_ai_suggested': wasAiSuggested,
      if (rating != null) 'rating': rating,
    });
  }

  OutfitLogsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? items,
    Value<String?>? destination,
    Value<String?>? vibeTag,
    Value<String?>? weatherSnapshot,
    Value<bool>? wasAiSuggested,
    Value<int?>? rating,
  }) {
    return OutfitLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      destination: destination ?? this.destination,
      vibeTag: vibeTag ?? this.vibeTag,
      weatherSnapshot: weatherSnapshot ?? this.weatherSnapshot,
      wasAiSuggested: wasAiSuggested ?? this.wasAiSuggested,
      rating: rating ?? this.rating,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (vibeTag.present) {
      map['vibe_tag'] = Variable<String>(vibeTag.value);
    }
    if (weatherSnapshot.present) {
      map['weather_snapshot'] = Variable<String>(weatherSnapshot.value);
    }
    if (wasAiSuggested.present) {
      map['was_ai_suggested'] = Variable<bool>(wasAiSuggested.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutfitLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('items: $items, ')
          ..write('destination: $destination, ')
          ..write('vibeTag: $vibeTag, ')
          ..write('weatherSnapshot: $weatherSnapshot, ')
          ..write('wasAiSuggested: $wasAiSuggested, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClothingItemsTable clothingItems = $ClothingItemsTable(this);
  late final $OutfitLogsTable outfitLogs = $OutfitLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clothingItems,
    outfitLogs,
  ];
}

typedef $$ClothingItemsTableCreateCompanionBuilder =
    ClothingItemsCompanion Function({
      Value<int> id,
      required ItemCategory category,
      required BodyZone bodyZone,
      Value<String?> name,
      Value<String?> color,
      required Fit fit,
      required String photo,
      Value<String?> photos,
      Value<bool> homeOnly,
      Value<int> warmthLevel,
      Value<bool> inLaundry,
      Value<DateTime?> lastWornDate,
      Value<int> wearCount,
      Value<DateTime> dateAdded,
    });
typedef $$ClothingItemsTableUpdateCompanionBuilder =
    ClothingItemsCompanion Function({
      Value<int> id,
      Value<ItemCategory> category,
      Value<BodyZone> bodyZone,
      Value<String?> name,
      Value<String?> color,
      Value<Fit> fit,
      Value<String> photo,
      Value<String?> photos,
      Value<bool> homeOnly,
      Value<int> warmthLevel,
      Value<bool> inLaundry,
      Value<DateTime?> lastWornDate,
      Value<int> wearCount,
      Value<DateTime> dateAdded,
    });

class $$ClothingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ItemCategory, ItemCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<BodyZone, BodyZone, int> get bodyZone =>
      $composableBuilder(
        column: $table.bodyZone,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Fit, Fit, int> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photos => $composableBuilder(
    column: $table.photos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get homeOnly => $composableBuilder(
    column: $table.homeOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warmthLevel => $composableBuilder(
    column: $table.warmthLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inLaundry => $composableBuilder(
    column: $table.inLaundry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWornDate => $composableBuilder(
    column: $table.lastWornDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearCount => $composableBuilder(
    column: $table.wearCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClothingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableOrderingComposer({
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

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bodyZone => $composableBuilder(
    column: $table.bodyZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fit => $composableBuilder(
    column: $table.fit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photos => $composableBuilder(
    column: $table.photos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get homeOnly => $composableBuilder(
    column: $table.homeOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warmthLevel => $composableBuilder(
    column: $table.warmthLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inLaundry => $composableBuilder(
    column: $table.inLaundry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWornDate => $composableBuilder(
    column: $table.lastWornDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearCount => $composableBuilder(
    column: $table.wearCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClothingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BodyZone, int> get bodyZone =>
      $composableBuilder(column: $table.bodyZone, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Fit, int> get fit =>
      $composableBuilder(column: $table.fit, builder: (column) => column);

  GeneratedColumn<String> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);

  GeneratedColumn<String> get photos =>
      $composableBuilder(column: $table.photos, builder: (column) => column);

  GeneratedColumn<bool> get homeOnly =>
      $composableBuilder(column: $table.homeOnly, builder: (column) => column);

  GeneratedColumn<int> get warmthLevel => $composableBuilder(
    column: $table.warmthLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get inLaundry =>
      $composableBuilder(column: $table.inLaundry, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWornDate => $composableBuilder(
    column: $table.lastWornDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wearCount =>
      $composableBuilder(column: $table.wearCount, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);
}

class $$ClothingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingItemsTable,
          ClothingItem,
          $$ClothingItemsTableFilterComposer,
          $$ClothingItemsTableOrderingComposer,
          $$ClothingItemsTableAnnotationComposer,
          $$ClothingItemsTableCreateCompanionBuilder,
          $$ClothingItemsTableUpdateCompanionBuilder,
          (
            ClothingItem,
            BaseReferences<_$AppDatabase, $ClothingItemsTable, ClothingItem>,
          ),
          ClothingItem,
          PrefetchHooks Function()
        > {
  $$ClothingItemsTableTableManager(_$AppDatabase db, $ClothingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ClothingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$ClothingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ClothingItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<ItemCategory> category = const Value.absent(),
                Value<BodyZone> bodyZone = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<Fit> fit = const Value.absent(),
                Value<String> photo = const Value.absent(),
                Value<String?> photos = const Value.absent(),
                Value<bool> homeOnly = const Value.absent(),
                Value<int> warmthLevel = const Value.absent(),
                Value<bool> inLaundry = const Value.absent(),
                Value<DateTime?> lastWornDate = const Value.absent(),
                Value<int> wearCount = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => ClothingItemsCompanion(
                id: id,
                category: category,
                bodyZone: bodyZone,
                name: name,
                color: color,
                fit: fit,
                photo: photo,
                photos: photos,
                homeOnly: homeOnly,
                warmthLevel: warmthLevel,
                inLaundry: inLaundry,
                lastWornDate: lastWornDate,
                wearCount: wearCount,
                dateAdded: dateAdded,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required ItemCategory category,
                required BodyZone bodyZone,
                Value<String?> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                required Fit fit,
                required String photo,
                Value<String?> photos = const Value.absent(),
                Value<bool> homeOnly = const Value.absent(),
                Value<int> warmthLevel = const Value.absent(),
                Value<bool> inLaundry = const Value.absent(),
                Value<DateTime?> lastWornDate = const Value.absent(),
                Value<int> wearCount = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
              }) => ClothingItemsCompanion.insert(
                id: id,
                category: category,
                bodyZone: bodyZone,
                name: name,
                color: color,
                fit: fit,
                photo: photo,
                photos: photos,
                homeOnly: homeOnly,
                warmthLevel: warmthLevel,
                inLaundry: inLaundry,
                lastWornDate: lastWornDate,
                wearCount: wearCount,
                dateAdded: dateAdded,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClothingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingItemsTable,
      ClothingItem,
      $$ClothingItemsTableFilterComposer,
      $$ClothingItemsTableOrderingComposer,
      $$ClothingItemsTableAnnotationComposer,
      $$ClothingItemsTableCreateCompanionBuilder,
      $$ClothingItemsTableUpdateCompanionBuilder,
      (
        ClothingItem,
        BaseReferences<_$AppDatabase, $ClothingItemsTable, ClothingItem>,
      ),
      ClothingItem,
      PrefetchHooks Function()
    >;
typedef $$OutfitLogsTableCreateCompanionBuilder =
    OutfitLogsCompanion Function({
      Value<int> id,
      required DateTime date,
      required String items,
      Value<String?> destination,
      Value<String?> vibeTag,
      Value<String?> weatherSnapshot,
      Value<bool> wasAiSuggested,
      Value<int?> rating,
    });
typedef $$OutfitLogsTableUpdateCompanionBuilder =
    OutfitLogsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> items,
      Value<String?> destination,
      Value<String?> vibeTag,
      Value<String?> weatherSnapshot,
      Value<bool> wasAiSuggested,
      Value<int?> rating,
    });

class $$OutfitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $OutfitLogsTable> {
  $$OutfitLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vibeTag => $composableBuilder(
    column: $table.vibeTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weatherSnapshot => $composableBuilder(
    column: $table.weatherSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasAiSuggested => $composableBuilder(
    column: $table.wasAiSuggested,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutfitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutfitLogsTable> {
  $$OutfitLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vibeTag => $composableBuilder(
    column: $table.vibeTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weatherSnapshot => $composableBuilder(
    column: $table.weatherSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasAiSuggested => $composableBuilder(
    column: $table.wasAiSuggested,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutfitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutfitLogsTable> {
  $$OutfitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vibeTag =>
      $composableBuilder(column: $table.vibeTag, builder: (column) => column);

  GeneratedColumn<String> get weatherSnapshot => $composableBuilder(
    column: $table.weatherSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasAiSuggested => $composableBuilder(
    column: $table.wasAiSuggested,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);
}

class $$OutfitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutfitLogsTable,
          OutfitLog,
          $$OutfitLogsTableFilterComposer,
          $$OutfitLogsTableOrderingComposer,
          $$OutfitLogsTableAnnotationComposer,
          $$OutfitLogsTableCreateCompanionBuilder,
          $$OutfitLogsTableUpdateCompanionBuilder,
          (
            OutfitLog,
            BaseReferences<_$AppDatabase, $OutfitLogsTable, OutfitLog>,
          ),
          OutfitLog,
          PrefetchHooks Function()
        > {
  $$OutfitLogsTableTableManager(_$AppDatabase db, $OutfitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$OutfitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OutfitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$OutfitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> items = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> vibeTag = const Value.absent(),
                Value<String?> weatherSnapshot = const Value.absent(),
                Value<bool> wasAiSuggested = const Value.absent(),
                Value<int?> rating = const Value.absent(),
              }) => OutfitLogsCompanion(
                id: id,
                date: date,
                items: items,
                destination: destination,
                vibeTag: vibeTag,
                weatherSnapshot: weatherSnapshot,
                wasAiSuggested: wasAiSuggested,
                rating: rating,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String items,
                Value<String?> destination = const Value.absent(),
                Value<String?> vibeTag = const Value.absent(),
                Value<String?> weatherSnapshot = const Value.absent(),
                Value<bool> wasAiSuggested = const Value.absent(),
                Value<int?> rating = const Value.absent(),
              }) => OutfitLogsCompanion.insert(
                id: id,
                date: date,
                items: items,
                destination: destination,
                vibeTag: vibeTag,
                weatherSnapshot: weatherSnapshot,
                wasAiSuggested: wasAiSuggested,
                rating: rating,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutfitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutfitLogsTable,
      OutfitLog,
      $$OutfitLogsTableFilterComposer,
      $$OutfitLogsTableOrderingComposer,
      $$OutfitLogsTableAnnotationComposer,
      $$OutfitLogsTableCreateCompanionBuilder,
      $$OutfitLogsTableUpdateCompanionBuilder,
      (OutfitLog, BaseReferences<_$AppDatabase, $OutfitLogsTable, OutfitLog>),
      OutfitLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClothingItemsTableTableManager get clothingItems =>
      $$ClothingItemsTableTableManager(_db, _db.clothingItems);
  $$OutfitLogsTableTableManager get outfitLogs =>
      $$OutfitLogsTableTableManager(_db, _db.outfitLogs);
}
