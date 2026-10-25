import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/world_loader.dart';
import '../game/engine.dart';
import '../game/entitlements.dart';
import '../game/save_store.dart';
import 'game_screen.dart';
import 'theme.dart';

class EldrinApp extends StatefulWidget {
  const EldrinApp({super.key, this.entitlements});

  /// Overrides the store-backed entitlements (tests and screenshots).
  final Entitlements? entitlements;

  @override
  State<EldrinApp> createState() => _EldrinAppState();
}

class _EldrinAppState extends State<EldrinApp> {
  static const _themeKey = 'eldrin.theme';

  ThemeMode _mode = ThemeMode.system;
  late final Future<GameEngine> _engine = _createEngine();
  late final Entitlements _entitlements = widget.entitlements ?? StoreEntitlements();

  @override
  void initState() {
    super.initState();
    _restoreTheme();
    _entitlements.init();
  }

  @override
  void dispose() {
    _entitlements.dispose();
    super.dispose();
  }

  Future<GameEngine> _createEngine() async {
    final world = await loadWorldFromAssets();
    return GameEngine(
      world: world,
      saveStore: PrefsSaveStore(),
      isEntitled: _entitlements.owns,
    );
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
            return Scaffold(
              backgroundColor: const Color(0xFF0E1116),
              body: Center(
                child: Image.asset('assets/icon/splash_logo.png', width: 288),
              ),
            );
          }
          return Builder(
            builder: (context) => GameScreen(
              engine: engine,
              entitlements: _entitlements,
              onToggleTheme: () => _cycleTheme(context),
            ),
          );
        },
      ),
    );
  }
}
