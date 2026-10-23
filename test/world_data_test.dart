import 'package:eldrin/game/rules_engine.dart';
import 'package:eldrin/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  final world = loadTestWorld();

  test('has at least 25 rooms', () {
    expect(world.rooms.length, greaterThanOrEqualTo(25));
  });

  test('every exit leads to a real room', () {
    for (final room in world.rooms.values) {
      for (final e in room.exits.entries) {
        expect(world.rooms, contains(e.value.to), reason: '${room.id}.${e.key}');
      }
    }
  });

  test('items and NPCs start somewhere that exists', () {
    for (final i in world.items.values) {
      expect(
        i.start == 'inv' || i.start == 'void' || world.rooms.containsKey(i.start),
        isTrue,
        reason: i.id,
      );
    }
    for (final n in world.npcs.values) {
      expect(world.rooms, contains(n.start), reason: n.id);
    }
    expect(world.rooms, contains(world.startRoom));
  });

  test('every condition and effect in the data parses and references real ids', () {
    final rules = RuleEvaluator(world, DateTime.now);
    final state = GameState.initial(world);

    void checkCondition(String c) {
      for (final alt in c.split('|')) {
        final a = alt.trim().replaceFirst('!', '');
        expect(() => rules.test(state, a), returnsNormally, reason: c);
        if (a.startsWith('has:') || a.startsWith('here:')) {
          expect(world.items, contains(a.split(':')[1]), reason: c);
        }
      }
    }

    void checkEffect(String e) {
      final scratch = GameState.initial(world);
      expect(() => rules.apply(scratch, e), returnsNormally, reason: e);
      final parts = e.split(':');
      if (const {'give', 'remove', 'spawn'}.contains(parts[0])) {
        expect(world.items, contains(parts[1]), reason: e);
      }
      if (parts[0] == 'move') expect(world.rooms, contains(parts[1]), reason: e);
    }

    for (final room in world.rooms.values) {
      for (final v in room.variants) {
        v.when.forEach(checkCondition);
        v.effects.forEach(checkEffect);
      }
      for (final e in room.exits.values) {
        [...e.requires, ...e.visibleIf].forEach(checkCondition);
      }
      for (final s in room.scenery) {
        for (final x in s.extras) {
          x.when.forEach(checkCondition);
          x.effects.forEach(checkEffect);
        }
        s.streak?.effects.forEach(checkEffect);
      }
    }
    for (final i in world.items.values) {
      i.takeRequires.forEach(checkCondition);
      i.onTake.forEach(checkEffect);
      i.useAlone?.effects.forEach(checkEffect);
      for (final x in i.extras) {
        x.when.forEach(checkCondition);
      }
    }
    for (final n in world.npcs.values) {
      for (final l in [...n.lines, ...n.please, ...n.thanks, ...n.topics.map((t) => t.line)]) {
        l.when.forEach(checkCondition);
        l.effects.forEach(checkEffect);
      }
    }
    for (final r in world.interactions) {
      r.requires.forEach(checkCondition);
      r.effects.forEach(checkEffect);
      for (final id in [r.item, r.target]) {
        if (id == null) continue;
        expect(
          world.items.containsKey(id) || world.scenery.containsKey(id) || world.npcs.containsKey(id),
          isTrue,
          reason: '${r.id} references unknown "$id"',
        );
      }
      if (r.room != null) expect(world.rooms, contains(r.room), reason: r.id);
    }
    for (final p in world.phraseRules) {
      p.requires.forEach(checkCondition);
      p.effects.forEach(checkEffect);
    }
    for (final h in world.hints) {
      h.when.forEach(checkCondition);
    }
    for (final s in world.pickupSequences) {
      for (final id in s.order) {
        expect(world.items, contains(id));
      }
      s.effects.forEach(checkEffect);
    }
  });

  test('scenery ids are globally unique', () {
    final seen = <String>{};
    for (final room in world.rooms.values) {
      for (final s in room.scenery) {
        expect(seen.add(s.id), isTrue, reason: 'duplicate scenery id ${s.id}');
      }
    }
  });
}
