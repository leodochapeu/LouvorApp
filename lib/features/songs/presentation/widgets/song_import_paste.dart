import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layout/app_card.dart';
import '../../domain/song_import.dart';
import '../../domain/song_import_parser.dart';

/// Paste area for the JSON cifra. On success it reports a parsed
/// [SongImport] so the song form can fill title, authors, keys and lyrics.
class SongImportPaste extends StatefulWidget {
  const SongImportPaste({super.key, required this.onParsed});

  final ValueChanged<SongImport> onParsed;

  @override
  State<SongImportPaste> createState() => _SongImportPasteState();
}

class _SongImportPasteState extends State<SongImportPaste> {
  late final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      setState(() => _error = 'A área de transferência está vazia.');
      return;
    }
    _controller.text = text;
    _apply();
  }

  void _apply() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Cole o JSON da música.');
      return;
    }

    try {
      final imported = SongImportParser.parse(raw);
      setState(() => _error = null);
      widget.onParsed(imported);
    } on SongImportException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Importar do JSON', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Cole o JSON da cifra para preencher nome, autor, tons e a letra.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          AppTextField(
            controller: _controller,
            label: 'JSON da música',
            hint: '{\n  "musica": { "titulo": "...", "artista": "..." },\n'
                '  "estrutura": [ ... ]\n}',
            keyboardType: TextInputType.multiline,
            minLines: 6,
            maxLines: 12,
            alignLabelWithHint: true,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              AppPrimaryButton(
                label: 'Preencher campos',
                icon: Icons.auto_fix_high_outlined,
                onPressed: _apply,
              ),
              OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_outlined, size: 20),
                label: const Text('Colar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
