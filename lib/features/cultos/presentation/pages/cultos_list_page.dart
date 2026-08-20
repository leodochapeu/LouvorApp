import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_search_field.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/culto_providers.dart';
import '../widgets/culto_card.dart';

/// Public cultos list with search. Create/edit stays behind login.
class CultosListPage extends ConsumerStatefulWidget {
  const CultosListPage({super.key});

  @override
  ConsumerState<CultosListPage> createState() => _CultosListPageState();
}

class _CultosListPageState extends ConsumerState<CultosListPage> {
  late final _searchController = TextEditingController(
    text: ref.read(cultoSearchQueryProvider),
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
    final hasQuery = ref.watch(cultoSearchQueryProvider).isNotEmpty;

    return Scaffold(
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
                  child: AppSearchField(
                    controller: _searchController,
                    hint: 'Buscar por nome ou data',
                    onChanged: (value) =>
                        ref.read(cultoSearchQueryProvider.notifier).state = value,
                  ),
                ),
                Expanded(
                  child: cultosAsync.when(
                    loading: () => const AppLoadingIndicator(),
                    error: (error, _) => AppErrorView(
                      message: 'Não foi possível carregar os cultos.\n$error',
                      onRetry: () => ref.invalidate(cultosStreamProvider),
                    ),
                    data: (cultos) {
                      if (cultos.isEmpty) {
                        return AppEmptyState(
                          icon: Icons.event_note_outlined,
                          title: hasQuery
                              ? 'Nenhum culto encontrado'
                              : 'Nenhum culto cadastrado',
                          message: hasQuery
                              ? 'Tente buscar por outro nome ou data.'
                              : (isLoggedIn
                                  ? 'Toque em "Novo culto" para montar o primeiro.'
                                  : 'Faça login para cadastrar cultos.'),
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
                            onTap: () => context.push(AppRoutes.cultoDetailPath(culto.id)),
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
    );
  }
}
