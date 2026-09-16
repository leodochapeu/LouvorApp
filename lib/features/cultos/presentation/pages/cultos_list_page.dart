import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/share/share_preview.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_search_field.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../../../core/widgets/layout/app_page_title.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/culto_list_filter.dart';
import '../providers/culto_providers.dart';
import '../widgets/culto_card.dart';
import '../widgets/culto_list_filters.dart';

/// Public cultos list with search and date filters. Create/edit stays behind login.
class CultosListPage extends ConsumerStatefulWidget {
  const CultosListPage({super.key});

  @override
  ConsumerState<CultosListPage> createState() => _CultosListPageState();
}

class _CultosListPageState extends ConsumerState<CultosListPage> {
  late final _searchController = TextEditingController(
    text: ref.read(cultoListFilterProvider).query,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cultosAsync = ref.watch(filteredCultosProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final filter = ref.watch(cultoListFilterProvider);

    return AppPageTitle(
      title: SharePreview.pageTitle('Cultos'),
      child: Scaffold(
        appBar: AppBar(title: const Text('Cultos')),
        drawer: const AppDrawer(),
        floatingActionButton: isLoggedIn
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.cultoNew),
                icon: const Icon(Icons.add),
                label: const Text('Novo culto'),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSearchField(
                            controller: _searchController,
                            hint: 'Buscar por nome ou data',
                            onChanged: (value) => ref
                                .read(cultoListFilterProvider.notifier)
                                .setQuery(value),
                          ),
                        ),
                        const CultoListFilterButton(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cultosAsync.when(
                      skipError: true,
                      skipLoadingOnReload: true,
                      loading: () => const AppLoadingIndicator(),
                      error: (error, _) => AppErrorView.fromWatch(
                        error: error,
                        message: 'Não foi possível carregar os cultos.',
                        onRetry: () => ref.invalidate(cultosStreamProvider),
                      ),
                      data: (cultos) {
                        if (cultos.isEmpty) {
                          return AppEmptyState(
                            icon: Icons.event_note_outlined,
                            title: _emptyTitle(filter),
                            message: _emptyMessage(filter),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.md,
                            AppSizes.sm,
                            AppSizes.md,
                            AppSizes.xxl,
                          ),
                          itemCount: cultos.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                          itemBuilder: (context, index) {
                            final culto = cultos[index];
                            return CultoCard(
                              culto: culto,
                              onTap: () =>
                                  context.push(AppRoutes.cultoDetailPath(culto.slug)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _emptyTitle(CultoListFilter filter) {
    if (filter.hasQuery) return 'Nenhum culto encontrado';
    if (filter.hasCustomRange) return 'Nenhum culto nesse período';
    return 'Nenhum evento cadastrado nessa semana';
  }

  String _emptyMessage(CultoListFilter filter) {
    if (filter.hasQuery) return 'Tente buscar por outro nome ou data.';
    if (filter.hasCustomRange) {
      return 'Tente outro intervalo, ou ative "Cultos passados" para incluir datas anteriores.';
    }
    return 'Abra os filtros para mudar o período ou ver cultos passados.';
  }
}
