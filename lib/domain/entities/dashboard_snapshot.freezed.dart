// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DashboardSnapshot {

 double get todaysExpense; double get weeklyExpense; double get weeklyCredit; double get weeklyDebit; double get weeklyBorrowed; double get weeklyLent; int get categoryCount; List<FinanceEntry> get recentEntries;
/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardSnapshotCopyWith<DashboardSnapshot> get copyWith => _$DashboardSnapshotCopyWithImpl<DashboardSnapshot>(this as DashboardSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardSnapshot&&(identical(other.todaysExpense, todaysExpense) || other.todaysExpense == todaysExpense)&&(identical(other.weeklyExpense, weeklyExpense) || other.weeklyExpense == weeklyExpense)&&(identical(other.weeklyCredit, weeklyCredit) || other.weeklyCredit == weeklyCredit)&&(identical(other.weeklyDebit, weeklyDebit) || other.weeklyDebit == weeklyDebit)&&(identical(other.weeklyBorrowed, weeklyBorrowed) || other.weeklyBorrowed == weeklyBorrowed)&&(identical(other.weeklyLent, weeklyLent) || other.weeklyLent == weeklyLent)&&(identical(other.categoryCount, categoryCount) || other.categoryCount == categoryCount)&&const DeepCollectionEquality().equals(other.recentEntries, recentEntries));
}


@override
int get hashCode => Object.hash(runtimeType,todaysExpense,weeklyExpense,weeklyCredit,weeklyDebit,weeklyBorrowed,weeklyLent,categoryCount,const DeepCollectionEquality().hash(recentEntries));

@override
String toString() {
  return 'DashboardSnapshot(todaysExpense: $todaysExpense, weeklyExpense: $weeklyExpense, weeklyCredit: $weeklyCredit, weeklyDebit: $weeklyDebit, weeklyBorrowed: $weeklyBorrowed, weeklyLent: $weeklyLent, categoryCount: $categoryCount, recentEntries: $recentEntries)';
}


}

/// @nodoc
abstract mixin class $DashboardSnapshotCopyWith<$Res>  {
  factory $DashboardSnapshotCopyWith(DashboardSnapshot value, $Res Function(DashboardSnapshot) _then) = _$DashboardSnapshotCopyWithImpl;
@useResult
$Res call({
 double todaysExpense, double weeklyExpense, double weeklyCredit, double weeklyDebit, double weeklyBorrowed, double weeklyLent, int categoryCount, List<FinanceEntry> recentEntries
});




}
/// @nodoc
class _$DashboardSnapshotCopyWithImpl<$Res>
    implements $DashboardSnapshotCopyWith<$Res> {
  _$DashboardSnapshotCopyWithImpl(this._self, this._then);

  final DashboardSnapshot _self;
  final $Res Function(DashboardSnapshot) _then;

/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? todaysExpense = null,Object? weeklyExpense = null,Object? weeklyCredit = null,Object? weeklyDebit = null,Object? weeklyBorrowed = null,Object? weeklyLent = null,Object? categoryCount = null,Object? recentEntries = null,}) {
  return _then(_self.copyWith(
todaysExpense: null == todaysExpense ? _self.todaysExpense : todaysExpense // ignore: cast_nullable_to_non_nullable
as double,weeklyExpense: null == weeklyExpense ? _self.weeklyExpense : weeklyExpense // ignore: cast_nullable_to_non_nullable
as double,weeklyCredit: null == weeklyCredit ? _self.weeklyCredit : weeklyCredit // ignore: cast_nullable_to_non_nullable
as double,weeklyDebit: null == weeklyDebit ? _self.weeklyDebit : weeklyDebit // ignore: cast_nullable_to_non_nullable
as double,weeklyBorrowed: null == weeklyBorrowed ? _self.weeklyBorrowed : weeklyBorrowed // ignore: cast_nullable_to_non_nullable
as double,weeklyLent: null == weeklyLent ? _self.weeklyLent : weeklyLent // ignore: cast_nullable_to_non_nullable
as double,categoryCount: null == categoryCount ? _self.categoryCount : categoryCount // ignore: cast_nullable_to_non_nullable
as int,recentEntries: null == recentEntries ? _self.recentEntries : recentEntries // ignore: cast_nullable_to_non_nullable
as List<FinanceEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardSnapshot].
extension DashboardSnapshotPatterns on DashboardSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _DashboardSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double todaysExpense,  double weeklyExpense,  double weeklyCredit,  double weeklyDebit,  double weeklyBorrowed,  double weeklyLent,  int categoryCount,  List<FinanceEntry> recentEntries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
return $default(_that.todaysExpense,_that.weeklyExpense,_that.weeklyCredit,_that.weeklyDebit,_that.weeklyBorrowed,_that.weeklyLent,_that.categoryCount,_that.recentEntries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double todaysExpense,  double weeklyExpense,  double weeklyCredit,  double weeklyDebit,  double weeklyBorrowed,  double weeklyLent,  int categoryCount,  List<FinanceEntry> recentEntries)  $default,) {final _that = this;
switch (_that) {
case _DashboardSnapshot():
return $default(_that.todaysExpense,_that.weeklyExpense,_that.weeklyCredit,_that.weeklyDebit,_that.weeklyBorrowed,_that.weeklyLent,_that.categoryCount,_that.recentEntries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double todaysExpense,  double weeklyExpense,  double weeklyCredit,  double weeklyDebit,  double weeklyBorrowed,  double weeklyLent,  int categoryCount,  List<FinanceEntry> recentEntries)?  $default,) {final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
return $default(_that.todaysExpense,_that.weeklyExpense,_that.weeklyCredit,_that.weeklyDebit,_that.weeklyBorrowed,_that.weeklyLent,_that.categoryCount,_that.recentEntries);case _:
  return null;

}
}

}

/// @nodoc


class _DashboardSnapshot extends DashboardSnapshot {
  const _DashboardSnapshot({required this.todaysExpense, required this.weeklyExpense, required this.weeklyCredit, required this.weeklyDebit, required this.weeklyBorrowed, required this.weeklyLent, required this.categoryCount, required final  List<FinanceEntry> recentEntries}): _recentEntries = recentEntries,super._();
  

@override final  double todaysExpense;
@override final  double weeklyExpense;
@override final  double weeklyCredit;
@override final  double weeklyDebit;
@override final  double weeklyBorrowed;
@override final  double weeklyLent;
@override final  int categoryCount;
 final  List<FinanceEntry> _recentEntries;
@override List<FinanceEntry> get recentEntries {
  if (_recentEntries is EqualUnmodifiableListView) return _recentEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentEntries);
}


/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardSnapshotCopyWith<_DashboardSnapshot> get copyWith => __$DashboardSnapshotCopyWithImpl<_DashboardSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardSnapshot&&(identical(other.todaysExpense, todaysExpense) || other.todaysExpense == todaysExpense)&&(identical(other.weeklyExpense, weeklyExpense) || other.weeklyExpense == weeklyExpense)&&(identical(other.weeklyCredit, weeklyCredit) || other.weeklyCredit == weeklyCredit)&&(identical(other.weeklyDebit, weeklyDebit) || other.weeklyDebit == weeklyDebit)&&(identical(other.weeklyBorrowed, weeklyBorrowed) || other.weeklyBorrowed == weeklyBorrowed)&&(identical(other.weeklyLent, weeklyLent) || other.weeklyLent == weeklyLent)&&(identical(other.categoryCount, categoryCount) || other.categoryCount == categoryCount)&&const DeepCollectionEquality().equals(other._recentEntries, _recentEntries));
}


@override
int get hashCode => Object.hash(runtimeType,todaysExpense,weeklyExpense,weeklyCredit,weeklyDebit,weeklyBorrowed,weeklyLent,categoryCount,const DeepCollectionEquality().hash(_recentEntries));

@override
String toString() {
  return 'DashboardSnapshot(todaysExpense: $todaysExpense, weeklyExpense: $weeklyExpense, weeklyCredit: $weeklyCredit, weeklyDebit: $weeklyDebit, weeklyBorrowed: $weeklyBorrowed, weeklyLent: $weeklyLent, categoryCount: $categoryCount, recentEntries: $recentEntries)';
}


}

/// @nodoc
abstract mixin class _$DashboardSnapshotCopyWith<$Res> implements $DashboardSnapshotCopyWith<$Res> {
  factory _$DashboardSnapshotCopyWith(_DashboardSnapshot value, $Res Function(_DashboardSnapshot) _then) = __$DashboardSnapshotCopyWithImpl;
@override @useResult
$Res call({
 double todaysExpense, double weeklyExpense, double weeklyCredit, double weeklyDebit, double weeklyBorrowed, double weeklyLent, int categoryCount, List<FinanceEntry> recentEntries
});




}
/// @nodoc
class __$DashboardSnapshotCopyWithImpl<$Res>
    implements _$DashboardSnapshotCopyWith<$Res> {
  __$DashboardSnapshotCopyWithImpl(this._self, this._then);

  final _DashboardSnapshot _self;
  final $Res Function(_DashboardSnapshot) _then;

/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? todaysExpense = null,Object? weeklyExpense = null,Object? weeklyCredit = null,Object? weeklyDebit = null,Object? weeklyBorrowed = null,Object? weeklyLent = null,Object? categoryCount = null,Object? recentEntries = null,}) {
  return _then(_DashboardSnapshot(
todaysExpense: null == todaysExpense ? _self.todaysExpense : todaysExpense // ignore: cast_nullable_to_non_nullable
as double,weeklyExpense: null == weeklyExpense ? _self.weeklyExpense : weeklyExpense // ignore: cast_nullable_to_non_nullable
as double,weeklyCredit: null == weeklyCredit ? _self.weeklyCredit : weeklyCredit // ignore: cast_nullable_to_non_nullable
as double,weeklyDebit: null == weeklyDebit ? _self.weeklyDebit : weeklyDebit // ignore: cast_nullable_to_non_nullable
as double,weeklyBorrowed: null == weeklyBorrowed ? _self.weeklyBorrowed : weeklyBorrowed // ignore: cast_nullable_to_non_nullable
as double,weeklyLent: null == weeklyLent ? _self.weeklyLent : weeklyLent // ignore: cast_nullable_to_non_nullable
as double,categoryCount: null == categoryCount ? _self.categoryCount : categoryCount // ignore: cast_nullable_to_non_nullable
as int,recentEntries: null == recentEntries ? _self._recentEntries : recentEntries // ignore: cast_nullable_to_non_nullable
as List<FinanceEntry>,
  ));
}


}

// dart format on
