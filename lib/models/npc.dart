import 'common.dart';

class Topic {
  const Topic({required this.keywords, required this.line});

  final List<String> keywords;
  final Conditional line;

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        keywords: readStrings(json['keywords']),
        line: Conditional.fromJson(json),
      );
}

class Npc {
  const Npc({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.start,
    required this.desc,
    this.lines = const [],
    this.topics = const [],
    this.please = const [],
    this.thanks = const [],
    this.fallback = const [],
  });

  final String id;
  final String name;
  final List<String> aliases;
  final String start;
  final String desc;

  /// Greeting lines; the first whose conditions hold is used.
  final List<Conditional> lines;
  final List<Topic> topics;

  /// Reactions to the player's manners; first whose conditions hold is used.
  final List<Conditional> please;
  final List<Conditional> thanks;
  final List<String> fallback;

  List<String> get names => [name, ...aliases];

  factory Npc.fromJson(Map<String, dynamic> json) => Npc(
        id: json['id'] as String,
        name: json['name'] as String,
        aliases: readStrings(json['aliases']),
        start: json['start'] as String,
        desc: json['desc'] as String,
        lines: Conditional.list(json['lines']),
        topics: (json['topics'] as List<dynamic>? ?? [])
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        please: Conditional.list(json['please']),
        thanks: Conditional.list(json['thanks']),
        fallback: readStrings(json['fallback']),
      );
}
