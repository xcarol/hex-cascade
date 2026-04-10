import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flame/game.dart' hide Matrix4;
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
  int _threshold = 0;
  bool _paused = false;
  List<Piece?> _rack = [];
  int? _selectedRackIndex;

  @override
  void initState() {
    super.initState();
    _score = widget.state.score;
    _threshold = widget.state.explosionThreshold;
    _rack = widget.state.rack;

    _game = HexCascadeGame(
      state: widget.state,
      onScoreChanged: (s, t) {
        if (mounted) {
          setState(() {
            _score = s;
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
      onRackChanged: (rack) {
        if (mounted) {
          setState(() {
            _rack = rack;
            _selectedRackIndex = null;
          });
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
            _RackWidget(
              rack: _rack,
              selectedIndex: _selectedRackIndex,
              onPieceSelected: (index) {
                if (_selectedRackIndex == index) {
                  setState(() => _selectedRackIndex = null);
                  _game.selectRackPiece(null);
                } else {
                  setState(() => _selectedRackIndex = index);
                  _game.selectRackPiece(index);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HUD extends StatelessWidget {
  final int score;
  final bool paused;
  final VoidCallback onUndo;
  final int threshold;
  final VoidCallback onPause;
  final VoidCallback onQuit;

  const _HUD({
    required this.score,
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
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                    color: Colors.white.withValues(alpha: 0.5),
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
                'TARGET',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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

class _RackWidget extends StatelessWidget {
  final List<Piece?> rack;
  final int? selectedIndex;
  final void Function(int index) onPieceSelected;

  const _RackWidget({
    required this.rack,
    required this.selectedIndex,
    required this.onPieceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(rack.length, (i) {
          final piece = rack[i];
          final isSelected = selectedIndex == i;
          return GestureDetector(
            onTap: piece != null ? () => onPieceSelected(i) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              transform: isSelected
                  ? (Matrix4.identity()..translateByDouble(0.0, -8.0, 0.0, 1.0))
                  : Matrix4.identity(),
              child: CustomPaint(
                size: const Size(64, 64),
                painter: piece != null
                    ? _HexPainter(piece: piece, isSelected: isSelected)
                    : _EmptyHexPainter(),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyHexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.9;
    final paint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (3.14159 / 3) * i - 3.14159 / 6;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EmptyHexPainter old) => false;
}

class _HexPainter extends CustomPainter {
  final Piece piece;
  final bool isSelected;
  const _HexPainter({required this.piece, this.isSelected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.9;

    final fillColor = piece.isSubtract
        ? const Color(0xFF5C1A1A)
        : piece.isSum
        ? const Color(0xFF1A5C4A)
        : const Color(0xFF4A7A9B);

    final borderColor = piece.isSubtract
        ? const Color(0xFFFF6B6B)
        : piece.isSum
        ? const Color(0xFF64FFDA)
        : isSelected
        ? Colors.white
        : Colors.white24;

    final fillPaint = Paint()..color = fillColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (3.14159 / 3) * i - 3.14159 / 6;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    final label = piece.isSubtract
        ? '✕'
        : piece.isSum
        ? '+${piece.value}'
        : '${piece.value}';

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: piece.isSubtract ? const Color(0xFFFF6B6B) : Colors.white,
          fontSize: 22,
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
  bool shouldRepaint(_HexPainter old) =>
      old.piece != piece || old.isSelected != isSelected;
}
