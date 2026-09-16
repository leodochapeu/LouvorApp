import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/culto_list_filter.dart';
import '../providers/culto_providers.dart';

/// Date-range chip + "cultos passados" toggle under the cultos search field.
class CultoListFilters extends ConsumerWidget {
  const CultoListFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(cultoListFilterProvider);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.sm),
      child: Wrap(
        spacing: AppSizes.sm,
        runSpacing: AppSizes.sm,
        children: [
          InputChip(
            avatar: Icon(
              Icons.date_range,
              size: 18,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            label: Text(_rangeLabel(filter)),
            selected: true,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            tooltip: 'Escolher período',
            onPressed: () => _pickRange(context, ref, filter, now),
            onDeleted: filter.hasCustomRange
                ? () => ref.read(cultoListFilterProvider.notifier).setCustomRange(null)
                : null,
            deleteButtonTooltip:
                filter.hasCustomRange ? 'Voltar para esta semana' : null,
          ),
          FilterChip(
            label: const Text('Cultos passados'),
            tooltip: 'Incluir cultos que já ocorreram',
            visualDensity: VisualDensity.compact,
            selected: filter.includePast,
            onSelected: (selected) =>
                ref.read(cultoListFilterProvider.notifier).setIncludePast(selected),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(CultoListFilter filter) {
    if (filter.customRange != null) {
      return DateFormatters.range(filter.customRange!.start, filter.customRange!.end);
    }
    if (filter.includePast) return 'Todos os cultos';
    return 'Esta semana';
  }

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    CultoListFilter filter,
    DateTime now,
  ) async {
    final firstDate = CultoListFiltering.firstSelectableDate(filter, now);
    final lastDate = CultoListFiltering.lastSelectableDate(now);
    final fallback = CultoListFiltering.defaultRange(now);
    final current = filter.customRange ?? fallback;

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
