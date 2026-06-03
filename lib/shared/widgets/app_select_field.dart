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
    final fieldBottom = origin.dy + box.size.height;

    // Calculate available space below the field and cap menu height so it
    // stays below the widget without Flutter flipping it upward.
    final spaceBelow = overlay.size.height - fieldBottom;
    final menuMaxHeight = (spaceBelow - 16).clamp(120.0, 320.0);

    final selectedIndex = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        fieldBottom,
        overlay.size.width - origin.dx - box.size.width,
        // Set bottom so the menu is constrained to menuMaxHeight below the field.
        overlay.size.height - fieldBottom - menuMaxHeight,
      ),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
        maxHeight: menuMaxHeight,
      ),
      items: options
          .asMap()
          .map(
            (index, option) => MapEntry(
              index,
              PopupMenuItem<int>(
                value: index,
                child: Row(
                  children: <Widget>[
                    if (option.leading != null) ...[
                      option.leading!,
                      const SizedBox(width: 8),
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
            ),
          )
          .values
          .toList(growable: false),
    );

    if (selectedIndex != null) {
      onChanged(options[selectedIndex].value);
    }
  }
}
