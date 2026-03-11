import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/hex_cascade_game.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import 'game_over_screen.dart';
import 'main_menu_screen.dart';

class GameScreen extends StatefulWidget {
  final GameState state;
  const GameScreen({super.key, required this.state});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late HexCascadeGame _game;
  int _score = 0;
  int _level = 1;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _score = widget.state.score;
    _level = widget.state.level;

    _game = HexCascadeGame(
      state: widget.state,
      onScoreChanged: (s, l) {
        if (mounted)
          setState(() {
            _score = s;
            _level = l;
          });
      },
      onGameOver: (finalScore) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameOverScreen(finalScore: finalScore),
            ),
          );
        }
      },
    );
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  Future<void> _quit() async {
    _game.pauseEngine();
    final save = await SaveService.hasSavedGame();
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A3550),
        title: const Text('Sortir', style: TextStyle(color: Colors.white)),
        content: Text(
          save
              ? 'La partida s\'ha desat. Segur que vols sortir?'
              : 'Segur que vols sortir?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sortir',
              style: TextStyle(color: Color(0xFF64FFDA)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (_) => false,
      );
    } else {
      _game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            _HUD(
              score: _score,
              level: _level,
              paused: _paused,
              onPause: _togglePause,
              onQuit: _quit,
            ),
            Expanded(
              child: Stack(
                children: [
                  GameWidget(game: _game),
                  if (_paused)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'PAUSA',
                          style: TextStyle(
                            color: Color(0xFF64FFDA),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HUD extends StatelessWidget {
  final int score;
  final int level;
  final bool paused;
  final VoidCallback onPause;
  final VoidCallback onQuit;

  const _HUD({
    required this.score,
    required this.level,
    required this.paused,
    required this.onPause,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onQuit,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'PUNTUACIÓ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'NIVELL',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
              Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onPause,
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
