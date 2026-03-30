// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategorySpend {

 String get categoryName; double get amount; int get colorValue;
/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorySpendCopyWith<CategorySpend> get copyWith => _$CategorySpendCopyWithImpl<CategorySpend>(this as CategorySpend, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySpend&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}


@override
int get hashCode => Object.hash(runtimeType,categoryName,amount,colorValue);

@override
String toString() {
  return 'CategorySpend(categoryName: $categoryName, amount: $amount, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class $CategorySpendCopyWith<$Res>  {
  factory $CategorySpendCopyWith(CategorySpend value, $Res Function(CategorySpend) _then) = _$CategorySpendCopyWithImpl;
@useResult
$Res call({
 String categoryName, double amount, int colorValue
});




}
/// @nodoc
class _$CategorySpendCopyWithImpl<$Res>
    implements $CategorySpendCopyWith<$Res> {
  _$CategorySpendCopyWithImpl(this._self, this._then);

  final CategorySpend _self;
  final $Res Function(CategorySpend) _then;

/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryName = null,Object? amount = null,Object? colorValue = null,}) {
  return _then(_self.copyWith(
categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategorySpend].
extension CategorySpendPatterns on CategorySpend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorySpend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorySpend value)  $default,){
final _that = this;
switch (_that) {
case _CategorySpend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorySpend value)?  $default,){
final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryName,  double amount,  int colorValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
return $default(_that.categoryName,_that.amount,_that.colorValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryName,  double amount,  int colorValue)  $default,) {final _that = this;
switch (_that) {
case _CategorySpend():
return $default(_that.categoryName,_that.amount,_that.colorValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryName,  double amount,  int colorValue)?  $default,) {final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
return $default(_that.categoryName,_that.amount,_that.colorValue);case _:
  return null;

}
}

}

/// @nodoc


class _CategorySpend implements CategorySpend {
  const _CategorySpend({required this.categoryName, required this.amount, required this.colorValue});
  

@override final  String categoryName;
@override final  double amount;
@override final  int colorValue;

/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorySpendCopyWith<_CategorySpend> get copyWith => __$CategorySpendCopyWithImpl<_CategorySpend>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorySpend&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}


@override
int get hashCode => Object.hash(runtimeType,categoryName,amount,colorValue);

@override
String toString() {
  return 'CategorySpend(categoryName: $categoryName, amount: $amount, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class _$CategorySpendCopyWith<$Res> implements $CategorySpendCopyWith<$Res> {
  factory _$CategorySpendCopyWith(_CategorySpend value, $Res Function(_CategorySpend) _then) = __$CategorySpendCopyWithImpl;
@override @useResult
$Res call({
 String categoryName, double amount, int colorValue
});




}
/// @nodoc
class __$CategorySpendCopyWithImpl<$Res>
    implements _$CategorySpendCopyWith<$Res> {
  __$CategorySpendCopyWithImpl(this._self, this._then);

  final _CategorySpend _self;
  final $Res Function(_CategorySpend) _then;

/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryName = null,Object? amount = null,Object? colorValue = null,}) {
  return _then(_CategorySpend(
categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TrendPoint {

 DateTime get period; double get amount; String get label;
/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendPointCopyWith<TrendPoint> get copyWith => _$TrendPointCopyWithImpl<TrendPoint>(this as TrendPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrendPoint&&(identical(other.period, period) || other.period == period)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,period,amount,label);

@override
String toString() {
  return 'TrendPoint(period: $period, amount: $amount, label: $label)';
}


}

/// @nodoc
abstract mixin class $TrendPointCopyWith<$Res>  {
  factory $TrendPointCopyWith(TrendPoint value, $Res Function(TrendPoint) _then) = _$TrendPointCopyWithImpl;
@useResult
$Res call({
 DateTime period, double amount, String label
});




}
/// @nodoc
class _$TrendPointCopyWithImpl<$Res>
    implements $TrendPointCopyWith<$Res> {
  _$TrendPointCopyWithImpl(this._self, this._then);

  final TrendPoint _self;
  final $Res Function(TrendPoint) _then;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? amount = null,Object? label = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TrendPoint].
extension TrendPointPatterns on TrendPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrendPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrendPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrendPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrendPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime period,  double amount,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
return $default(_that.period,_that.amount,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime period,  double amount,  String label)  $default,) {final _that = this;
switch (_that) {
case _TrendPoint():
return $default(_that.period,_that.amount,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime period,  double amount,  String label)?  $default,) {final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
return $default(_that.period,_that.amount,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _TrendPoint implements TrendPoint {
  const _TrendPoint({required this.period, required this.amount, required this.label});
  

@override final  DateTime period;
@override final  double amount;
@override final  String label;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendPointCopyWith<_TrendPoint> get copyWith => __$TrendPointCopyWithImpl<_TrendPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrendPoint&&(identical(other.period, period) || other.period == period)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,period,amount,label);

@override
String toString() {
  return 'TrendPoint(period: $period, amount: $amount, label: $label)';
}


}

/// @nodoc
abstract mixin class _$TrendPointCopyWith<$Res> implements $TrendPointCopyWith<$Res> {
  factory _$TrendPointCopyWith(_TrendPoint value, $Res Function(_TrendPoint) _then) = __$TrendPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime period, double amount, String label
});




}
/// @nodoc
class __$TrendPointCopyWithImpl<$Res>
    implements _$TrendPointCopyWith<$Res> {
  __$TrendPointCopyWithImpl(this._self, this._then);

  final _TrendPoint _self;
  final $Res Function(_TrendPoint) _then;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? amount = null,Object? label = null,}) {
  return _then(_TrendPoint(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AnalyticsReport {

 AnalyticsWindow get window; DateTime get rangeStart; DateTime get rangeEnd; double get totalExpense; double get totalIncome; double get totalBorrowed; double get totalLent; double get totalCredit; double get totalDebit; double get outstandingLiability; double get outstandingReceivable; List<CategorySpend> get categoryDistribution; List<TrendPoint> get trendPoints; List<FinanceEntry> get entries;
/// Create a copy of AnalyticsReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsReportCopyWith<AnalyticsReport> get copyWith => _$AnalyticsReportCopyWithImpl<AnalyticsReport>(this as AnalyticsReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsReport&&(identical(other.window, window) || other.window == window)&&(identical(other.rangeStart, rangeStart) || other.rangeStart == rangeStart)&&(identical(other.rangeEnd, rangeEnd) || other.rangeEnd == rangeEnd)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalBorrowed, totalBorrowed) || other.totalBorrowed == totalBorrowed)&&(identical(other.totalLent, totalLent) || other.totalLent == totalLent)&&(identical(other.totalCredit, totalCredit) || other.totalCredit == totalCredit)&&(identical(other.totalDebit, totalDebit) || other.totalDebit == totalDebit)&&(identical(other.outstandingLiability, outstandingLiability) || other.outstandingLiability == outstandingLiability)&&(identical(other.outstandingReceivable, outstandingReceivable) || other.outstandingReceivable == outstandingReceivable)&&const DeepCollectionEquality().equals(other.categoryDistribution, categoryDistribution)&&const DeepCollectionEquality().equals(other.trendPoints, trendPoints)&&const DeepCollectionEquality().equals(other.entries, entries));
}


@override
int get hashCode => Object.hash(runtimeType,window,rangeStart,rangeEnd,totalExpense,totalIncome,totalBorrowed,totalLent,totalCredit,totalDebit,outstandingLiability,outstandingReceivable,const DeepCollectionEquality().hash(categoryDistribution),const DeepCollectionEquality().hash(trendPoints),const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'AnalyticsReport(window: $window, rangeStart: $rangeStart, rangeEnd: $rangeEnd, totalExpense: $totalExpense, totalIncome: $totalIncome, totalBorrowed: $totalBorrowed, totalLent: $totalLent, totalCredit: $totalCredit, totalDebit: $totalDebit, outstandingLiability: $outstandingLiability, outstandingReceivable: $outstandingReceivable, categoryDistribution: $categoryDistribution, trendPoints: $trendPoints, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $AnalyticsReportCopyWith<$Res>  {
  factory $AnalyticsReportCopyWith(AnalyticsReport value, $Res Function(AnalyticsReport) _then) = _$AnalyticsReportCopyWithImpl;
@useResult
$Res call({
 AnalyticsWindow window, DateTime rangeStart, DateTime rangeEnd, double totalExpense, double totalIncome, double totalBorrowed, double totalLent, double totalCredit, double totalDebit, double outstandingLiability, double outstandingReceivable, List<CategorySpend> categoryDistribution, List<TrendPoint> trendPoints, List<FinanceEntry> entries
});




}
/// @nodoc
class _$AnalyticsReportCopyWithImpl<$Res>
    implements $AnalyticsReportCopyWith<$Res> {
  _$AnalyticsReportCopyWithImpl(this._self, this._then);

  final AnalyticsReport _self;
  final $Res Function(AnalyticsReport) _then;

/// Create a copy of AnalyticsReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? rangeStart = null,Object? rangeEnd = null,Object? totalExpense = null,Object? totalIncome = null,Object? totalBorrowed = null,Object? totalLent = null,Object? totalCredit = null,Object? totalDebit = null,Object? outstandingLiability = null,Object? outstandingReceivable = null,Object? categoryDistribution = null,Object? trendPoints = null,Object? entries = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as AnalyticsWindow,rangeStart: null == rangeStart ? _self.rangeStart : rangeStart // ignore: cast_nullable_to_non_nullable
as DateTime,rangeEnd: null == rangeEnd ? _self.rangeEnd : rangeEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalBorrowed: null == totalBorrowed ? _self.totalBorrowed : totalBorrowed // ignore: cast_nullable_to_non_nullable
as double,totalLent: null == totalLent ? _self.totalLent : totalLent // ignore: cast_nullable_to_non_nullable
as double,totalCredit: null == totalCredit ? _self.totalCredit : totalCredit // ignore: cast_nullable_to_non_nullable
as double,totalDebit: null == totalDebit ? _self.totalDebit : totalDebit // ignore: cast_nullable_to_non_nullable
as double,outstandingLiability: null == outstandingLiability ? _self.outstandingLiability : outstandingLiability // ignore: cast_nullable_to_non_nullable
as double,outstandingReceivable: null == outstandingReceivable ? _self.outstandingReceivable : outstandingReceivable // ignore: cast_nullable_to_non_nullable
as double,categoryDistribution: null == categoryDistribution ? _self.categoryDistribution : categoryDistribution // ignore: cast_nullable_to_non_nullable
as List<CategorySpend>,trendPoints: null == trendPoints ? _self.trendPoints : trendPoints // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<FinanceEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsReport].
extension AnalyticsReportPatterns on AnalyticsReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsReport value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsReport value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AnalyticsWindow window,  DateTime rangeStart,  DateTime rangeEnd,  double totalExpense,  double totalIncome,  double totalBorrowed,  double totalLent,  double totalCredit,  double totalDebit,  double outstandingLiability,  double outstandingReceivable,  List<CategorySpend> categoryDistribution,  List<TrendPoint> trendPoints,  List<FinanceEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsReport() when $default != null:
return $default(_that.window,_that.rangeStart,_that.rangeEnd,_that.totalExpense,_that.totalIncome,_that.totalBorrowed,_that.totalLent,_that.totalCredit,_that.totalDebit,_that.outstandingLiability,_that.outstandingReceivable,_that.categoryDistribution,_that.trendPoints,_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AnalyticsWindow window,  DateTime rangeStart,  DateTime rangeEnd,  double totalExpense,  double totalIncome,  double totalBorrowed,  double totalLent,  double totalCredit,  double totalDebit,  double outstandingLiability,  double outstandingReceivable,  List<CategorySpend> categoryDistribution,  List<TrendPoint> trendPoints,  List<FinanceEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsReport():
return $default(_that.window,_that.rangeStart,_that.rangeEnd,_that.totalExpense,_that.totalIncome,_that.totalBorrowed,_that.totalLent,_that.totalCredit,_that.totalDebit,_that.outstandingLiability,_that.outstandingReceivable,_that.categoryDistribution,_that.trendPoints,_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AnalyticsWindow window,  DateTime rangeStart,  DateTime rangeEnd,  double totalExpense,  double totalIncome,  double totalBorrowed,  double totalLent,  double totalCredit,  double totalDebit,  double outstandingLiability,  double outstandingReceivable,  List<CategorySpend> categoryDistribution,  List<TrendPoint> trendPoints,  List<FinanceEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsReport() when $default != null:
return $default(_that.window,_that.rangeStart,_that.rangeEnd,_that.totalExpense,_that.totalIncome,_that.totalBorrowed,_that.totalLent,_that.totalCredit,_that.totalDebit,_that.outstandingLiability,_that.outstandingReceivable,_that.categoryDistribution,_that.trendPoints,_that.entries);case _:
  return null;

}
}

}

/// @nodoc


class _AnalyticsReport extends AnalyticsReport {
  const _AnalyticsReport({required this.window, required this.rangeStart, required this.rangeEnd, required this.totalExpense, required this.totalIncome, required this.totalBorrowed, required this.totalLent, required this.totalCredit, required this.totalDebit, required this.outstandingLiability, required this.outstandingReceivable, required final  List<CategorySpend> categoryDistribution, required final  List<TrendPoint> trendPoints, required final  List<FinanceEntry> entries}): _categoryDistribution = categoryDistribution,_trendPoints = trendPoints,_entries = entries,super._();
  

@override final  AnalyticsWindow window;
@override final  DateTime rangeStart;
@override final  DateTime rangeEnd;
@override final  double totalExpense;
@override final  double totalIncome;
@override final  double totalBorrowed;
@override final  double totalLent;
@override final  double totalCredit;
@override final  double totalDebit;
@override final  double outstandingLiability;
@override final  double outstandingReceivable;
 final  List<CategorySpend> _categoryDistribution;
@override List<CategorySpend> get categoryDistribution {
  if (_categoryDistribution is EqualUnmodifiableListView) return _categoryDistribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryDistribution);
}

 final  List<TrendPoint> _trendPoints;
@override List<TrendPoint> get trendPoints {
  if (_trendPoints is EqualUnmodifiableListView) return _trendPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trendPoints);
}

 final  List<FinanceEntry> _entries;
@override List<FinanceEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of AnalyticsReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsReportCopyWith<_AnalyticsReport> get copyWith => __$AnalyticsReportCopyWithImpl<_AnalyticsReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsReport&&(identical(other.window, window) || other.window == window)&&(identical(other.rangeStart, rangeStart) || other.rangeStart == rangeStart)&&(identical(other.rangeEnd, rangeEnd) || other.rangeEnd == rangeEnd)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalBorrowed, totalBorrowed) || other.totalBorrowed == totalBorrowed)&&(identical(other.totalLent, totalLent) || other.totalLent == totalLent)&&(identical(other.totalCredit, totalCredit) || other.totalCredit == totalCredit)&&(identical(other.totalDebit, totalDebit) || other.totalDebit == totalDebit)&&(identical(other.outstandingLiability, outstandingLiability) || other.outstandingLiability == outstandingLiability)&&(identical(other.outstandingReceivable, outstandingReceivable) || other.outstandingReceivable == outstandingReceivable)&&const DeepCollectionEquality().equals(other._categoryDistribution, _categoryDistribution)&&const DeepCollectionEquality().equals(other._trendPoints, _trendPoints)&&const DeepCollectionEquality().equals(other._entries, _entries));
}


@override
int get hashCode => Object.hash(runtimeType,window,rangeStart,rangeEnd,totalExpense,totalIncome,totalBorrowed,totalLent,totalCredit,totalDebit,outstandingLiability,outstandingReceivable,const DeepCollectionEquality().hash(_categoryDistribution),const DeepCollectionEquality().hash(_trendPoints),const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'AnalyticsReport(window: $window, rangeStart: $rangeStart, rangeEnd: $rangeEnd, totalExpense: $totalExpense, totalIncome: $totalIncome, totalBorrowed: $totalBorrowed, totalLent: $totalLent, totalCredit: $totalCredit, totalDebit: $totalDebit, outstandingLiability: $outstandingLiability, outstandingReceivable: $outstandingReceivable, categoryDistribution: $categoryDistribution, trendPoints: $trendPoints, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsReportCopyWith<$Res> implements $AnalyticsReportCopyWith<$Res> {
  factory _$AnalyticsReportCopyWith(_AnalyticsReport value, $Res Function(_AnalyticsReport) _then) = __$AnalyticsReportCopyWithImpl;
@override @useResult
$Res call({
 AnalyticsWindow window, DateTime rangeStart, DateTime rangeEnd, double totalExpense, double totalIncome, double totalBorrowed, double totalLent, double totalCredit, double totalDebit, double outstandingLiability, double outstandingReceivable, List<CategorySpend> categoryDistribution, List<TrendPoint> trendPoints, List<FinanceEntry> entries
});




}
/// @nodoc
class __$AnalyticsReportCopyWithImpl<$Res>
    implements _$AnalyticsReportCopyWith<$Res> {
  __$AnalyticsReportCopyWithImpl(this._self, this._then);

  final _AnalyticsReport _self;
  final $Res Function(_AnalyticsReport) _then;

/// Create a copy of AnalyticsReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? rangeStart = null,Object? rangeEnd = null,Object? totalExpense = null,Object? totalIncome = null,Object? totalBorrowed = null,Object? totalLent = null,Object? totalCredit = null,Object? totalDebit = null,Object? outstandingLiability = null,Object? outstandingReceivable = null,Object? categoryDistribution = null,Object? trendPoints = null,Object? entries = null,}) {
  return _then(_AnalyticsReport(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as AnalyticsWindow,rangeStart: null == rangeStart ? _self.rangeStart : rangeStart // ignore: cast_nullable_to_non_nullable
as DateTime,rangeEnd: null == rangeEnd ? _self.rangeEnd : rangeEnd // ignore: cast_nullable_to_non_nullable
as DateTime,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalBorrowed: null == totalBorrowed ? _self.totalBorrowed : totalBorrowed // ignore: cast_nullable_to_non_nullable
as double,totalLent: null == totalLent ? _self.totalLent : totalLent // ignore: cast_nullable_to_non_nullable
as double,totalCredit: null == totalCredit ? _self.totalCredit : totalCredit // ignore: cast_nullable_to_non_nullable
as double,totalDebit: null == totalDebit ? _self.totalDebit : totalDebit // ignore: cast_nullable_to_non_nullable
as double,outstandingLiability: null == outstandingLiability ? _self.outstandingLiability : outstandingLiability // ignore: cast_nullable_to_non_nullable
as double,outstandingReceivable: null == outstandingReceivable ? _self.outstandingReceivable : outstandingReceivable // ignore: cast_nullable_to_non_nullable
as double,categoryDistribution: null == categoryDistribution ? _self._categoryDistribution : categoryDistribution // ignore: cast_nullable_to_non_nullable
as List<CategorySpend>,trendPoints: null == trendPoints ? _self._trendPoints : trendPoints // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<FinanceEntry>,
  ));
}


}

// dart format on
