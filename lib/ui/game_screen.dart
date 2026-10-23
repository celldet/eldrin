import 'package:flutter/material.dart';

import '../game/engine.dart';
import 'quick_action_bar.dart';

enum _EntryKind { echo, heading, text, banner }

class _LogEntry {
  const _LogEntry(this.kind, this.text);
  final _EntryKind kind;
  final String text;
}

/// The single game screen: status bar, scrolling log, quick actions, input.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.engine, required this.onToggleTheme});

  final GameEngine engine;
  final VoidCallback onToggleTheme;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _log = <_LogEntry>[];
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _history = <String>[];
  int _historyIndex = 0;
  bool _busy = false;

  GameEngine get _engine => widget.engine;

  @override
  void initState() {
    super.initState();
    _log.add(_LogEntry(_EntryKind.banner, _engine.titleScreen.first));
    _log.add(_LogEntry(_EntryKind.text, _engine.titleScreen.last));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    _busy = true;
    _controller.clear();
    _history.add(text);
    _historyIndex = _history.length;
    setState(() => _log.add(_LogEntry(_EntryKind.echo, '> $text')));
    try {
      final lines = await _engine.submit(text);
      setState(() {
        for (final line in lines) {
          _log.add(line.startsWith('# ')
              ? _LogEntry(_EntryKind.heading, line.substring(2))
              : _LogEntry(_EntryKind.text, line));
        }
      });
    } finally {
      _busy = false;
    }
    _scrollToEnd();
    _focus.requestFocus();
  }

  void _prefill(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _focus.requestFocus();
  }

  void _recall(int delta) {
    if (_history.isEmpty) return;
    _historyIndex = (_historyIndex + delta).clamp(0, _history.length);
    _prefill(_historyIndex == _history.length ? '' : _history[_historyIndex]);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELDRIN'),
        actions: [
          IconButton(
            tooltip: 'Toggle light / dark',
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme,
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _submit(v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'help', child: Text('Help')),
              PopupMenuItem(value: 'save', child: Text('Save game')),
              PopupMenuItem(value: 'load', child: Text('Load game')),
              PopupMenuItem(value: 'score', child: Text('Score')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StatusBar(engine: _engine),
            Expanded(child: _buildLog(context)),
            const Divider(height: 1),
            QuickActionBar(
              exits: _engine.availableExits,
              onCommand: _submit,
              onPrefill: _prefill,
            ),
            _buildInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLog(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge!.copyWith(height: 1.4, fontSize: 15);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _log.length,
      itemBuilder: (context, i) {
        final e = _log[i];
        switch (e.kind) {
          case _EntryKind.banner:
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  e.text,
                  style: base.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.15,
                  ),
                ),
              ),
            );
          case _EntryKind.heading:
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                e.text.toUpperCase(),
                style: base.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            );
          case _EntryKind.echo:
            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Text(
                e.text,
                style: base.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          case _EntryKind.text:
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(e.text, style: base),
            );
        }
      },
    );
  }

  Widget _buildInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous command',
            icon: const Icon(Icons.history),
            onPressed: () => _recall(-1),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.send,
              onSubmitted: _submit,
              decoration: const InputDecoration(
                hintText: 'What do you do?',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            icon: const Icon(Icons.keyboard_return),
            onPressed: () => _submit(_controller.text),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inGame = engine.phase != Phase.title;
    final fraction = engine.maxLight == 0 ? 0.0 : engine.light / engine.maxLight;
    final style = theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: inGame
          ? Row(
              children: [
                Expanded(
                  child: Text(engine.roomName, style: style, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text('Score ${engine.score}', style: style),
                const SizedBox(width: 12),
                Icon(Icons.local_fire_department,
                    size: 14,
                    color: fraction < 0.25 ? theme.colorScheme.error : theme.colorScheme.primary),
                const SizedBox(width: 4),
                SizedBox(
                  width: 56,
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 6,
                    color: fraction < 0.25 ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                ),
              ],
            )
          : Text('Type BEGIN to start', style: style),
    );
  }
}
