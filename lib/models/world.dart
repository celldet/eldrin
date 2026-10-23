import 'dart:convert';

import 'common.dart';
import 'item.dart';
import 'npc.dart';
import 'room.dart';
import 'rules.dart';

/// The immutable game content, parsed from the JSON files in `assets/world`.
class World {
  World({
    required this.startRoom,
    required this.maxLight,
    required this.rooms,
    required this.items,
    required this.npcs,
    required this.interactions,
    required this.phraseRules,
    required this.hints,
    required this.titleWords,
    required this.pickupSequences,
  }) {
    for (final room in rooms.values) {
      for (final s in room.scenery) {
        scenery[s.id] = s;
        sceneryRoom[s.id] = room.id;
      }
    }
  }

  final String startRoom;
  final int maxLight;
  final Map<String, Room> rooms;
  final Map<String, ItemDef> items;
  final Map<String, Npc> npcs;
  final List<Interaction> interactions;
  final List<PhraseRule> phraseRules;
  final List<Conditional> hints;
  final Map<String, TitleWord> titleWords;
  final List<PickupSequence> pickupSequences;

  final Map<String, Scenery> scenery = {};
  final Map<String, String> sceneryRoom = {};

  /// Builds a world from the raw text of the five content files.
  factory World.fromJsonStrings({
    required String rooms,
    required String items,
    required String npcs,
    required String rules,
    required String secrets,
  }) {
    final r = jsonDecode(rooms) as Map<String, dynamic>;
    final i = jsonDecode(items) as List<dynamic>;
    final n = jsonDecode(npcs) as List<dynamic>;
    final ru = jsonDecode(rules) as Map<String, dynamic>;
    final s = jsonDecode(secrets) as Map<String, dynamic>;

    List<T> parse<T>(Object? v, T Function(Map<String, dynamic>) f) =>
        (v as List<dynamic>? ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList(growable: false);

    return World(
      startRoom: r['start'] as String,
      maxLight: r['maxLight'] as int? ?? 30,
      rooms: {
        for (final e in parse(r['rooms'], Room.fromJson)) e.id: e,
      },
      items: {
        for (final e in i.map((e) => ItemDef.fromJson(e as Map<String, dynamic>)))
          e.id: e,
      },
      npcs: {
        for (final e in n.map((e) => Npc.fromJson(e as Map<String, dynamic>)))
          e.id: e,
      },
      interactions: parse(ru['interactions'], Interaction.fromJson),
      phraseRules: [
        ...parse(ru['phrases'], PhraseRule.fromJson),
        ...parse(s['phrases'], PhraseRule.fromJson),
      ],
      hints: Conditional.list(ru['hints']),
      titleWords: {
        for (final e in parse(s['titleWords'], TitleWord.fromJson)) e.word: e,
      },
      pickupSequences: parse(s['pickupSequences'], PickupSequence.fromJson),
    );
  }
}
