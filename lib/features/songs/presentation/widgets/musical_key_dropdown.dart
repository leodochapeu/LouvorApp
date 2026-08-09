import 'package:flutter/material.dart';

import '../../../../core/constants/musical_keys.dart';

/// Dropdown to pick a musical key (used for both "tom original" and "tom
/// alterado"). When [allowEmpty] is true, an extra "Nenhum" option is
/// offered — used for the optional "tom alterado" field.
class MusicalKeyDropdown extends StatelessWidget {
  const MusicalKeyDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowEmpty = false,
    this.validator,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowEmpty;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      items: [
        if (allowEmpty)
          const DropdownMenuItem<String>(
            value: '',
            child: Text('Nenhum (usar o tom original)'),
          ),
        ...MusicalKeys.all.map(
          (key) => DropdownMenuItem<String>(value: key, child: Text(key)),
        ),
      ],
      onChanged: (selected) => onChanged(selected == '' ? null : selected),
    );
  }
}
