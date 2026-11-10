import 'package:flutter/material.dart';

/// Filtros accesibles con selección visible en modo claro y oscuro.
class FilterChipsRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  const FilterChipsRow({super.key, required this.values, required this.selected,
    required this.labelOf, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labelOf(value).toUpperCase()),
              selected: selected == value,
              showCheckmark: false,
              avatar: selected == value
                ? const Icon(Icons.check_circle, size: 17) : null,
              onSelected: (_) => onSelected(value),
              labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: .7,
                color: selected == value ? colors.onPrimaryContainer : colors.onSurface),
              selectedColor: colors.primaryContainer,
              backgroundColor: colors.surfaceContainerLow,
              side: BorderSide(color: selected == value
                ? colors.primary : colors.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
      ]),
    );
  }
}
