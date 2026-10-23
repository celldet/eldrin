/// Words the parser understands: verb synonyms, directions, fillers.
class Vocabulary {
  const Vocabulary._();

  /// canonical verb -> synonyms
  static const Map<String, List<String>> verbs = {
    'go': ['go', 'walk', 'run', 'move', 'head', 'travel', 'enter', 'climb', 'crawl', 'leave', 'exit', 'flee'],
    'look': ['look', 'l', 'gaze', 'peek', 'glance'],
    'examine': ['examine', 'x', 'inspect', 'check', 'study', 'search', 'observe', 'view', 'describe', 'ex', 'scrutinize'],
    'read': ['read', 'peruse', 'decipher'],
    'take': ['take', 'get', 'grab', 'pick', 'snag', 'steal', 'pocket', 'collect', 'carry', 'seize', 'fetch', 'acquire'],
    'drop': ['drop', 'discard', 'ditch', 'abandon', 'dump'],
    'inventory': ['inventory', 'i', 'inv', 'items', 'possessions', 'pockets'],
    'use': ['use', 'apply', 'employ', 'utilize', 'throw', 'hurl', 'swing', 'cast', 'wield', 'wear', 'don', 'equip'],
    'put': ['put', 'place', 'insert', 'set', 'pour', 'fill', 'lay', 'deposit', 'slot', 'install', 'attach'],
    'give': ['give', 'offer', 'hand', 'present', 'feed', 'gift', 'deliver', 'trade'],
    'talk': ['talk', 'speak', 'chat', 'greet', 'hail', 'ask', 'question', 'converse', 'hello', 'hi', 'hey', 'tell'],
    'open': ['open', 'unlock', 'unseal', 'unbar', 'unlatch'],
    'light': ['light', 'ignite', 'kindle', 'burn', 'illuminate'],
    'combine': ['combine', 'mix', 'join', 'tie', 'bind', 'lash', 'fasten', 'merge', 'craft', 'assemble', 'knot', 'connect'],
    'ring': ['ring', 'strike', 'chime', 'toll', 'tap', 'hit'],
    'push': ['push', 'press', 'shove', 'pull', 'tug', 'yank', 'lift', 'heave'],
    'turn': ['turn', 'twist', 'rotate', 'spin', 'crank'],
    'bow': ['bow', 'kneel', 'curtsy', 'curtsey', 'salute', 'genuflect'],
    'dance': ['dance', 'twirl', 'jig', 'waltz', 'boogie'],
    'sing': ['sing', 'hum', 'chant', 'whistle', 'serenade'],
    'say': ['say', 'shout', 'yell', 'whisper', 'utter', 'mutter', 'declare', 'scream', 'chant', 'recite', 'answer', 'respond'],
    'rest': ['rest', 'wait', 'sleep', 'z', 'sit', 'nap', 'relax', 'breathe'],
    'eat': ['eat', 'taste', 'consume', 'drink', 'munch', 'swallow', 'devour'],
    'attack': ['attack', 'kill', 'punch', 'fight', 'slay', 'smash', 'stab', 'kick', 'break', 'destroy'],
    'save': ['save'],
    'load': ['load', 'restore', 'resume'],
    'help': ['help', 'h', '?', 'commands', 'instructions'],
    'score': ['score', 'rank', 'status', 'points', 'progress'],
    'hint': ['hint', 'clue', 'stuck', 'advice'],
    'quit': ['quit', 'q', 'bye', 'goodbye'],
    'new': ['restart'],
  };

  /// Words that default to a direction when used alone ("enter", "leave").
  static const Map<String, String> impliedDirection = {
    'enter': 'in',
    'leave': 'out',
    'exit': 'out',
    'climb': 'up',
  };

  static const Map<String, String> directions = {
    'north': 'north', 'n': 'north',
    'south': 'south', 's': 'south',
    'east': 'east', 'e': 'east',
    'west': 'west', 'w': 'west',
    'up': 'up', 'u': 'up', 'upstairs': 'up', 'ascend': 'up',
    'down': 'down', 'd': 'down', 'downstairs': 'down', 'descend': 'down',
    'in': 'in', 'inside': 'in', 'enter': 'in',
    'out': 'out', 'outside': 'out',
  };

  static const Set<String> articles = {
    'the', 'a', 'an', 'my', 'some', 'that', 'this', 'those', 'these', 'your', 'our',
  };

  /// Words that split a direct object from an indirect one.
  static const Set<String> prepositions = {
    'on', 'onto', 'with', 'in', 'into', 'to', 'at', 'from', 'using', 'and',
    'about', 'across', 'over', 'through', 'under', 'against', 'upon', 'for', 'around',
  };

  /// Prepositions silently dropped straight after the verb ("talk to wick").
  static const Set<String> leadingFillers = {
    'to', 'at', 'with', 'toward', 'towards', 'on', 'onto', 'in', 'into', 'inside', 'through', 'under', 'around', 'about',
  };

  /// Canonical verb for [word], or null. For words shared by several verbs
  /// ("chant", "hit"), the first listed canonical verb wins.
  static String? verbFor(String word) {
    for (final e in verbs.entries) {
      if (e.value.contains(word)) return e.key;
    }
    return null;
  }

  static String? direction(String word) => directions[word];

  /// Lowercases, strips punctuation, and splits into tokens.
  static List<String> tokenize(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9? ]+'), ' ');
    return cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  /// Normalised single-string form used for phrase matching.
  static String normalize(String input) => tokenize(input).join(' ');
}
