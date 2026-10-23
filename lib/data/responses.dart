/// Static text: banners, help, and the varied replies used for input the game
/// does not understand. `{x}` placeholders are substituted by the engine.
class Responses {
  const Responses._();

  static const String titleBanner = '''
   _____ _     ____  ____  ___ _   _
  | ____| |   |  _ \\|  _ \\|_ _| \\ | |
  |  _| | |   | | | | |_) || ||  \\| |
  | |___| |___| |_| |  _ < | || |\\  |
  |_____|_____|____/|_| \\_\\___|_| \\_|

     The Lanterns of the Deep
''';

  static const String titlePrompt =
      'Type BEGIN to start a new journey, or LOAD to continue a saved one.';

  static const String intro =
      'The Hollowmere has no sun. It has only the memory of one, and that memory is fading. '
      'Long ago three Lanterns kept the deep lit: Tide, Ember and Hush. Then the Lanterns were '
      'scattered, the lights went out, and the drowned cities began to dream badly.\n\n'
      'You are not sure who you were. You are quite sure what you are for.';

  static const String help = '''
HOW TO PLAY
Type short commands, or tap the buttons below.

  go north / n / s / e / w / up / down
  look            see the room again
  examine <thing> (or x, or "look at")
  take <thing> / drop <thing>
  inventory       (or i)
  use <a> on <b>  /  give <a> to <b>
  combine <a> with <b>
  talk to <person>  /  ask <person> about <topic>
  open, read, ring, bow, sing, say <words>
  rest            recover some light
  hint            a gentle nudge
  score           your rank so far
  save / load     keep or resume your journey

LIGHT
Dark places drain your lamp's light as you walk. Rest in glowing places to recover it fully. If it runs out, you won't die; you'll just be carried gently back to safety.''';

  /// Rank titles, in ascending order of minimum score.
  static const List<(int, String)> ranks = [
    (0, 'Shoreline Sleepwalker'),
    (15, 'Tide-Touched Wanderer'),
    (40, 'Lamp-Bearer'),
    (70, 'Walker of Drowned Halls'),
    (100, 'Lanternwright'),
    (130, 'Keeper of the Deep Light'),
  ];

  static String rankFor(int score) {
    var title = ranks.first.$2;
    for (final r in ranks) {
      if (score >= r.$1) title = r.$2;
    }
    return title;
  }

  static const List<String> unknownVerb = [
    "The Hollowmere does not know how to '{word}'. It is, however, willing to learn.",
    "You try to '{word}'. Nothing happens, but you do it with great conviction.",
    "'{word}'? That's not a thing the shadows here recognise.",
    "A nearby puddle seems to snicker at '{word}'.",
    "You attempt to '{word}'. The air politely ignores you.",
    "I don't understand '{word}', but I admire the optimism.",
    "'{word}' is not in the Hollowmere's vocabulary. Try 'help' for the words it does know.",
    "If '{word}' is a magic word, it isn't working yet.",
    "The gods of the Hollowmere have forgotten many things, '{word}' among them.",
    "You say '{word}' to yourself, thoughtfully. It does not help.",
  ];

  static const List<String> notHere = [
    "You don't see any '{noun}' here.",
    "There's no '{noun}' you can reach from here.",
    "'{noun}'? Not in this part of the Hollowmere.",
    "You look around for a '{noun}'. The Hollowmere shrugs.",
    "Whatever a '{noun}' is, it isn't here.",
  ];

  static const List<String> needNoun = [
    '{verb} what?',
    'You need to tell me what to {verb}.',
    '{verb}... what, exactly?',
  ];

  static const List<String> cantGo = [
    "You can't go that way.",
    'A wall of shadow and stubbornness says otherwise.',
    "That way isn't a way.",
    'You walk bravely into the scenery and bounce off.',
  ];

  static const List<String> nothingHappens = [
    'Nothing happens.',
    "You try it, but it doesn't seem to do anything.",
    'The Hollowmere remains unmoved.',
    "That doesn't seem to work. Perhaps something else?",
    'You fiddle with it for a bit. Nothing.',
  ];

  static const List<String> attack = [
    'Violence is rarely the answer in a land this tired.',
    'You feel a surge of aggression, and then remember how very wet everything is.',
    'The Hollowmere has suffered enough. Perhaps try kindness?',
    "You swing at the air. The air doesn't mind.",
  ];

  static const List<String> sayNothing = [
    'You say it aloud. The Hollowmere listens, unimpressed.',
    'Your words drift away across the water.',
    'You speak. The shadows lean in, think about it, and lean out again.',
  ];

  static const List<String> noOneToTalk = [
    'There is no one here to talk to. You talk to yourself, briefly, and the conversation goes nowhere.',
    "You speak to the empty air. It doesn't answer, but it doesn't interrupt, either.",
  ];

  static const List<String> manners = [
    "Manners are never wasted in the Hollowmere, even when there's no one to hear them.",
    'You are very polite to the empty air. It seems flattered.',
  ];

  static const List<String> restLines = [
    'You close your eyes for a moment and let the quiet settle over you.',
    'You sit still and breathe. The ember in your lamp breathes with you.',
    'You rest a while. The Hollowmere waits.',
  ];

  static const List<String> tooDark = [
    "It's pitch dark. You grope around uselessly. Perhaps you need your lamp.",
    'You can see nothing at all. The dark is very thorough.',
  ];

  static const List<String> titleNudges = [
    'The title screen waits expectantly. Type BEGIN to start, or LOAD to continue.',
    'Nothing happens, but in a title-screenly way. Type BEGIN, or LOAD to continue.',
  ];
}
