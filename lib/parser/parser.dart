import 'command.dart';
import 'vocabulary.dart';

/// Turns free text into a [ParsedCommand].
///
/// Handles synonyms ("grab" -> take), single-letter directions, multi-word
/// forms ("pick up", "look at") and splits "verb noun preposition noun".
/// Anything it cannot understand becomes an `unknown` command rather than an
/// error, so the game can respond playfully.
class CommandParser {
  const CommandParser();

  ParsedCommand parse(String input) {
    final tokens = Vocabulary.tokenize(input);
    if (tokens.isEmpty) return ParsedCommand(verb: 'empty', raw: input);

    final first = tokens.first;

    // Bare direction: "north", "n", "up".
    final bareDirection = Vocabulary.direction(first);
    if (bareDirection != null && tokens.length == 1) {
      return ParsedCommand(verb: 'go', noun: bareDirection, direction: bareDirection, raw: input);
    }

    var verb = Vocabulary.verbFor(first);
    if (verb == null) {
      return ParsedCommand(verb: 'unknown', unknownWord: first, raw: input);
    }

    var rest = tokens.sublist(1);

    // "pick up lamp" / "pick lamp up"
    if (first == 'pick') rest = rest.where((t) => t != 'up').toList();

    // "look at statue" is examining; plain "look" is the room.
    if (verb == 'look') {
      rest = _dropLeading(rest, const {'at', 'in', 'inside', 'into', 'under', 'through', 'around', 'to'});
      if (rest.isEmpty) return ParsedCommand(verb: 'look', raw: input);
      verb = 'examine';
    }

    final startsWithDirection =
        verb == 'go' && rest.isNotEmpty && Vocabulary.direction(rest.first) != null;
    if (!startsWithDirection) rest = _dropLeading(rest, Vocabulary.leadingFillers);

    String? direction;
    if (verb == 'go') {
      if (rest.isEmpty) {
        direction = Vocabulary.impliedDirection[first];
        if (direction == null) {
          return ParsedCommand(verb: 'go', raw: input);
        }
        return ParsedCommand(verb: 'go', noun: direction, direction: direction, raw: input);
      }
      direction = Vocabulary.direction(rest.first);
      if (direction == null && first == 'climb') direction = 'up';
    }

    // Split on the first preposition that follows at least one noun word.
    int split = -1;
    for (var i = 1; i < rest.length; i++) {
      if (Vocabulary.prepositions.contains(rest[i])) {
        split = i;
        break;
      }
    }

    String? noun;
    String? indirect;
    String? preposition;
    if (split == -1) {
      noun = _phrase(rest);
    } else {
      noun = _phrase(rest.sublist(0, split));
      preposition = rest[split];
      indirect = _phrase(_dropLeading(rest.sublist(split + 1), Vocabulary.leadingFillers));
    }

    return ParsedCommand(
      verb: verb,
      noun: noun,
      indirect: indirect,
      preposition: preposition,
      direction: direction,
      raw: input,
    );
  }

  List<String> _dropLeading(List<String> tokens, Set<String> fillers) {
    var i = 0;
    while (i < tokens.length && fillers.contains(tokens[i])) {
      i++;
    }
    return tokens.sublist(i);
  }

  String? _phrase(List<String> tokens) {
    final words = tokens.where((t) => !Vocabulary.articles.contains(t)).toList();
    return words.isEmpty ? null : words.join(' ');
  }
}
