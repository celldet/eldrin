import '../models/game_state.dart';
import '../models/world.dart';

typedef Clock = DateTime Function();

/// Evaluates the small condition/effect language used by the world data.
///
/// Conditions (prefix `!` negates; `a|b` means "a or b"):
///   flag:x     a story flag is set
///   has:x      item x is carried
///   here:x     item x is lying in the current room
///   npc:x      NPC x is in the current room
///   room:x     the player is in room x
///   visited:x  room x has been visited
///   time:night real-world local time is between 22:00 and 04:00
///   time:day   the opposite
///   `light<N` / `light>N`   compare the lamp's light
///
/// Effects:
///   set:x / clear:x       set or clear a flag
///   give:x                put item x in the inventory
///   remove:x              remove item x from the world
///   spawn:x               drop item x in the current room
///   place:x@room          put item x in a given room
///   score:N               add N points
///   light:+N / light:full refill the lamp
///   move:room             teleport the player
class RuleEvaluator {
  RuleEvaluator(this.world, this.clock);

  final World world;
  final Clock clock;

  bool isNight() {
    final h = clock().hour;
    return h >= 22 || h < 4;
  }

  bool all(GameState s, Iterable<String> conditions) =>
      conditions.every((c) => test(s, c));

  bool test(GameState s, String condition) {
    if (condition.isEmpty) return true;
    return condition.split('|').any((alt) => _testOne(s, alt.trim()));
  }

  bool _testOne(GameState s, String raw) {
    final negate = raw.startsWith('!');
    final c = negate ? raw.substring(1) : raw;
    return _eval(s, c) != negate;
  }

  bool _eval(GameState s, String c) {
    if (c.startsWith('light<')) return s.light < int.parse(c.substring(6));
    if (c.startsWith('light>')) return s.light > int.parse(c.substring(6));
    final i = c.indexOf(':');
    if (i < 0) throw FormatException('Bad condition "$c"');
    final kind = c.substring(0, i);
    final arg = c.substring(i + 1);
    switch (kind) {
      case 'flag':
        return s.flags.contains(arg);
      case 'has':
        return s.has(arg);
      case 'here':
        return s.itemLocations[arg] == s.room;
      case 'npc':
        return s.itemLocations[arg] == s.room;
      case 'room':
        return s.room == arg;
      case 'visited':
        return s.visited.contains(arg);
      case 'time':
        return arg == 'night' ? isNight() : !isNight();
      default:
        throw FormatException('Unknown condition kind "$kind"');
    }
  }

  void applyAll(GameState s, Iterable<String> effects) {
    for (final e in effects) {
      apply(s, e);
    }
  }

  void apply(GameState s, String effect) {
    if (effect.startsWith('light:')) {
      final arg = effect.substring(6);
      if (arg == 'full') {
        s.light = world.maxLight;
      } else {
        s.light = (s.light + int.parse(arg)).clamp(0, world.maxLight);
      }
      return;
    }
    final i = effect.indexOf(':');
    if (i < 0) throw FormatException('Bad effect "$effect"');
    final kind = effect.substring(0, i);
    final arg = effect.substring(i + 1);
    switch (kind) {
      case 'set':
        s.flags.add(arg);
      case 'clear':
        s.flags.remove(arg);
      case 'give':
        s.itemLocations[arg] = kInventory;
      case 'remove':
        s.itemLocations[arg] = kVoid;
      case 'spawn':
        s.itemLocations[arg] = s.room;
      case 'place':
        final parts = arg.split('@');
        s.itemLocations[parts[0]] = parts[1];
      case 'score':
        s.score += int.parse(arg);
      case 'move':
        s.room = arg;
      default:
        throw FormatException('Unknown effect kind "$kind"');
    }
  }
}
