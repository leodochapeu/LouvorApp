import 'package:flutter/material.dart';

import '../../../../core/widgets/chips/app_chip.dart';

/// Input for the song's "autores" list: type a name and press enter/the add
/// button to turn it into a chip; tap a chip's "x" to remove it.
class AuthorsInput extends StatefulWidget {
  const AuthorsInput({
    super.key,
    required this.authors,
    required this.onChanged,
  });

  final List<String> authors;
  final ValueChanged<List<String>> onChanged;

  @override
  State<AuthorsInput> createState() => _AuthorsInputState();
}

class _AuthorsInputState extends State<AuthorsInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addAuthor() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    if (widget.authors.contains(name)) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.authors, name]);
    _controller.clear();
  }

  void _removeAuthor(String name) {
    widget.onChanged(widget.authors.where((a) => a != name).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Autores', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Nome do autor',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addAuthor(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar autor',
              onPressed: _addAuthor,
            ),
          ],
        ),
        if (widget.authors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.authors
                .map((author) => AppChip(
                      label: author,
                      onDeleted: () => _removeAuthor(author),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
