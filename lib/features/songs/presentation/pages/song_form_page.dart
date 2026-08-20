import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/feedback/app_error_view.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layout/app_drawer.dart';
import '../../domain/duplicate_song_exception.dart';
import '../../domain/entities/song.dart';
import '../../domain/lyrics_parser.dart';
import '../../domain/song_catalog_lookup.dart';
import '../../domain/song_slug.dart';
import '../providers/song_providers.dart';
import '../widgets/authors_input.dart';
import '../widgets/lyrics_field.dart';
import '../widgets/lyrics_preview.dart';
import '../widgets/musical_key_dropdown.dart';

/// Optional extras when opening "Nova música" from the culto template flow.
class SongFormArgs {
  const SongFormArgs({this.prefill, this.popOnSave = false});

  final SongFormPrefill? prefill;

  /// When true, saving pops back to the previous screen (the culto form)
  /// instead of navigating to the song detail page.
  final bool popOnSave;
}

class SongFormPrefill {
  const SongFormPrefill({this.title, this.authors, this.referenceUrl});

  final String? title;
  final List<String>? authors;
  final String? referenceUrl;
}

/// Create/edit form for a song. `songId == null` means "create new".
class SongFormPage extends ConsumerWidget {
  const SongFormPage({super.key, this.songId, this.args});

  final String? songId;
  final SongFormArgs? args;

  bool get isEditing => songId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isEditing ? 'Editar música' : 'Nova música';
    final popOnSave = args?.popOnSave == true;

    Widget body;
    if (!isEditing) {
      body = _SongFormBody(song: null, args: args);
    } else {
      final songAsync = ref.watch(songByIdProvider(songId!));
      body = songAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => AppErrorView(
          message: 'Não foi possível carregar a música.\n$error',
          onRetry: () => ref.invalidate(songByIdProvider(songId!)),
        ),
        data: (song) => _SongFormBody(key: ValueKey(song.id), song: song, args: args),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: popOnSave ? null : const AppDrawer(),
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

class _SongFormBody extends ConsumerStatefulWidget {
  const _SongFormBody({super.key, required this.song, this.args});

  /// `null` when creating a new song.
  final Song? song;
  final SongFormArgs? args;

  @override
  ConsumerState<_SongFormBody> createState() => _SongFormBodyState();
}

class _SongFormBodyState extends ConsumerState<_SongFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.song?.title ?? widget.args?.prefill?.title ?? '',
  );
  late final _referenceUrlController = TextEditingController(
    text: widget.song?.referenceUrl ?? widget.args?.prefill?.referenceUrl ?? '',
  );
  late final _lyricsController = TextEditingController(
    text: widget.song == null ? '' : LyricsParser.toRawText(widget.song!.lines),
  );
  late List<String> _authors = List.of(
    widget.song?.authors ?? widget.args?.prefill?.authors ?? const [],
  );
  late String? _originalKey = widget.song?.originalKey;
  late String? _currentKey = widget.song?.currentKey;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _referenceUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _referenceUrlController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  String _duplicateMessage(SongCatalogMatch match) {
    return switch (match.by) {
      SongMatchBy.slug =>
        'Já existe uma música cadastrada com este nome e autor(es).',
      SongMatchBy.youtube =>
        'Já existe uma música cadastrada com este link do YouTube.',
    };
  }

  SongCatalogMatch? _duplicateOf({
    required List<Song> catalog,
    String? referenceUrl,
  }) {
    return SongCatalogLookup.match(
      catalog: catalog,
      title: _titleController.text,
      authors: _authors,
      referenceUrl: referenceUrl ?? _referenceUrlController.text,
      excludingId: widget.song?.id,
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_originalKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tom original.')),
      );
      return;
    }

    final input = SongInput(
      title: _titleController.text.trim(),
      authors: _authors,
      originalKey: _originalKey!,
      currentKey: _currentKey,
      lines: LyricsParser.parse(_lyricsController.text),
      referenceUrl: UrlUtils.normalize(_referenceUrlController.text),
    );

    final duplicate = _duplicateOf(
      catalog: ref.read(songsStreamProvider).value ?? const [],
      referenceUrl: input.referenceUrl,
    );
    if (duplicate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_duplicateMessage(duplicate))),
      );
      return;
    }

    final saved = await ref
        .read(songMutationControllerProvider.notifier)
        .save(id: widget.song?.id, input: input);

    if (!mounted) return;

    if (saved != null) {
      if (widget.args?.popOnSave == true) {
        context.pop(saved);
      } else {
        context.go(AppRoutes.songDetailPath(saved.id));
      }
    } else {
      final error = ref.read(songMutationControllerProvider).error;
      final message = error is DuplicateSongException
          ? error.toString()
          : 'Não foi possível salvar a música.\n$error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(songMutationControllerProvider).isLoading;
    final catalog = ref.watch(songsStreamProvider).value ?? const <Song>[];
    final slug = SongSlug.from(title: _titleController.text, authors: _authors);
    final duplicate = _duplicateOf(catalog: catalog);
    final isDuplicate = duplicate != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _titleController,
              label: 'Nome da música',
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(value, field: 'O nome'),
            ),
            const SizedBox(height: AppSizes.lg),
            AuthorsInput(
              authors: _authors,
              onChanged: (authors) => setState(() => _authors = authors),
            ),
            const SizedBox(height: AppSizes.sm),
            if (_titleController.text.trim().isNotEmpty || isDuplicate)
              _DuplicateStatus(
                slug: slug,
                duplicate: duplicate,
                message: duplicate == null ? null : _duplicateMessage(duplicate),
              ),
            const SizedBox(height: AppSizes.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MusicalKeyDropdown(
                    label: 'Tom original',
                    value: _originalKey,
                    onChanged: (value) => setState(() => _originalKey = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Selecione o tom' : null,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: MusicalKeyDropdown(
                    label: 'Tom alterado',
                    value: _currentKey,
                    allowEmpty: true,
                    onChanged: (value) => setState(() => _currentKey = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              controller: _referenceUrlController,
              label: 'Link de referência',
              hint: 'https://youtube.com/watch?v=...',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.link,
              validator: Validators.optionalUrl,
            ),
            const SizedBox(height: AppSizes.lg),
            LyricsField(
              controller: _lyricsController,
              validator: (value) => Validators.required(value, field: 'A letra'),
            ),
            const SizedBox(height: AppSizes.lg),
            LyricsPreview(controller: _lyricsController),
            const SizedBox(height: AppSizes.xl),
            AppPrimaryButton(
              label: widget.song == null ? 'Cadastrar música' : 'Salvar alterações',
              icon: Icons.save_outlined,
              isLoading: isSaving,
              onPressed: isDuplicate ? null : _submit,
            ),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}

class _DuplicateStatus extends StatelessWidget {
  const _DuplicateStatus({
    required this.slug,
    required this.duplicate,
    required this.message,
  });

  final String slug;
  final SongCatalogMatch? duplicate;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDuplicate = duplicate != null;
    final color = isDuplicate ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identificador: $slug',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
        if (isDuplicate && message != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
