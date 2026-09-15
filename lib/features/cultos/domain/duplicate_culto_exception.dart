/// Thrown when a culto cannot be saved because another row already uses
/// the same title+date slug.
class DuplicateCultoException implements Exception {
  const DuplicateCultoException();

  @override
  String toString() =>
      'Já existe um culto cadastrado com este nome nesta data.';
}
