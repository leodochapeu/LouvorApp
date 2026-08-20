import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../domain/entities/culto.dart';
import '../providers/culto_providers.dart';
import '../widgets/culto_song_picker.dart';

/// Create/edit form for a culto. `cultoId == null` means "create new".
class CultoFormPage extends ConsumerWidget {
  const CultoFormPage({super.key, this.cultoId});

  final String? cultoId;

  bool get isEditing => cultoId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isEditing ? 'Editar culto' : 'Novo culto';

    Widget body;
    if (!isEditing) {
      body = const _CultoFormBody(culto: null);
    } else {
      final cultoAsync = ref.watch(cultoByIdProvider(cultoId!));
      body = cultoAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => AppErrorView(
          message: 'Não foi possível carregar o culto.\n$error',
          onRetry: () => ref.invalidate(cultoByIdProvider(cultoId!)),
        ),
        data: (culto) => _CultoFormBody(key: ValueKey(culto.id), culto: culto),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _CultoFormBody extends ConsumerStatefulWidget {
  const _CultoFormBody({super.key, required this.culto});

  /// `null` when creating a new culto.
  final Culto? culto;

  @override
  ConsumerState<_CultoFormBody> createState() => _CultoFormBodyState();
}

class _CultoFormBodyState extends ConsumerState<_CultoFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.culto?.title ?? '');
  late DateTime? _date = widget.culto?.date;
  late List<String> _songIds = List.of(widget.culto?.songIds ?? const []);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      helpText: 'Data do culto',
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data do culto.')),
      );
      return;
    }

    if (_songIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma música.')),
      );
      return;
    }

    final input = CultoInput(
      title: _titleController.text.trim(),
      date: _date!,
      songIds: _songIds,
    );

    final saved = await ref
        .read(cultoMutationControllerProvider.notifier)
        .save(id: widget.culto?.id, input: input);

    if (!mounted) return;

    if (saved != null) {
      context.go(AppRoutes.cultoDetailPath(saved.id));
    } else {
      final error = ref.read(cultoMutationControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o culto.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(cultoMutationControllerProvider).isLoading;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _titleController,
              label: 'Nome do culto',
              hint: 'Ex.: Culto da Família, Santa Ceia',
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(value, field: 'O nome'),
            ),
            const SizedBox(height: AppSizes.lg),
            FormField<DateTime>(
              initialValue: _date,
              validator: (value) => value == null ? 'Selecione a data' : null,
              builder: (state) {
                return InkWell(
                  onTap: () async {
                    await _pickDate();
                    state.didChange(_date);
                  },
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data do culto',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      errorText: state.errorText,
                    ),
                    child: Text(
                      _date == null
                          ? 'Selecionar data'
                          : DateFormatters.long(_date!),
                      style: _date == null
                          ? theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : theme.textTheme.bodyLarge,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.xl),
            CultoSongPicker(
              songIds: _songIds,
              onChanged: (ids) => setState(() => _songIds = ids),
            ),
            const SizedBox(height: AppSizes.xl),
            AppPrimaryButton(
              label: widget.culto == null ? 'Cadastrar culto' : 'Salvar alterações',
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}
