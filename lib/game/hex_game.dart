import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hex_cascade/models/piece_generator.dart';
import 'package:hex_cascade/models/xplosion_engine.dart';
import '../models/game_state.dart';
import 'hex_cell.dart' show PlacementMode;
import 'hex_board.dart';

/// Callback types for communicating back to Flutter widgets.
typedef ScoreCallback = void Function(int score, int level, int threshold);
typedef GameOverCallback = void Function(int finalScore);
typedef PieceCallback = void Function(Piece piece);

class HexCascadeGame extends FlameGame {
  final ScoreCallback? onScoreChanged;
  final GameOverCallback? onGameOver;
  final PieceCallback? onPieceChanged;

  final GameState state;
  late final HexBoard _hexGrid;
  final List<GameStateSnapshot> _history = [];

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

    _updatePlacementMode();
  }

  void _onCellTapped(int row, int col) {
    _saveState();
    final piece = state.currentPiece;
    if (piece == null) return;

    final tile = state.board[row][col];

    if (piece.isNormal && tile != null) return;
    if (piece.isNegative && tile == null) return;
    if (piece.isSpecial &&
        tile != null &&
        (tile.value ?? 0) + piece.value != state.explosionThreshold) {
      return;
    }

    final result = ExplosionEngine.process(
      board: state.board,
      row: row,
      col: col,
      value: piece.value,
      threshold: state.explosionThreshold,
      pieceType: piece.type,
    );

    state.board = result.board;
    state.score += result.pointsScored;

    if (state.isBoardEmpty) {
      _onLevelUp();
      return;
    }

    onScoreChanged?.call(state.score, state.level, state.explosionThreshold);
    state.moveCount++;
    state.generateNextPiece();
    onPieceChanged?.call(state.currentPiece!);
    _hexGrid.populateFromState(state.board);
    _updatePlacementMode();

    if (_isGameOver()) {
      onGameOver?.call(state.score);
    }
  }

  void _onLevelUp() {
    state.level++;
    state.moveCount = 0;

    final bonus = state.level * 100;
    state.score += bonus;
    onScoreChanged?.call(state.score, state.level, state.explosionThreshold);

    state.generateNextPiece();
    onPieceChanged?.call(state.currentPiece!);
    _hexGrid.populateFromState(state.board);
    _updatePlacementMode();
  }

  bool _isGameOver() {
    final piece = state.currentPiece;
    if (piece == null) return false;

    if (piece.isNegative) {
      return state.board.every((row) => row.every((tile) => tile == null));
    } else {
      return state.isBoardFull;
    }
  }

  void _updatePlacementMode() {
    final piece = state.currentPiece;
    if (piece == null) return;

    if (piece.isNegative) {
      _hexGrid.setPlacementMode(PlacementMode.negative);
    } else if (piece.isSpecial) {
      _hexGrid.setPlacementMode(PlacementMode.special);
    } else {
      _hexGrid.setPlacementMode(PlacementMode.normalOccupied);
    }
  }

  void _saveState() {
    _history.add(state.createSnapshot());
    if (_history.length > 20) {
      _history.removeAt(0);
    }
  }

  bool canUndo() => _history.isNotEmpty;

  void undo() {
    if (_history.isEmpty) return;

    final snapshot = _history.removeLast();
    state.board = snapshot.board;
    state.score = snapshot.score;
    state.level = snapshot.level;
    state.currentPiece = snapshot.currentPiece;
    state.moveCount = snapshot.moveCount;

    onScoreChanged?.call(state.score, state.level, state.explosionThreshold);
    if (state.currentPiece != null) {
      onPieceChanged?.call(state.currentPiece!);
    }
    _hexGrid.populateFromState(state.board);
  }
}
