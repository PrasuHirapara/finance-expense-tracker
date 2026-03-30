// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExportChartSnapshots {

 Uint8List? get pieChart; Uint8List? get lineChart; Uint8List? get barChart;
/// Create a copy of ExportChartSnapshots
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportChartSnapshotsCopyWith<ExportChartSnapshots> get copyWith => _$ExportChartSnapshotsCopyWithImpl<ExportChartSnapshots>(this as ExportChartSnapshots, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportChartSnapshots&&const DeepCollectionEquality().equals(other.pieChart, pieChart)&&const DeepCollectionEquality().equals(other.lineChart, lineChart)&&const DeepCollectionEquality().equals(other.barChart, barChart));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pieChart),const DeepCollectionEquality().hash(lineChart),const DeepCollectionEquality().hash(barChart));

@override
String toString() {
  return 'ExportChartSnapshots(pieChart: $pieChart, lineChart: $lineChart, barChart: $barChart)';
}


}

/// @nodoc
abstract mixin class $ExportChartSnapshotsCopyWith<$Res>  {
  factory $ExportChartSnapshotsCopyWith(ExportChartSnapshots value, $Res Function(ExportChartSnapshots) _then) = _$ExportChartSnapshotsCopyWithImpl;
@useResult
$Res call({
 Uint8List? pieChart, Uint8List? lineChart, Uint8List? barChart
});




}
/// @nodoc
class _$ExportChartSnapshotsCopyWithImpl<$Res>
    implements $ExportChartSnapshotsCopyWith<$Res> {
  _$ExportChartSnapshotsCopyWithImpl(this._self, this._then);

  final ExportChartSnapshots _self;
  final $Res Function(ExportChartSnapshots) _then;

/// Create a copy of ExportChartSnapshots
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pieChart = freezed,Object? lineChart = freezed,Object? barChart = freezed,}) {
  return _then(_self.copyWith(
pieChart: freezed == pieChart ? _self.pieChart : pieChart // ignore: cast_nullable_to_non_nullable
as Uint8List?,lineChart: freezed == lineChart ? _self.lineChart : lineChart // ignore: cast_nullable_to_non_nullable
as Uint8List?,barChart: freezed == barChart ? _self.barChart : barChart // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExportChartSnapshots].
extension ExportChartSnapshotsPatterns on ExportChartSnapshots {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExportChartSnapshots value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExportChartSnapshots() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExportChartSnapshots value)  $default,){
final _that = this;
switch (_that) {
case _ExportChartSnapshots():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExportChartSnapshots value)?  $default,){
final _that = this;
switch (_that) {
case _ExportChartSnapshots() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Uint8List? pieChart,  Uint8List? lineChart,  Uint8List? barChart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExportChartSnapshots() when $default != null:
return $default(_that.pieChart,_that.lineChart,_that.barChart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Uint8List? pieChart,  Uint8List? lineChart,  Uint8List? barChart)  $default,) {final _that = this;
switch (_that) {
case _ExportChartSnapshots():
return $default(_that.pieChart,_that.lineChart,_that.barChart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Uint8List? pieChart,  Uint8List? lineChart,  Uint8List? barChart)?  $default,) {final _that = this;
switch (_that) {
case _ExportChartSnapshots() when $default != null:
return $default(_that.pieChart,_that.lineChart,_that.barChart);case _:
  return null;

}
}

}

/// @nodoc


class _ExportChartSnapshots implements ExportChartSnapshots {
  const _ExportChartSnapshots({this.pieChart, this.lineChart, this.barChart});
  

@override final  Uint8List? pieChart;
@override final  Uint8List? lineChart;
@override final  Uint8List? barChart;

/// Create a copy of ExportChartSnapshots
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExportChartSnapshotsCopyWith<_ExportChartSnapshots> get copyWith => __$ExportChartSnapshotsCopyWithImpl<_ExportChartSnapshots>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExportChartSnapshots&&const DeepCollectionEquality().equals(other.pieChart, pieChart)&&const DeepCollectionEquality().equals(other.lineChart, lineChart)&&const DeepCollectionEquality().equals(other.barChart, barChart));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pieChart),const DeepCollectionEquality().hash(lineChart),const DeepCollectionEquality().hash(barChart));

@override
String toString() {
  return 'ExportChartSnapshots(pieChart: $pieChart, lineChart: $lineChart, barChart: $barChart)';
}


}

/// @nodoc
abstract mixin class _$ExportChartSnapshotsCopyWith<$Res> implements $ExportChartSnapshotsCopyWith<$Res> {
  factory _$ExportChartSnapshotsCopyWith(_ExportChartSnapshots value, $Res Function(_ExportChartSnapshots) _then) = __$ExportChartSnapshotsCopyWithImpl;
@override @useResult
$Res call({
 Uint8List? pieChart, Uint8List? lineChart, Uint8List? barChart
});




}
/// @nodoc
class __$ExportChartSnapshotsCopyWithImpl<$Res>
    implements _$ExportChartSnapshotsCopyWith<$Res> {
  __$ExportChartSnapshotsCopyWithImpl(this._self, this._then);

  final _ExportChartSnapshots _self;
  final $Res Function(_ExportChartSnapshots) _then;

/// Create a copy of ExportChartSnapshots
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pieChart = freezed,Object? lineChart = freezed,Object? barChart = freezed,}) {
  return _then(_ExportChartSnapshots(
pieChart: freezed == pieChart ? _self.pieChart : pieChart // ignore: cast_nullable_to_non_nullable
as Uint8List?,lineChart: freezed == lineChart ? _self.lineChart : lineChart // ignore: cast_nullable_to_non_nullable
as Uint8List?,barChart: freezed == barChart ? _self.barChart : barChart // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

// dart format on
