/// Thrown when a song cannot be saved because another row already uses the
/// same title+authors slug.
class DuplicateSongException implements Exception {
  const DuplicateSongException();

  @override
  String toString() =>
      'Já existe uma música cadastrada com este nome e autor(es).';
}
