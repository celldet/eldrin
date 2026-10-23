import 'dart:io';

import 'package:eldrin/game/engine.dart';
import 'package:eldrin/game/save_store.dart';
import 'package:eldrin/models/world.dart';

World loadTestWorld() {
  String read(String name) => File('assets/world/$name').readAsStringSync();
  return World.fromJsonStrings(
    rooms: read('rooms.json'),
    items: read('items.json'),
    npcs: read('npcs.json'),
    rules: read('rules.json'),
    secrets: read('secrets.json'),
  );
}

/// A started game with a fixed (daytime) clock and a seeded RNG.
Future<GameEngine> startedEngine({
  DateTime? now,
  MemorySaveStore? store,
  bool entitled = true,
}) async {
  final engine = GameEngine(
    world: loadTestWorld(),
    saveStore: store ?? MemorySaveStore(),
    isEntitled: (_) => entitled,
    clock: () => now ?? DateTime(2026, 1, 1, 12),
  );
  await engine.submit('begin');
  return engine;
}

/// Runs each command and returns the text of the last one.
Future<String> run(GameEngine engine, List<String> commands) async {
  var last = <String>[];
  for (final c in commands) {
    last = await engine.submit(c);
  }
  return last.join('\n');
}
