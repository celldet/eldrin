import 'dart:convert';
import 'dart:math';

import '../data/responses.dart';
import '../models/common.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import '../models/npc.dart';
import '../models/room.dart';
import '../models/world.dart';
import '../parser/command.dart';
import '../parser/parser.dart';
import '../parser/vocabulary.dart';
import 'bell_puzzle.dart';
import 'rules_engine.dart';
import 'save_store.dart';

enum Phase { title, playing, choice, ended }

enum _Kind { item, scenery, npc }

class _Target {
  const _Target(this.kind, this.id, this.name);
  final _Kind kind;
  final String id;
  final String name;
}

/// The whole game: owns the [GameState], interprets commands, and returns the
/// text to show. Text lines starting with `# ` are headings.
class GameEngine {
  GameEngine({
    required this.world,
    required this.saveStore,
    Clock? clock,
    Random? random,
  })  : _rules = RuleEvaluator(world, clock ?? DateTime.now),
        _rng = random ?? Random() {
    state = GameState.initial(world);
  }

  static const _parser = CommandParser();

  final World world;
  final SaveStore saveStore;
  final RuleEvaluator _rules;
  final Random _rng;

  late GameState state;
  Phase phase = Phase.title;

  final List<String> _titleEffects = [];
  bool _please = false;
  bool _thanks = false;
  final Map<String, int> _lastPick = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  List<String> get titleScreen => [Responses.titleBanner, Responses.titlePrompt];

  String get roomName => _canSee ? _room.name : 'Darkness';
  int get score => state.score;
  int get light => state.light;
  int get maxLight => world.maxLight;
  int get moves => state.moves;
  String get rank => Responses.rankFor(state.score);

  /// Directions the player could try from here (for the quick-action bar).
  List<String> get availableExits => _canSee
      ? _room.exits.entries
          .where((e) => _rules.all(state, e.value.visibleIf))
          .map((e) => e.key)
          .toList()
      : const [];

  Future<List<String>> submit(String raw) async {
    final input = raw.trim();
    if (input.isEmpty) return const [];
    switch (phase) {
      case Phase.title:
        return _handleTitle(input);
      case Phase.choice:
        return _handleChoice(input);
      case Phase.ended:
        return _handleEnded(input);
      case Phase.playing:
        return _handlePlaying(input);
    }
  }

  // ---------------------------------------------------------------------------
  // Phases
  // ---------------------------------------------------------------------------

  Future<List<String>> _handleTitle(String input) async {
    final norm = Vocabulary.normalize(input);
    if (const {'begin', 'new', 'start', 'play', 'new game', 'n'}.contains(norm)) {
      return _beginGame();
    }
    if (const {'load', 'continue', 'resume'}.contains(norm)) {
      return _loadGame();
    }
    if (const {'help', 'h', '?'}.contains(norm)) {
      return [Responses.help];
    }
    final word = world.titleWords[norm];
    if (word != null) {
      _titleEffects.addAll(word.effects);
      return [word.text];
    }
    return [_pick('titleNudge', Responses.titleNudges)];
  }

  List<String> _beginGame() {
    state = GameState.initial(world);
    _rules.applyAll(state, _titleEffects);
    _titleEffects.clear();
    phase = Phase.playing;
    return [Responses.intro, ..._describeRoom()];
  }

  Future<List<String>> _handleEnded(String input) async {
    final norm = Vocabulary.normalize(input);
    if (const {'new', 'restart', 'begin', 'again', 'new game'}.contains(norm)) {
      return _beginGame();
    }
    if (const {'load', 'continue', 'restore'}.contains(norm)) return _loadGame();
    return ['The story is told. Type NEW to begin again, or LOAD to return to a saved game.'];
  }

  Future<List<String>> _handleChoice(String input) async {
    final norm = Vocabulary.normalize(input);
    final toWorld = {'world', 'share', 'release', 'give', 'kindle', 'all', 'everyone', 'light'};
    final keep = {'spark', 'keep', 'mine', 'hoard', 'me', 'myself'};
    if (toWorld.contains(norm)) {
      state.score += 10;
      state.flags.add('ending_world');
      return _finish([
        'You open your hands. The light of the three Lanterns pours up through the dark roof of the world, '
            'and out across the Hollowmere. The drowned cities blink awake. The herons lift their heads. '
            'Far away, a child who has never seen a sunrise sees one.\n\n'
            'The Deep remembers the day.',
      ]);
    }
    if (keep.contains(norm)) {
      state.flags.add('ending_spark');
      return _finish([
        'You cup a small warm spark of the Lanterns in your hands and let the rest rise. It is enough to light '
            'a hundred lamps, and the Hollowmere is brighter than it has ever been. But you know the spark is '
            "there, in your chest, and that it's yours, and you will carry it a long way.\n\n"
            'The Deep remembers the day, for you in particular.',
      ]);
    }
    return ['Type WORLD to give the light to the Hollowmere, or SPARK to keep a little of it for yourself.'];
  }

  List<String> _finish(List<String> story) {
    phase = Phase.ended;
    final curios = state.flags.where((f) => f.startsWith('curio_')).length;
    return [
      ...story,
      '# The End',
      'Final score: ${state.score}\n'
          'Rank: ${Responses.rankFor(state.score)}\n'
          'Moves: ${state.moves}\n'
          'Places explored: ${state.visited.length} of ${world.rooms.length}\n'
          'Curiosities found: $curios',
      'Type NEW to begin again, or LOAD to return to a saved game.',
    ];
  }

  // ---------------------------------------------------------------------------
  // Playing
  // ---------------------------------------------------------------------------

  static const _metaVerbs = {
    'save', 'load', 'help', 'score', 'hint', 'quit', 'new', 'empty', 'look', 'inventory', 'unknown',
  };
  static const _speechOnly = {'say', 'tell', 'talk', 'ask', 'speak', 'whisper'};

  Future<List<String>> _handlePlaying(String input) async {
    _please = false;
    _thanks = false;
    final cleaned = _stripManners(input);
    final lines = <String>[];

    final bool politeOnly = cleaned.isEmpty || _speechOnly.contains(cleaned);
    if (politeOnly && (_please || _thanks)) {
      lines.addAll(_politeReaction(standalone: true));
      return lines;
    }

    final phrase = _tryPhraseRules(cleaned);
    if (phrase != null) {
      state.moves++;
      _resetStreak();
      lines.addAll(phrase);
      lines.addAll(_politeReaction());
      return lines;
    }

    final cmd = _parser.parse(cleaned);
    if (cmd.verb != 'examine') _resetStreak();
    if (!_metaVerbs.contains(cmd.verb)) state.moves++;

    lines.addAll(await _dispatch(cmd));
    lines.addAll(_politeReaction());
    lines.addAll(_checkEnding());
    return lines;
  }

  /// Removes "please" / "thank you" from the input, remembering that they were
  /// said so NPCs can react.
  String _stripManners(String input) {
    final words = Vocabulary.tokenize(input);
    final kept = <String>[];
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      if (w == 'please' || w == 'pls' || w == 'plz') {
        _please = true;
      } else if (w == 'thanks' || w == 'thx' || w == 'ty') {
        _thanks = true;
      } else if (w == 'thank') {
        _thanks = true;
        if (i + 1 < words.length && (words[i + 1] == 'you' || words[i + 1] == 'u')) i++;
      } else {
        kept.add(w);
      }
    }
    return kept.join(' ');
  }

  List<String> _politeReaction({bool standalone = false}) {
    if (!_please && !_thanks) return const [];
    final npc = _npcsHere().firstOrNull;
    if (npc == null) {
      return standalone ? [_pick('manners', Responses.manners)] : const [];
    }
    final out = <String>[];
    void react(bool said, List<Conditional> lines) {
      if (!said) return;
      for (final line in lines) {
        if (_rules.all(state, line.when)) {
          _rules.applyAll(state, line.effects);
          out.add(line.text);
          return;
        }
      }
      if (standalone) out.add('${npc.name} nods graciously.');
    }

    react(_please, npc.please);
    react(_thanks, npc.thanks);
    return out;
  }

  void _resetStreak() {
    state.lastExamined = null;
    state.examineCount = 0;
  }

  List<String> _checkEnding() {
    if (phase != Phase.playing) return const [];
    if (state.flags.containsAll(['placed_tide', 'placed_ember', 'placed_hush'])) {
      phase = Phase.choice;
      return [
        '# The Three Lights',
        'The third Lantern settles into its socket, and the altar wakes. Tide, Ember and Hush burn together, '
            'and the black glass around you fills with light like water rising in a glass. Something very large, '
            'very old and very kind turns toward you in the dark.\n\n'
            '"You have kindled us," it says, without speaking. "What shall we do with the light?"',
        'Type WORLD to give the light to the whole Hollowmere, or SPARK to keep a little of it for yourself.',
      ];
    }
    return const [];
  }

  Future<List<String>> _dispatch(ParsedCommand c) async {
    switch (c.verb) {
      case 'empty':
        return const [];
      case 'unknown':
        return [_pick('unknown', Responses.unknownVerb).replaceAll('{word}', c.unknownWord ?? '')];
      case 'go':
        return _go(c);
      case 'look':
        return _describeRoom();
      case 'examine':
        return _examine(c);
      case 'read':
        return _read(c);
      case 'take':
        return _take(c);
      case 'drop':
        return _drop(c);
      case 'inventory':
        return _inventory();
      case 'talk':
        return _talk(c);
      case 'say':
        return _say(c);
      case 'ring':
        return _ring(c);
      case 'rest':
        return _rest();
      case 'attack':
        return [_pick('attack', Responses.attack)];
      case 'save':
        return _saveGame();
      case 'load':
        return _loadGame();
      case 'help':
        return [Responses.help];
      case 'score':
        return _scoreReport();
      case 'hint':
        return _hint();
      case 'quit':
        return ['The Hollowmere will wait for you. Your last save, if you made one, is safe. Close the app whenever you like.'];
      case 'new':
        return ['To start over, type NEW after the story ends, or load a save.'];
      default:
        return _interact(c);
    }
  }

  // ---------------------------------------------------------------------------
  // World queries
  // ---------------------------------------------------------------------------

  Room get _room => world.rooms[state.room]!;

  bool get _canSee => !_room.dark || (state.has('lamp') && state.light > 0);

  Iterable<ItemDef> _itemsHere() => world.items.values
      .where((i) => state.itemLocations[i.id] == state.room);

  Iterable<ItemDef> _inventoryItems() =>
      world.items.values.where((i) => state.has(i.id));

  List<Npc> _npcsHere() => !_canSee
      ? const []
      : world.npcs.values.where((n) => state.itemLocations[n.id] == state.room).toList();

  /// Everything the player could be referring to. Carried items come first
  /// unless [preferRoom] is set (used by "take", where the thing you want is
  /// the one you are not yet holding).
  List<_Target> _scope({bool preferRoom = false}) {
    final carried = [
      for (final i in _inventoryItems()) _Target(_Kind.item, i.id, i.name),
    ];
    final around = _canSee
        ? [
            for (final i in _itemsHere()) _Target(_Kind.item, i.id, i.name),
            for (final s in _room.scenery) _Target(_Kind.scenery, s.id, s.names.first),
            for (final n in _npcsHere()) _Target(_Kind.npc, n.id, n.name),
          ]
        : <_Target>[];
    return preferRoom ? [...around, ...carried] : [...carried, ...around];
  }

  List<String> _namesOf(_Target t) {
    switch (t.kind) {
      case _Kind.item:
        return world.items[t.id]!.names;
      case _Kind.scenery:
        return world.scenery[t.id]!.names;
      case _Kind.npc:
        return world.npcs[t.id]!.names;
    }
  }

  _Target? _resolve(String? phrase, {bool preferRoom = false}) {
    if (phrase == null) return null;
    final norm = Vocabulary.normalize(phrase);
    final scope = _scope(preferRoom: preferRoom);
    for (final t in scope) {
      if (_namesOf(t).any((n) => Vocabulary.normalize(n) == norm)) return t;
    }
    final words = norm.split(' ');
    for (final t in scope) {
      for (final n in _namesOf(t)) {
        final nameWords = Vocabulary.normalize(n).split(' ');
        if (words.every(nameWords.contains)) return t;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Room description and movement
  // ---------------------------------------------------------------------------

  List<String> _describeRoom() {
    if (!_canSee) {
      return [
        '# Darkness',
        '${_pick('tooDark', Responses.tooDark)} You can still feel your way along the walls.',
      ];
    }
    final room = _room;
    final out = <String>['# ${room.name}'];
    final buf = StringBuffer(room.desc);
    for (final v in room.variants) {
      if (_rules.all(state, v.when)) {
        buf.write(' ${v.text}');
        _rules.applyAll(state, v.effects);
      }
    }
    out.add(buf.toString());

    final items = _itemsHere().map((i) => i.withArticle).toList();
    if (items.isNotEmpty) out.add('You can see: ${_joinList(items)}.');
    final npcs = _npcsHere().map((n) => n.name).toList();
    if (npcs.isNotEmpty) out.add('${_joinList(npcs)} ${npcs.length == 1 ? 'is' : 'are'} here.');
    final exits = availableExits;
    out.add(exits.isEmpty ? 'There are no obvious exits.' : 'Exits: ${exits.join(', ')}.');
    return out;
  }

  String _joinList(List<String> parts) {
    if (parts.length <= 1) return parts.join();
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }

  List<String> _go(ParsedCommand c) {
    final dir = c.direction;
    if (dir == null) {
      if (c.noun == null) return ['Which way do you want to go?'];
      return [_pick('cantGo', Responses.cantGo)];
    }
    final exit = _room.exits[dir];
    if (exit == null || !_rules.all(state, exit.visibleIf)) {
      return [_canSee
          ? _pick('cantGo', Responses.cantGo)
          : 'You grope blindly $dir and bump into cold, damp stone.'];
    }
    if (!_rules.all(state, exit.requires)) {
      return [exit.blocked ?? 'Something bars the way.'];
    }
    final dest = world.rooms[exit.to]!;
    final out = <String>[];
    if (exit.text != null) out.add(exit.text!);
    state.room = dest.id;

    var firstVisit = false;
    if (state.visited.add(dest.id)) {
      state.score += 1;
      firstVisit = true;
    }

    if (dest.dark && state.has('lamp')) {
      state.light -= 1;
      if (state.light <= 0) {
        return [...out, ..._collapse()];
      }
    }

    out.addAll(_describeRoom());
    if (dest.dark && state.has('lamp')) {
      if (state.light <= 5) {
        out.add('Your lamp is guttering. Find somewhere glowing to rest, soon.');
      } else if (state.light <= 10 && firstVisit) {
        out.add('Your lamp is dimming. Dark places are costing you.');
      }
    }
    return out;
  }

  /// Out of light: not fatal, just a gentle return to safety.
  List<String> _collapse() {
    state.room = state.flags.contains('beacon_lit') ? 'lighthouse_base' : world.startRoom;
    state.light = world.maxLight ~/ 2;
    return [
      'Your lamp gutters, flares once, and goes out. The dark closes in, but it does not bite. Something kind in '
          'the Hush takes your hand and leads you, blind and unhurried, back toward the light. When your eyes '
          'open, you are safe, and the lamp has caught a little of its ember again.',
      ..._describeRoom(),
    ];
  }

  List<String> _rest() {
    if (_room.glow) {
      state.light = world.maxLight;
      return ['${_pick('rest', Responses.restLines)} The glow around you seeps into your lamp, and it burns bright and full.'];
    }
    state.light = min(world.maxLight, state.light + 12);
    return ['${_pick('rest', Responses.restLines)} Your lamp recovers a little.'];
  }

  // ---------------------------------------------------------------------------
  // Examining, taking, dropping
  // ---------------------------------------------------------------------------

  List<String> _examine(ParsedCommand c) {
    if (c.noun == null) return _describeRoom();
    final t = _resolve(c.noun);
    if (t == null) {
      if (!_canSee) return [_pick('tooDark', Responses.tooDark)];
      if (Vocabulary.direction(c.noun!) != null) return ['You see nothing special that way.'];
      return [_notHere(c.noun!)];
    }
    final out = <String>[];
    Streak? streak;
    switch (t.kind) {
      case _Kind.item:
        final item = world.items[t.id]!;
        out.add(item.desc);
        out.addAll(_extras(item.extras));
        streak = item.streak;
      case _Kind.scenery:
        final s = world.scenery[t.id]!;
        out.add(s.desc);
        out.addAll(_extras(s.extras));
        streak = s.streak;
      case _Kind.npc:
        out.add(world.npcs[t.id]!.desc);
    }

    if (state.lastExamined == t.id) {
      state.examineCount++;
    } else {
      state.lastExamined = t.id;
      state.examineCount = 1;
    }
    final key = 'streak_${t.id}';
    if (streak != null && state.examineCount >= streak.count && !state.flags.contains(key)) {
      state.flags.add(key);
      _rules.applyAll(state, streak.effects);
      out.add(streak.text);
    }
    return [out.join(' ')];
  }

  List<String> _extras(List<Conditional> extras) {
    final out = <String>[];
    for (final x in extras) {
      if (_rules.all(state, x.when)) {
        _rules.applyAll(state, x.effects);
        if (x.text.isNotEmpty) out.add(x.text);
      }
    }
    return out;
  }

  List<String> _read(ParsedCommand c) {
    if (c.noun == null) return [_pick('needNoun', Responses.needNoun).replaceAll('{verb}', 'Read')];
    final t = _resolve(c.noun);
    if (t == null) return [_canSee ? _notHere(c.noun!) : _pick('tooDark', Responses.tooDark)];
    if (t.kind == _Kind.item) {
      final item = world.items[t.id]!;
      if (item.readText != null) {
        return [item.readText!];
      }
    }
    return _examine(c);
  }

  List<String> _take(ParsedCommand c) {
    if (c.noun == null) return [_pick('needNoun', Responses.needNoun).replaceAll('{verb}', 'Take')];
    if (const {'all', 'everything'}.contains(c.noun)) return _takeAll();
    final t = _resolve(c.noun, preferRoom: true);
    if (t == null) return [_canSee ? _notHere(c.noun!) : _pick('tooDark', Responses.tooDark)];
    switch (t.kind) {
      case _Kind.scenery:
        return [world.scenery[t.id]!.takeText ?? "You can't take that; it's part of the scenery."];
      case _Kind.npc:
        return ['${t.name} would almost certainly object to being picked up.'];
      case _Kind.item:
        return _takeItem(world.items[t.id]!);
    }
  }

  List<String> _takeItem(ItemDef item) {
    if (state.has(item.id)) return ['You already have the ${item.name}.'];
    if (!item.portable) return ["You can't take the ${item.name}."];
    if (!_rules.all(state, item.takeRequires)) {
      return [item.takeBlocked ?? "You can't take that yet."];
    }
    state.itemLocations[item.id] = kInventory;
    state.pickupLog.add(item.id);
    _rules.applyAll(state, item.onTake);
    final out = <String>[item.takeText ?? 'Taken: the ${item.name}.'];
    for (final seq in world.pickupSequences) {
      if (state.pickupLog.length >= seq.order.length &&
          _rules.all(state, seq.requires)) {
        final tail = state.pickupLog.sublist(state.pickupLog.length - seq.order.length);
        var match = true;
        for (var i = 0; i < tail.length; i++) {
          if (tail[i] != seq.order[i]) match = false;
        }
        if (match) {
          _rules.applyAll(state, seq.effects);
          out.add(seq.text);
        }
      }
    }
    return out;
  }

  List<String> _takeAll() {
    if (!_canSee) return [_pick('tooDark', Responses.tooDark)];
    final out = <String>[];
    for (final item in _itemsHere().toList()) {
      if (item.portable && _rules.all(state, item.takeRequires)) {
        out.addAll(_takeItem(item));
      }
    }
    return out.isEmpty ? ["There's nothing here you can take."] : out;
  }

  List<String> _drop(ParsedCommand c) {
    if (c.noun == null) return [_pick('needNoun', Responses.needNoun).replaceAll('{verb}', 'Drop')];
    final t = _resolve(c.noun);
    if (t == null || t.kind != _Kind.item || !state.has(t.id)) {
      return ["You aren't carrying any '${c.noun}'."];
    }
    state.itemLocations[t.id] = state.room;
    return ['Dropped: the ${t.name}.'];
  }

  List<String> _inventory() {
    final items = _inventoryItems().toList();
    if (items.isEmpty) return ['You are carrying nothing at all.'];
    return [
      'You are carrying: ${_joinList(items.map((i) => i.withArticle).toList())}.',
      'Light: ${state.light}/${world.maxLight}.',
    ];
  }

  // ---------------------------------------------------------------------------
  // Using things
  // ---------------------------------------------------------------------------

  List<String> _interact(ParsedCommand c) {
    final verb = c.verb;
    final a = _resolve(c.noun);
    final b = _resolve(c.indirect);

    if (c.noun != null && a == null) {
      return [_canSee ? _notHere(c.noun!) : _pick('tooDark', Responses.tooDark)];
    }
    if (c.indirect != null && b == null) {
      return [_canSee ? _notHere(c.indirect!) : _pick('tooDark', Responses.tooDark)];
    }

    const mustHold = {'use', 'put', 'give', 'combine'};
    if (mustHold.contains(verb)) {
      for (final t in [a, b]) {
        if (t != null && t.kind == _Kind.item && !state.has(t.id)) {
          final isTargetOnly = t == b && verb != 'combine';
          if (!isTargetOnly) {
            return ["You aren't carrying the ${t.name}."];
          }
        }
      }
    }

    final ruled = _tryInteraction(verb, a, b);
    if (ruled != null) return ruled;

    // "light beacon" is shorthand for using the lamp on it.
    if (verb == 'light' && a != null && a.kind != _Kind.item && b == null && state.has('lamp')) {
      final lamp = _Target(_Kind.item, 'lamp', 'ember lamp');
      final r = _tryInteraction('use', lamp, a);
      if (r != null) return r;
    }

    // Using an item on its own.
    if (a != null && a.kind == _Kind.item && b == null) {
      final item = world.items[a.id]!;
      final alone = item.useAlone;
      if (alone != null && const {'use', 'eat', 'light', 'put', 'open', 'push', 'turn'}.contains(verb)) {
        if (_rules.all(state, alone.requires)) {
          _rules.applyAll(state, alone.effects);
          return [alone.text];
        }
        return [alone.failText ?? 'It does nothing right now.'];
      }
    }

    // Sensible defaults for common-but-unhandled cases.
    switch (verb) {
      case 'give':
        if (a == null) return [_pick('needNoun', Responses.needNoun).replaceAll('{verb}', 'Give')];
        if (b == null) return ['Give it to whom?'];
        return b.kind == _Kind.npc
            ? ['${b.name} considers the ${a.name} and politely declines.']
            : [_pick('nothing', Responses.nothingHappens)];
      case 'use':
      case 'put':
        if (a == null) return [_pick('needNoun', Responses.needNoun).replaceAll('{verb}', 'Use')];
        if (b == null) return ['What do you want to use the ${a.name} on?'];
      case 'combine':
        if (a == null || b == null) return ['Combine what with what?'];
        return ["The ${a.name} and the ${b.name} don't fit together in any useful way."];
      case 'open':
      case 'light':
      case 'push':
      case 'turn':
      case 'eat':
      case 'bow':
        if (a == null && verb != 'bow') {
          return [_pick('needNoun', Responses.needNoun).replaceAll('{verb}', _capitalise(verb))];
        }
        if (verb == 'bow') return ['You bow. Nobody notices, but it feels right.'];
        if (verb == 'eat') return ["That doesn't look edible."];
      case 'dance':
        return ['You dance a little. The Hollowmere does not clap, but it does not leave.'];
      case 'sing':
        return ['You sing a few bars. The Hollowmere listens with the patience of old stone.'];
    }
    return [_pick('nothing', Responses.nothingHappens)];
  }

  List<String>? _tryInteraction(String verb, _Target? a, _Target? b) {
    String? failText;
    var matched = false;
    for (final r in world.interactions) {
      if (!r.verbs.contains(verb)) continue;
      if (r.room != null && r.room != state.room) continue;
      if (!_ruleMatches(r.item, r.target, r.implicit, a?.id, b?.id)) continue;
      matched = true;
      if (_rules.all(state, r.requires)) {
        _rules.applyAll(state, r.effects);
        return [r.text];
      }
      failText ??= r.failText;
    }
    if (!matched) return null;
    return [failText ?? _pick('nothing', Responses.nothingHappens)];
  }

  bool _ruleMatches(String? item, String? target, bool implicit, String? a, String? b) {
    if (item != null && target != null) {
      return (a == item && b == target) || (a == target && b == item);
    }
    if (target != null) {
      return a == target && b == null || (implicit && a == null && b == null);
    }
    if (item != null) return a == item && b == null;
    return a == null && b == null;
  }

  // ---------------------------------------------------------------------------
  // Talking and saying
  // ---------------------------------------------------------------------------

  List<String> _talk(ParsedCommand c) {
    final here = _npcsHere();
    Npc? npc;
    if (c.noun != null) {
      final t = _resolve(c.noun);
      if (t == null) return [_canSee ? _notHere(c.noun!) : _pick('tooDark', Responses.tooDark)];
      if (t.kind != _Kind.npc) return ["The ${t.name} isn't much of a talker."];
      npc = world.npcs[t.id];
    } else {
      npc = here.firstOrNull;
    }
    if (npc == null) return [_pick('noOne', Responses.noOneToTalk)];

    if (c.indirect != null) {
      final words = Vocabulary.tokenize(c.indirect!).toSet();
      for (final topic in npc.topics) {
        final hit = topic.keywords.any((k) => words.contains(k));
        if (hit && _rules.all(state, topic.line.when)) {
          _rules.applyAll(state, topic.line.effects);
          return [topic.line.text];
        }
      }
      if (npc.fallback.isNotEmpty) return [npc.fallback[_rng.nextInt(npc.fallback.length)]];
      return ['${npc.name} has nothing to say about that.'];
    }

    for (final line in npc.lines) {
      if (_rules.all(state, line.when)) {
        _rules.applyAll(state, line.effects);
        return [line.text];
      }
    }
    return ['${npc.name} nods at you.'];
  }

  List<String> _say(ParsedCommand c) {
    if (c.noun == null) return ['Say what?'];
    return [_pick('sayNothing', Responses.sayNothing)];
  }

  static const _sayVerbs = {
    'say', 'shout', 'yell', 'whisper', 'utter', 'mutter', 'declare', 'scream', 'recite',
    'answer', 'respond', 'speak', 'chant', 'sing', 'hum',
  };

  List<String>? _tryPhraseRules(String cleaned) {
    if (cleaned.isEmpty) return null;
    var words = cleaned.split(' ');
    while (words.length > 1 && _sayVerbs.contains(words.first)) {
      words = words.sublist(1);
    }
    final phrase = words.join(' ');
    for (final rule in world.phraseRules) {
      if (rule.room != null && rule.room != state.room) continue;
      if (rule.darkOnly && !_room.dark) continue;
      if (!rule.phrases.any((p) => Vocabulary.normalize(p) == phrase)) continue;
      if (!_rules.all(state, rule.requires)) {
        if (rule.failText != null) return [rule.failText!];
        continue;
      }
      _rules.applyAll(state, rule.effects);
      return [rule.text];
    }
    return null;
  }

  List<String> _ring(ParsedCommand c) {
    if (c.noun == null) return ['Ring what?'];
    final t = _resolve(c.noun);
    if (t == null) return [_canSee ? _notHere(c.noun!) : _pick('tooDark', Responses.tooDark)];
    final ruled = _tryInteraction('ring', t, null);
    if (ruled != null) return ruled;
    if (!BellPuzzle.order.contains(t.id)) {
      return ["The ${t.name} doesn't ring."];
    }
    if (state.flags.contains('choir_open')) {
      return ['The bells hang silent, their work done.'];
    }
    state.bellSequence.add(t.id);
    if (!BellPuzzle.isPrefix(state.bellSequence)) {
      state.bellSequence.clear();
      return [BellPuzzle.notes[t.id]!, BellPuzzle.wrong];
    }
    if (BellPuzzle.isComplete(state.bellSequence)) {
      state.bellSequence.clear();
      state.flags.add('choir_open');
      state.score += 6;
      return [BellPuzzle.notes[t.id]!, BellPuzzle.solved];
    }
    return [BellPuzzle.notes[t.id]!, 'The note hangs in the air, waiting for a companion.'];
  }

  // ---------------------------------------------------------------------------
  // Meta commands
  // ---------------------------------------------------------------------------

  List<String> _scoreReport() {
    final lanterns = ['got_tide', 'got_ember', 'got_hush'].where(state.flags.contains).length;
    return [
      'Score: ${state.score}. Rank: ${Responses.rankFor(state.score)}.\n'
          'Moves: ${state.moves}. Places explored: ${state.visited.length} of ${world.rooms.length}. '
          'Lanterns found: $lanterns of 3.',
    ];
  }

  List<String> _hint() {
    for (final h in world.hints) {
      if (_rules.all(state, h.when)) return [h.text];
    }
    return ['You are on your own, for now.'];
  }

  Future<List<String>> _saveGame() async {
    await saveStore.write(jsonEncode(state.toJson()));
    return ['Game saved.'];
  }

  Future<List<String>> _loadGame() async {
    final data = await saveStore.read();
    if (data == null) return ['There is no saved game to load.'];
    try {
      state = GameState.fromJson(jsonDecode(data) as Map<String, dynamic>, world);
    } catch (_) {
      return ['The saved game could not be read. It may be from a different version.'];
    }
    phase = Phase.playing;
    return ['Game loaded.', ..._describeRoom()];
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _notHere(String noun) => _pick('notHere', Responses.notHere).replaceAll('{noun}', noun);

  String _capitalise(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Picks a random entry, avoiding repeating the previous pick for [key].
  String _pick(String key, List<String> options) {
    if (options.length == 1) return options.first;
    var i = _rng.nextInt(options.length);
    if (i == _lastPick[key]) i = (i + 1) % options.length;
    _lastPick[key] = i;
    return options[i];
  }
}
