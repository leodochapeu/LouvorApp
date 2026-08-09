import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Large multiline text field for the song's lyrics + chords ("cifra").
///
/// Uses a monospaced font so chords typed above lyric lines stay aligned,
/// which is how cifras are conventionally written as plain text.
class LyricsField extends StatelessWidget {
  const LyricsField({
    super.key,
    required this.controller,
    this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: 20,
      minLines: 12,
      style: AppTextStyles.chordSheet(context),
      decoration: const InputDecoration(
        labelText: 'Letra e cifra',
        hintText: 'Cole ou digite a letra com os acordes acima das linhas...',
        alignLabelWithHint: true,
      ),
    );
  }
}
