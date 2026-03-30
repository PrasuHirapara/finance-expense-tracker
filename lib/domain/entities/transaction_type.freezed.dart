// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionType {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransactionType()';
}


}

/// @nodoc
class $TransactionTypeCopyWith<$Res>  {
$TransactionTypeCopyWith(TransactionType _, $Res Function(TransactionType) __);
}


/// Adds pattern-matching-related methods to [TransactionType].
extension TransactionTypePatterns on TransactionType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExpenseTransactionType value)?  expense,TResult Function( IncomeTransactionType value)?  income,TResult Function( BorrowedTransactionType value)?  borrowed,TResult Function( LentTransactionType value)?  lent,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExpenseTransactionType() when expense != null:
return expense(_that);case IncomeTransactionType() when income != null:
return income(_that);case BorrowedTransactionType() when borrowed != null:
return borrowed(_that);case LentTransactionType() when lent != null:
return lent(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExpenseTransactionType value)  expense,required TResult Function( IncomeTransactionType value)  income,required TResult Function( BorrowedTransactionType value)  borrowed,required TResult Function( LentTransactionType value)  lent,}){
final _that = this;
switch (_that) {
case ExpenseTransactionType():
return expense(_that);case IncomeTransactionType():
return income(_that);case BorrowedTransactionType():
return borrowed(_that);case LentTransactionType():
return lent(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExpenseTransactionType value)?  expense,TResult? Function( IncomeTransactionType value)?  income,TResult? Function( BorrowedTransactionType value)?  borrowed,TResult? Function( LentTransactionType value)?  lent,}){
final _that = this;
switch (_that) {
case ExpenseTransactionType() when expense != null:
return expense(_that);case IncomeTransactionType() when income != null:
return income(_that);case BorrowedTransactionType() when borrowed != null:
return borrowed(_that);case LentTransactionType() when lent != null:
return lent(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  expense,TResult Function()?  income,TResult Function()?  borrowed,TResult Function()?  lent,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExpenseTransactionType() when expense != null:
return expense();case IncomeTransactionType() when income != null:
return income();case BorrowedTransactionType() when borrowed != null:
return borrowed();case LentTransactionType() when lent != null:
return lent();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  expense,required TResult Function()  income,required TResult Function()  borrowed,required TResult Function()  lent,}) {final _that = this;
switch (_that) {
case ExpenseTransactionType():
return expense();case IncomeTransactionType():
return income();case BorrowedTransactionType():
return borrowed();case LentTransactionType():
return lent();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  expense,TResult? Function()?  income,TResult? Function()?  borrowed,TResult? Function()?  lent,}) {final _that = this;
switch (_that) {
case ExpenseTransactionType() when expense != null:
return expense();case IncomeTransactionType() when income != null:
return income();case BorrowedTransactionType() when borrowed != null:
return borrowed();case LentTransactionType() when lent != null:
return lent();case _:
  return null;

}
}

}

/// @nodoc


class ExpenseTransactionType extends TransactionType {
  const ExpenseTransactionType(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseTransactionType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransactionType.expense()';
}


}




/// @nodoc


class IncomeTransactionType extends TransactionType {
  const IncomeTransactionType(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomeTransactionType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransactionType.income()';
}


}




/// @nodoc


class BorrowedTransactionType extends TransactionType {
  const BorrowedTransactionType(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BorrowedTransactionType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransactionType.borrowed()';
}


}




/// @nodoc


class LentTransactionType extends TransactionType {
  const LentTransactionType(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LentTransactionType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransactionType.lent()';
}


}




// dart format on
