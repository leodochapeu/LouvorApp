import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/buttons/app_icon_button.dart';
import '../../../../core/widgets/buttons/app_text_button.dart';
import '../../domain/culto_list_filter.dart';
import '../providers/culto_providers.dart';

/// Filter-icon button that opens the cultos list filter dialog.
class CultoListFilterButton extends ConsumerWidget {
  const CultoListFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(cultoListFilterProvider);
    return Badge(
      isLabelVisible: filter.hasActiveFilters,
      child: AppIconButton(
        icon: Icons.filter_alt_outlined,
        tooltip: 'Filtros',
        onPressed: () => CultoListFiltersDialog.show(context),
      ),
    );
  }
}

/// Modal with the date range and "cultos passados" toggle.
class CultoListFiltersDialog extends ConsumerWidget {
  const CultoListFiltersDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const CultoListFiltersDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(cultoListFilterProvider);
    final now = DateTime.now();
    final range = CultoListFiltering.effectiveRange(filter, now);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Filtros'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cultos passados'),
              subtitle: Text(
                filter.includePast
                    ? 'Inclui dias anteriores dentro do período.'
                    : 'O período não pode começar antes de hoje.',
                style: theme.textTheme.bodySmall,
              ),
              value: filter.includePast,
              onChanged: (selected) =>
                  ref.read(cultoListFilterProvider.notifier).setIncludePast(selected),
            ),
            const SizedBox(height: AppSizes.md),
            Text('Período', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSizes.sm),
            OutlinedButton.icon(
              onPressed: () => _pickRange(context, ref, filter, now),
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                DateFormatters.range(range.start, range.end),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              filter.hasCustomRange ? 'Intervalo personalizado' : 'Esta semana',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (filter.hasActiveFilters)
          AppTextButton(
            label: 'Limpar',
            onPressed: () => ref.read(cultoListFilterProvider.notifier).reset(),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ver cultos'),
        ),
      ],
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    CultoListFilter filter,
    DateTime now,
  ) async {
    final firstDate = CultoListFiltering.firstSelectableDate(filter, now);
    final lastDate = CultoListFiltering.lastSelectableDate(now);
    final current = CultoListFiltering.effectiveRange(filter, now);

    var start = CultoListFiltering.dateOnly(current.start);
    var end = CultoListFiltering.dateOnly(current.end);
    if (start.isBefore(firstDate)) start = firstDate;
    if (end.isBefore(start)) end = start;
    if (end.isAfter(lastDate)) end = lastDate;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: filter.includePast
          ? 'Período dos cultos'
          : 'Período dos cultos (a partir de hoje)',
      saveText: 'Filtrar',
      cancelText: 'Cancelar',
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;

    ref.read(cultoListFilterProvider.notifier).setCustomRange(
      CultoDateRange(start: picked.start, end: picked.end),
    );
  }
}
