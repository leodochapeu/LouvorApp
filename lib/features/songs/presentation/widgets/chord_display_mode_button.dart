import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/song_providers.dart';

/// Compact icon that opens a popover to switch chord notation between
/// scale degrees (`1 2 3…`) and note names (`C D E…`).
class ChordDisplayModeButton extends ConsumerWidget {
  const ChordDisplayModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(chordDisplayModeProvider);
    final theme = Theme.of(context);

    return PopupMenuButton<ChordDisplayMode>(
      tooltip: 'Notação dos acordes',
      initialValue: mode,
      icon: Icon(
        Icons.arrow_drop_down_circle_outlined,
        color: mode == ChordDisplayMode.names ? theme.colorScheme.primary : null,
      ),
      onSelected: (selected) {
        ref.read(chordDisplayModeProvider.notifier).state = selected;
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: ChordDisplayMode.degrees,
          checked: mode == ChordDisplayMode.degrees,
          child: const Text('Graus (1 2 3 4 5 6 7)'),
        ),
        CheckedPopupMenuItem(
          value: ChordDisplayMode.names,
          checked: mode == ChordDisplayMode.names,
          child: const Text('Cifras (C D E F G A B)'),
        ),
      ],
    );
  }
}
