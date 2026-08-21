import 'dart:convert';

import '../../../core/constants/musical_keys.dart';
import 'entities/song_line.dart';
import 'song_import.dart';

/// Converts the structured JSON cifra into a [SongImport] that fills the
/// song form: title, authors, keys, and lyrics using the same markup rules
/// as the lyrics parser (`> ` seção, `|| ... ||` cifra, `_\"...\"_` letra).
abstract final class SongImportParser {
  static final _codeFence = RegExp(
    r'^```(?:json)?\s*',
    caseSensitive: false,
  );
  static final _referenceParts = RegExp(r'^(.*)_(\d+)$');
  static final _accents = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ç': 'c',
    'ä': 'a',
    'ë': 'e',
    'ï': 'i',
    'ö': 'o',
    'ü': 'u',
  };
  static const _superscriptDigits = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
  static const _sectionTitles = {
    'introducao': 'Introdução',
    'estrofe': 'Estrofe',
    'refrao': 'Refrão',
    'ponte': 'Ponte',
    'interludio': 'Interlúdio',
    'solo': 'Solo',
    'finalizacao': 'Finalização',
    'pre_refrao': 'Pré-refrão',
    'prerefrao': 'Pré-refrão',
    'instrumental': 'Instrumental',
    'coda': 'Coda',
    'bridge': 'Ponte',
    'chorus': 'Refrão',
    'verse': 'Estrofe',
    'intro': 'Introdução',
    'outro': 'Finalização',
  };

  static SongImport parse(String raw) {
    final text = _unwrap(raw);
    if (text.isEmpty) {
      throw const SongImportException('Cole o JSON da música.');
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const SongImportException(
        'JSON inválido. Confira as aspas e as vírgulas.',
      );
    }

    if (decoded is! Map) {
      throw const SongImportException(
        'O JSON precisa ser um objeto com "musica" e "estrutura".',
      );
    }

    final root = _asStringKeyedMap(decoded);
    final musicaRaw = root['musica'];
    if (musicaRaw is! Map) {
      throw const SongImportException('Campo "musica" não encontrado.');
    }
    final musica = _asStringKeyedMap(musicaRaw);

    final estruturaRaw = root['estrutura'];
    if (estruturaRaw != null && estruturaRaw is! List) {
      throw const SongImportException('Campo "estrutura" precisa ser uma lista.');
    }

    final title = _string(musica['titulo']) ?? '';
    final authors = _authors(_string(musica['artista']));
    final originalKey = _canonicalKey(_string(musica['tom_original']));
    final importedKey = _canonicalKey(_string(musica['tom']));
    final resolvedOriginal = originalKey ?? importedKey;
    final currentKey =
        importedKey != null && importedKey != resolvedOriginal ? importedKey : null;
    final version = _string(musica['versao']);

    final blocks = <Map<String, Object?>>[
      for (final item in (estruturaRaw as List? ?? const []))
        if (item is Map) _asStringKeyedMap(item),
    ];

    final lines = _linesFrom(
      version: version,
      blocks: blocks,
    );

    if (title.isEmpty && authors.isEmpty && lines.isEmpty) {
      throw const SongImportException(
        'Não foi possível ler título, autor ou estrutura no JSON.',
      );
    }

    return SongImport(
      title: title,
      authors: authors,
      originalKey: resolvedOriginal,
      currentKey: currentKey,
      lines: lines,
    );
  }

  static String _unwrap(String raw) {
    var text = raw.trim();
    if (!text.startsWith('```')) return text;
    text = text.replaceFirst(_codeFence, '');
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  static List<String> _authors(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static List<SongLine> _linesFrom({
    required String? version,
    required List<Map<String, Object?>> blocks,
  }) {
    final lines = <SongLine>[];
    if (version != null && version.isNotEmpty) {
      lines.add(SongLine(type: SongLineType.extras, content: '($version)'));
      if (blocks.isNotEmpty) {
        lines.add(const SongLine(type: SongLineType.extras, content: ''));
      }
    }

    final definitions = <String, List<SongLine>>{};
    final groups = _groupBlocks(blocks);

    for (final group in groups) {
      final body = _renderGroup(group, definitions);
      if (body.isEmpty && _sectionTitleOf(group.first).isEmpty) continue;

      if (lines.isNotEmpty && lines.last.content.isNotEmpty) {
        lines.add(const SongLine(type: SongLineType.extras, content: ''));
      }

      final title = _sectionTitleOf(group.first);
      if (title.isNotEmpty) {
        lines.add(SongLine(type: SongLineType.sessao, content: title));
      }
      lines.addAll(body);

      if (!_isReferenceOnly(group)) {
        definitions[_definitionKey(group.first)] = List.of(body);
      }
    }

    return lines;
  }

  static List<List<Map<String, Object?>>> _groupBlocks(
    List<Map<String, Object?>> blocks,
  ) {
    final groups = <List<Map<String, Object?>>>[];
    for (final block in blocks) {
      if (groups.isNotEmpty &&
          _groupKey(groups.last.first) == _groupKey(block)) {
        groups.last.add(block);
      } else {
        groups.add([block]);
      }
    }
    return groups;
  }

  static String _groupKey(Map<String, Object?> block) {
    final tipo = _normalizeTipo(_string(block['tipo']) ?? '');
    final numero = _asInt(block['numero']);
    return '$tipo|${numero ?? ''}';
  }

  static List<SongLine> _renderGroup(
    List<Map<String, Object?>> group,
    Map<String, List<SongLine>> definitions,
  ) {
    if (_isReferenceOnly(group)) {
      return _resolveReference(group.first, definitions);
    }

    final body = <SongLine>[];
    for (final block in group) {
      body.addAll(_renderBlock(block, definitions));
    }
    return body;
  }

  static bool _isReferenceOnly(List<Map<String, Object?>> group) {
    return group.length == 1 && _referenceKey(group.first) != null;
  }

  static List<SongLine> _renderBlock(
    Map<String, Object?> block,
    Map<String, List<SongLine>> definitions,
  ) {
    final reference = _referenceKey(block);
    if (reference != null) {
      return _resolveReference(block, definitions);
    }

    final lines = <SongLine>[];
    final descricao = _string(block['descricao']);
    if (descricao != null) {
      lines.add(SongLine(type: SongLineType.extras, content: descricao));
    }
    final instrumento = _string(block['instrumento']);
    if (instrumento != null) {
      lines.add(SongLine(type: SongLineType.extras, content: instrumento));
    }
    final trecho = _string(block['trecho']);
    if (trecho != null) {
      lines.add(SongLine(type: SongLineType.letra, content: trecho));
    }

    final acordes = _asStringList(block['acordes']);
    if (acordes.isNotEmpty) {
      lines.add(
        SongLine(
          type: SongLineType.cifra,
          content: acordes.join(' '),
          suffix: _repeatSuffix(_asInt(block['repeticoes']) ?? 1),
        ),
      );
    }

    final partesRaw = block['partes'];
    if (partesRaw is List) {
      for (final parte in partesRaw) {
        if (parte is! Map) continue;
        final parteMap = _asStringKeyedMap(parte);
        final parteAcordes = _asStringList(parteMap['acordes']);
        if (parteAcordes.isEmpty) continue;
        lines.add(
          SongLine(
            type: SongLineType.cifra,
            content: parteAcordes.join(' '),
            suffix: _repeatSuffix(_asInt(parteMap['repeticoes']) ?? 1),
          ),
        );
      }
    }

    return lines;
  }

  static List<SongLine> _resolveReference(
    Map<String, Object?> block,
    Map<String, List<SongLine>> definitions,
  ) {
    final key = _referenceKey(block)!;
    final copied = definitions[key];
    final repeats = _asInt(block['repeticoes']) ?? 1;
    final fallbackTitle = _referenceLabel(key);

    if (copied == null || copied.isEmpty) {
      final content = repeats > 1
          ? '(igual à $fallbackTitle) ${_repeatSuffix(repeats)}'
          : '(igual à $fallbackTitle)';
      return [SongLine(type: SongLineType.extras, content: content)];
    }

    final lines = List<SongLine>.of(copied);
    if (repeats > 1 && !_hasLineRepeat(copied)) {
      lines.add(SongLine(type: SongLineType.extras, content: '(${repeats}x)'));
    }
    return lines;
  }

  static bool _hasLineRepeat(List<SongLine> lines) {
    return lines.any((line) => line.suffix.isNotEmpty);
  }

  static String? _referenceKey(Map<String, Object?> block) {
    final raw = _string(block['referencia']);
    if (raw == null) return null;
    final match = _referenceParts.firstMatch(raw);
    if (match != null) {
      return '${_normalizeTipo(match.group(1)!)}_${match.group(2)!}';
    }
    return _normalizeTipo(raw);
  }

  static String _definitionKey(Map<String, Object?> block) {
    final tipo = _normalizeTipo(_string(block['tipo']) ?? '');
    final numero = _asInt(block['numero']);
    return numero == null ? tipo : '${tipo}_$numero';
  }

  static String _sectionTitleOf(Map<String, Object?> block) {
    final tipo = _normalizeTipo(_string(block['tipo']) ?? '');
    if (tipo.isEmpty) return '';
    final name = _sectionTitles[tipo] ?? _titleCase(_string(block['tipo'])!);
    final numero = _asInt(block['numero']);
    if (numero == null) return name;
    return '$name $numero';
  }

  static String _referenceLabel(String key) {
    final match = _referenceParts.firstMatch(key);
    final tipo = match?.group(1) ?? key;
    final numero = match?.group(2);
    final name = _sectionTitles[tipo] ?? _titleCase(tipo);
    return numero == null ? name : '$name $numero';
  }

  static String _repeatSuffix(int times) {
    if (times <= 1) return '';
    return '(${_superscript(times)}*)';
  }

  static String _superscript(int n) {
    return n.toString().split('').map((d) => _superscriptDigits[int.parse(d)]).join();
  }

  static String _normalizeTipo(String raw) {
    final lower = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  static String _titleCase(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  static String? _canonicalKey(String? raw) {
    if (raw == null) return null;
    final normalized = raw.replaceAll('♯', '#').replaceAll('♭', 'b');
    for (final key in MusicalKeys.all) {
      if (key.toLowerCase() == normalized.toLowerCase()) return key;
    }
    return null;
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static List<String> _asStringList(Object? value) {
    if (value is List) {
      return [
        for (final item in value)
          if (_string(item) != null) _string(item)!,
      ];
    }
    if (value is String && value.trim().isNotEmpty) {
      return value.trim().split(RegExp(r'\s+'));
    }
    return const [];
  }

  static Map<String, Object?> _asStringKeyedMap(Map<dynamic, dynamic> raw) {
    return {
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
  }
}
