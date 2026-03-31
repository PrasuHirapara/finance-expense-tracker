import 'package:flutter/material.dart';

import '../extensions/date_time_x.dart';

enum ModuleExportRange { week, month, year, custom }

enum ModuleExportFormat { pdf, excel }

extension ModuleExportRangeX on ModuleExportRange {
  String get label => switch (this) {
    ModuleExportRange.week => 'Week',
    ModuleExportRange.month => 'Month',
    ModuleExportRange.year => 'Year',
    ModuleExportRange.custom => 'Custom',
  };

  DateTimeRange resolveRange(DateTime anchor) {
    final normalizedAnchor = anchor.startOfDay;
    return switch (this) {
      ModuleExportRange.week => DateTimeRange(
        start: normalizedAnchor.startOfWeek,
        end: normalizedAnchor.endOfWeek,
      ),
      ModuleExportRange.month => DateTimeRange(
        start: normalizedAnchor.startOfMonth,
        end: normalizedAnchor.endOfMonth,
      ),
      ModuleExportRange.year => DateTimeRange(
        start: normalizedAnchor.startOfYear,
        end: normalizedAnchor.endOfYear,
      ),
      ModuleExportRange.custom => DateTimeRange(
        start: normalizedAnchor,
        end: normalizedAnchor.endOfDay,
      ),
    };
  }
}

extension ModuleExportFormatX on ModuleExportFormat {
  String get label => switch (this) {
    ModuleExportFormat.pdf => 'PDF',
    ModuleExportFormat.excel => 'Excel',
  };

  String get fileExtension => switch (this) {
    ModuleExportFormat.pdf => 'pdf',
    ModuleExportFormat.excel => 'xlsx',
  };
}
