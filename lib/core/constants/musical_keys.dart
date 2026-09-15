/// Standard musical keys used across the app for "tom original" and the
/// per-culto "tom alterado" selectors.
///
/// Kept as a flat list of major/minor tonalities (e.g. `C`, `C#m`) instead of
/// a full music-theory model, since the app only needs to store and display
/// the label chosen by the user.
abstract final class MusicalKeys {
  static const List<String> majors = [
    'C',
    'C#',
    'Db',
    'D',
    'D#',
    'Eb',
    'E',
    'F',
    'F#',
    'Gb',
    'G',
    'G#',
    'Ab',
    'A',
    'A#',
    'Bb',
    'B',
  ];

  static List<String> get minors => [for (final key in majors) '${key}m'];

  static List<String> get all => [...majors, ...minors];
}
