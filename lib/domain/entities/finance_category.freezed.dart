// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'finance_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FinanceCategory {

 int get id; String get name; int get iconCodePoint; int get colorValue;
/// Create a copy of FinanceCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceCategoryCopyWith<FinanceCategory> get copyWith => _$FinanceCategoryCopyWithImpl<FinanceCategory>(this as FinanceCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconCodePoint, iconCodePoint) || other.iconCodePoint == iconCodePoint)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,iconCodePoint,colorValue);

@override
String toString() {
  return 'FinanceCategory(id: $id, name: $name, iconCodePoint: $iconCodePoint, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class $FinanceCategoryCopyWith<$Res>  {
  factory $FinanceCategoryCopyWith(FinanceCategory value, $Res Function(FinanceCategory) _then) = _$FinanceCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String name, int iconCodePoint, int colorValue
});




}
/// @nodoc
class _$FinanceCategoryCopyWithImpl<$Res>
    implements $FinanceCategoryCopyWith<$Res> {
  _$FinanceCategoryCopyWithImpl(this._self, this._then);

  final FinanceCategory _self;
  final $Res Function(FinanceCategory) _then;

/// Create a copy of FinanceCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconCodePoint = null,Object? colorValue = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconCodePoint: null == iconCodePoint ? _self.iconCodePoint : iconCodePoint // ignore: cast_nullable_to_non_nullable
as int,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FinanceCategory].
extension FinanceCategoryPatterns on FinanceCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceCategory value)  $default,){
final _that = this;
switch (_that) {
case _FinanceCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceCategory value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int iconCodePoint,  int colorValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceCategory() when $default != null:
return $default(_that.id,_that.name,_that.iconCodePoint,_that.colorValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int iconCodePoint,  int colorValue)  $default,) {final _that = this;
switch (_that) {
case _FinanceCategory():
return $default(_that.id,_that.name,_that.iconCodePoint,_that.colorValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int iconCodePoint,  int colorValue)?  $default,) {final _that = this;
switch (_that) {
case _FinanceCategory() when $default != null:
return $default(_that.id,_that.name,_that.iconCodePoint,_that.colorValue);case _:
  return null;

}
}

}

/// @nodoc


class _FinanceCategory implements FinanceCategory {
  const _FinanceCategory({required this.id, required this.name, required this.iconCodePoint, required this.colorValue});
  

@override final  int id;
@override final  String name;
@override final  int iconCodePoint;
@override final  int colorValue;

/// Create a copy of FinanceCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceCategoryCopyWith<_FinanceCategory> get copyWith => __$FinanceCategoryCopyWithImpl<_FinanceCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconCodePoint, iconCodePoint) || other.iconCodePoint == iconCodePoint)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,iconCodePoint,colorValue);

@override
String toString() {
  return 'FinanceCategory(id: $id, name: $name, iconCodePoint: $iconCodePoint, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class _$FinanceCategoryCopyWith<$Res> implements $FinanceCategoryCopyWith<$Res> {
  factory _$FinanceCategoryCopyWith(_FinanceCategory value, $Res Function(_FinanceCategory) _then) = __$FinanceCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int iconCodePoint, int colorValue
});




}
/// @nodoc
class __$FinanceCategoryCopyWithImpl<$Res>
    implements _$FinanceCategoryCopyWith<$Res> {
  __$FinanceCategoryCopyWithImpl(this._self, this._then);

  final _FinanceCategory _self;
  final $Res Function(_FinanceCategory) _then;

/// Create a copy of FinanceCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconCodePoint = null,Object? colorValue = null,}) {
  return _then(_FinanceCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconCodePoint: null == iconCodePoint ? _self.iconCodePoint : iconCodePoint // ignore: cast_nullable_to_non_nullable
as int,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
