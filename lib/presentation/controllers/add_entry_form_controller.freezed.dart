// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_entry_form_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddEntryFormState {

 TransactionType get type; String get title; String get amountInput; int? get selectedCategoryId; String get paymentMode; DateTime get date; String get notes; String get counterparty; bool get isSaving; bool get showValidation;
/// Create a copy of AddEntryFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddEntryFormStateCopyWith<AddEntryFormState> get copyWith => _$AddEntryFormStateCopyWithImpl<AddEntryFormState>(this as AddEntryFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddEntryFormState&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.amountInput, amountInput) || other.amountInput == amountInput)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.date, date) || other.date == date)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.counterparty, counterparty) || other.counterparty == counterparty)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.showValidation, showValidation) || other.showValidation == showValidation));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,amountInput,selectedCategoryId,paymentMode,date,notes,counterparty,isSaving,showValidation);

@override
String toString() {
  return 'AddEntryFormState(type: $type, title: $title, amountInput: $amountInput, selectedCategoryId: $selectedCategoryId, paymentMode: $paymentMode, date: $date, notes: $notes, counterparty: $counterparty, isSaving: $isSaving, showValidation: $showValidation)';
}


}

/// @nodoc
abstract mixin class $AddEntryFormStateCopyWith<$Res>  {
  factory $AddEntryFormStateCopyWith(AddEntryFormState value, $Res Function(AddEntryFormState) _then) = _$AddEntryFormStateCopyWithImpl;
@useResult
$Res call({
 TransactionType type, String title, String amountInput, int? selectedCategoryId, String paymentMode, DateTime date, String notes, String counterparty, bool isSaving, bool showValidation
});


$TransactionTypeCopyWith<$Res> get type;

}
/// @nodoc
class _$AddEntryFormStateCopyWithImpl<$Res>
    implements $AddEntryFormStateCopyWith<$Res> {
  _$AddEntryFormStateCopyWithImpl(this._self, this._then);

  final AddEntryFormState _self;
  final $Res Function(AddEntryFormState) _then;

/// Create a copy of AddEntryFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? amountInput = null,Object? selectedCategoryId = freezed,Object? paymentMode = null,Object? date = null,Object? notes = null,Object? counterparty = null,Object? isSaving = null,Object? showValidation = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountInput: null == amountInput ? _self.amountInput : amountInput // ignore: cast_nullable_to_non_nullable
as String,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as int?,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,counterparty: null == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as String,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,showValidation: null == showValidation ? _self.showValidation : showValidation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AddEntryFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionTypeCopyWith<$Res> get type {
  
  return $TransactionTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [AddEntryFormState].
extension AddEntryFormStatePatterns on AddEntryFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddEntryFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddEntryFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddEntryFormState value)  $default,){
final _that = this;
switch (_that) {
case _AddEntryFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddEntryFormState value)?  $default,){
final _that = this;
switch (_that) {
case _AddEntryFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransactionType type,  String title,  String amountInput,  int? selectedCategoryId,  String paymentMode,  DateTime date,  String notes,  String counterparty,  bool isSaving,  bool showValidation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddEntryFormState() when $default != null:
return $default(_that.type,_that.title,_that.amountInput,_that.selectedCategoryId,_that.paymentMode,_that.date,_that.notes,_that.counterparty,_that.isSaving,_that.showValidation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransactionType type,  String title,  String amountInput,  int? selectedCategoryId,  String paymentMode,  DateTime date,  String notes,  String counterparty,  bool isSaving,  bool showValidation)  $default,) {final _that = this;
switch (_that) {
case _AddEntryFormState():
return $default(_that.type,_that.title,_that.amountInput,_that.selectedCategoryId,_that.paymentMode,_that.date,_that.notes,_that.counterparty,_that.isSaving,_that.showValidation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransactionType type,  String title,  String amountInput,  int? selectedCategoryId,  String paymentMode,  DateTime date,  String notes,  String counterparty,  bool isSaving,  bool showValidation)?  $default,) {final _that = this;
switch (_that) {
case _AddEntryFormState() when $default != null:
return $default(_that.type,_that.title,_that.amountInput,_that.selectedCategoryId,_that.paymentMode,_that.date,_that.notes,_that.counterparty,_that.isSaving,_that.showValidation);case _:
  return null;

}
}

}

/// @nodoc


class _AddEntryFormState extends AddEntryFormState {
  const _AddEntryFormState({required this.type, required this.title, required this.amountInput, this.selectedCategoryId, required this.paymentMode, required this.date, required this.notes, required this.counterparty, required this.isSaving, required this.showValidation}): super._();
  

@override final  TransactionType type;
@override final  String title;
@override final  String amountInput;
@override final  int? selectedCategoryId;
@override final  String paymentMode;
@override final  DateTime date;
@override final  String notes;
@override final  String counterparty;
@override final  bool isSaving;
@override final  bool showValidation;

/// Create a copy of AddEntryFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddEntryFormStateCopyWith<_AddEntryFormState> get copyWith => __$AddEntryFormStateCopyWithImpl<_AddEntryFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddEntryFormState&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.amountInput, amountInput) || other.amountInput == amountInput)&&(identical(other.selectedCategoryId, selectedCategoryId) || other.selectedCategoryId == selectedCategoryId)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.date, date) || other.date == date)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.counterparty, counterparty) || other.counterparty == counterparty)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.showValidation, showValidation) || other.showValidation == showValidation));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,amountInput,selectedCategoryId,paymentMode,date,notes,counterparty,isSaving,showValidation);

@override
String toString() {
  return 'AddEntryFormState(type: $type, title: $title, amountInput: $amountInput, selectedCategoryId: $selectedCategoryId, paymentMode: $paymentMode, date: $date, notes: $notes, counterparty: $counterparty, isSaving: $isSaving, showValidation: $showValidation)';
}


}

/// @nodoc
abstract mixin class _$AddEntryFormStateCopyWith<$Res> implements $AddEntryFormStateCopyWith<$Res> {
  factory _$AddEntryFormStateCopyWith(_AddEntryFormState value, $Res Function(_AddEntryFormState) _then) = __$AddEntryFormStateCopyWithImpl;
@override @useResult
$Res call({
 TransactionType type, String title, String amountInput, int? selectedCategoryId, String paymentMode, DateTime date, String notes, String counterparty, bool isSaving, bool showValidation
});


@override $TransactionTypeCopyWith<$Res> get type;

}
/// @nodoc
class __$AddEntryFormStateCopyWithImpl<$Res>
    implements _$AddEntryFormStateCopyWith<$Res> {
  __$AddEntryFormStateCopyWithImpl(this._self, this._then);

  final _AddEntryFormState _self;
  final $Res Function(_AddEntryFormState) _then;

/// Create a copy of AddEntryFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? amountInput = null,Object? selectedCategoryId = freezed,Object? paymentMode = null,Object? date = null,Object? notes = null,Object? counterparty = null,Object? isSaving = null,Object? showValidation = null,}) {
  return _then(_AddEntryFormState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountInput: null == amountInput ? _self.amountInput : amountInput // ignore: cast_nullable_to_non_nullable
as String,selectedCategoryId: freezed == selectedCategoryId ? _self.selectedCategoryId : selectedCategoryId // ignore: cast_nullable_to_non_nullable
as int?,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,counterparty: null == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as String,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,showValidation: null == showValidation ? _self.showValidation : showValidation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AddEntryFormState
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
