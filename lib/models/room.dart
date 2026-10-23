import 'common.dart';

/// A connection from one room to another.
class RoomExit {
  const RoomExit({
    required this.to,
    this.requires = const [],
    this.visibleIf = const [],
    this.blocked,
    this.text,
    this.entitlement,
    this.paywallText,
  });

  final String to;

  /// Conditions that must hold to pass. If they fail, [blocked] is shown.
  final List<String> requires;

  /// Conditions for the exit to exist at all (hidden passages).
  final List<String> visibleIf;
  final String? blocked;

  /// Text shown when the player walks through.
  final String? text;

  /// Product the player must own to pass (e.g. "full"). Checked after
  /// [requires]; if missing, [paywallText] is shown and the paywall opens.
  final String? entitlement;
  final String? paywallText;

  factory RoomExit.fromJson(Object json) {
    if (json is String) return RoomExit(to: json);
    final m = json as Map<String, dynamic>;
    return RoomExit(
      to: m['to'] as String,
      requires: readStrings(m['requires']),
      visibleIf: readStrings(m['visibleIf']),
      blocked: m['blocked'] as String?,
      text: m['text'] as String?,
      entitlement: m['entitlement'] as String?,
      paywallText: m['paywallText'] as String?,
    );
  }
}

/// A non-portable thing in a room that can be examined and used in puzzles.
class Scenery {
  const Scenery({
    required this.id,
    required this.names,
    required this.desc,
    this.extras = const [],
    this.takeText,
    this.streak,
  });

  final String id;
  final List<String> names;
  final String desc;
  final List<Conditional> extras;
  final String? takeText;
  final Streak? streak;

  factory Scenery.fromJson(Map<String, dynamic> json) => Scenery(
        id: json['id'] as String,
        names: readStrings(json['names']),
        desc: json['desc'] as String,
        extras: Conditional.list(json['extras']),
        takeText: json['takeText'] as String?,
        streak: Streak.fromJson(json['streak']),
      );
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.desc,
    this.dark = false,
    this.glow = false,
    this.variants = const [],
    this.exits = const {},
    this.scenery = const [],
  });

  final String id;
  final String name;
  final String desc;

  /// Dark rooms need a lit lamp and drain light when entered.
  final bool dark;

  /// Glowing rooms restore all light when the player rests.
  final bool glow;
  final List<Conditional> variants;
  final Map<String, RoomExit> exits;
  final List<Scenery> scenery;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        name: json['name'] as String,
        desc: json['desc'] as String,
        dark: json['dark'] as bool? ?? false,
        glow: json['glow'] as bool? ?? false,
        variants: Conditional.list(json['variants']),
        exits: {
          for (final e in (json['exits'] as Map<String, dynamic>? ?? {}).entries)
            e.key: RoomExit.fromJson(e.value as Object),
        },
        scenery: (json['scenery'] as List<dynamic>? ?? [])
            .map((e) => Scenery.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}
