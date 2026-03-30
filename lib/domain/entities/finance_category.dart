import 'package:equatable/equatable.dart';

class FinanceCategory extends Equatable {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final int id;
  final String name;
  final int iconCodePoint;
  final int colorValue;

  @override
  List<Object?> get props => <Object?>[id, name, iconCodePoint, colorValue];
}
