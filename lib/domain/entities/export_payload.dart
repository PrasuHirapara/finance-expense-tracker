import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ExportChartSnapshots extends Equatable {
  const ExportChartSnapshots({
    this.pieChart,
    this.lineChart,
    this.barChart,
  });

  final Uint8List? pieChart;
  final Uint8List? lineChart;
  final Uint8List? barChart;

  @override
  List<Object?> get props => <Object?>[pieChart, lineChart, barChart];
}
