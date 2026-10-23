import 'package:flutter/services.dart' show rootBundle;

import '../models/world.dart';

/// Loads the game world from the JSON files bundled in `assets/world`.
Future<World> loadWorldFromAssets() async {
  Future<String> read(String name) => rootBundle.loadString('assets/world/$name');
  return World.fromJsonStrings(
    rooms: await read('rooms.json'),
    items: await read('items.json'),
    npcs: await read('npcs.json'),
    rules: await read('rules.json'),
    secrets: await read('secrets.json'),
  );
}
