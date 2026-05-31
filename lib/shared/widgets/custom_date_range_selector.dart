import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class CustomDateRangeSelector extends StatelessWidget {
  const CustomDateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime startDate, DateTime endDate) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: <Widget>[
        SizedBox(
          width: 190,
          child: _DateRangeField(
            label: 'From Date',
            value: AppConstants.shortDateFormat.format(startDate),
            icon: Icons.event_rounded,
            onTap: () => _pickDate(context, isStart: true),
          ),
        ),
        SizedBox(
          width: 190,
          child: _DateRangeField(
            label: 'To Date',
            value: AppConstants.shortDateFormat.format(endDate),
            icon: Icons.event_available_rounded,
            onTap: () => _pickDate(context, isStart: false),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? startDate : endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }

    if (isStart) {
      onChanged(picked, endDate);
    } else {
      onChanged(startDate, picked);
    }
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(icon)),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
