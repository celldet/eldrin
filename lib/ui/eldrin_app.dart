import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/world_loader.dart';
import '../game/engine.dart';
import '../game/save_store.dart';
import 'game_screen.dart';
import 'theme.dart';

class EldrinApp extends StatefulWidget {
  const EldrinApp({super.key});

  @override
  State<EldrinApp> createState() => _EldrinAppState();
}

class _EldrinAppState extends State<EldrinApp> {
  static const _themeKey = 'eldrin.theme';

  ThemeMode _mode = ThemeMode.system;
  late final Future<GameEngine> _engine = _createEngine();

  @override
  void initState() {
    super.initState();
    _restoreTheme();
  }

  Future<GameEngine> _createEngine() async {
    final world = await loadWorldFromAssets();
    return GameEngine(world: world, saveStore: PrefsSaveStore());
  }

  Future<void> _restoreTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_themeKey);
      final mode = ThemeMode.values.where((m) => m.name == name).firstOrNull;
      if (mode != null && mounted) setState(() => _mode = mode);
    } catch (_) {
      // Theme preference is optional.
    }
  }

  Future<void> _cycleTheme(BuildContext context) async {
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = _mode == ThemeMode.dark || (_mode == ThemeMode.system && platformDark);
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _mode = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, next.name);
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eldrin',
      debugShowCheckedModeBanner: false,
      theme: EldrinTheme.light(),
      darkTheme: EldrinTheme.dark(),
      themeMode: _mode,
      home: FutureBuilder<GameEngine>(
        future: _engine,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('The Hollowmere failed to wake:\n${snapshot.error}'),
                ),
              ),
            );
          }
          final engine = snapshot.data;
          if (engine == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Builder(
            builder: (context) => GameScreen(
              engine: engine,
              onToggleTheme: () => _cycleTheme(context),
            ),
          );
        },
      ),
    );
  }
}
