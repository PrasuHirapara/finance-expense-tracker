import 'package:flutter/material.dart';

class AppSelectOption<T> {
  const AppSelectOption({
    required this.value,
    required this.label,
    this.leading,
  });

  final T value;
  final String label;
  final Widget? leading;
}

class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.errorText,
    this.hintText,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? errorText;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selectedOption = options.cast<AppSelectOption<T>?>().firstWhere(
      (option) => option?.value == value,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: enabled ? () => _openMenu(context) : null,
      child: InputDecorator(
        isEmpty: selectedOption == null,
        decoration: InputDecoration(
          enabled: enabled,
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Row(
          children: <Widget>[
            if (selectedOption?.leading != null) ...<Widget>[
              selectedOption!.leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                selectedOption?.label ?? hintText ?? 'Select',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: selectedOption == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height,
        overlay.size.width - origin.dx - box.size.width,
        overlay.size.height - origin.dy,
      ),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
        maxHeight: 320,
      ),
      items: options
          .map(
            (option) => PopupMenuItem<T>(
              value: option.value,
              child: Row(
                children: <Widget>[
                  if (option.leading != null) ...<Widget>[
                    option.leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}
