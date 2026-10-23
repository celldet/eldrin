/// Reads a JSON list of strings (or null) into an immutable list.
List<String> readStrings(Object? value) => value == null
    ? const <String>[]
    : List<String>.unmodifiable((value as List<dynamic>).cast<String>());

/// A piece of text guarded by conditions, optionally with side effects.
///
/// Used for room description variants, scenery extras, dialogue lines and
/// hints. Condition and effect syntax is documented in `game/rules_engine.dart`.
class Conditional {
  const Conditional({
    this.when = const [],
    this.text = '',
    this.effects = const [],
  });

  final List<String> when;
  final String text;
  final List<String> effects;

  factory Conditional.fromJson(Map<String, dynamic> json) => Conditional(
        when: readStrings(json['when']),
        text: json['text'] as String? ?? '',
        effects: readStrings(json['effects']),
      );

  static List<Conditional> list(Object? value) => value == null
      ? const []
      : (value as List<dynamic>)
          .map((e) => Conditional.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
}

/// Examining something [count] times in a row triggers [text] and [effects]
/// (once).
class Streak {
  const Streak({required this.count, required this.text, this.effects = const []});

  final int count;
  final String text;
  final List<String> effects;

  static Streak? fromJson(Object? json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return Streak(
      count: m['count'] as int,
      text: m['text'] as String,
      effects: readStrings(m['effects']),
    );
  }
}
