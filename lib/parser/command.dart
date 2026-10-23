/// The structured result of parsing one line of player input.
class ParsedCommand {
  const ParsedCommand({
    required this.verb,
    this.noun,
    this.indirect,
    this.preposition,
    this.direction,
    this.unknownWord,
    this.raw = '',
  });

  /// Canonical verb ("go", "take", "examine"...), `unknown` or `empty`.
  final String verb;

  /// Direct object phrase ("brass key").
  final String? noun;

  /// Indirect object phrase ("door" in "use key on door").
  final String? indirect;
  final String? preposition;

  /// Canonical direction for `go` commands ("north", "up"...).
  final String? direction;

  /// The first word typed, when the verb was not recognised.
  final String? unknownWord;
  final String raw;

  bool get isUnknown => verb == 'unknown';
  bool get isEmpty => verb == 'empty';

  @override
  String toString() =>
      'ParsedCommand($verb, noun: $noun, prep: $preposition, indirect: $indirect, dir: $direction)';
}
