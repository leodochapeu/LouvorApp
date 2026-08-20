import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/layout/app_card.dart';
import '../../domain/culto_template.dart';
import '../../domain/culto_template_parser.dart';

/// Paste area for the WhatsApp-style setlist. On success it reports a parsed
/// [CultoTemplate] so the culto form can fill title, date and songs.
class CultoTemplatePaste extends StatefulWidget {
  const CultoTemplatePaste({super.key, required this.onParsed});

  final ValueChanged<CultoTemplate> onParsed;

  @override
  State<CultoTemplatePaste> createState() => _CultoTemplatePasteState();
}

class _CultoTemplatePasteState extends State<CultoTemplatePaste> {
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
      setState(() => _error = 'Cole o texto da programação do culto.');
      return;
    }

    final template = CultoTemplateParser.parse(raw);
    if (template.songs.isEmpty) {
      setState(
        () => _error =
            'Nenhuma música encontrada. Use o formato: 1. Título - Autor (Tom)',
      );
      return;
    }

    setState(() => _error = null);
    widget.onParsed(template);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Preencher a partir do template', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Cole a programação enviada no grupo para preencher nome, data e músicas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          AppTextField(
            controller: _controller,
            label: 'Programação do culto',
            hint: 'Músicas para o culto de quinta (20/08)\n'
                '1. Título - Autor (B)\n'
                'https://youtu.be/...',
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
