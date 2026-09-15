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
import '../../../songs/domain/entities/song.dart';
import '../../../songs/domain/song_catalog_lookup.dart';
import '../../../songs/presentation/pages/song_form_page.dart';
import '../../../songs/presentation/providers/song_providers.dart';
import '../../domain/culto_template.dart';
import '../../domain/entities/culto.dart';
import '../providers/culto_providers.dart';
import '../widgets/culto_song_picker.dart';
import '../widgets/culto_template_paste.dart';
import '../widgets/missing_template_songs_alert.dart';

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
        skipError: true,
        skipLoadingOnReload: true,
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => AppErrorView.fromWatch(
          error: error,
          message: 'Não foi possível carregar o culto.',
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
  late Map<String, String> _songKeys = Map.of(widget.culto?.songKeys ?? const {});
  List<CultoTemplateSong> _templateSongs = const [];

  bool get _isCreating => widget.culto == null;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<CultoTemplateSong> _missingSongs(List<Song> catalog) {
    return [
      for (final item in _templateSongs)
        if (SongCatalogLookup.find(
              catalog: catalog,
              title: item.title,
              authors: item.authors,
              referenceUrl: item.referenceUrl,
            ) ==
            null)
          item,
    ];
  }

  void _syncSongIds(List<Song> catalog, {bool applyTemplateKeys = false}) {
    final matched = <String>[];
    final keys = <String, String>{};
    for (final item in _templateSongs) {
      final song = SongCatalogLookup.find(
        catalog: catalog,
        title: item.title,
        authors: item.authors,
        referenceUrl: item.referenceUrl,
      );
      if (song != null && !matched.contains(song.id)) {
        matched.add(song.id);
        final existing = _songKeys[song.id];
        if (!applyTemplateKeys && existing != null && existing.trim().isNotEmpty) {
          keys[song.id] = existing.trim();
        } else {
          final templateKey = item.musicalKey?.trim();
          if (templateKey != null &&
              templateKey.isNotEmpty &&
              templateKey != song.originalKey) {
            keys[song.id] = templateKey;
          }
        }
      }
    }
    final extras = _songIds.where((id) => !matched.contains(id));
    for (final id in extras) {
      final existing = _songKeys[id];
      if (existing != null && existing.trim().isNotEmpty) {
        keys[id] = existing.trim();
      }
    }
    _songIds = [...matched, ...extras];
    _songKeys = keys;
  }

  void _applyTemplate(CultoTemplate template) {
    final catalog = ref.read(songsStreamProvider).value ?? const [];
    setState(() {
      if (template.title != null && template.title!.trim().isNotEmpty) {
        _titleController.text = template.title!;
      }
      if (template.date != null) {
        _date = template.date;
      }
      _templateSongs = template.songs;
      _syncSongIds(catalog, applyTemplateKeys: true);
    });

    final missing = _missingSongs(catalog);
    final matchedCount = template.songs.length - missing.length;
    final message = missing.isEmpty
        ? 'Culto preenchido com ${template.songs.length} '
            '${template.songs.length == 1 ? 'música' : 'músicas'}.'
        : '$matchedCount de ${template.songs.length} músicas já estão cadastradas. '
            'Cadastre as que faltam antes de criar o culto.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _registerMissingSong(CultoTemplateSong item) async {
    final saved = await context.push<Song>(
      AppRoutes.songNew,
      extra: SongFormArgs(
        popOnSave: true,
        prefill: SongFormPrefill(
          title: item.title,
          authors: item.authors,
          referenceUrl: item.referenceUrl,
        ),
      ),
    );
    if (!mounted) return;

    final catalog = [
      ...?ref.read(songsStreamProvider).value,
      if (saved != null) saved,
    ];
    setState(() => _syncSongIds(catalog));
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

    final catalog = ref.read(songsStreamProvider).value ?? const [];
    final missing = _missingSongs(catalog);
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missing.length == 1
                ? 'Cadastre a música que falta antes de criar o culto.'
                : 'Cadastre as ${missing.length} músicas que faltam antes de criar o culto.',
          ),
        ),
      );
      return;
    }

    if (_songIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma música.')),
      );
      return;
    }

    final byId = {for (final song in catalog) song.id: song};
    final songKeys = <String, String>{};
    for (final id in _songIds) {
      final key = _songKeys[id]?.trim();
      final original = byId[id]?.originalKey;
      if (key != null && key.isNotEmpty && key != original) {
        songKeys[id] = key;
      }
    }

    final input = CultoInput(
      title: _titleController.text.trim(),
      date: _date!,
      songIds: _songIds,
      songKeys: songKeys,
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
    final songsAsync = ref.watch(songsStreamProvider);
    final catalog = songsAsync.value ?? const <Song>[];
    final missing = songsAsync.hasValue ? _missingSongs(catalog) : const <CultoTemplateSong>[];
    final hasUnresolvedTemplate =
        _templateSongs.isNotEmpty && (!songsAsync.hasValue || missing.isNotEmpty);
    final theme = Theme.of(context);

    ref.listen(songsStreamProvider, (previous, next) {
      final songs = next.value;
      if (songs == null || _templateSongs.isEmpty) return;
      setState(() => _syncSongIds(songs));
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isCreating) ...[
              CultoTemplatePaste(onParsed: _applyTemplate),
              const SizedBox(height: AppSizes.xl),
            ],
            AppTextField(
              controller: _titleController,
              label: 'Nome do culto',
              hint: 'Ex.: Culto da Família, Santa Ceia',
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(value, field: 'O nome'),
            ),
            const SizedBox(height: AppSizes.lg),
            FormField<DateTime>(
              key: ValueKey(_date),
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
            if (missing.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xl),
              MissingTemplateSongsAlert(
                songs: missing,
                onRegister: _registerMissingSong,
              ),
            ],
            const SizedBox(height: AppSizes.xl),
            CultoSongPicker(
              songIds: _songIds,
              songKeys: _songKeys,
              onChanged: (ids, keys) => setState(() {
                _songIds = ids;
                _songKeys = keys;
              }),
            ),
            const SizedBox(height: AppSizes.xl),
            AppPrimaryButton(
              label: widget.culto == null ? 'Cadastrar culto' : 'Salvar alterações',
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: hasUnresolvedTemplate ? null : _submit,
            ),
            if (hasUnresolvedTemplate) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                'Cadastre as músicas que faltam para habilitar o cadastro do culto.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}
