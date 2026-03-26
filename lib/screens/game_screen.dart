import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:hex_cascade/models/piece_generator.dart';
import '../game/hex_game.dart';
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
  int _threshold = 0;
  bool _paused = false;
  Piece? _currentPiece;

  @override
  void initState() {
    super.initState();
    _score = widget.state.score;
    _level = widget.state.level;
    _threshold = widget.state.explosionThreshold;
    _currentPiece = widget.state.currentPiece;

    _game = HexCascadeGame(
      state: widget.state,
      onScoreChanged: (s, l, t) {
        if (mounted) {
          debugPrint('Score changed: $s, Level: $l, Threshold: $t');
          setState(() {
            _score = s;
            _level = l;
            _threshold = t;
          });
        }
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
      onPieceChanged: (piece) {
        if (mounted) setState(() => _currentPiece = piece);
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

  void _undo() {
    if (_game.canUndo()) {
      setState(() {
        _game.undo();
      });
    }
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
              onUndo: _undo,
              threshold: _threshold,
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
            _CurrentPieceWidget(piece: _currentPiece),
            const SizedBox(height: 16),
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
  final VoidCallback onUndo;
  final int threshold;
  final VoidCallback onPause;
  final VoidCallback onQuit;

  const _HUD({
    required this.score,
    required this.level,
    required this.threshold,
    required this.paused,
    required this.onUndo,
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
          Column(
            children: [
              Text(
                'TARGET',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
              Text(
                '$threshold',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onUndo,
            icon: const Icon(
              Icons.undo_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ),
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

class _CurrentPieceWidget extends StatelessWidget {
  final Piece? piece;
  const _CurrentPieceWidget({required this.piece});

  @override
  Widget build(BuildContext context) {
    if (piece == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            piece!.isNegative ? 'FITXA NEGATIVA' : 'FITXA ACTUAL',
            style: TextStyle(
              color: piece!.isNegative
                  ? const Color(0xFFFF6B6B)
                  : Colors.white38,
              fontSize: 10,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          CustomPaint(
            size: const Size(72, 72),
            painter: _HexPainter(piece: piece!),
          ),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final Piece piece;
  const _HexPainter({required this.piece});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.9;

    final fillPaint = Paint()
      ..color = piece.isNegative
          ? const Color(0xFF5C1A1A)
          : const Color(0xFF4A7A9B);
    final borderPaint = Paint()
      ..color = piece.isNegative ? const Color(0xFFFF6B6B) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = piece.isNegative ? 3 : 2;

    final label = piece.isNegative ? '${piece.value}' : '+${piece.value}';

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.piece != piece;
}
