import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import '../services/games_service.dart';
import 'hex_grid.dart';

/// Callback types for communicating back to Flutter widgets.
typedef ScoreCallback = void Function(int score, int level);
typedef GameOverCallback = void Function(int finalScore);

class HexCascadeGame extends FlameGame {
  final ScoreCallback? onScoreChanged;
  final GameOverCallback? onGameOver;

  final GameState state;
  late final HexGrid _hexGrid;

  static const int _movesPerLevel = 20;
  static const int _scoreLevelUp = 500;

  HexCascadeGame({required this.state, this.onScoreChanged, this.onGameOver})
    : super();

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _hexGrid = HexGrid();
    await add(_hexGrid);

    if (state.board.every((row) => row.every((t) => t == null))) {
      _hexGrid.buildRandom();
    } else {
      _hexGrid.populateFromState(
        List.generate(GameState.rows, (_) => List.filled(GameState.cols, null)),
        state.board,
      );
    }
  }

  void onTileTapped(int row, int col) {
    final (score, changed) = _hexGrid.handleTap(row, col);
    if (!changed) return;

    state.score += score;
    state.movesInLevel++;

    // Refill board after cascades.
    _hexGrid.refillEmptyCells();

    // Level up logic.
    if (state.score >= state.level * _scoreLevelUp) {
      state.level++;
    }

    // Game over after too many moves (simple termination condition).
    if (state.movesInLevel >= _movesPerLevel * state.level) {
      onGameOver?.call(state.score);
      return;
    }

    onScoreChanged?.call(state.score, state.level);
    _autosave();
  }

  Future<void> _autosave() async {
    state.board = _hexGrid.toStateTiles();
    await SaveService.saveGame(state);
    if (GamesService.isSignedIn) {
      await GamesService.saveSnapshot(state.toJson());
    }
  }

  Future<void> submitScore() async {
    await GamesService.submitScore(state.score);
  }
}
