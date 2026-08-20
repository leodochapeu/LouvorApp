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
import '../../domain/entities/song.dart';
import '../../domain/lyrics_parser.dart';
import '../providers/song_providers.dart';
import '../widgets/authors_input.dart';
import '../widgets/lyrics_field.dart';
import '../widgets/lyrics_preview.dart';
import '../widgets/musical_key_dropdown.dart';

/// Create/edit form for a song. `songId == null` means "create new".
class SongFormPage extends ConsumerWidget {
  const SongFormPage({super.key, this.songId});

  final String? songId;

  bool get isEditing => songId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isEditing ? 'Editar música' : 'Nova música';

    Widget body;
    if (!isEditing) {
      body = const _SongFormBody(song: null);
    } else {
      final songAsync = ref.watch(songByIdProvider(songId!));
      body = songAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => AppErrorView(
          message: 'Não foi possível carregar a música.\n$error',
          onRetry: () => ref.invalidate(songByIdProvider(songId!)),
        ),
        data: (song) => _SongFormBody(key: ValueKey(song.id), song: song),
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

class _SongFormBody extends ConsumerStatefulWidget {
  const _SongFormBody({super.key, required this.song});

  /// `null` when creating a new song.
  final Song? song;

  @override
  ConsumerState<_SongFormBody> createState() => _SongFormBodyState();
}

class _SongFormBodyState extends ConsumerState<_SongFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.song?.title ?? '');
  late final _referenceUrlController = TextEditingController(
    text: widget.song?.referenceUrl ?? '',
  );
  late final _lyricsController = TextEditingController(
    text: widget.song == null ? '' : LyricsParser.toRawText(widget.song!.lines),
  );
  late List<String> _authors = List.of(widget.song?.authors ?? const []);
  late String? _originalKey = widget.song?.originalKey;
  late String? _currentKey = widget.song?.currentKey;

  @override
  void dispose() {
    _titleController.dispose();
    _referenceUrlController.dispose();
    _lyricsController.dispose();
    super.dispose();
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

    final saved = await ref
        .read(songMutationControllerProvider.notifier)
        .save(id: widget.song?.id, input: input);

    if (!mounted) return;

    if (saved != null) {
      context.go(AppRoutes.songDetailPath(saved.id));
    } else {
      final error = ref.read(songMutationControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a música.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(songMutationControllerProvider).isLoading;

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
              onPressed: _submit,
            ),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}
