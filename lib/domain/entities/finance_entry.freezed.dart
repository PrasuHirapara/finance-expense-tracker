// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'finance_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FinanceEntry {

 int get id; String get title; double get amount; TransactionType get type; FinanceCategory get category; DateTime get date; String get paymentMode; String get notes; String? get counterparty;
/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceEntryCopyWith<FinanceEntry> get copyWith => _$FinanceEntryCopyWithImpl<FinanceEntry>(this as FinanceEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.counterparty, counterparty) || other.counterparty == counterparty));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,amount,type,category,date,paymentMode,notes,counterparty);

@override
String toString() {
  return 'FinanceEntry(id: $id, title: $title, amount: $amount, type: $type, category: $category, date: $date, paymentMode: $paymentMode, notes: $notes, counterparty: $counterparty)';
}


}

/// @nodoc
abstract mixin class $FinanceEntryCopyWith<$Res>  {
  factory $FinanceEntryCopyWith(FinanceEntry value, $Res Function(FinanceEntry) _then) = _$FinanceEntryCopyWithImpl;
@useResult
$Res call({
 int id, String title, double amount, TransactionType type, FinanceCategory category, DateTime date, String paymentMode, String notes, String? counterparty
});


$TransactionTypeCopyWith<$Res> get type;$FinanceCategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$FinanceEntryCopyWithImpl<$Res>
    implements $FinanceEntryCopyWith<$Res> {
  _$FinanceEntryCopyWithImpl(this._self, this._then);

  final FinanceEntry _self;
  final $Res Function(FinanceEntry) _then;

/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? amount = null,Object? type = null,Object? category = null,Object? date = null,Object? paymentMode = null,Object? notes = null,Object? counterparty = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FinanceCategory,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,counterparty: freezed == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionTypeCopyWith<$Res> get type {
  
  return $TransactionTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinanceCategoryCopyWith<$Res> get category {
  
  return $FinanceCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [FinanceEntry].
extension FinanceEntryPatterns on FinanceEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceEntry value)  $default,){
final _that = this;
switch (_that) {
case _FinanceEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  double amount,  TransactionType type,  FinanceCategory category,  DateTime date,  String paymentMode,  String notes,  String? counterparty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceEntry() when $default != null:
return $default(_that.id,_that.title,_that.amount,_that.type,_that.category,_that.date,_that.paymentMode,_that.notes,_that.counterparty);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  double amount,  TransactionType type,  FinanceCategory category,  DateTime date,  String paymentMode,  String notes,  String? counterparty)  $default,) {final _that = this;
switch (_that) {
case _FinanceEntry():
return $default(_that.id,_that.title,_that.amount,_that.type,_that.category,_that.date,_that.paymentMode,_that.notes,_that.counterparty);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  double amount,  TransactionType type,  FinanceCategory category,  DateTime date,  String paymentMode,  String notes,  String? counterparty)?  $default,) {final _that = this;
switch (_that) {
case _FinanceEntry() when $default != null:
return $default(_that.id,_that.title,_that.amount,_that.type,_that.category,_that.date,_that.paymentMode,_that.notes,_that.counterparty);case _:
  return null;

}
}

}

/// @nodoc


class _FinanceEntry implements FinanceEntry {
  const _FinanceEntry({required this.id, required this.title, required this.amount, required this.type, required this.category, required this.date, required this.paymentMode, required this.notes, this.counterparty});
  

@override final  int id;
@override final  String title;
@override final  double amount;
@override final  TransactionType type;
@override final  FinanceCategory category;
@override final  DateTime date;
@override final  String paymentMode;
@override final  String notes;
@override final  String? counterparty;

/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceEntryCopyWith<_FinanceEntry> get copyWith => __$FinanceEntryCopyWithImpl<_FinanceEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.counterparty, counterparty) || other.counterparty == counterparty));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,amount,type,category,date,paymentMode,notes,counterparty);

@override
String toString() {
  return 'FinanceEntry(id: $id, title: $title, amount: $amount, type: $type, category: $category, date: $date, paymentMode: $paymentMode, notes: $notes, counterparty: $counterparty)';
}


}

/// @nodoc
abstract mixin class _$FinanceEntryCopyWith<$Res> implements $FinanceEntryCopyWith<$Res> {
  factory _$FinanceEntryCopyWith(_FinanceEntry value, $Res Function(_FinanceEntry) _then) = __$FinanceEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, double amount, TransactionType type, FinanceCategory category, DateTime date, String paymentMode, String notes, String? counterparty
});


@override $TransactionTypeCopyWith<$Res> get type;@override $FinanceCategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$FinanceEntryCopyWithImpl<$Res>
    implements _$FinanceEntryCopyWith<$Res> {
  __$FinanceEntryCopyWithImpl(this._self, this._then);

  final _FinanceEntry _self;
  final $Res Function(_FinanceEntry) _then;

/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? amount = null,Object? type = null,Object? category = null,Object? date = null,Object? paymentMode = null,Object? notes = null,Object? counterparty = freezed,}) {
  return _then(_FinanceEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FinanceCategory,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,counterparty: freezed == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionTypeCopyWith<$Res> get type {
  
  return $TransactionTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of FinanceEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinanceCategoryCopyWith<$Res> get category {
  
  return $FinanceCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc
mixin _$FinanceEntryDraft {

 String get title; double get amount; TransactionType get type; int get categoryId; DateTime get date; String get paymentMode; String get notes; String? get counterparty;
/// Create a copy of FinanceEntryDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceEntryDraftCopyWith<FinanceEntryDraft> get copyWith => _$FinanceEntryDraftCopyWithImpl<FinanceEntryDraft>(this as FinanceEntryDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceEntryDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.date, date) || other.date == date)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.counterparty, counterparty) || other.counterparty == counterparty));
}


@override
int get hashCode => Object.hash(runtimeType,title,amount,type,categoryId,date,paymentMode,notes,counterparty);

@override
String toString() {
  return 'FinanceEntryDraft(title: $title, amount: $amount, type: $type, categoryId: $categoryId, date: $date, paymentMode: $paymentMode, notes: $notes, counterparty: $counterparty)';
}


}

/// @nodoc
abstract mixin class $FinanceEntryDraftCopyWith<$Res>  {
  factory $FinanceEntryDraftCopyWith(FinanceEntryDraft value, $Res Function(FinanceEntryDraft) _then) = _$FinanceEntryDraftCopyWithImpl;
@useResult
$Res call({
 String title, double amount, TransactionType type, int categoryId, DateTime date, String paymentMode, String notes, String? counterparty
});


$TransactionTypeCopyWith<$Res> get type;

}
/// @nodoc
class _$FinanceEntryDraftCopyWithImpl<$Res>
    implements $FinanceEntryDraftCopyWith<$Res> {
  _$FinanceEntryDraftCopyWithImpl(this._self, this._then);

  final FinanceEntryDraft _self;
  final $Res Function(FinanceEntryDraft) _then;

/// Create a copy of FinanceEntryDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? amount = null,Object? type = null,Object? categoryId = null,Object? date = null,Object? paymentMode = null,Object? notes = null,Object? counterparty = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,counterparty: freezed == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FinanceEntryDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionTypeCopyWith<$Res> get type {
  
  return $TransactionTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [FinanceEntryDraft].
extension FinanceEntryDraftPatterns on FinanceEntryDraft {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceEntryDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceEntryDraft() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceEntryDraft value)  $default,){
final _that = this;
switch (_that) {
case _FinanceEntryDraft():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceEntryDraft value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceEntryDraft() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  double amount,  TransactionType type,  int categoryId,  DateTime date,  String paymentMode,  String notes,  String? counterparty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceEntryDraft() when $default != null:
return $default(_that.title,_that.amount,_that.type,_that.categoryId,_that.date,_that.paymentMode,_that.notes,_that.counterparty);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  double amount,  TransactionType type,  int categoryId,  DateTime date,  String paymentMode,  String notes,  String? counterparty)  $default,) {final _that = this;
switch (_that) {
case _FinanceEntryDraft():
return $default(_that.title,_that.amount,_that.type,_that.categoryId,_that.date,_that.paymentMode,_that.notes,_that.counterparty);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  double amount,  TransactionType type,  int categoryId,  DateTime date,  String paymentMode,  String notes,  String? counterparty)?  $default,) {final _that = this;
switch (_that) {
case _FinanceEntryDraft() when $default != null:
return $default(_that.title,_that.amount,_that.type,_that.categoryId,_that.date,_that.paymentMode,_that.notes,_that.counterparty);case _:
  return null;

}
}

}

/// @nodoc


class _FinanceEntryDraft implements FinanceEntryDraft {
  const _FinanceEntryDraft({required this.title, required this.amount, required this.type, required this.categoryId, required this.date, required this.paymentMode, required this.notes, this.counterparty});
  

@override final  String title;
@override final  double amount;
@override final  TransactionType type;
@override final  int categoryId;
@override final  DateTime date;
@override final  String paymentMode;
@override final  String notes;
@override final  String? counterparty;

/// Create a copy of FinanceEntryDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceEntryDraftCopyWith<_FinanceEntryDraft> get copyWith => __$FinanceEntryDraftCopyWithImpl<_FinanceEntryDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceEntryDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.date, date) || other.date == date)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.counterparty, counterparty) || other.counterparty == counterparty));
}


@override
int get hashCode => Object.hash(runtimeType,title,amount,type,categoryId,date,paymentMode,notes,counterparty);

@override
String toString() {
  return 'FinanceEntryDraft(title: $title, amount: $amount, type: $type, categoryId: $categoryId, date: $date, paymentMode: $paymentMode, notes: $notes, counterparty: $counterparty)';
}


}

/// @nodoc
abstract mixin class _$FinanceEntryDraftCopyWith<$Res> implements $FinanceEntryDraftCopyWith<$Res> {
  factory _$FinanceEntryDraftCopyWith(_FinanceEntryDraft value, $Res Function(_FinanceEntryDraft) _then) = __$FinanceEntryDraftCopyWithImpl;
@override @useResult
$Res call({
 String title, double amount, TransactionType type, int categoryId, DateTime date, String paymentMode, String notes, String? counterparty
});


@override $TransactionTypeCopyWith<$Res> get type;

}
/// @nodoc
class __$FinanceEntryDraftCopyWithImpl<$Res>
    implements _$FinanceEntryDraftCopyWith<$Res> {
  __$FinanceEntryDraftCopyWithImpl(this._self, this._then);

  final _FinanceEntryDraft _self;
  final $Res Function(_FinanceEntryDraft) _then;

/// Create a copy of FinanceEntryDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? amount = null,Object? type = null,Object? categoryId = null,Object? date = null,Object? paymentMode = null,Object? notes = null,Object? counterparty = freezed,}) {
  return _then(_FinanceEntryDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,counterparty: freezed == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FinanceEntryDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionTypeCopyWith<$Res> get type {
  
  return $TransactionTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

// dart format on
