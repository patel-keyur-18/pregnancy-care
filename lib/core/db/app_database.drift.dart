// dart format width=80
// ignore_for_file: type=lint
part of 'app_database.dart';

class $PregnanciesTable extends Pregnancies
    with TableInfo<$PregnanciesTable, Pregnancy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PregnanciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    clientDefault: DateTime.now,
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
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PregnancyStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PregnancyStatus>($PregnanciesTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DatingMethod, String>
  datingMethod = GeneratedColumn<String>(
    'dating_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DatingMethod>($PregnanciesTable.$converterdatingMethod);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> lmp =
      GeneratedColumn<String>(
        'lmp',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PregnanciesTable.$converterlmpn);
  static const VerificationMeta _cycleLengthMeta = const VerificationMeta(
    'cycleLength',
  );
  @override
  late final GeneratedColumn<int> cycleLength = GeneratedColumn<int>(
    'cycle_length',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> anchorDate =
      GeneratedColumn<String>(
        'anchor_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PregnanciesTable.$converteranchorDaten);
  static const VerificationMeta _embryoDayMeta = const VerificationMeta(
    'embryoDay',
  );
  @override
  late final GeneratedColumn<int> embryoDay = GeneratedColumn<int>(
    'embryo_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PregnanciesTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> dueDate =
      GeneratedColumn<String>(
        'due_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PregnanciesTable.$converterdueDate);
  static const VerificationMeta _twinsMeta = const VerificationMeta('twins');
  @override
  late final GeneratedColumn<bool> twins = GeneratedColumn<bool>(
    'twins',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("twins" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _highRiskMeta = const VerificationMeta(
    'highRisk',
  );
  @override
  late final GeneratedColumn<bool> highRisk = GeneratedColumn<bool>(
    'high_risk',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("high_risk" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exerciseClearedMeta = const VerificationMeta(
    'exerciseCleared',
  );
  @override
  late final GeneratedColumn<bool> exerciseCleared = GeneratedColumn<bool>(
    'exercise_cleared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exercise_cleared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    status,
    datingMethod,
    lmp,
    cycleLength,
    anchorDate,
    embryoDay,
    startDate,
    dueDate,
    twins,
    highRisk,
    exerciseCleared,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pregnancy';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pregnancy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('cycle_length')) {
      context.handle(
        _cycleLengthMeta,
        cycleLength.isAcceptableOrUnknown(
          data['cycle_length']!,
          _cycleLengthMeta,
        ),
      );
    }
    if (data.containsKey('embryo_day')) {
      context.handle(
        _embryoDayMeta,
        embryoDay.isAcceptableOrUnknown(data['embryo_day']!, _embryoDayMeta),
      );
    }
    if (data.containsKey('twins')) {
      context.handle(
        _twinsMeta,
        twins.isAcceptableOrUnknown(data['twins']!, _twinsMeta),
      );
    }
    if (data.containsKey('high_risk')) {
      context.handle(
        _highRiskMeta,
        highRisk.isAcceptableOrUnknown(data['high_risk']!, _highRiskMeta),
      );
    }
    if (data.containsKey('exercise_cleared')) {
      context.handle(
        _exerciseClearedMeta,
        exerciseCleared.isAcceptableOrUnknown(
          data['exercise_cleared']!,
          _exerciseClearedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pregnancy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pregnancy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      status: $PregnanciesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      datingMethod: $PregnanciesTable.$converterdatingMethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dating_method'],
        )!,
      ),
      lmp: $PregnanciesTable.$converterlmpn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}lmp'],
        ),
      ),
      cycleLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_length'],
      ),
      anchorDate: $PregnanciesTable.$converteranchorDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}anchor_date'],
        ),
      ),
      embryoDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}embryo_day'],
      ),
      startDate: $PregnanciesTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      dueDate: $PregnanciesTable.$converterdueDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}due_date'],
        )!,
      ),
      twins: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}twins'],
      )!,
      highRisk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}high_risk'],
      )!,
      exerciseCleared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exercise_cleared'],
      )!,
    );
  }

  @override
  $PregnanciesTable createAlias(String alias) {
    return $PregnanciesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PregnancyStatus, String, String> $converterstatus =
      const EnumNameConverter<PregnancyStatus>(PregnancyStatus.values);
  static JsonTypeConverter2<DatingMethod, String, String>
  $converterdatingMethod = const EnumNameConverter<DatingMethod>(
    DatingMethod.values,
  );
  static TypeConverter<DateTime, String> $converterlmp =
      const DateOnlyConverter();
  static TypeConverter<DateTime?, String?> $converterlmpn =
      NullAwareTypeConverter.wrap($converterlmp);
  static TypeConverter<DateTime, String> $converteranchorDate =
      const DateOnlyConverter();
  static TypeConverter<DateTime?, String?> $converteranchorDaten =
      NullAwareTypeConverter.wrap($converteranchorDate);
  static TypeConverter<DateTime, String> $converterstartDate =
      const DateOnlyConverter();
  static TypeConverter<DateTime, String> $converterdueDate =
      const DateOnlyConverter();
}

class Pregnancy extends DataClass implements Insertable<Pregnancy> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final PregnancyStatus status;
  final DatingMethod datingMethod;
  final DateTime? lmp;
  final int? cycleLength;

  /// Conception date, IVF transfer date or scan due date.
  final DateTime? anchorDate;
  final int? embryoDay;
  final DateTime startDate;
  final DateTime dueDate;
  final bool twins;
  final bool highRisk;
  final bool exerciseCleared;
  const Pregnancy({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.status,
    required this.datingMethod,
    this.lmp,
    this.cycleLength,
    this.anchorDate,
    this.embryoDay,
    required this.startDate,
    required this.dueDate,
    required this.twins,
    required this.highRisk,
    required this.exerciseCleared,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    {
      map['status'] = Variable<String>(
        $PregnanciesTable.$converterstatus.toSql(status),
      );
    }
    {
      map['dating_method'] = Variable<String>(
        $PregnanciesTable.$converterdatingMethod.toSql(datingMethod),
      );
    }
    if (!nullToAbsent || lmp != null) {
      map['lmp'] = Variable<String>(
        $PregnanciesTable.$converterlmpn.toSql(lmp),
      );
    }
    if (!nullToAbsent || cycleLength != null) {
      map['cycle_length'] = Variable<int>(cycleLength);
    }
    if (!nullToAbsent || anchorDate != null) {
      map['anchor_date'] = Variable<String>(
        $PregnanciesTable.$converteranchorDaten.toSql(anchorDate),
      );
    }
    if (!nullToAbsent || embryoDay != null) {
      map['embryo_day'] = Variable<int>(embryoDay);
    }
    {
      map['start_date'] = Variable<String>(
        $PregnanciesTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['due_date'] = Variable<String>(
        $PregnanciesTable.$converterdueDate.toSql(dueDate),
      );
    }
    map['twins'] = Variable<bool>(twins);
    map['high_risk'] = Variable<bool>(highRisk);
    map['exercise_cleared'] = Variable<bool>(exerciseCleared);
    return map;
  }

  PregnanciesCompanion toCompanion(bool nullToAbsent) {
    return PregnanciesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      status: Value(status),
      datingMethod: Value(datingMethod),
      lmp: lmp == null && nullToAbsent ? const Value.absent() : Value(lmp),
      cycleLength: cycleLength == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleLength),
      anchorDate: anchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorDate),
      embryoDay: embryoDay == null && nullToAbsent
          ? const Value.absent()
          : Value(embryoDay),
      startDate: Value(startDate),
      dueDate: Value(dueDate),
      twins: Value(twins),
      highRisk: Value(highRisk),
      exerciseCleared: Value(exerciseCleared),
    );
  }

  factory Pregnancy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pregnancy(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      status: $PregnanciesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      datingMethod: $PregnanciesTable.$converterdatingMethod.fromJson(
        serializer.fromJson<String>(json['datingMethod']),
      ),
      lmp: serializer.fromJson<DateTime?>(json['lmp']),
      cycleLength: serializer.fromJson<int?>(json['cycleLength']),
      anchorDate: serializer.fromJson<DateTime?>(json['anchorDate']),
      embryoDay: serializer.fromJson<int?>(json['embryoDay']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      twins: serializer.fromJson<bool>(json['twins']),
      highRisk: serializer.fromJson<bool>(json['highRisk']),
      exerciseCleared: serializer.fromJson<bool>(json['exerciseCleared']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'status': serializer.toJson<String>(
        $PregnanciesTable.$converterstatus.toJson(status),
      ),
      'datingMethod': serializer.toJson<String>(
        $PregnanciesTable.$converterdatingMethod.toJson(datingMethod),
      ),
      'lmp': serializer.toJson<DateTime?>(lmp),
      'cycleLength': serializer.toJson<int?>(cycleLength),
      'anchorDate': serializer.toJson<DateTime?>(anchorDate),
      'embryoDay': serializer.toJson<int?>(embryoDay),
      'startDate': serializer.toJson<DateTime>(startDate),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'twins': serializer.toJson<bool>(twins),
      'highRisk': serializer.toJson<bool>(highRisk),
      'exerciseCleared': serializer.toJson<bool>(exerciseCleared),
    };
  }

  Pregnancy copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    PregnancyStatus? status,
    DatingMethod? datingMethod,
    Value<DateTime?> lmp = const Value.absent(),
    Value<int?> cycleLength = const Value.absent(),
    Value<DateTime?> anchorDate = const Value.absent(),
    Value<int?> embryoDay = const Value.absent(),
    DateTime? startDate,
    DateTime? dueDate,
    bool? twins,
    bool? highRisk,
    bool? exerciseCleared,
  }) => Pregnancy(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    status: status ?? this.status,
    datingMethod: datingMethod ?? this.datingMethod,
    lmp: lmp.present ? lmp.value : this.lmp,
    cycleLength: cycleLength.present ? cycleLength.value : this.cycleLength,
    anchorDate: anchorDate.present ? anchorDate.value : this.anchorDate,
    embryoDay: embryoDay.present ? embryoDay.value : this.embryoDay,
    startDate: startDate ?? this.startDate,
    dueDate: dueDate ?? this.dueDate,
    twins: twins ?? this.twins,
    highRisk: highRisk ?? this.highRisk,
    exerciseCleared: exerciseCleared ?? this.exerciseCleared,
  );
  Pregnancy copyWithCompanion(PregnanciesCompanion data) {
    return Pregnancy(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      status: data.status.present ? data.status.value : this.status,
      datingMethod: data.datingMethod.present
          ? data.datingMethod.value
          : this.datingMethod,
      lmp: data.lmp.present ? data.lmp.value : this.lmp,
      cycleLength: data.cycleLength.present
          ? data.cycleLength.value
          : this.cycleLength,
      anchorDate: data.anchorDate.present
          ? data.anchorDate.value
          : this.anchorDate,
      embryoDay: data.embryoDay.present ? data.embryoDay.value : this.embryoDay,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      twins: data.twins.present ? data.twins.value : this.twins,
      highRisk: data.highRisk.present ? data.highRisk.value : this.highRisk,
      exerciseCleared: data.exerciseCleared.present
          ? data.exerciseCleared.value
          : this.exerciseCleared,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pregnancy(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('status: $status, ')
          ..write('datingMethod: $datingMethod, ')
          ..write('lmp: $lmp, ')
          ..write('cycleLength: $cycleLength, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('embryoDay: $embryoDay, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('twins: $twins, ')
          ..write('highRisk: $highRisk, ')
          ..write('exerciseCleared: $exerciseCleared')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    status,
    datingMethod,
    lmp,
    cycleLength,
    anchorDate,
    embryoDay,
    startDate,
    dueDate,
    twins,
    highRisk,
    exerciseCleared,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pregnancy &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.status == this.status &&
          other.datingMethod == this.datingMethod &&
          other.lmp == this.lmp &&
          other.cycleLength == this.cycleLength &&
          other.anchorDate == this.anchorDate &&
          other.embryoDay == this.embryoDay &&
          other.startDate == this.startDate &&
          other.dueDate == this.dueDate &&
          other.twins == this.twins &&
          other.highRisk == this.highRisk &&
          other.exerciseCleared == this.exerciseCleared);
}

class PregnanciesCompanion extends UpdateCompanion<Pregnancy> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<PregnancyStatus> status;
  final Value<DatingMethod> datingMethod;
  final Value<DateTime?> lmp;
  final Value<int?> cycleLength;
  final Value<DateTime?> anchorDate;
  final Value<int?> embryoDay;
  final Value<DateTime> startDate;
  final Value<DateTime> dueDate;
  final Value<bool> twins;
  final Value<bool> highRisk;
  final Value<bool> exerciseCleared;
  final Value<int> rowid;
  const PregnanciesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.datingMethod = const Value.absent(),
    this.lmp = const Value.absent(),
    this.cycleLength = const Value.absent(),
    this.anchorDate = const Value.absent(),
    this.embryoDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.twins = const Value.absent(),
    this.highRisk = const Value.absent(),
    this.exerciseCleared = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PregnanciesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required PregnancyStatus status,
    required DatingMethod datingMethod,
    this.lmp = const Value.absent(),
    this.cycleLength = const Value.absent(),
    this.anchorDate = const Value.absent(),
    this.embryoDay = const Value.absent(),
    required DateTime startDate,
    required DateTime dueDate,
    this.twins = const Value.absent(),
    this.highRisk = const Value.absent(),
    this.exerciseCleared = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : status = Value(status),
       datingMethod = Value(datingMethod),
       startDate = Value(startDate),
       dueDate = Value(dueDate);
  static Insertable<Pregnancy> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? status,
    Expression<String>? datingMethod,
    Expression<String>? lmp,
    Expression<int>? cycleLength,
    Expression<String>? anchorDate,
    Expression<int>? embryoDay,
    Expression<String>? startDate,
    Expression<String>? dueDate,
    Expression<bool>? twins,
    Expression<bool>? highRisk,
    Expression<bool>? exerciseCleared,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (status != null) 'status': status,
      if (datingMethod != null) 'dating_method': datingMethod,
      if (lmp != null) 'lmp': lmp,
      if (cycleLength != null) 'cycle_length': cycleLength,
      if (anchorDate != null) 'anchor_date': anchorDate,
      if (embryoDay != null) 'embryo_day': embryoDay,
      if (startDate != null) 'start_date': startDate,
      if (dueDate != null) 'due_date': dueDate,
      if (twins != null) 'twins': twins,
      if (highRisk != null) 'high_risk': highRisk,
      if (exerciseCleared != null) 'exercise_cleared': exerciseCleared,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PregnanciesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<PregnancyStatus>? status,
    Value<DatingMethod>? datingMethod,
    Value<DateTime?>? lmp,
    Value<int?>? cycleLength,
    Value<DateTime?>? anchorDate,
    Value<int?>? embryoDay,
    Value<DateTime>? startDate,
    Value<DateTime>? dueDate,
    Value<bool>? twins,
    Value<bool>? highRisk,
    Value<bool>? exerciseCleared,
    Value<int>? rowid,
  }) {
    return PregnanciesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      status: status ?? this.status,
      datingMethod: datingMethod ?? this.datingMethod,
      lmp: lmp ?? this.lmp,
      cycleLength: cycleLength ?? this.cycleLength,
      anchorDate: anchorDate ?? this.anchorDate,
      embryoDay: embryoDay ?? this.embryoDay,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      twins: twins ?? this.twins,
      highRisk: highRisk ?? this.highRisk,
      exerciseCleared: exerciseCleared ?? this.exerciseCleared,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PregnanciesTable.$converterstatus.toSql(status.value),
      );
    }
    if (datingMethod.present) {
      map['dating_method'] = Variable<String>(
        $PregnanciesTable.$converterdatingMethod.toSql(datingMethod.value),
      );
    }
    if (lmp.present) {
      map['lmp'] = Variable<String>(
        $PregnanciesTable.$converterlmpn.toSql(lmp.value),
      );
    }
    if (cycleLength.present) {
      map['cycle_length'] = Variable<int>(cycleLength.value);
    }
    if (anchorDate.present) {
      map['anchor_date'] = Variable<String>(
        $PregnanciesTable.$converteranchorDaten.toSql(anchorDate.value),
      );
    }
    if (embryoDay.present) {
      map['embryo_day'] = Variable<int>(embryoDay.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $PregnanciesTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(
        $PregnanciesTable.$converterdueDate.toSql(dueDate.value),
      );
    }
    if (twins.present) {
      map['twins'] = Variable<bool>(twins.value);
    }
    if (highRisk.present) {
      map['high_risk'] = Variable<bool>(highRisk.value);
    }
    if (exerciseCleared.present) {
      map['exercise_cleared'] = Variable<bool>(exerciseCleared.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PregnanciesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('status: $status, ')
          ..write('datingMethod: $datingMethod, ')
          ..write('lmp: $lmp, ')
          ..write('cycleLength: $cycleLength, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('embryoDay: $embryoDay, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('twins: $twins, ')
          ..write('highRisk: $highRisk, ')
          ..write('exerciseCleared: $exerciseCleared, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    clientDefault: DateTime.now,
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
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    key,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String key;
  final String value;
  const Setting({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? key,
    String? value,
  }) => Setting(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, deletedAt, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistTicksTable extends ChecklistTicks
    with TableInfo<$ChecklistTicksTable, ChecklistTick> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistTicksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    clientDefault: DateTime.now,
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
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pregnancyIdMeta = const VerificationMeta(
    'pregnancyId',
  );
  @override
  late final GeneratedColumn<String> pregnancyId = GeneratedColumn<String>(
    'pregnancy_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pregnancy (id)',
    ),
  );
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    pregnancyId,
    itemKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_tick';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistTick> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('pregnancy_id')) {
      context.handle(
        _pregnancyIdMeta,
        pregnancyId.isAcceptableOrUnknown(
          data['pregnancy_id']!,
          _pregnancyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pregnancyIdMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {pregnancyId, itemKey},
  ];
  @override
  ChecklistTick map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistTick(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      pregnancyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_id'],
      )!,
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
    );
  }

  @override
  $ChecklistTicksTable createAlias(String alias) {
    return $ChecklistTicksTable(attachedDatabase, alias);
  }
}

class ChecklistTick extends DataClass implements Insertable<ChecklistTick> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String pregnancyId;

  /// `ChecklistItem.key` from the content pack, e.g. `w24-gtt`.
  final String itemKey;
  const ChecklistTick({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.pregnancyId,
    required this.itemKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['pregnancy_id'] = Variable<String>(pregnancyId);
    map['item_key'] = Variable<String>(itemKey);
    return map;
  }

  ChecklistTicksCompanion toCompanion(bool nullToAbsent) {
    return ChecklistTicksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pregnancyId: Value(pregnancyId),
      itemKey: Value(itemKey),
    );
  }

  factory ChecklistTick.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistTick(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      pregnancyId: serializer.fromJson<String>(json['pregnancyId']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'pregnancyId': serializer.toJson<String>(pregnancyId),
      'itemKey': serializer.toJson<String>(itemKey),
    };
  }

  ChecklistTick copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? pregnancyId,
    String? itemKey,
  }) => ChecklistTick(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pregnancyId: pregnancyId ?? this.pregnancyId,
    itemKey: itemKey ?? this.itemKey,
  );
  ChecklistTick copyWithCompanion(ChecklistTicksCompanion data) {
    return ChecklistTick(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pregnancyId: data.pregnancyId.present
          ? data.pregnancyId.value
          : this.pregnancyId,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistTick(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('itemKey: $itemKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, deletedAt, pregnancyId, itemKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistTick &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pregnancyId == this.pregnancyId &&
          other.itemKey == this.itemKey);
}

class ChecklistTicksCompanion extends UpdateCompanion<ChecklistTick> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> pregnancyId;
  final Value<String> itemKey;
  final Value<int> rowid;
  const ChecklistTicksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistTicksCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String pregnancyId,
    required String itemKey,
    this.rowid = const Value.absent(),
  }) : pregnancyId = Value(pregnancyId),
       itemKey = Value(itemKey);
  static Insertable<ChecklistTick> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? pregnancyId,
    Expression<String>? itemKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (itemKey != null) 'item_key': itemKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistTicksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? pregnancyId,
    Value<String>? itemKey,
    Value<int>? rowid,
  }) {
    return ChecklistTicksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      itemKey: itemKey ?? this.itemKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (pregnancyId.present) {
      map['pregnancy_id'] = Variable<String>(pregnancyId.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistTicksCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('itemKey: $itemKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PregnanciesTable pregnancies = $PregnanciesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ChecklistTicksTable checklistTicks = $ChecklistTicksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pregnancies,
    settings,
    checklistTicks,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$PregnanciesTableCreateCompanionBuilder =
    PregnanciesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required PregnancyStatus status,
      required DatingMethod datingMethod,
      Value<DateTime?> lmp,
      Value<int?> cycleLength,
      Value<DateTime?> anchorDate,
      Value<int?> embryoDay,
      required DateTime startDate,
      required DateTime dueDate,
      Value<bool> twins,
      Value<bool> highRisk,
      Value<bool> exerciseCleared,
      Value<int> rowid,
    });
typedef $$PregnanciesTableUpdateCompanionBuilder =
    PregnanciesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<PregnancyStatus> status,
      Value<DatingMethod> datingMethod,
      Value<DateTime?> lmp,
      Value<int?> cycleLength,
      Value<DateTime?> anchorDate,
      Value<int?> embryoDay,
      Value<DateTime> startDate,
      Value<DateTime> dueDate,
      Value<bool> twins,
      Value<bool> highRisk,
      Value<bool> exerciseCleared,
      Value<int> rowid,
    });

final class $$PregnanciesTableReferences
    extends BaseReferences<_$AppDatabase, $PregnanciesTable, Pregnancy> {
  $$PregnanciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChecklistTicksTable, List<ChecklistTick>>
  _checklistTicksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.checklistTicks,
    aliasName: 'pregnancy__id__checklist_tick__pregnancy_id',
  );

  $$ChecklistTicksTableProcessedTableManager get checklistTicksRefs {
    final manager = $$ChecklistTicksTableTableManager(
      $_db,
      $_db.checklistTicks,
    ).filter((f) => f.pregnancyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_checklistTicksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PregnanciesTableFilterComposer
    extends Composer<_$AppDatabase, $PregnanciesTable> {
  $$PregnanciesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PregnancyStatus, PregnancyStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DatingMethod, DatingMethod, String>
  get datingMethod => $composableBuilder(
    column: $table.datingMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get lmp =>
      $composableBuilder(
        column: $table.lmp,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get cycleLength => $composableBuilder(
    column: $table.cycleLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get anchorDate =>
      $composableBuilder(
        column: $table.anchorDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get embryoDay => $composableBuilder(
    column: $table.embryoDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get dueDate =>
      $composableBuilder(
        column: $table.dueDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get twins => $composableBuilder(
    column: $table.twins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get highRisk => $composableBuilder(
    column: $table.highRisk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get exerciseCleared => $composableBuilder(
    column: $table.exerciseCleared,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> checklistTicksRefs(
    Expression<bool> Function($$ChecklistTicksTableFilterComposer f) f,
  ) {
    final $$ChecklistTicksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checklistTicks,
      getReferencedColumn: (t) => t.pregnancyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistTicksTableFilterComposer(
            $db: $db,
            $table: $db.checklistTicks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PregnanciesTableOrderingComposer
    extends Composer<_$AppDatabase, $PregnanciesTable> {
  $$PregnanciesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datingMethod => $composableBuilder(
    column: $table.datingMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lmp => $composableBuilder(
    column: $table.lmp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleLength => $composableBuilder(
    column: $table.cycleLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get embryoDay => $composableBuilder(
    column: $table.embryoDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get twins => $composableBuilder(
    column: $table.twins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get highRisk => $composableBuilder(
    column: $table.highRisk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get exerciseCleared => $composableBuilder(
    column: $table.exerciseCleared,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PregnanciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PregnanciesTable> {
  $$PregnanciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PregnancyStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DatingMethod, String> get datingMethod =>
      $composableBuilder(
        column: $table.datingMethod,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get lmp =>
      $composableBuilder(column: $table.lmp, builder: (column) => column);

  GeneratedColumn<int> get cycleLength => $composableBuilder(
    column: $table.cycleLength,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get anchorDate =>
      $composableBuilder(
        column: $table.anchorDate,
        builder: (column) => column,
      );

  GeneratedColumn<int> get embryoDay =>
      $composableBuilder(column: $table.embryoDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get twins =>
      $composableBuilder(column: $table.twins, builder: (column) => column);

  GeneratedColumn<bool> get highRisk =>
      $composableBuilder(column: $table.highRisk, builder: (column) => column);

  GeneratedColumn<bool> get exerciseCleared => $composableBuilder(
    column: $table.exerciseCleared,
    builder: (column) => column,
  );

  Expression<T> checklistTicksRefs<T extends Object>(
    Expression<T> Function($$ChecklistTicksTableAnnotationComposer a) f,
  ) {
    final $$ChecklistTicksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checklistTicks,
      getReferencedColumn: (t) => t.pregnancyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistTicksTableAnnotationComposer(
            $db: $db,
            $table: $db.checklistTicks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PregnanciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PregnanciesTable,
          Pregnancy,
          $$PregnanciesTableFilterComposer,
          $$PregnanciesTableOrderingComposer,
          $$PregnanciesTableAnnotationComposer,
          $$PregnanciesTableCreateCompanionBuilder,
          $$PregnanciesTableUpdateCompanionBuilder,
          (Pregnancy, $$PregnanciesTableReferences),
          Pregnancy,
          PrefetchHooks Function({bool checklistTicksRefs})
        > {
  $$PregnanciesTableTableManager(_$AppDatabase db, $PregnanciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PregnanciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PregnanciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PregnanciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<PregnancyStatus> status = const Value.absent(),
                Value<DatingMethod> datingMethod = const Value.absent(),
                Value<DateTime?> lmp = const Value.absent(),
                Value<int?> cycleLength = const Value.absent(),
                Value<DateTime?> anchorDate = const Value.absent(),
                Value<int?> embryoDay = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<bool> twins = const Value.absent(),
                Value<bool> highRisk = const Value.absent(),
                Value<bool> exerciseCleared = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                status: status,
                datingMethod: datingMethod,
                lmp: lmp,
                cycleLength: cycleLength,
                anchorDate: anchorDate,
                embryoDay: embryoDay,
                startDate: startDate,
                dueDate: dueDate,
                twins: twins,
                highRisk: highRisk,
                exerciseCleared: exerciseCleared,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required PregnancyStatus status,
                required DatingMethod datingMethod,
                Value<DateTime?> lmp = const Value.absent(),
                Value<int?> cycleLength = const Value.absent(),
                Value<DateTime?> anchorDate = const Value.absent(),
                Value<int?> embryoDay = const Value.absent(),
                required DateTime startDate,
                required DateTime dueDate,
                Value<bool> twins = const Value.absent(),
                Value<bool> highRisk = const Value.absent(),
                Value<bool> exerciseCleared = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                status: status,
                datingMethod: datingMethod,
                lmp: lmp,
                cycleLength: cycleLength,
                anchorDate: anchorDate,
                embryoDay: embryoDay,
                startDate: startDate,
                dueDate: dueDate,
                twins: twins,
                highRisk: highRisk,
                exerciseCleared: exerciseCleared,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PregnanciesTable, Pregnancy>(table),
                  $$PregnanciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({checklistTicksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (checklistTicksRefs) db.checklistTicks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (checklistTicksRefs)
                    await $_getPrefetchedData<
                      Pregnancy,
                      $PregnanciesTable,
                      ChecklistTick
                    >(
                      currentTable: table,
                      referencedTable: $$PregnanciesTableReferences
                          ._checklistTicksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PregnanciesTableReferences(
                            db,
                            table,
                            p0,
                          ).checklistTicksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.pregnancyId == item.id,
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

typedef $$PregnanciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PregnanciesTable,
      Pregnancy,
      $$PregnanciesTableFilterComposer,
      $$PregnanciesTableOrderingComposer,
      $$PregnanciesTableAnnotationComposer,
      $$PregnanciesTableCreateCompanionBuilder,
      $$PregnanciesTableUpdateCompanionBuilder,
      (Pregnancy, $$PregnanciesTableReferences),
      Pregnancy,
      PrefetchHooks Function({bool checklistTicksRefs})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$ChecklistTicksTableCreateCompanionBuilder =
    ChecklistTicksCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String pregnancyId,
      required String itemKey,
      Value<int> rowid,
    });
typedef $$ChecklistTicksTableUpdateCompanionBuilder =
    ChecklistTicksCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> pregnancyId,
      Value<String> itemKey,
      Value<int> rowid,
    });

final class $$ChecklistTicksTableReferences
    extends BaseReferences<_$AppDatabase, $ChecklistTicksTable, ChecklistTick> {
  $$ChecklistTicksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PregnanciesTable _pregnancyIdTable(_$AppDatabase db) =>
      db.pregnancies.createAlias('checklist_tick__pregnancy_id__pregnancy__id');

  $$PregnanciesTableProcessedTableManager get pregnancyId {
    final $_column = $_itemColumn<String>('pregnancy_id')!;

    final manager = $$PregnanciesTableTableManager(
      $_db,
      $_db.pregnancies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pregnancyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChecklistTicksTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistTicksTable> {
  $$ChecklistTicksTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  $$PregnanciesTableFilterComposer get pregnancyId {
    final $$PregnanciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pregnancyId,
      referencedTable: $db.pregnancies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PregnanciesTableFilterComposer(
            $db: $db,
            $table: $db.pregnancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChecklistTicksTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistTicksTable> {
  $$ChecklistTicksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$PregnanciesTableOrderingComposer get pregnancyId {
    final $$PregnanciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pregnancyId,
      referencedTable: $db.pregnancies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PregnanciesTableOrderingComposer(
            $db: $db,
            $table: $db.pregnancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChecklistTicksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistTicksTable> {
  $$ChecklistTicksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  $$PregnanciesTableAnnotationComposer get pregnancyId {
    final $$PregnanciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pregnancyId,
      referencedTable: $db.pregnancies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PregnanciesTableAnnotationComposer(
            $db: $db,
            $table: $db.pregnancies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChecklistTicksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistTicksTable,
          ChecklistTick,
          $$ChecklistTicksTableFilterComposer,
          $$ChecklistTicksTableOrderingComposer,
          $$ChecklistTicksTableAnnotationComposer,
          $$ChecklistTicksTableCreateCompanionBuilder,
          $$ChecklistTicksTableUpdateCompanionBuilder,
          (ChecklistTick, $$ChecklistTicksTableReferences),
          ChecklistTick,
          PrefetchHooks Function({bool pregnancyId})
        > {
  $$ChecklistTicksTableTableManager(
    _$AppDatabase db,
    $ChecklistTicksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistTicksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistTicksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistTicksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> pregnancyId = const Value.absent(),
                Value<String> itemKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistTicksCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pregnancyId: pregnancyId,
                itemKey: itemKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String pregnancyId,
                required String itemKey,
                Value<int> rowid = const Value.absent(),
              }) => ChecklistTicksCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                pregnancyId: pregnancyId,
                itemKey: itemKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChecklistTicksTable, ChecklistTick>(table),
                  $$ChecklistTicksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pregnancyId = false}) {
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
                    if (pregnancyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.pregnancyId,
                        referencedTable: $$ChecklistTicksTableReferences
                            ._pregnancyIdTable(db),
                        referencedColumn: $$ChecklistTicksTableReferences
                            ._pregnancyIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ChecklistTicksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistTicksTable,
      ChecklistTick,
      $$ChecklistTicksTableFilterComposer,
      $$ChecklistTicksTableOrderingComposer,
      $$ChecklistTicksTableAnnotationComposer,
      $$ChecklistTicksTableCreateCompanionBuilder,
      $$ChecklistTicksTableUpdateCompanionBuilder,
      (ChecklistTick, $$ChecklistTicksTableReferences),
      ChecklistTick,
      PrefetchHooks Function({bool pregnancyId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PregnanciesTableTableManager get pregnancies =>
      $$PregnanciesTableTableManager(_db, _db.pregnancies);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ChecklistTicksTableTableManager get checklistTicks =>
      $$ChecklistTicksTableTableManager(_db, _db.checklistTicks);
}
