import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/games_service.dart';
import 'hex_board.dart';

/// Callback types for communicating back to Flutter widgets.
typedef ScoreCallback = void Function(int score, int level);
typedef GameOverCallback = void Function(int finalScore);

class HexCascadeGame extends FlameGame {
  final ScoreCallback? onScoreChanged;
  final GameOverCallback? onGameOver;

  final GameState state;
  late final HexBoard _hexGrid;

  HexCascadeGame({required this.state, this.onScoreChanged, this.onGameOver})
    : super();

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _hexGrid = HexBoard();
    await add(_hexGrid);

    if (state.board.every((row) => row.every((t) => t == null))) {
      _hexGrid.build();
    } else {
      _hexGrid.populateFromState(
        List.generate(GameState.rows, (_) => List.filled(GameState.cols, null)),
        state.board,
      );
    }
  }

  Future<void> submitScore() async {
    await GamesService.submitScore(state.score);
  }
}
