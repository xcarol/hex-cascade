import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/games_service.dart';
import 'hex_board.dart';

/// Callback types for communicating back to Flutter widgets.
typedef ScoreCallback = void Function(int score, int level);
typedef GameOverCallback = void Function(int finalScore);
typedef PieceCallback = void Function(int value);

class HexCascadeGame extends FlameGame {
  final ScoreCallback? onScoreChanged;
  final GameOverCallback? onGameOver;
  final PieceCallback? onPieceChanged;

  final GameState state;
  late final HexBoard _hexGrid;

  HexCascadeGame({
    required this.state,
    this.onScoreChanged,
    this.onGameOver,
    this.onPieceChanged,
  }) : super();

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _hexGrid = HexBoard(onCellTapped: _onCellTapped);
    await add(_hexGrid);

    if (state.board.every((row) => row.every((t) => t == null))) {
      _hexGrid.build();
    } else {
      _hexGrid.populateFromState(state.board);
    }
  }

  void _onCellTapped(int row, int col) {
    final piece = state.currentPieceValue;
    if (piece == null) return;

    // Col·loca la fitxa
    state.board[row][col] = HexTile(row: row, col: col, value: piece);

    // Acumula als veïns
    _accumulateNeighbours(row, col, piece);

    // Genera la següent fitxa
    state.generateNextPiece();
    onPieceChanged?.call(state.currentPieceValue!);

    // Refresca el tauler visual
    _hexGrid.populateFromState(state.board);
  }

  void _accumulateNeighbours(int row, int col, int value) {
    final neighbours = _getNeighbours(row, col);
    for (final n in neighbours) {
      final r = n[0];
      final c = n[1];
      final tile = state.board[r][c];
      if (tile != null) {
        state.board[r][c] = HexTile(
          row: r,
          col: c,
          value: (tile.value ?? 0) + value,
          color: tile.color,
        );
      }
    }
  }

  List<List<int>> _getNeighbours(int row, int col) {
    final isOdd = row % 2 == 1;
    return [
          [row - 1, isOdd ? col : col - 1], // dalt-esquerra
          [row - 1, isOdd ? col + 1 : col], // dalt-dreta
          [row, col - 1], // esquerra
          [row, col + 1], // dreta
          [row + 1, isOdd ? col : col - 1], // baix-esquerra
          [row + 1, isOdd ? col + 1 : col], // baix-dreta
        ]
        .where(
          (n) =>
              n[0] >= 0 &&
              n[0] < GameState.rows &&
              n[1] >= 0 &&
              n[1] < GameState.cols,
        )
        .toList();
  }

  Future<void> submitScore() async {
    await GamesService.submitScore(state.score);
  }
}
