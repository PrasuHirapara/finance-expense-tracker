import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_payload.freezed.dart';

@freezed
abstract class ExportChartSnapshots with _$ExportChartSnapshots {
  const factory ExportChartSnapshots({
    Uint8List? pieChart,
    Uint8List? lineChart,
    Uint8List? barChart,
  }) = _ExportChartSnapshots;
}
