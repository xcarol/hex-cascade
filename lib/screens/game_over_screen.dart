import 'package:flutter/material.dart';
import '../services/games_service.dart';
import '../services/save_service.dart';
import '../models/game_state.dart';
import 'main_menu_screen.dart';
import 'game_screen.dart';

class GameOverScreen extends StatefulWidget {
  final int finalScore;
  const GameOverScreen({super.key, required this.finalScore});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _submitScore();
  }

  Future<void> _submitScore() async {
    if (GamesService.isSignedIn) {
      await GamesService.submitScore(widget.finalScore);
      if (mounted) setState(() => _submitted = true);
    }
    await SaveService.deleteSave();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _newGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(state: GameState())),
    );
  }

  void _menu() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A3550)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'PUNTUACIÓ FINAL',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF64FFDA), Color(0xFF00B0FF)],
                    ).createShader(bounds),
                    child: Text(
                      '${widget.finalScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_submitted) ...[
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF64FFDA),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Puntuació enviada a Google Play',
                          style: TextStyle(
                            color: Color(0xFF64FFDA),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 240,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _newGame,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('TORNA A JUGAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64FFDA),
                        foregroundColor: const Color(0xFF0D1B2A),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _menu,
                    child: const Text(
                      'MENÚ PRINCIPAL',
                      style: TextStyle(
                        color: Colors.white54,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
