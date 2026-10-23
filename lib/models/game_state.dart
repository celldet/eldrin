import 'world.dart';

/// Location value for items the player carries.
const String kInventory = 'inv';

/// Location value for items that are not (yet) anywhere in the world.
const String kVoid = 'void';

/// Everything that changes during play. Serialisable for save/load.
class GameState {
  GameState({
    required this.room,
    required this.itemLocations,
    required this.flags,
    required this.visited,
    this.score = 0,
    required this.light,
    this.moves = 0,
    List<String>? pickupLog,
    List<String>? bellSequence,
    this.lastExamined,
    this.examineCount = 0,
  })  : pickupLog = pickupLog ?? [],
        bellSequence = bellSequence ?? [];

  String room;
  final Map<String, String> itemLocations;
  final Set<String> flags;
  final Set<String> visited;
  int score;
  int light;
  int moves;
  final List<String> pickupLog;
  final List<String> bellSequence;
  String? lastExamined;
  int examineCount;

  factory GameState.initial(World world) => GameState(
        room: world.startRoom,
        itemLocations: {
          for (final item in world.items.values) item.id: item.start,
          for (final npc in world.npcs.values) npc.id: npc.start,
        },
        flags: {},
        visited: {world.startRoom},
        light: world.maxLight,
      );

  bool has(String itemId) => itemLocations[itemId] == kInventory;

  Iterable<String> get inventory => itemLocations.entries
      .where((e) => e.value == kInventory)
      .map((e) => e.key);

  Map<String, dynamic> toJson() => {
        'version': 1,
        'room': room,
        'itemLocations': itemLocations,
        'flags': flags.toList()..sort(),
        'visited': visited.toList()..sort(),
        'score': score,
        'light': light,
        'moves': moves,
        'pickupLog': pickupLog,
        'bellSequence': bellSequence,
      };

  /// Restores a saved state; ids no longer present in [world] are dropped and
  /// newly added ones get their starting values, so old saves survive content
  /// updates.
  factory GameState.fromJson(Map<String, dynamic> json, World world) {
    final fresh = GameState.initial(world);
    final saved = (json['itemLocations'] as Map<String, dynamic>).cast<String, String>();
    for (final key in fresh.itemLocations.keys) {
      final loc = saved[key];
      if (loc != null) fresh.itemLocations[key] = loc;
    }
    final room = json['room'] as String;
    return GameState(
      room: world.rooms.containsKey(room) ? room : world.startRoom,
      itemLocations: fresh.itemLocations,
      flags: (json['flags'] as List<dynamic>).cast<String>().toSet(),
      visited: (json['visited'] as List<dynamic>).cast<String>().toSet(),
      score: json['score'] as int,
      light: json['light'] as int,
      moves: json['moves'] as int,
      pickupLog: (json['pickupLog'] as List<dynamic>).cast<String>().toList(),
      bellSequence: (json['bellSequence'] as List<dynamic>).cast<String>().toList(),
    );
  }
}
